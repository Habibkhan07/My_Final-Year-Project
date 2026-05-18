# Platform-Funded Promotion → Tech Wallet Reimbursement
**Sprint plan — backend-only**

> Status: drafted, awaiting second-pass review.
> Author conversation: 2026-05-18.
> Scope rule (per `feedback_critical_financial_code` memory): backend in isolation, defensive maximalism, never bundle FE into the same plan.

---

## 1. The locked requirement

A **platform-funded promotion** means:

- (a) **Customer** pays less cash, by the discount amount.
- (b) **Technician** earns exactly the same net as the no-promo case (held harmless).
- (c) **Platform** absorbs the full discount cost (no commission earned on it).

Since customer↔tech is cash-only and tech↔platform is wallet, the only place the platform can compensate the tech is by **crediting the tech's wallet** by the discount amount.

---

## 2. Worked examples

### Case A — Rs.1500 work + Rs.500 inspection + Rs.300 platform promo

| Actor | Cash | Wallet | Net |
|---|---|---|---|
| Customer | −Rs.700 | — | −Rs.700 |
| Tech | +Rs.700 | +Rs.300 reimbursement, −Rs.200 commission (20% of Rs.1000 held-harmless figure) | **+Rs.800** |
| Platform | — | −Rs.300 reimbursement, +Rs.200 commission | **−Rs.100** |

Baseline (no promo): Tech would have collected Rs.1000 cash, paid Rs.200 commission, netted Rs.800. **✓ held-harmless.**

### Case B — Rs.200 work + Rs.500 inspection + Rs.300 promo (degenerate)

- `work_owed = max(0, 200-500) = 0`
- `discount_applied = min(300, 0) = 0`
- `final_cash = 0`
- No reimbursement. No underflow. **✓**

### Case C — Rs.1500 first quote + Rs.500 upsell mid-job

- First approval: `discount_applied = 300`, `final_cash = 700`
- Upsell approval: `is_upsell=True` → discount unchanged
- New running total: Rs.2000. `final_cash = max(0, 2000-500) - 300 = Rs.1200`
- At completion: tech +Rs.1200 cash + Rs.300 wallet − Rs.300 commission (20% × Rs.1500). Net = **+Rs.1200**.
- Baseline no-promo (same upsell): tech +Rs.1500 cash − Rs.300 commission = **+Rs.1200**. **✓ held-harmless.**

---

## 3. Invariants (must hold at every commit boundary)

| # | Invariant |
|---|---|
| I1 | `discount_applied` stamped EXACTLY ONCE, on the FIRST quote approval. Upsell never restamps. Never recomputed. |
| I2 | `discount_applied <= max(0, base_services_total - inspection_fee)`. Cap is silent — never raises, never goes negative. |
| I3 | `final_cash_to_collect = max(0, base_services_total - inspection_fee) - discount_applied`. Always ≥ 0. |
| I4 | A `PROMO_REIMBURSEMENT_CREDIT` ledger row exists IFF (booking is COMPLETED AND `discount_applied > 0`). One-to-one with booking. |
| I5 | `JobCommission.payout_amount = cash_collected + (discount_applied or 0)`. Commission base = held-harmless figure, not raw cash. This is the single behavioral change to `record_commission`. |
| I6 | Only `Promotion.funded_by == PLATFORM` reaches a booking. TECHNICIAN-funded rejected at booking-create. |
| I7 | Reconciliation: `SUM(WalletTransaction WHERE type=PROMO_REIMBURSEMENT_CREDIT) == SUM(discount_applied WHERE status=COMPLETED)`. Always. |

---

## 4. The three formulas (the whole feature in 5 lines of math)

### At `approve_quote` — first approval only (`not quote.is_upsell and booking.discount_applied is None`)

```
work_owed         = max(0, base_services_total - inspection_fee)
discount_applied  = min(promo_discount_snapshot, work_owed)
                    [only if booking.promotion exists and is PLATFORM-funded]
final_cash        = work_owed - discount_applied
```

### At `mark_complete_with_cash`

