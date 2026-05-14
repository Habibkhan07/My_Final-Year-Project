"""Canonical-envelope exception classes for wallet operations.

Mirrors ``bookings.exceptions.BookingValidationError`` and
``chatbot.exceptions.ChatbotError`` — the custom DRF exception handler at
``core.common.failures.exception`` matches on these classes and emits the
project's ``{status, code, message, errors}`` envelope without letting DRF's
default flow flatten ``code`` into the generic ``"validation_error"``.

Two distinct error types live here, with distinct semantics — do NOT
conflate:

* ``InsufficientFundsError`` (400) — raised by ``record_transaction`` when
  a ``WITHDRAWAL_DEBIT`` would drive the balance below zero. Tech cannot
  borrow money from the platform via withdrawal. The per-type sufficiency
  policy lives in ``wallet.services.ledger.record_transaction``: commission
  and refund debits proceed even into negative territory (driving the
  lockout signal consumed at job-accept time); withdrawal is the ONLY
  debit the ledger refuses to record.

* ``WalletLockoutError`` (403) — raised by tech-facing action services
  (booking accept, etc.) when the technician's wallet balance is currently
  negative. The lockout signal is structurally ``balance < 0`` — not a
  configurable threshold — because commission magnitude is unknown at
  accept-job time (decided in the post-inspection quote phase), so any
  positive threshold would be arbitrary.

Status 403 vs 400 is intentional: lockout is a permission-style refusal
("you may not perform this action right now"), distinct from a validation
failure on the request body itself.
"""
from __future__ import annotations

from rest_framework import status as drf_status
from rest_framework.exceptions import APIException


class InsufficientFundsError(APIException):
    """Raised when a ``WITHDRAWAL_DEBIT`` ledger write would overdraw.

    Carries the requested and available amounts so the UI can render an
    exact "Cannot withdraw X, you have Y" message without a second
    round-trip. Both values are PKR integers — paisa precision is moot
    for this user-facing error.

    The exception raises BEFORE any ledger row is created, inside the
    ledger's ``transaction.atomic()`` block, so the failed attempt leaves
    no audit trace. (If forensic visibility of failed withdrawals is
    needed later, the WithdrawalRequest row at status=PENDING_REVIEW
    serves that purpose — the ledger is for executed money movement only.)
    """

    status_code = drf_status.HTTP_400_BAD_REQUEST
    default_code = "insufficient_funds"
    default_detail = "Insufficient wallet balance for withdrawal."

    def __init__(self, *, requested_pkr: int, available_pkr: int):
        self.code = "insufficient_funds"
        self.message = (
            f"Cannot withdraw Rs. {requested_pkr}. "
            f"Available balance: Rs. {available_pkr}."
        )
        # Wrapped as list-of-string to match the canonical envelope's
        # ``errors: dict[str, list[str]]`` shape (see BookingValidationError
        # and ChatbotError for the same convention).
        self.errors = {
            "requested_pkr": [str(requested_pkr)],
            "available_pkr": [str(available_pkr)],
        }
        super().__init__(detail=self.message, code=self.code)


class WalletLockoutError(APIException):
    """Raised when a tech-facing action is gated by negative-balance lockout.

    Carries both the signed balance (negative — ``balance_pkr``) and the
    owed amount (positive — ``owed_pkr``) so the UI banner can compose
    "Top up Rs. X to come online" without client-side math. Both values
    are PKR integers.

    This exception does NOT touch the ledger. It is raised by action
    services (e.g. ``bookings.services.job_request_action.accept_job_booking``)
    after reading the technician row under ``select_for_update`` — see
    ``wallet.selectors.lockout.is_wallet_locked`` for the single source of
    truth on the rule.
    """

    status_code = drf_status.HTTP_403_FORBIDDEN
    default_code = "wallet_lockout"
    default_detail = "Wallet is locked due to negative balance."

    def __init__(self, *, balance_pkr: int, owed_pkr: int):
        self.code = "wallet_lockout"
        self.message = "Wallet is locked. Top up to continue accepting jobs."
        self.errors = {
            "balance_pkr": [str(balance_pkr)],
            "owed_pkr": [str(owed_pkr)],
        }
        super().__init__(detail=self.message, code=self.code)
