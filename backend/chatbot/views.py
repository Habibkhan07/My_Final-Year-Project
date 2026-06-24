"""Thin DRF views — parse request, delegate to chatbot.services, respond.

Five endpoints (mounted under /api/chat/ — see chatbot/urls.py):

  POST <persona>/start/             open or resume a conversation
  POST conversations/<id>/message/  process one user turn
  POST conversations/<id>/attachments/  upload a file (multipart)
  POST conversations/<id>/close/    explicit close (idempotent)
  GET  conversations/<id>/          fetch state + recent messages

Per CLAUDE.md: views contain no business logic. Service exceptions are
translated to ``ChatbotError`` (canonical envelope) and re-raised — the
exception handler renders the envelope.
"""

# THis is a comment
# This is a comment
from __future__ import annotations

from django.conf import settings
from django.db import transaction
from rest_framework import status as drf_status
from rest_framework.decorators import api_view, parser_classes, permission_classes
from rest_framework.parsers import JSONParser, MultiPartParser
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from chatbot import personas
from chatbot.exceptions import (
    ERROR_ATTACHMENT_COUNT_EXCEEDED,
    ERROR_ATTACHMENT_TOO_LARGE,
    ERROR_CONVERSATION_CLOSED,
    ERROR_CONVERSATION_NOT_FOUND,
    ERROR_LLM_QUOTA_EXCEEDED,
    ERROR_NOT_ELIGIBLE_TO_START,
    ERROR_PERSONA_NOT_FOUND,
    ERROR_UNSUPPORTED_MESSAGE_KIND,
    ChatbotError,
)
from chatbot.models import Attachment, Conversation
from chatbot.personas.dispute.flow import (
    ConversationAlreadyClosed,
    UnsupportedMessageKind,
)
from chatbot.serializers import (
    AttachmentUploadSerializer,
    MessageSerializer,
    StartConversationSerializer,
)
from chatbot.services import conversation as conv_service
from chatbot.services.quota import QuotaExceeded


# ---- POST /api/chat/<persona_key>/start/ ---------------------------------

@api_view(["POST"])
@permission_classes([IsAuthenticated])
def start_view(request, persona_key: str):
    # SECURITY: persona.is_eligible_to_start scopes the booking lookup
    # to request.user with select_for_update, so IDOR and races are
    # blocked at the service layer.
    try:
        personas.get(persona_key)
    except personas.PersonaNotFound:
        raise ChatbotError(
            code=ERROR_PERSONA_NOT_FOUND,
            message=f"Unknown persona: {persona_key}.",
            status=drf_status.HTTP_404_NOT_FOUND,
        )

    body = StartConversationSerializer(data=request.data)
    body.is_valid(raise_exception=True)

    try:
        conv = conv_service.start_conversation(
            request.user,
            persona_key,
            dict(body.validated_data.get("context") or {}),
        )
    except conv_service.NotEligibleToStart:
        raise ChatbotError(
            code=ERROR_NOT_ELIGIBLE_TO_START,
            message="You're not eligible to start this conversation right now.",
            status=drf_status.HTTP_400_BAD_REQUEST,
        )

    return Response(
        _serialize_conversation_start(conv),
        status=drf_status.HTTP_201_CREATED,
    )


# ---- POST /api/chat/conversations/<id>/message/ --------------------------

@api_view(["POST"])
@permission_classes([IsAuthenticated])
def message_view(request, conversation_id: int):
    # SECURITY: conv_service.handle_message scopes the Conversation lookup
    # to request.user. Wrong-user requests get ConversationNotFound →
    # 404 envelope, never 403 (which would confirm existence).
    body = MessageSerializer(data=request.data)
    body.is_valid(raise_exception=True)

    try:
        result = conv_service.handle_message(
            conversation_id,
            request.user,
            body.validated_data["kind"],
            body.validated_data.get("payload"),
        )
    except conv_service.ConversationNotFound:
        raise ChatbotError(
            code=ERROR_CONVERSATION_NOT_FOUND,
            message="Conversation not found.",
            status=drf_status.HTTP_404_NOT_FOUND,
        )
    except conv_service.ConversationClosed:
        raise ChatbotError(
            code=ERROR_CONVERSATION_CLOSED,
            message="This conversation has already been closed.",
            status=drf_status.HTTP_409_CONFLICT,
        )
    except ConversationAlreadyClosed:
        raise ChatbotError(
            code=ERROR_CONVERSATION_CLOSED,
            message="This conversation has already been closed.",
            status=drf_status.HTTP_409_CONFLICT,
        )
    except QuotaExceeded:
        raise ChatbotError(
            code=ERROR_LLM_QUOTA_EXCEEDED,
            message="Daily AI message limit reached. Please try again tomorrow.",
            status=drf_status.HTTP_429_TOO_MANY_REQUESTS,
        )
    except UnsupportedMessageKind as exc:
        raise ChatbotError(
            code=ERROR_UNSUPPORTED_MESSAGE_KIND,
            message=str(exc) or "Unsupported message kind for this conversation phase.",
            status=drf_status.HTTP_400_BAD_REQUEST,
        )

    # SECURITY: rescope by user even though the service already enforced
    # IDOR — defence-in-depth so any future divergence in the service's
    # scoping cannot leak another user's conversation through this refetch.
    conv = Conversation.objects.get(id=conversation_id, user=request.user)
    return Response(
        _serialize_turn_result(conv, result),
        status=drf_status.HTTP_200_OK,
    )