```
record_promo_reimbursement(booking)                 # credits tech wallet by discount_applied
payout_amount = cash_collected + discount_applied   # held-harmless
record_commission(booking, payout_amount=...)       # commission on held-harmless figure
```

---

## 5. Schema changes (1 migration)

### `wallet/models.py`

```python
class TransactionType(models.TextChoices):
    ...
    PROMO_REIMBURSEMENT_CREDIT = 'PROMO_REIMBURSEMENT_CREDIT', 'Promo reimbursement credit'


class PromoReimbursement(models.Model):
    wallet_transaction = OneToOneField(WalletTransaction, on_delete=PROTECT,
                                       related_name='promo_reimbursement')
    booking            = OneToOneField('bookings.JobBooking', on_delete=PROTECT,
                                       related_name='promo_reimbursement')
    discount_amount    = DecimalField(max_digits=10, decimal_places=2)
    promotion          = ForeignKey('marketing.Promotion', on_delete=SET_NULL,
                                    null=True, blank=True)
    recorded_at        = DateTimeField(auto_now_add=True)
```

Migration: `wallet/migrations/0NNN_add_promo_reimbursement.py`
- Choice expansion only — no DDL for `TransactionType` (choices live in Python).
- `CreateModel` for `PromoReimbursement`.
- Zero data migration needed (no existing rows have `discount_applied` set).

---

## 6. File-by-file change list

### Extend protocol + adapters (3 files)

| File | Change |
|---|---|
| `bookings/services/finance_ports.py` | + `record_promo_reimbursement(*, booking) -> None` on Protocol. Rename `record_commission` param `amount` → `payout_amount` for semantic clarity. |
| `bookings/adapters/null_finance.py` | + `record_promo_reimbursement` as no-op. Match new `record_commission` signature. |
| `wallet/adapters/wallet_finance_adapter.py` | + `record_promo_reimbursement` (~50 lines, mirrors `record_commission` exactly). Patch `record_commission` to use `payout_amount`. |

`record_promo_reimbursement` implementation pattern:
- Return None if `discount_applied is None` or `<= 0`.
- Idempotency pre-check via `PromoReimbursement.objects.filter(booking=).exists()`.
- `record_transaction` with idempotency key `f'booking:{id}:promo_reimbursement'`.
- Attach `PromoReimbursement` subtype with `IntegrityError` catch (race-safety mirror of `JobCommission`).

### Update pricing math (1 file, 2 functions)

`bookings/services/orchestrator.py`:

**`approve_quote` (~line 858):**
```python
work_owed = max(Decimal('0'), running - inspection_credit)

# Stamp ONCE on first approval — never on upsell, never recomputed.
if not quote.is_upsell and booking.discount_applied is None:
    promo = booking.promotion
    if promo is not None and promo.funded_by == Promotion.FundingSource.PLATFORM:
        snapshot = booking.promo_discount_snapshot or Decimal('0')
        booking.discount_applied = min(snapshot, work_owed)
        update_fields.append('discount_applied')

discount = booking.discount_applied or Decimal('0')
booking.final_cash_to_collect = work_owed - discount
```

**`mark_complete_with_cash` (~line 1106):**
```python
finance.record_cash_collected(booking=booking, amount=cash_amount_d, method=method)
finance.record_promo_reimbursement(booking=booking)                  # NEW, BEFORE commission
payout = cash_amount_d + (booking.discount_applied or Decimal('0'))
finance.record_commission(booking=booking, payout_amount=payout)     # renamed param
```

### Gate promos to PLATFORM-funded only (3 files)

| File | Change |
|---|---|
| `marketing/selectors/promotion_selector.py` | `get_active_promotions`: add `.filter(funded_by=Promotion.FundingSource.PLATFORM)`. Home feed + intent selector both hide TECHNICIAN promos. |
| `bookings/services/instant_book_service.py` | `_resolve_promotion` (or just after lookup): `if promotion.funded_by != PLATFORM: raise PromoFirewallError(...)`. Belt + braces — refuses hand-crafted `promotion_id` POSTs. |
| `bookings/exceptions.py` | Extend `PromoFirewallError` with a second variant (or add `TechFundedPromoNotSupportedError`). |

