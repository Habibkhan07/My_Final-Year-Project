// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_ui_block_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BookingUiBlockModel _$BookingUiBlockModelFromJson(Map<String, dynamic> json) =>
    _BookingUiBlockModel(
      statusLabel: json['status_label'] as String,
      bodyText: json['body_text'] as String,
      primaryAction: json['primary_action'] == null
          ? null
          : BookingUiActionModel.fromJson(
              json['primary_action'] as Map<String, dynamic>,
            ),
      secondaryActions:
          (json['secondary_actions'] as List<dynamic>?)
              ?.map(
                (e) => BookingUiActionModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <BookingUiActionModel>[],
      showTracking: json['show_tracking'] as bool,
      showQuoteCard: json['show_quote_card'] as bool,
      showDisputeButton: json['show_dispute_button'] as bool,
      tone: json['tone'] as String,
    );

Map<String, dynamic> _$BookingUiBlockModelToJson(
  _BookingUiBlockModel instance,
) => <String, dynamic>{
  'status_label': instance.statusLabel,
  'body_text': instance.bodyText,
  'primary_action': instance.primaryAction,
  'secondary_actions': instance.secondaryActions,
  'show_tracking': instance.showTracking,
  'show_quote_card': instance.showQuoteCard,
  'show_dispute_button': instance.showDisputeButton,
  'tone': instance.tone,
};

_BookingUiActionModel _$BookingUiActionModelFromJson(
  Map<String, dynamic> json,
) => _BookingUiActionModel(
  label: json['label'] as String,
  endpoint: json['endpoint'] as String,
  method: json['method'] as String,
  style: json['style'] as String?,
);

Map<String, dynamic> _$BookingUiActionModelToJson(
  _BookingUiActionModel instance,
) => <String, dynamic>{
  'label': instance.label,
  'endpoint': instance.endpoint,
  'method': instance.method,
  'style': instance.style,
};
