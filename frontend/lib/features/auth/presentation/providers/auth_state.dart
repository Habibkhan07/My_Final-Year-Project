import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../core/common/domain/entities/user_entity.dart';

part 'auth_state.freezed.dart';

@freezed
abstract class AuthState with _$AuthState {
  const factory AuthState({String? successMessage, UserEntity? user}) =
      _AuthState;
}