### Wallet read surfaces (3 files)

| File | Change |
|---|---|
| `wallet/selectors/wallet_selectors.py` | Add `PROMO_REIMBURSEMENT_CREDIT` branch in subtitle resolver: `"Promo reimbursement: {promo_code_snapshot} (booking #{id})"`. |
| `wallet/admin.py` | `_SIGN_TONE_MAP`: add `PROMO_REIMBURSEMENT_CREDIT → 'positive'`. + `PromoReimbursementAdmin` (read-only, mirrors `RefundDeductionAdmin`). |
| `wallet/management/commands/seed_wallet.py` | Add a `PROMO_REIMBURSEMENT_CREDIT` row to demo ledger so wallet history shows the new entry kind in seeds. |

---

## 7. Test matrix (mandatory per CLAUDE.md backend testing rules)

| Test file | Cases |
|---|---|
| `backend/tests/factories/wallet.py` | + `PromoReimbursementFactory` |
| `backend/tests/wallet/adapters/test_wallet_finance_adapter_promo.py` | happy (Rs.1500 + Rs.300 promo → ledger row + balance += 300); short-circuit on `discount_applied = None`; short-circuit on 0; idempotent double-call → 1 row; `record_commission(payout_amount=...)` writes correct `commission_amount` |
| `backend/tests/bookings/services/test_orchestrator_promo.py` | approve_quote stamps on first approval (PLATFORM); skips if no promo; skips on upsell; caps at `work_owed`; decline_quote leaves discount unstamped; mark_complete order = reimbursement THEN commission; correct `payout_amount` passed |
| `backend/tests/bookings/services/test_held_harmless_invariant.py` *(integration)* | end-to-end: book → approve → complete; assert tech net == no-promo baseline; assert platform net == −discount; assert customer cash = `quote - inspection - discount` |
| `backend/tests/bookings/services/test_instant_book_promo_firewall.py` | rejects TECHNICIAN; accepts PLATFORM; regression: still rejects any promo on fixed-gig |
| `backend/tests/marketing/selectors/test_promotion_selector.py` | `get_active_promotions` returns only PLATFORM; TECHNICIAN-funded active promo excluded |
| `backend/tests/wallet/test_reconciliation.py` *(invariant test)* | seed N COMPLETED bookings with assorted discounts; assert `SUM(reimbursements) == SUM(discount_applied for COMPLETED)` |

---

## 8. Rollout sequence (deploy-safe)

1. Schema migration (table + choice).
2. Add to `FinancePort` + `NullFinanceAdapter` (no-op). Existing tests still pass.
3. Implement `WalletFinanceAdapter.record_promo_reimbursement`.
4. Adapter unit tests (in isolation, no orchestrator).
5. Patch `approve_quote` to stamp `discount_applied`.
6. Patch `mark_complete_with_cash` to call reimbursement + adjust commission base.
7. Orchestrator + integration tests.
8. Marketing selector filter + instant_book guard.
9. Wallet admin + selector display polish.
10. Update `seed_demo.py` promo to use `funded_by=PLATFORM` explicitly (already default).
11. Manual end-to-end smoke via `demo_journey.sh`:
    - Make `Freon Gas Top-up` sub-service have a PLATFORM promo applied
    - `drive_booking` through full flow; assert wallet balance increased by discount
12. Run full backend test suite green.

---

## 9. Edge cases verified in matrix

| # | Scenario | Behavior |
|---|---|---|
| E1 | Promo deleted between booking creation and quote approval | FK SET_NULL → no stamping. Customer doesn't get discount; tech earns normally. |
| E2 | Promo deleted between approval and completion | `discount_applied` still stamped → reimbursement still fires. Obligation lives on the column, not the FK. |
| E3 | Upsell after promo | Discount locked at first approval; upsell delta gets no promo coverage; tech earns full commission on delta. |
| E4 | Quote total < inspection fee | `work_owed=0`, `discount_applied=0`, no reimbursement. |
| E5 | Customer declines quote | COMPLETED_INSPECTION_ONLY, no discount stamping, no reimbursement. |
| E6 | Mid-job cancellation after quote approval | `discount_applied` stamped but no completion → no wallet impact. |
| E7 | Concurrent double-completion | Idempotency key + 1:1 OneToOne on booking → single ledger row. |
| E8 | `promo_discount_snapshot > work_owed` | Silent floor at `work_owed` (no negative bill, no over-credit). |
| E9 | `funded_by==TECHNICIAN` somehow reaches booking | Reimbursement gates on FK check at approve_quote; `discount_applied` never stamped; safe degradation. Primary defense is rejection at instant_book. |

