import '../../domain/entities/topup_session.dart';

/// Wire-shape for ``POST /api/technicians/wallet/topups/``.
///
/// Backend response (201):
/// ```json
/// {
///   "topup_id": 42,
///   "redirect_url": "https://api.example.com/api/technicians/wallet/topups/42/bridge/?t=<signed>"
/// }
/// ```
class TopupSessionModel {
  final int topupId;
  final String redirectUrl;

  const TopupSessionModel({
    required this.topupId,
    required this.redirectUrl,
  });

  factory TopupSessionModel.fromJson(Map<String, dynamic> json) =>
      TopupSessionModel(
        topupId: json['topup_id'] as int,
        redirectUrl: json['redirect_url'] as String,
      );

  TopupSession toEntity() => TopupSession(
        topupId: topupId,
        redirectUrl: redirectUrl,
      );
}
