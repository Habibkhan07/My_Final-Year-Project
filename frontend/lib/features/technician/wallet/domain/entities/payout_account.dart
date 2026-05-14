/// Sealed hierarchy of payout targets a tech can withdraw to.
///
/// Backend ships two distinct lists (``bank_accounts`` /
/// ``jazzcash_accounts``) per ``GET /api/technicians/wallet/payout-accounts/``.
/// We model the two as separate concrete classes under one sealed parent
/// so the withdrawal-sheet picker can exhaustively switch on the kind
/// (radio icon + masking shape) without leaking the wire-shape choice
/// into the widget.
///
/// Raw account number / mobile number NEVER appear on the wire — the
/// backend serializer ships only the masked form. The [masked] field
/// here is the display string the picker shows; there is no path to
/// reconstruct the raw value client-side, which is the property we want.
sealed class PayoutAccount {
  /// Server-issued primary key. Submitted back to the server as
  /// ``payout_bank_account_id`` or ``payout_jazzcash_account_id``
  /// depending on the concrete type — the resolver is IDOR-scoped to
  /// the requesting tech.
  final int id;

  /// User-entered display name (e.g. "Ali Khan" — what was on the
  /// account-add form). Never the bank name.
  final String accountTitle;

  /// Masked detail. For banks: ``"••<last4>"`` of the account number /
  /// IBAN. For JazzCash: ``"+923•••<last3>"`` of the MSISDN.
  final String masked;

  const PayoutAccount({
    required this.id,
    required this.accountTitle,
    required this.masked,
  });
}

/// Bank transfer payout target. Carries the bank name distinctly from
/// the holder name so the picker can render "HBL — Ali Khan" without
/// the row widget having to parse a composite label.
final class BankPayoutAccount extends PayoutAccount {
  final String bankName;

  const BankPayoutAccount({
    required super.id,
    required this.bankName,
    required super.accountTitle,
    required super.masked,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BankPayoutAccount &&
          id == other.id &&
          bankName == other.bankName &&
          accountTitle == other.accountTitle &&
          masked == other.masked;

  @override
  int get hashCode => Object.hash(id, bankName, accountTitle, masked);
}

/// JazzCash mobile-wallet payout target. Auto-created on first
/// successful JazzCash top-up; bank accounts must be added manually
/// (admin-side for now — tech-facing add-bank UI is deferred per the
/// withdrawal-flow flag).
final class JazzCashPayoutAccount extends PayoutAccount {
  const JazzCashPayoutAccount({
    required super.id,
    required super.accountTitle,
    required super.masked,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JazzCashPayoutAccount &&
          id == other.id &&
          accountTitle == other.accountTitle &&
          masked == other.masked;

  @override
  int get hashCode => Object.hash(id, accountTitle, masked);
}
