// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attachment_upload_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AttachmentUploadResponseModel _$AttachmentUploadResponseModelFromJson(
  Map<String, dynamic> json,
) => _AttachmentUploadResponseModel(
  attachmentId: (json['attachment_id'] as num).toInt(),
  attachmentsCount: (json['attachments_count'] as num).toInt(),
);

Map<String, dynamic> _$AttachmentUploadResponseModelToJson(
  _AttachmentUploadResponseModel instance,
) => <String, dynamic>{
  'attachment_id': instance.attachmentId,
  'attachments_count': instance.attachmentsCount,
};
