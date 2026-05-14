"""API tests for chatbot views.

Two layers of coverage:
  1. Each error envelope is reachable and renders the canonical
     ``{status, code, message, errors}`` shape with the right ``code``
     and HTTP status.
  2. A full happy-path transcript: start → text turn → attachment_done
     → form → confirm → close, exercising the entire dispute flow
     end-to-end via the API surface with a FakeAgent.

``get_default_agent`` is patched per-test so no real Gemini calls
happen. ``force_authenticate`` bypasses token auth so we don't have to
create real tokens for every test user.
"""
from __future__ import annotations

import io
import json
from unittest.mock import patch

import pytest
from PIL import Image
from rest_framework.test import APIClient

from chatbot.models import Conversation
from tests.chatbot._fakes import FakeAgent
from tests.factories.accounts import UserFactory
from tests.factories.bookings import (
    JobBookingCompletedFactory,
    JobBookingFactory,
)


# ---- Helpers / fixtures --------------------------------------------------

@pytest.fixture
def api():
    return APIClient()


@pytest.fixture
def completed_booking(db):
    return JobBookingCompletedFactory()


@pytest.fixture
def user(completed_booking):
    return completed_booking.customer


@pytest.fixture
def authed(api, user):
    api.force_authenticate(user=user)
    return api


def _patch_agent(*, text="OK", structured=None, responses=None):
    """Context-manager-style patch for the default agent factory."""
    fake = FakeAgent(text=text, structured=structured, responses=responses)
    return patch(
        "chatbot.services.conversation.get_default_agent",
        return_value=fake,
    ), fake


def _make_image_bytes(size_px: int = 64) -> bytes:
    img = Image.new("RGB", (size_px, size_px), color=(120, 120, 120))
    buf = io.BytesIO()
    img.save(buf, format="JPEG")
    return buf.getvalue()


# ---- Auth ---------------------------------------------------------------

@pytest.mark.django_db
class TestUnauthenticated:
    def test_start_returns_401(self, api):
        resp = api.post("/api/chat/dispute/start/", {"context": {}}, format="json")
        assert resp.status_code == 401

    def test_message_returns_401(self, api):
        resp = api.post("/api/chat/conversations/1/message/", {}, format="json")
        assert resp.status_code == 401

    def test_close_returns_401(self, api):
        resp = api.post("/api/chat/conversations/1/close/")
        assert resp.status_code == 401

    def test_get_returns_401(self, api):
        resp = api.get("/api/chat/conversations/1/")
        assert resp.status_code == 401


# ---- POST /api/chat/<persona>/start/ ------------------------------------

@pytest.mark.django_db
class TestStartEndpoint:
    def test_unknown_persona_404(self, authed):
        resp = authed.post(
            "/api/chat/notapersona/start/",
            {"context": {}},
            format="json",
        )
        assert resp.status_code == 404
        assert resp.data["code"] == "persona_not_found"
        assert "notapersona" in resp.data["message"]

    def test_ineligible_booking_400(self, authed):
        # AWAITING (default) — not eligible.
        booking = JobBookingFactory()
        authed.force_authenticate(user=booking.customer)
        resp = authed.post(
            "/api/chat/dispute/start/",
            {"context": {"booking_id": booking.id}},
            format="json",
        )
        assert resp.status_code == 400
        assert resp.data["code"] == "not_eligible_to_start"

    def test_other_users_booking_400(self, authed, completed_booking):
        other = UserFactory()
        authed.force_authenticate(user=other)
        resp = authed.post(
            "/api/chat/dispute/start/",
            {"context": {"booking_id": completed_booking.id}},
            format="json",
        )
        assert resp.status_code == 400
        # IDOR returns same code as eligibility failure (no info leak).
        assert resp.data["code"] == "not_eligible_to_start"

    def test_success_returns_conversation(self, authed, completed_booking):
        with _patch_agent()[0]:
            resp = authed.post(
                "/api/chat/dispute/start/",
                {"context": {"booking_id": completed_booking.id}},
                format="json",
            )
        assert resp.status_code == 201
        assert "conversation_id" in resp.data
        assert resp.data["persona_key"] == "dispute"
        assert resp.data["current_phase"] == "UNDERSTAND"
        assert resp.data["bot_message"]  # opening greeting
        assert resp.data["ui_input_kind"] == "text"

    def test_resumes_existing_conversation(self, authed, completed_booking):
        with _patch_agent()[0]:
            first = authed.post(
                "/api/chat/dispute/start/",
                {"context": {"booking_id": completed_booking.id}},
                format="json",
            )
            second = authed.post(
                "/api/chat/dispute/start/",
                {"context": {"booking_id": completed_booking.id}},
                format="json",
            )
        assert first.data["conversation_id"] == second.data["conversation_id"]
        assert Conversation.objects.count() == 1


