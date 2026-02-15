import 'package:equatable/equatable.dart';

class TechnicianEntity extends Equatable {
  final int profileId;
  final String status;
  final String fullName;
  final String joinedDate;
  final int experienceYears;

  const TechnicianEntity({
    required this.profileId,
    required this.status,
    required this.fullName,
    required this.joinedDate,
    required this.experienceYears,
  });

  // Adding copyWith for future state updates
  TechnicianEntity copyWith({
    String? status,
    String? fullName,
    int? experienceYears,
  }) {
    return TechnicianEntity(
      profileId: profileId, // These usually stay the same
      joinedDate: joinedDate,
      status: status ?? this.status,
      fullName: fullName ?? this.fullName,
      experienceYears: experienceYears ?? this.experienceYears,
    );
  }

  @override
  List<Object?> get props => [
    profileId,
    status,
    fullName,
    joinedDate,
    experienceYears,
  ];
}
