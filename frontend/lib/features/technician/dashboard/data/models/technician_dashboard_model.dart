import 'package:flutter/foundation.dart';

import '../../domain/entities/technician_dashboard_entity.dart';

class UpNextJobModel {
  final int jobId;
  final String serviceTitle;
  final DateTime scheduledTime;
  final String customerName;
  final String? customerPhone;
  final String addressText;
  final double lat;
  final double lng;

  const UpNextJobModel({
    required this.jobId,
    required this.serviceTitle,
    required this.scheduledTime,
    required this.customerName,
    this.customerPhone,
    required this.addressText,
    required this.lat,
    required this.lng,
  });

  factory UpNextJobModel.fromJson(Map<String, dynamic> json) => UpNextJobModel(
    jobId: json['job_id'],
    serviceTitle: json['service_title'],
    scheduledTime: DateTime.parse(json['scheduled_time']),
    customerName: json['customer_name'],
    customerPhone: json['customer_phone'] as String?,
    addressText: json['address_text'],
    lat: (json['lat'] as num).toDouble(),
    lng: (json['lng'] as num).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'job_id': jobId,
    'service_title': serviceTitle,
    'scheduled_time': scheduledTime.toIso8601String(),
    'customer_name': customerName,
    'customer_phone': customerPhone,
    'address_text': addressText,
    'lat': lat,
    'lng': lng,
  };

  UpNextJobEntity toEntity() => UpNextJobEntity(
    jobId: jobId,
    serviceTitle: serviceTitle,
    scheduledTime: scheduledTime,
    customerName: customerName,
    customerPhone: customerPhone,
    addressText: addressText,
    lat: lat,
    lng: lng,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UpNextJobModel &&
          runtimeType == other.runtimeType &&
          jobId == other.jobId &&
          serviceTitle == other.serviceTitle &&
          scheduledTime == other.scheduledTime &&
          customerName == other.customerName &&
          customerPhone == other.customerPhone &&
          addressText == other.addressText &&
          lat == other.lat &&
          lng == other.lng;

  @override
  int get hashCode =>
      jobId.hashCode ^
      serviceTitle.hashCode ^
      scheduledTime.hashCode ^
      customerName.hashCode ^
      customerPhone.hashCode ^
      addressText.hashCode ^
      lat.hashCode ^
      lng.hashCode;
}

class LaterTodayJobModel {
  final int jobId;
  final String serviceTitle;
  final DateTime scheduledTime;
  final String addressText;

  const LaterTodayJobModel({
    required this.jobId,
    required this.serviceTitle,
    required this.scheduledTime,
    required this.addressText,
  });

  factory LaterTodayJobModel.fromJson(Map<String, dynamic> json) =>
      LaterTodayJobModel(
        jobId: json['job_id'],
        serviceTitle: json['service_title'],
        scheduledTime: DateTime.parse(json['scheduled_time']),
        addressText: json['address_text'],
      );

  Map<String, dynamic> toJson() => {
    'job_id': jobId,
    'service_title': serviceTitle,
    'scheduled_time': scheduledTime.toIso8601String(),
    'address_text': addressText,
  };

  LaterTodayJobEntity toEntity() => LaterTodayJobEntity(
    jobId: jobId,
    serviceTitle: serviceTitle,
    scheduledTime: scheduledTime,
    addressText: addressText,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LaterTodayJobModel &&
          runtimeType == other.runtimeType &&
          jobId == other.jobId &&
          serviceTitle == other.serviceTitle &&
          scheduledTime == other.scheduledTime &&
          addressText == other.addressText;

  @override
  int get hashCode =>
      jobId.hashCode ^
      serviceTitle.hashCode ^
      scheduledTime.hashCode ^
      addressText.hashCode;
}

class TechnicianDashboardModel {
  final double walletBalance;
  final bool isOnline;
  final String? profilePicture;
  final UpNextJobModel? upNextJob;
  final List<LaterTodayJobModel> laterTodayJobs;
  // Mirrors the new ``has_work_location`` + ``work_address_label`` keys on
  // the dashboard payload. Defaulted in [fromJson] so cached payloads from
  // before this rollout deserialise cleanly as "not set" / null.
  final bool hasWorkLocation;
  final String? workAddressLabel;

  const TechnicianDashboardModel({
    required this.walletBalance,
    required this.isOnline,
    this.profilePicture,
    this.upNextJob,
    required this.laterTodayJobs,
    this.hasWorkLocation = false,
    this.workAddressLabel,
  });

  factory TechnicianDashboardModel.fromJson(Map<String, dynamic> json) =>
      TechnicianDashboardModel(
        walletBalance: (json['wallet_balance'] as num).toDouble(),
        isOnline: json['is_online'],
        profilePicture: json['profile_picture'],
        upNextJob: json['up_next_job'] != null
            ? UpNextJobModel.fromJson(json['up_next_job'])
            : null,
        laterTodayJobs: (json['later_today_jobs'] as List)
            .map((i) => LaterTodayJobModel.fromJson(i))
            .toList(),
        hasWorkLocation: json['has_work_location'] as bool? ?? false,
        workAddressLabel: json['work_address_label'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'wallet_balance': walletBalance,
    'is_online': isOnline,
    'profile_picture': profilePicture,
    'up_next_job': upNextJob?.toJson(),
    'later_today_jobs': laterTodayJobs.map((i) => i.toJson()).toList(),
    'has_work_location': hasWorkLocation,
    'work_address_label': workAddressLabel,
  };

  TechnicianDashboardEntity toEntity() => TechnicianDashboardEntity(
    walletBalance: walletBalance,
    isOnline: isOnline,
    profilePicture: profilePicture,
    upNextJob: upNextJob?.toEntity(),
    laterTodayJobs: laterTodayJobs.map((i) => i.toEntity()).toList(),
    hasWorkLocation: hasWorkLocation,
    workAddressLabel: workAddressLabel,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TechnicianDashboardModel &&
          runtimeType == other.runtimeType &&
          walletBalance == other.walletBalance &&
          isOnline == other.isOnline &&
          profilePicture == other.profilePicture &&
          upNextJob == other.upNextJob &&
          listEquals(laterTodayJobs, other.laterTodayJobs) &&
          hasWorkLocation == other.hasWorkLocation &&
          workAddressLabel == other.workAddressLabel;

  @override
  int get hashCode =>
      walletBalance.hashCode ^
      isOnline.hashCode ^
      profilePicture.hashCode ^
      upNextJob.hashCode ^
      Object.hashAll(laterTodayJobs) ^
      hasWorkLocation.hashCode ^
      workAddressLabel.hashCode;
}
