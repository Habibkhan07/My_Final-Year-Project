import 'payout_account.dart';

/// Two-list wrapper returned by ``listPayoutAccounts()``.
///
/// We keep the two lists separate (rather than collapsing to a single
/// ``List<PayoutAccount>``) so the withdrawal-sheet UI can render two
/// labelled sections — "Bank accounts" and "JazzCash" — without needing
/// to group on the fly. Each list is independently empty.
class PayoutAccounts {
  final List<BankPayoutAccount> bankAccounts;
  final List<JazzCashPayoutAccount> jazzcashAccounts;

  const PayoutAccounts({
    required this.bankAccounts,
    required this.jazzcashAccounts,
  });

  /// True when the tech has no usable payout target at all. The
  /// withdrawal sheet uses this to render the "no payout account on
  /// file" empty state with the submit button disabled.
  bool get isEmpty => bankAccounts.isEmpty && jazzcashAccounts.isEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PayoutAccounts &&
          _listEquals(bankAccounts, other.bankAccounts) &&
          _listEquals(jazzcashAccounts, other.jazzcashAccounts);

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(bankAccounts), Object.hashAll(jazzcashAccounts));

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
