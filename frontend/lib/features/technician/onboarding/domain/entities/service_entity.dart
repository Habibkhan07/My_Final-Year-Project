import 'package:equatable/equatable.dart';

class ServiceEntity extends Equatable {
  final int id;
  final String name;
  final List<SubServiceEntity>
  subServices; // Matches the backend 'sub_services'

  const ServiceEntity({
    required this.id,
    required this.name,
    required this.subServices,
  });

  @override
  List<Object?> get props => [id, name, subServices];
}

class SubServiceEntity extends Equatable {
  final int id;
  final String name;
  final String
  basePrice; // Stored as String to handle decimal precision from Python

  const SubServiceEntity({
    required this.id,
    required this.name,
    required this.basePrice,
  });

  @override
  List<Object?> get props => [id, name, basePrice];
}
