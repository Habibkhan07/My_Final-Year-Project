import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../auth/presentation/providers/auth_notifier.dart';
import '../../domain/entities/technician_status.dart';
import 'dependency_injection.dart';

part 'technician_status_provider.g.dart';

/// The router's source of truth for "what surface should this user see?".
///
/// `keepAlive: true` because the router reads it on every navigation —
/// rebuilding on each read would refetch the endpoint constantly.
/// Invalidate explicitly after onboarding finalize (so the router picks
/// up `Pending`) or on logout.
///
/// Watches [authProvider] so that login/logout transitions trigger a
/// rebuild — without this, a logged-out user who logs back in would see
/// the previous account's cached status.
@Riverpod(keepAlive: true)
Future<TechnicianStatus> technicianStatus(Ref ref) async {
  final user = ref.watch(authProvider.select((async) => async.value?.user));
  if (user == null) {
    // No one is logged in — the router redirects to /login before reading
    // this value, but returning NoProfile keeps the type non-nullable so
    // downstream pattern matches stay exhaustive.
    return const TechnicianStatusNoProfile();
  }

  final repository = ref.watch(technicianStatusRepositoryProvider);
  return repository.getMyStatus();
}
