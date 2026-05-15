/// Wallet-feature money formatter.
///
/// Renders a PKR amount with smart precision:
///   * whole rupee  → "Rs. 100"   (no .00 clutter)
///   * paisa frac   → "Rs. 100.50" (2dp, never more)
///   * null / NaN   → "Rs. 0"     (degraded but never crashes)
///
/// Used by every wallet surface that renders an amount (balance card,
/// history row, pending pill, withdraw sheet, transactions list).
/// Centralised so a future rounding tweak applies everywhere at once.
String formatRs(double? amount) {
  if (amount == null || amount.isNaN) return 'Rs. 0';
  // Paisa precision: 2dp. We then trim trailing zeros so 100.00 → 100.
  final twoDp = amount.toStringAsFixed(2);
  // Quick path: if the last three chars are ".00", strip them.
  if (twoDp.endsWith('.00')) {
    return 'Rs. ${twoDp.substring(0, twoDp.length - 3)}';
  }
  // Otherwise show the full 2dp value. We deliberately don't trim a
  // single trailing zero (e.g. ".50" stays ".50", not ".5") — paisa
  // amounts read more naturally with the trailing zero.
  return 'Rs. $twoDp';
}