# ---- POST /api/chat/conversations/<id>/message/ -------------------------

@pytest.mark.django_db
class TestMessageEndpoint:
    def _start(self, authed, booking) -> int:
        with _patch_agent()[0]:
            resp = authed.post(
                "/api/chat/dispute/start/",
                {"context": {"booking_id": booking.id}},
                format="json",
            )
        return resp.data["conversation_id"]

    def test_nonexistent_conversation_404(self, authed):
        resp = authed.post(
            "/api/chat/conversations/999999/message/",
            {"kind": "text", "payload": "hi"},
            format="json",
        )
        assert resp.status_code == 404
        assert resp.data["code"] == "conversation_not_found"

    def test_other_users_conversation_404(self, authed, completed_booking):
        conv_id = self._start(authed, completed_booking)
        # Switch to another user.
        other = UserFactory()
        authed.force_authenticate(user=other)
        resp = authed.post(
            f"/api/chat/conversations/{conv_id}/message/",
            {"kind": "text", "payload": "hi"},
            format="json",
        )
        assert resp.status_code == 404
        assert resp.data["code"] == "conversation_not_found"

    def test_closed_conversation_409(self, authed, completed_booking):
        conv_id = self._start(authed, completed_booking)
        Conversation.objects.filter(id=conv_id).update(is_closed=True)
        resp = authed.post(
            f"/api/chat/conversations/{conv_id}/message/",
            {"kind": "text", "payload": "hi"},
            format="json",
        )
        assert resp.status_code == 409
        assert resp.data["code"] == "conversation_closed"

    def test_invalid_kind_returns_validation_error(self, authed, completed_booking):
        conv_id = self._start(authed, completed_booking)
        resp = authed.post(
            f"/api/chat/conversations/{conv_id}/message/",
            {"kind": "shout", "payload": "anything"},
            format="json",
        )
        assert resp.status_code == 400
        assert resp.data["code"] == "validation_error"

    def test_empty_text_payload_returns_validation_error(self, authed, completed_booking):
        conv_id = self._start(authed, completed_booking)
        resp = authed.post(
            f"/api/chat/conversations/{conv_id}/message/",
            {"kind": "text", "payload": ""},
            format="json",
        )
        assert resp.status_code == 400
        assert resp.data["code"] == "validation_error"

    def test_form_kind_validates_iban(self, authed, completed_booking):
        # Push conversation to PAYOUT phase manually.
        conv_id = self._start(authed, completed_booking)
        Conversation.objects.filter(id=conv_id).update(
            state={
                "phase": "PAYOUT",
                "captured_fields": {"issue_summary": "AC failure"},
                "bank_draft": {},
                "off_topic_count": 0,
                "forced_advance": False,
            }
        )
        resp = authed.post(
            f"/api/chat/conversations/{conv_id}/message/",
            {
                "kind": "form",
                "payload": {
                    "bank_name": "HBL",
                    "account_title": "Test",
                    "iban": "not-an-iban",
                },
            },
            format="json",
        )
        assert resp.status_code == 400
        assert resp.data["code"] == "validation_error"

    def test_quota_exceeded_429(self, authed, completed_booking, settings):
        conv_id = self._start(authed, completed_booking)
        settings.CHATBOT_DAILY_CALL_LIMIT = 0
        with _patch_agent()[0]:
            resp = authed.post(
                f"/api/chat/conversations/{conv_id}/message/",
                {"kind": "text", "payload": "hi"},
                format="json",
            )
        assert resp.status_code == 429
        assert resp.data["code"] == "llm_quota_exceeded"

    def test_unsupported_message_kind_400(self, authed, completed_booking):
        conv_id = self._start(authed, completed_booking)
        # UNDERSTAND phase doesn't accept form.
        Conversation.objects.filter(id=conv_id).update(
            state={
                "phase": "UNDERSTAND",
                "captured_fields": {},
                "bank_draft": {},
                "off_topic_count": 0,
                "forced_advance": False,
            }
        )
        # Send form kind — caught by serializer-level kind validation OR
        # by the flow's UnsupportedMessageKind. Either way, 400.
        resp = authed.post(
            f"/api/chat/conversations/{conv_id}/message/",
            {
                "kind": "form",
                "payload": {
                    "bank_name": "HBL",
                    "account_title": "Test",
                    "iban": "PK36HABB0011223344556677",
                },
            },
            format="json",
        )
        assert resp.status_code == 400
        assert resp.data["code"] in (
            "unsupported_message_kind",
            "validation_error",
        )

    def test_text_turn_success(self, authed, completed_booking):
        conv_id = self._start(authed, completed_booking)
        ctx_mgr, _ = _patch_agent(
            text="Tell me more about when this happened.",
            structured={
                "message_to_user": "Tell me more about when this happened.",
                "phase_complete": False,
                "fields_captured": {"issue_summary": "AC failure"},
                "asked_off_topic": False,
            },
        )
        with ctx_mgr:
            resp = authed.post(
                f"/api/chat/conversations/{conv_id}/message/",
                {"kind": "text", "payload": "My AC stopped working."},
                format="json",
            )
        assert resp.status_code == 200
        assert resp.data["bot_message"]
        assert resp.data["state_summary"]["captured_fields"]["issue_summary"] == "AC failure"


