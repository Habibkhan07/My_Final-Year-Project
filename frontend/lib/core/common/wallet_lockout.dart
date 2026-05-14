/// Wallet lockout — single source of truth for the rule and its rounding.
///
/// The rule is structural: ``balance < 0`` means the tech is currently in
/// lockout. Zero is allowed; only strictly negative triggers. See backend
/// memory ``wallet-money-mechanics`` and ``wallet.selectors.lockout`` for
/// the authoritative reference.
///
/// This module lives in ``core/common/`` rather than the wallet feature
/// because TWO features consume the rule:
///
///   * Wallet feature — [WalletState.fromBalance] derives the entity's
///     ``isLockedOut`` / ``balancePkr`` / ``owedPkr`` from a raw balance.
///   * Dashboard feature — the lockout banner and the online-toggle
///     gate both branch on this rule.
///
/// Keeping the formula in one place prevents drift: a paisa-rounding
/// tweak in one consumer would otherwise silently disagree with the
/// other, and the visual reconciliation ``balancePkr + owedPkr == 0``
/// would break.
///
/// Rounding policy (matches backend ``lockout_status``):
///
///   * ``balanceRupees(b)`` — for non-negative balances, truncates toward
///     zero; for negative balances, FLOORs (rounds toward -infinity).
///   * ``owedRupees(b)`` — 0 for non-negative; CEILING of |b| otherwise.
///
/// Together these guarantee ``balanceRupees + owedRupees == 0`` for
/// locked accounts, so the displayed numbers reconcile visually
/// (a tech who pays ``owedRupees`` always fully clears lockout — never
/// a sub-rupee shortfall).
library;

/// True iff the wallet is currently in lockout. Strict ``< 0``.
bool isWalletLocked(double balance) => balance < 0;

/// Top-up amount, in whole rupees, that clears the lockout. Rounds UP
/// on paisa fractions so paying this amount always fully clears.
/// Returns 0 when not in lockout.
int owedRupees(double balance) {
  if (balance >= 0) return 0;
  return (-balance).ceil();
}

/// Display-friendly signed balance, in whole rupees. For locked accounts
/// returns FLOOR(balance) so ``balanceRupees + owedRupees == 0`` holds —
/// the wallet card and the lockout strip reconcile visually. For
/// non-negative balances truncates toward zero (the natural ``int(b)``).
int balanceRupees(double balance) {
  if (balance < 0) return balance.floor();
  return balance.truncate();
}
