"""Canonical-envelope exception classes for wallet operations.

Mirrors ``bookings.exceptions.BookingValidationError`` and
``chatbot.exceptions.ChatbotError`` — the custom DRF exception handler at
``core.common.failures.exception`` matches on these classes and emits the
project's ``{status, code, message, errors}`` envelope without letting DRF's
default flow flatten ``code`` into the generic ``"validation_error"``.

Four distinct error types live here, with distinct semantics — do NOT
conflate:

* ``InsufficientFundsError`` (400) — raised by ``record_transaction`` AND by
  ``withdrawal_service.create_withdrawal_request`` when a withdrawal amount
  would drive the balance below zero. The request-time gate (service) and
  the ledger-time gate (record_transaction) share this single exception
  type by design: the frontend handles one envelope shape regardless of
  which gate fires. Tech cannot borrow money from the platform via
  withdrawal at either point.

* ``WalletLockoutError`` (403) — raised by tech-facing action services
  (booking accept, withdrawal submit, etc.) when the technician's wallet
  balance is currently negative. The lockout signal is structurally
  ``balance < 0`` — not a configurable threshold — because commission
  magnitude is unknown at accept-job time (decided in the post-inspection
  quote phase), so any positive threshold would be arbitrary.

* ``DuplicatePendingWithdrawalError`` (409) — raised when the tech tries to
  submit a withdrawal while an existing one is still ``PENDING_REVIEW``.
  Single in-flight withdrawal per tech is a workflow guarantee, not a
  validation rule on the request body.

* ``InactiveTechnicianError`` (403) — raised when a non-APPROVED tech
  attempts any wallet-mutating action. Permission-style refusal, mirrors
  ``WalletLockoutError`` semantics for a different gate.

Status 403 vs 400 vs 409 is intentional: 400 = bad request shape, 403 =
permission-style refusal, 409 = server-state conflict with a well-formed
request. The frontend's ``_mapFailures`` switch uses ``code``, not
``status``, to pick the sealed-class — but the HTTP status carries the
correct semantic for logs, monitoring, and any future generic handler.
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


class DuplicatePendingWithdrawalError(APIException):
    """Raised when a tech tries to submit a withdrawal while one is still PENDING_REVIEW.

    The platform enforces "one in-flight withdrawal at a time" per tech: the
    admin queue stays unambiguous (one approve-or-reject decision maps to one
    request), and the tech UX has no "which one did admin process?" confusion.
    Past REJECTED / PROCESSED requests do NOT block a fresh submit — only an
    open ``PENDING_REVIEW`` (and ``APPROVED``-but-not-yet-fulfilled, which is
    the same in-flight class).

    Carries ``pending_request_id`` so the frontend can deep-link to that
    request's status row if the tech taps the error.

    Status 409 (Conflict) is intentional: the request is well-formed but the
    server's state — an existing pending row — prevents acceptance. Distinct
    from 400 (request shape invalid) and 403 (permission denied).
    """

    status_code = drf_status.HTTP_409_CONFLICT
    default_code = "duplicate_pending_withdrawal"
    default_detail = "A previous withdrawal request is still under review."

    def __init__(self, *, pending_request_id: int):
        self.code = "duplicate_pending_withdrawal"
        self.message = (
            "A previous withdrawal request is still under review. "
            "Wait for it to be processed before submitting a new one."
        )
        self.errors = {
            "pending_request_id": [str(pending_request_id)],
        }
        super().__init__(detail=self.message, code=self.code)


class InactiveTechnicianError(APIException):
    """Raised when a non-APPROVED tech attempts a wallet-mutating action.

    The ``TechnicianProfile.status`` lifecycle is ``PENDING → APPROVED |
    REJECTED``. Only ``APPROVED`` technicians may move money — pending
    onboardings cannot withdraw imagined balances, and rejected accounts
    must not be able to drain whatever credit they accumulated before
    rejection. Same envelope shape and semantics as ``WalletLockoutError``
    (permission-style refusal, not validation), hence 403.

    Carries ``status`` so the UI can render the right message ("approval
    pending" vs "account rejected") without a second round-trip.
    """

    status_code = drf_status.HTTP_403_FORBIDDEN
    default_code = "inactive_technician"
    default_detail = "Technician account is not approved."

    def __init__(self, *, status: str):
        self.code = "inactive_technician"
        self.message = "Your technician account is not approved for withdrawals."
        self.errors = {
            "status": [str(status)],
        }
        super().__init__(detail=self.message, code=self.code)