# ---- POST /api/chat/conversations/<id>/attachments/ ----------------------

@api_view(["POST"])
@parser_classes([MultiPartParser])
@permission_classes([IsAuthenticated])
def attachment_view(request, conversation_id: int):
    # SECURITY: explicit (user, id) scope — IDOR-safe; wrong user → 404.
    # The lookup is done FIRST so the error envelope ordering matches
    # the message endpoint: 404 for missing/IDOR, 409 for closed,
    # 400 for validation. Doing it AFTER body parsing would surface a
    # 400 file-validation error to wrong-user probes that should see
    # 404 (a small but real info leak).
    try:
        conv = Conversation.objects.get(id=conversation_id, user=request.user)
    except Conversation.DoesNotExist:
        raise ChatbotError(
            code=ERROR_CONVERSATION_NOT_FOUND,
            message="Conversation not found.",
            status=drf_status.HTTP_404_NOT_FOUND,
        )

    if conv.is_closed:
        raise ChatbotError(
            code=ERROR_CONVERSATION_CLOSED,
            message="Cannot attach files to a closed conversation.",
            status=drf_status.HTTP_409_CONFLICT,
        )

    body = AttachmentUploadSerializer(data=request.data)
    body.is_valid(raise_exception=True)
    file = body.validated_data["file"]

    max_bytes = settings.CHATBOT_MAX_ATTACHMENT_MB * 1024 * 1024
    if file.size > max_bytes:
        raise ChatbotError(
            code=ERROR_ATTACHMENT_TOO_LARGE,
            message=(
                f"File too large. Maximum size is "
                f"{settings.CHATBOT_MAX_ATTACHMENT_MB} MB."
            ),
            status=drf_status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
        )

    # Race-safe: the count+check+create critical section runs inside a
    # ``select_for_update`` on the Conversation row. Two parallel POSTs
    # serialize on that lock, so the cap can't be silently exceeded by
    # both reading ``existing=9`` before either inserts. The is_closed
    # re-check inside the lock catches the rare case where the
    # conversation was closed between the unlocked check above and the
    # critical section.
    with transaction.atomic():
        conv = (
            Conversation.objects.select_for_update()
            .get(id=conversation_id, user=request.user)
        )
        if conv.is_closed:
            raise ChatbotError(
                code=ERROR_CONVERSATION_CLOSED,
                message="Cannot attach files to a closed conversation.",
                status=drf_status.HTTP_409_CONFLICT,
            )
        existing = conv.attachments.count()
        if existing >= settings.CHATBOT_MAX_ATTACHMENTS:
            raise ChatbotError(
                code=ERROR_ATTACHMENT_COUNT_EXCEEDED,
                message=(
                    f"Maximum {settings.CHATBOT_MAX_ATTACHMENTS} "
                    f"attachments per conversation."
                ),
                status=drf_status.HTTP_400_BAD_REQUEST,
            )
        attachment = Attachment.objects.create(
            conversation=conv,
            file=file,
            mime_type=(
                getattr(file, "content_type", None)
                or "application/octet-stream"
            ),
            size_bytes=file.size,
        )
        # Post-insert count read inside the lock — authoritative even
        # if a parallel request just blocked behind us.
        attachments_count = conv.attachments.count()

    return Response(
        {
            "attachment_id": attachment.id,
            "attachments_count": attachments_count,
        },
        status=drf_status.HTTP_201_CREATED,
    )


# ---- POST /api/chat/conversations/<id>/close/ ----------------------------

