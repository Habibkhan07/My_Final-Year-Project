"""Technician online-status toggle service.

The counterpart to the ledger's auto-offline gate in
``wallet/services/ledger.py``. The ledger flips ``is_online = False``
when a write drives ``current_wallet_balance`` strictly negative; this
service is the user-initiated path that flips ``is_online`` in either
direction, with the lockout rule re-checked under the same row lock
so a commission landing mid-toggle cannot slip past.

Architecture
------------
* ``select_for_update`` on the TechnicianProfile row — same lock the
  ledger acquires. Two competing writers (ledger commission vs. user
  tap-online) serialize at this lock; whichever loses sees the other's
  committed state and behaves correctly.
* Lockout decision delegated to ``wallet.selectors.lockout.is_wallet_locked``
  — the single source of truth for the ``balance < 0`` rule. Do NOT
  inline the comparison here; the whole point of that selector is one
  place to change if the rule ever changes.
* Going OFFLINE is always allowed (even when locked). Opting out of work
  is structurally safe; only opting IN requires sufficient funds.
* Status guard: only ``APPROVED`` technicians may toggle. PENDING /
  REJECTED accounts cannot self-promote into the dispatch pool.

Wire shape returned
-------------------
``{is_online: bool, current_wallet_balance: str}`` — the balance is
returned so the dashboard can self-correct without a separate refetch
(e.g. if a top-up cleared lockout between the dashboard load and the
toggle tap, the FE sees the fresh number in the same round trip).
"""
from __future__ import annotations

from decimal import Decimal

from django.contrib.auth import get_user_model
from django.db import transaction
from rest_framework.exceptions import PermissionDenied

from technicians.models import TechnicianProfile
from wallet.exceptions import WalletLockoutError
from wallet.selectors.lockout import is_wallet_locked, lockout_status

User = get_user_model()


def set_online(*, user, desired: bool) -> dict:
    """Toggle ``request.user``'s tech profile ``is_online`` flag.

    SECURITY: scoped to the supplied ``user`` only — never accepts a tech
    id from the request. The view layer passes ``request.user`` directly.

    Parameters
    ----------
    user:
        The authenticated User. MUST have a related TechnicianProfile.
    desired:
        Target value for ``is_online``. ``True`` = go online (gated on
        lockout); ``False`` = go offline (always allowed).

    Returns
    -------
    dict
        ``{"is_online": bool, "current_wallet_balance": str}`` after the
        commit. Balance is stringified to preserve Decimal precision on
        the wire (matches the ledger's broadcast payload shape).

    Raises
    ------
    PermissionDenied
        Tech has no profile, or profile is not APPROVED. Mapped to 403
        by the project's custom exception handler.
    WalletLockoutError
        ``desired=True`` AND wallet balance is strictly negative. Mapped
        to 403 ``wallet_lockout`` envelope identical to the one returned
        by ``accept_job_booking`` — same FE handling path.
    """
    with transaction.atomic():
        # Lock + reload. ``select_for_update`` queues this writer behind
        # any in-flight ledger commission against the same row, so the
        # lockout check below sees the latest committed balance — not a
        # snapshot that another connection has already invalidated.
        try:
            tech = (
                TechnicianProfile.objects
                .select_for_update()
                .select_related('user')
                .get(user=user)
            )
        except TechnicianProfile.DoesNotExist:
            raise PermissionDenied('No technician profile for this user.')

        if tech.status != 'APPROVED':
            raise PermissionDenied(
                f'Technician profile is {tech.status}, not APPROVED.'
            )

        # Admin-suspension gate. ``is_active=False`` is set atomically with
        # ``is_online=False`` by the ``suspend_selected`` admin action
        # (technicians/admin.py:642-645). A suspended tech must NOT be able
        # to self-promote back online — that would create the contradictory
        # state ``is_active=False, is_online=True`` which the customer-side
        # matchmaker filter at ``matchmaking_selectors.py:46`` would silently
        # exclude anyway, but any future code path that gates on ``is_online``
        # alone (without ANDing ``is_active``) would let the suspended tech
        # leak through. Refuse here as the invariant guard.
        if not tech.is_active:
            raise PermissionDenied(
                'Technician profile is suspended.'
            )

        if desired and is_wallet_locked(tech):
            # Same envelope as accept_job_booking — the FE's existing
            # wallet_lockout handler is reused without modification.
            status = lockout_status(tech)
            raise WalletLockoutError(
                balance_pkr=status['balance_pkr'],
                owed_pkr=status['owed_pkr'],
            )

        # No-op short-circuit: already in desired state. We still take
        # the lock above (cheap) so concurrent callers can't see a
        # different value across the read. Skip the write to avoid an
        # unnecessary UPDATE and an unnecessary save() signal cascade.
        if tech.is_online == desired:
            return {
                'is_online': tech.is_online,
                'current_wallet_balance': str(tech.current_wallet_balance),
            }

        tech.is_online = desired
        tech.save(update_fields=['is_online'])

        return {
            'is_online': tech.is_online,
            'current_wallet_balance': str(tech.current_wallet_balance),
        }
