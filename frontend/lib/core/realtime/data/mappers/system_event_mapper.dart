import 'dart:developer';

import '../../domain/entities/system_event_entity.dart';
import '../models/system_event_model.dart';

extension SystemEventMapper on SystemEventModel {
  /// Maps a [SystemEventModel] (JSON shape) to a [SystemEventEntity] (domain).
  ///
  /// Returns `null` if any required field is malformed (bad timestamp,
  /// unexpected payload shape, etc.). This method NEVER throws — the
  /// listener loop runs it on every WebSocket frame and every FCM payload,
  /// so a single bad event must not kill the stream. Callers filter nulls.
  ///
  /// `expires_at` is flag #19 envelope-level expiry. If present and
  /// unparseable, we log and treat as null rather than dropping the
  /// whole event — a malformed expiry on a future event should not gate
  /// the entire delivery.
  SystemEventEntity? toDomain() {
    try {
      final parsedTimestamp = DateTime.parse(timestamp);
      DateTime? parsedExpiresAt;
      if (expiresAt != null) {
        parsedExpiresAt = DateTime.tryParse(expiresAt!);
        if (parsedExpiresAt == null) {
          log(
            'SystemEventMapper.toDomain: unparseable expires_at "${expiresAt!}" '
            'on event id=$id rawType=$rawType — treating as null',
            name: 'core.data.mapper',
          );
        }
      }
      return SystemEventEntity.fromComponents(
        id: id,
        rawType: rawType,
        targetRoleStr: targetRole,
        timestamp: parsedTimestamp,
        payload: payload,
        expiresAt: parsedExpiresAt,
        recipientUserId: recipientUserId,
      );
    } catch (e, stack) {
      log(
        'SystemEventMapper.toDomain: dropping malformed event id=$id '
        'rawType=$rawType error=$e',
        name: 'core.data.mapper',
        stackTrace: stack,
      );
      return null;
    }
  }
}