# ---- POST /api/chat/conversations/<id>/attachments/ ---------------------

@pytest.mark.django_db
class TestAttachmentEndpoint:
    def _start(self, authed, booking) -> int:
        with _patch_agent()[0]:
            resp = authed.post(
                "/api/chat/dispute/start/",
                {"context": {"booking_id": booking.id}},
                format="json",
            )
        return resp.data["conversation_id"]

    def test_nonexistent_conversation_404(self, authed):
        resp = authed.post(
            "/api/chat/conversations/999999/attachments/",
            {"file": io.BytesIO(_make_image_bytes())},
            format="multipart",
        )
        assert resp.status_code == 404
        assert resp.data["code"] == "conversation_not_found"

    def test_closed_conversation_409(self, authed, completed_booking):
        conv_id = self._start(authed, completed_booking)
        Conversation.objects.filter(id=conv_id).update(is_closed=True)
        from django.core.files.uploadedfile import SimpleUploadedFile
        resp = authed.post(
            f"/api/chat/conversations/{conv_id}/attachments/",
            {"file": SimpleUploadedFile("a.jpg", _make_image_bytes(), "image/jpeg")},
            format="multipart",
        )
        assert resp.status_code == 409
        assert resp.data["code"] == "conversation_closed"

    def test_count_exceeded_400(self, authed, completed_booking, settings):
        conv_id = self._start(authed, completed_booking)
        settings.CHATBOT_MAX_ATTACHMENTS = 1
        from django.core.files.uploadedfile import SimpleUploadedFile

        first = authed.post(
            f"/api/chat/conversations/{conv_id}/attachments/",
            {"file": SimpleUploadedFile("a.jpg", _make_image_bytes(), "image/jpeg")},
            format="multipart",
        )
        assert first.status_code == 201

        second = authed.post(
            f"/api/chat/conversations/{conv_id}/attachments/",
            {"file": SimpleUploadedFile("b.jpg", _make_image_bytes(), "image/jpeg")},
            format="multipart",
        )
        assert second.status_code == 400
        assert second.data["code"] == "attachment_count_exceeded"

    def test_too_large_413(self, authed, completed_booking, settings):
        conv_id = self._start(authed, completed_booking)
        settings.CHATBOT_MAX_ATTACHMENT_MB = 0  # any file is too large
        from django.core.files.uploadedfile import SimpleUploadedFile
        resp = authed.post(
            f"/api/chat/conversations/{conv_id}/attachments/",
            {"file": SimpleUploadedFile("a.jpg", _make_image_bytes(), "image/jpeg")},
            format="multipart",
        )
        assert resp.status_code == 413
        assert resp.data["code"] == "attachment_too_large"

    def test_success_201(self, authed, completed_booking):
        conv_id = self._start(authed, completed_booking)
        from django.core.files.uploadedfile import SimpleUploadedFile
        resp = authed.post(
            f"/api/chat/conversations/{conv_id}/attachments/",
            {"file": SimpleUploadedFile("a.jpg", _make_image_bytes(), "image/jpeg")},
            format="multipart",
        )
        assert resp.status_code == 201
        assert "attachment_id" in resp.data
        assert resp.data["attachments_count"] == 1


# ---- POST /api/chat/conversations/<id>/close/ ---------------------------