---

## 10. Out of scope (explicit non-goals)

- **Frontend** booking-detail UI showing "You saved Rs.300". `discount_applied` already in serializer; Flutter wire-up is a separate FE PR (per `feedback_critical_financial_code` — never bundle).
- **Refund reversal** (clawback reimbursement when admin refunds a completed booking). RefundDeduction is schema-only; no admin refund flow yet. See flag entry below.
- **TECHNICIAN-funded promos** (v1.1 — structurally rejected today).
- **Stacked promos** (one promo per booking).
- **Customer-side cash-receipt PDF** showing discount line.

---

## 11. flag.md entry (propose before writing)

**Where**: `wallet/adapters/wallet_finance_adapter.py` (record_promo_reimbursement forward path); `wallet/models.py` (RefundDeduction subtype — no caller yet).

**What's wrong**: Forward path (booking COMPLETED → tech wallet credit) is bulletproof and reconciles. Reverse path (booking refunded → clawback reimbursement) has no caller. The admin refund flow itself is unbuilt — `RefundDeduction` is schema-only, written only by `seed_wallet` for demo data.

**Why we shipped it**: Sprint scope. Refund admin flow is its own sprint with its own surfaces (admin button, refund-reason taxonomy, customer notification). Bundling would push the promo wallet credit past freeze.

**The proper fix**: When admin refund flow lands, add `reverse_promo_reimbursement(booking)` to the refund service. Mirror the forward pattern:
- Idempotency key `f'booking:{id}:promo_reimbursement_reversal'`
- 1:1 with booking via new `PromoReimbursementReversal` subtype (or reuse `RefundDeduction` with a reason discriminator)
- Reverse commission alongside (`PromoReimbursementReversal` credit balanced by `CommissionReversal` credit, both signed positive to tech).

---

## 12. Estimate (realistic, defensive)

### Backend

| Task | Hours |
|---|---|
| Schema migration + model | 1 |
| FinancePort + NullFinanceAdapter + WalletFinanceAdapter | 2 |
| approve_quote + mark_complete wire-in | 2 |
| Marketing selector + instant_book firewall + exception | 1 |
| Admin + wallet selector display polish | 1 |
| Tests (factory + 7 test files) | 4 |
| Manual E2E QA via demo_journey.sh | 1 |
| Buffer (financial code → always 2x) | 2 |
| **Total** | **~14 hours** |

### Frontend (separate PR)

| Task | Hours |
|---|---|
| Booking-detail discount line + adjusted total | 1 |
| Wallet history "Promo reimbursement" badge | 0.5 |
| Tech completion screen footnote | 0.5 |
| **Total** | **~2 hours** |

---

## 13. Open questions for second-pass review

These were derived from the requirement, not negotiated — call out if any feel wrong:

1. **PLATFORM-only in v1**: TECHNICIAN-funded promos are rejected at instant_book. Acceptable to defer TECHNICIAN handling, or should v1 also support tech-absorbed discounts (no reimbursement, customer still gets discount)?
2. **Discount locked at first approval** (never grows on upsell). Is this the intended promo semantics for the product?
3. **Commission base change**: `payout_amount = cash_collected + discount_applied` changes commission math for promo'd bookings (always taxes the held-harmless figure). For non-promo bookings (discount=0), behavior is unchanged. Confirm.
4. **Refund reversal deferred**: documented as flag entry. OK to ship forward path only and wire reversal alongside the admin refund flow?
5. **funded_by snapshot on JobBooking**: not added (the `discount_applied` column is the wallet-side contract). If a future change broadens funded_by handling, a snapshot column may be needed then.
