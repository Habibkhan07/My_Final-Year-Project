import '../../domain/entities/payout_account.dart';
import '../../domain/entities/payout_accounts.dart';

/// Wire shape for ``GET /api/technicians/wallet/payout-accounts/``.
///
/// ```json
/// {
///   "bank_accounts": [
///     {"id": 7, "bank_name": "HBL", "account_title": "Ali Khan", "masked_number": "••1234"}
///   ],
///   "jazzcash_accounts": [
///     {"id": 12, "account_title": "Ali Khan", "masked_mobile": "+923•••567"}
///   ]
/// }
/// ```
///
/// The raw ``account_number_or_iban`` and ``mobile_number`` columns
/// are NEVER on the wire — backend serializer only ships the masked
/// fields. There is no path from the wire to the raw value here, which
/// is the property we want.
class PayoutAccountsModel {
  final List<BankPayoutAccountModel> bankAccounts;
  final List<JazzCashPayoutAccountModel> jazzcashAccounts;

  const PayoutAccountsModel({
    required this.bankAccounts,
    required this.jazzcashAccounts,
  });

  factory PayoutAccountsModel.fromJson(Map<String, dynamic> json) {
    final banks = (json['bank_accounts'] as List<dynamic>? ?? <dynamic>[])
        .map((e) => BankPayoutAccountModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final jazz = (json['jazzcash_accounts'] as List<dynamic>? ?? <dynamic>[])
        .map((e) =>
            JazzCashPayoutAccountModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return PayoutAccountsModel(
      bankAccounts: banks,
      jazzcashAccounts: jazz,
    );
  }

  PayoutAccounts toEntity() => PayoutAccounts(
        bankAccounts: bankAccounts.map((m) => m.toEntity()).toList(),
        jazzcashAccounts:
            jazzcashAccounts.map((m) => m.toEntity()).toList(),
      );
}

class BankPayoutAccountModel {
  final int id;
  final String bankName;
  final String accountTitle;
  final String maskedNumber;

  const BankPayoutAccountModel({
    required this.id,
    required this.bankName,
    required this.accountTitle,
    required this.maskedNumber,
  });

  factory BankPayoutAccountModel.fromJson(Map<String, dynamic> json) =>
      BankPayoutAccountModel(
        id: json['id'] as int,
        // Backwards-compat: backend always ships these fields, but the
        // ``?? ''`` defaults keep the parser from crashing on shape
        // drift (mid-rollout new variant, missing field) — better to
        // render an empty label than to crash the picker.
        bankName: (json['bank_name'] as String?) ?? '',
        accountTitle: (json['account_title'] as String?) ?? '',
        maskedNumber: (json['masked_number'] as String?) ?? '',
      );

  BankPayoutAccount toEntity() => BankPayoutAccount(
        id: id,
        bankName: bankName,
        accountTitle: accountTitle,
        masked: maskedNumber,
      );
}

class JazzCashPayoutAccountModel {
  final int id;
  final String accountTitle;
  final String maskedMobile;

  const JazzCashPayoutAccountModel({
    required this.id,
    required this.accountTitle,
    required this.maskedMobile,
  });

  factory JazzCashPayoutAccountModel.fromJson(Map<String, dynamic> json) =>
      JazzCashPayoutAccountModel(
        id: json['id'] as int,
        accountTitle: (json['account_title'] as String?) ?? '',
        maskedMobile: (json['masked_mobile'] as String?) ?? '',
      );

  JazzCashPayoutAccount toEntity() => JazzCashPayoutAccount(
        id: id,
        accountTitle: accountTitle,
        masked: maskedMobile,
      );
}