@pytest.mark.django_db
class TestCloseEndpoint:
    def test_nonexistent_404(self, authed):
        resp = authed.post("/api/chat/conversations/999999/close/")
        assert resp.status_code == 404
        assert resp.data["code"] == "conversation_not_found"

    def test_idempotent_on_already_closed(self, authed, completed_booking):
        with _patch_agent()[0]:
            start = authed.post(
                "/api/chat/dispute/start/",
                {"context": {"booking_id": completed_booking.id}},
                format="json",
            )
        conv_id = start.data["conversation_id"]
        Conversation.objects.filter(id=conv_id).update(
            is_closed=True, output_refs={"support_ticket_id": 42}
        )
        resp = authed.post(f"/api/chat/conversations/{conv_id}/close/")
        assert resp.status_code == 200
        assert resp.data["output_refs"] == {"support_ticket_id": 42}


# ---- GET /api/chat/conversations/<id>/ ----------------------------------

@pytest.mark.django_db
class TestGetEndpoint:
    def test_nonexistent_404(self, authed):
        resp = authed.get("/api/chat/conversations/999999/")
        assert resp.status_code == 404
        assert resp.data["code"] == "conversation_not_found"

    def test_returns_conversation_state(self, authed, completed_booking):
        with _patch_agent()[0]:
            start = authed.post(
                "/api/chat/dispute/start/",
                {"context": {"booking_id": completed_booking.id}},
                format="json",
            )
        conv_id = start.data["conversation_id"]
        resp = authed.get(f"/api/chat/conversations/{conv_id}/")
        assert resp.status_code == 200
        assert resp.data["conversation_id"] == conv_id
        assert resp.data["persona_key"] == "dispute"
        assert resp.data["is_closed"] is False
        # Opening BOT message should be present.
        assert any(m["role"] == "BOT" for m in resp.data["messages"])


# ---- Full happy path: start → UNDERSTAND → EVIDENCE → PAYOUT → closed --
# CONFIRM is no longer a discrete user-visible step — the form submit
# finalises the ticket inline (see flow._handle_payout_form).

@pytest.mark.django_db
class TestFullHappyPath:
    def test_end_to_end_dispute_flow(self, authed, completed_booking):
        from django.core.files.uploadedfile import SimpleUploadedFile

        # 1) start
        with _patch_agent()[0]:
            r = authed.post(
                "/api/chat/dispute/start/",
                {"context": {"booking_id": completed_booking.id}},
                format="json",
            )
        assert r.status_code == 201
        conv_id = r.data["conversation_id"]

        # 2) UNDERSTAND turn that advances to EVIDENCE
        ctx_mgr, _ = _patch_agent(
            text="Got it.",
            structured={
                "message_to_user": "Got it.",
                "phase_complete": True,
                "fields_captured": {"issue_summary": "AC failure"},
                "asked_off_topic": False,
            },
        )
        with ctx_mgr:
            r = authed.post(
                f"/api/chat/conversations/{conv_id}/message/",
                {"kind": "text", "payload": "AC stopped working after the technician left."},
                format="json",
            )
        assert r.status_code == 200
        assert r.data["state_summary"]["phase"] == "EVIDENCE"
        assert r.data["ui_input_kind"] == "attachment"

        # 3) attach a photo
        r = authed.post(
            f"/api/chat/conversations/{conv_id}/attachments/",
            {"file": SimpleUploadedFile("a.jpg", _make_image_bytes(), "image/jpeg")},
            format="multipart",
        )
        assert r.status_code == 201

        # 4) attachment_done → PAYOUT
        with _patch_agent()[0]:
            r = authed.post(
                f"/api/chat/conversations/{conv_id}/message/",
                {"kind": "attachment_done", "payload": None},
                format="json",
            )
        assert r.status_code == 200
        assert r.data["state_summary"]["phase"] == "PAYOUT"
        assert r.data["ui_input_kind"] == "form"

        # 5) bank form → ticket filed + conversation closed (single turn)
        ctx_mgr, _ = _patch_agent(
            text="Customer reported AC failure after service."
        )
        with ctx_mgr:
            r = authed.post(
                f"/api/chat/conversations/{conv_id}/message/",
                {
                    "kind": "form",
                    "payload": {
                        "bank_name": "HBL",
                        "account_title": "Test User",
                        "iban": "PK36HABB0011223344556677",
                    },
                },
                format="json",
            )
        assert r.status_code == 200
        assert r.data["is_closed"] is True
        assert "support_ticket_id" in r.data["output_refs"]

        # 6) GET shows the closed state + ticket reference
        r = authed.get(f"/api/chat/conversations/{conv_id}/")
        assert r.data["is_closed"] is True
        assert "support_ticket_id" in r.data["output_refs"]
        # System closing message present
        assert any(m["role"] == "SYSTEM" for m in r.data["messages"])
