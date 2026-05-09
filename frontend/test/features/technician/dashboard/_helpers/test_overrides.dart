import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import 'package:frontend/core/common/domain/entities/user_entity.dart';
import 'package:frontend/features/auth/presentation/providers/auth_notifier.dart';
import 'package:frontend/features/auth/presentation/providers/auth_state.dart';
import 'package:frontend/features/technician/dashboard/presentation/providers/current_position_provider.dart';

/// Test-only AuthNotifier that returns a fixed user without touching
/// secure storage. Use via [authProvider.overrideWith].
class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier(this._user);
  final UserEntity? _user;

  @override
  Future<AuthState> build() async => AuthState(user: _user);
}

/// Test-only CurrentPosition that returns a fixed Position (or null).
/// Use via [currentPositionProvider.overrideWith].
class FakeCurrentPosition extends CurrentPosition {
  FakeCurrentPosition(this._position);
  final Position? _position;

  @override
  Future<Position?> build() async => _position;

  @override
  void invalidateCache() {}
}

/// Standard fake user used by widget/screen tests when a real auth identity
/// is not the focus of the test.
final fakeUser = UserEntity(
  phone: '+923001234567',
  firstName: 'Ali',
  lastName: 'Raza',
);

/// Wraps [child] in a ProviderScope with auth + currentPosition overrides
/// pre-installed. Inline construction sidesteps Riverpod's internal Override
/// type which isn't publicly exported.
Widget dashboardScope({
  required Widget child,
  UserEntity? user,
  Position? position,
}) {
  return ProviderScope(
    overrides: [
      authProvider.overrideWith(() => FakeAuthNotifier(user ?? fakeUser)),
      currentPositionProvider.overrideWith(() => FakeCurrentPosition(position)),
    ],
    child: child,
  );
}

/// AsyncLoading override for CurrentPosition — useful for cache-warm tests
/// that want to verify behavior while location is still resolving.
class StallCurrentPosition extends CurrentPosition {
  @override
  Future<Position?> build() => Completer<Position?>().future;

  @override
  void invalidateCache() {}
}