@api_view(["POST"])
@permission_classes([IsAuthenticated])
def close_view(request, conversation_id: int):
    # SECURITY: close_conversation scopes lookup to request.user.
    # Idempotent: calling on already-closed returns the existing
    # output_refs without re-running on_close.
    try:
        output_refs = conv_service.close_conversation(
            conversation_id, request.user
        )
    except conv_service.ConversationNotFound:
        raise ChatbotError(
            code=ERROR_CONVERSATION_NOT_FOUND,
            message="Conversation not found.",
            status=drf_status.HTTP_404_NOT_FOUND,
        )

    # SECURITY: rescope by user — defence-in-depth (same rationale as the
    # message_view refetch).
    conv = Conversation.objects.get(id=conversation_id, user=request.user)
    return Response(
        {
            "closed_at": conv.closed_at.isoformat() if conv.closed_at else None,
            "output_refs": output_refs,
        },
        status=drf_status.HTTP_200_OK,
    )


# ---- GET /api/chat/conversations/<id>/ -----------------------------------

@api_view(["GET"])
@permission_classes([IsAuthenticated])
def get_view(request, conversation_id: int):
    # SECURITY: explicit (user, id) scope.
    try:
        conv = (
            Conversation.objects
            .prefetch_related("messages", "attachments")
            .get(id=conversation_id, user=request.user)
        )
    except Conversation.DoesNotExist:
        raise ChatbotError(
            code=ERROR_CONVERSATION_NOT_FOUND,
            message="Conversation not found.",
            status=drf_status.HTTP_404_NOT_FOUND,
        )
    return Response(
        _serialize_conversation_detail(conv),
        status=drf_status.HTTP_200_OK,
    )


# ---- Serialization helpers (kept inline — no reuse outside this module) --

def _serialize_conversation_start(conv: Conversation) -> dict:
    last_bot = (
        conv.messages.filter(role="BOT")
        .order_by("-created_at").first()
    )
    # Resume-safe: a returning user (recovered_id missing, conv still
    # open server-side) may be mid-EVIDENCE or mid-PAYOUT. Hardcoding
    # ui_input_kind="text" here would mount the wrong composer. Ask the
    # persona's flow what directive matches the current state — if the
    # flow doesn't expose ``directive_from_state`` (older persona), fall
    # back to the UNDERSTAND-shaped opening defaults.
    persona = personas.get(conv.persona_key)
    flow = persona.flow_engine
    directive_for_state = getattr(flow, "directive_from_state", None)
    if directive_for_state is not None:
        directive = directive_for_state(conv)
    else:
        directive = {
            "ui_input_kind": "text",
            "ui_form_schema": None,
            "ui_hint": "Tell me what happened",
        }
    return {
        "conversation_id": conv.id,
        "persona_key": conv.persona_key,
        "current_phase": conv.state.get("phase", ""),
        "bot_message": last_bot.text if last_bot else "",
        "ui_input_kind": directive["ui_input_kind"],
        "ui_form_schema": directive["ui_form_schema"],
        "ui_hint": directive["ui_hint"],
        "state_summary": _state_summary(conv),
    }


def _serialize_turn_result(conv: Conversation, result) -> dict:
    return {
        "conversation_id": conv.id,
        "current_phase": conv.state.get("phase", ""),
        "bot_message": result.bot_message,
        "ui_input_kind": result.ui_input_kind,
        "ui_form_schema": result.ui_form_schema,
        "ui_hint": result.ui_hint,
        "state_summary": _state_summary(conv),
        "is_closed": conv.is_closed,
        "output_refs": conv.output_refs or {},
    }


def _serialize_conversation_detail(conv: Conversation) -> dict:
    return {
        "conversation_id": conv.id,
        "persona_key": conv.persona_key,
        "current_phase": conv.state.get("phase", ""),
        "is_closed": conv.is_closed,
        "closed_at": conv.closed_at.isoformat() if conv.closed_at else None,
        "state_summary": _state_summary(conv),
        "messages": [
            {
                "id": m.id,
                "role": m.role,
                "text": m.text,
                "phase": m.phase,
                "created_at": m.created_at.isoformat(),
            }
            for m in conv.messages.order_by("created_at")
        ],
        "attachments": [
            {
                "id": a.id,
                "file": a.file.url if a.file else "",
                "mime_type": a.mime_type,
                "size_bytes": a.size_bytes,
            }
            for a in conv.attachments.order_by("created_at")
        ],
        "output_refs": conv.output_refs or {},
    }


def _state_summary(conv: Conversation) -> dict:
    """Public-safe state snapshot for the frontend. Excludes any field
    that's persona-internal (forced_advance reason, internal counters)."""
    return {
        "phase": conv.state.get("phase", ""),
        "captured_fields": conv.state.get("captured_fields", {}),
        "attachments_count": conv.attachments.count(),
    }
