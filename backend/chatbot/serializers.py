"""DRF serializers for chatbot views.

All serializers explicitly whitelist fields (never ``fields='__all__'``)
per CLAUDE.md mass-assignment guard. ``MessageSerializer`` is a single
endpoint that handles three input kinds (text, form, attachment_done)
via discriminated validation — the alternative would be three sibling
endpoints with duplicated auth, which clutters the URL surface for no
real benefit.
"""
from __future__ import annotations

from rest_framework import serializers

#This is a comment
# This is a comment

class StartConversationSerializer(serializers.Serializer):
    """Body of POST /api/chat/<persona>/start/.

    ``context`` is a free-form JSON dict — its schema is owned by the
    persona (e.g. dispute requires ``{"booking_id": int}``). The persona's
    ``is_eligible_to_start`` validates contents; we just enforce shape
    here (must be a dict, not a string or list).
    """
    context = serializers.DictField(required=False, default=dict)


class BankFormSerializer(serializers.Serializer):
    """The bank-details form submitted during the PAYOUT phase.

    The IBAN regex matches our content-safety pattern (ISO-13616-ish:
    country code + 2 digits + 11-30 alphanumeric). Pakistani IBANs
    start with PK; the regex tolerates other countries for forward
    compatibility.
    """
    bank_name = serializers.CharField(max_length=64)
    account_title = serializers.CharField(max_length=128)
    iban = serializers.RegexField(regex=r"^[A-Z]{2}\d{2}[A-Z0-9]{11,30}$")


_MESSAGE_KINDS = ("text", "form", "attachment_done")


class MessageSerializer(serializers.Serializer):
    """Body of POST /api/chat/conversations/<id>/message/.

    ``kind`` discriminates the ``payload`` shape:
      - text             → payload is a string (max 2000 chars)
      - form             → payload is a bank-details dict (validated by
                            BankFormSerializer)
      - attachment_done  → payload is null/absent (signal only)
    """
    kind = serializers.ChoiceField(choices=_MESSAGE_KINDS)
    payload = serializers.JSONField(required=False, allow_null=True)

    def validate(self, attrs):
        kind = attrs["kind"]
        payload = attrs.get("payload")

        if kind == "text":
            if not isinstance(payload, str) or not payload.strip():
                raise serializers.ValidationError(
                    {"payload": ["Must be a non-empty string for kind=text."]}
                )
            if len(payload) > 2000:
                raise serializers.ValidationError(
                    {"payload": ["Maximum 2000 characters."]}
                )
            attrs["payload"] = payload

        elif kind == "form":
            if not isinstance(payload, dict):
                raise serializers.ValidationError(
                    {"payload": ["Must be a JSON object for kind=form."]}
                )
            bank = BankFormSerializer(data=payload)
            bank.is_valid(raise_exception=True)
            attrs["payload"] = dict(bank.validated_data)

        else:  # attachment_done
            attrs["payload"] = None

        return attrs


class AttachmentUploadSerializer(serializers.Serializer):
    """Body of POST /api/chat/conversations/<id>/attachments/.

    multipart upload. ``ImageField`` validates that the file is a
    real image (Pillow can parse it) — non-image files are rejected
    here before they reach the Attachment.save EXIF-strip path.
    """
    file = serializers.ImageField()
