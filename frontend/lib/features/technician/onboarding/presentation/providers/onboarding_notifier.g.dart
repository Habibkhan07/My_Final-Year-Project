// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(OnboardingNotifier)
final onboardingProvider = OnboardingNotifierProvider._();

final class OnboardingNotifierProvider
    extends $AsyncNotifierProvider<OnboardingNotifier, OnboardingState> {
  OnboardingNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingNotifierHash();

  @$internal
  @override
  OnboardingNotifier create() => OnboardingNotifier();
}

String _$onboardingNotifierHash() =>
    r'959f2384a5498281f84651d473f0d9b0d71d4857';

abstract class _$OnboardingNotifier extends $AsyncNotifier<OnboardingState> {
  FutureOr<OnboardingState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<OnboardingState>, OnboardingState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<OnboardingState>, OnboardingState>,
              AsyncValue<OnboardingState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(authenticatedUser)
final authenticatedUserProvider = AuthenticatedUserProvider._();

final class AuthenticatedUserProvider
    extends $FunctionalProvider<UserEntity?, UserEntity?, UserEntity?>
    with $Provider<UserEntity?> {
  AuthenticatedUserProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authenticatedUserProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authenticatedUserHash();

  @$internal
  @override
  $ProviderElement<UserEntity?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  UserEntity? create(Ref ref) {
    return authenticatedUser(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UserEntity? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UserEntity?>(value),
    );
  }
}

String _$authenticatedUserHash() => r'687092532cac8e6cf54a01236717ec6204236cff';
