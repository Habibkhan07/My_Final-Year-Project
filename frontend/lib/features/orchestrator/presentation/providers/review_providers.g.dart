// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(reviewRemoteDataSource)
final reviewRemoteDataSourceProvider = ReviewRemoteDataSourceProvider._();

final class ReviewRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          IReviewRemoteDataSource,
          IReviewRemoteDataSource,
          IReviewRemoteDataSource
        >
    with $Provider<IReviewRemoteDataSource> {
  ReviewRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reviewRemoteDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reviewRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<IReviewRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IReviewRemoteDataSource create(Ref ref) {
    return reviewRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IReviewRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IReviewRemoteDataSource>(value),
    );
  }
}

String _$reviewRemoteDataSourceHash() =>
    r'aecb5db4065f8cde95cfccbdcaa2fa97d0b0a094';

@ProviderFor(reviewRepository)
final reviewRepositoryProvider = ReviewRepositoryProvider._();

final class ReviewRepositoryProvider
    extends
        $FunctionalProvider<
          IReviewRepository,
          IReviewRepository,
          IReviewRepository
        >
    with $Provider<IReviewRepository> {
  ReviewRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reviewRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reviewRepositoryHash();

  @$internal
  @override
  $ProviderElement<IReviewRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IReviewRepository create(Ref ref) {
    return reviewRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IReviewRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IReviewRepository>(value),
    );
  }
}

String _$reviewRepositoryHash() => r'920fe18715bbc32c9f225e98b785dcc552a9935c';

@ProviderFor(bookingReviewSnapshot)
final bookingReviewSnapshotProvider = BookingReviewSnapshotFamily._();

final class BookingReviewSnapshotProvider
    extends
        $FunctionalProvider<
          AsyncValue<BookingReviewSnapshot>,
          BookingReviewSnapshot,
          FutureOr<BookingReviewSnapshot>
        >
    with
        $FutureModifier<BookingReviewSnapshot>,
        $FutureProvider<BookingReviewSnapshot> {
  BookingReviewSnapshotProvider._({
    required BookingReviewSnapshotFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'bookingReviewSnapshotProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$bookingReviewSnapshotHash();

  @override
  String toString() {
    return r'bookingReviewSnapshotProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<BookingReviewSnapshot> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<BookingReviewSnapshot> create(Ref ref) {
    final argument = this.argument as int;
    return bookingReviewSnapshot(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is BookingReviewSnapshotProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$bookingReviewSnapshotHash() =>
    r'7034e461a9b15cba979ffe45474a7f5e4b9ce196';

final class BookingReviewSnapshotFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<BookingReviewSnapshot>, int> {
  BookingReviewSnapshotFamily._()
    : super(
        retry: null,
        name: r'bookingReviewSnapshotProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  BookingReviewSnapshotProvider call(int bookingId) =>
      BookingReviewSnapshotProvider._(argument: bookingId, from: this);

  @override
  String toString() => r'bookingReviewSnapshotProvider';
}

@ProviderFor(ReviewFormNotifier)
final reviewFormProvider = ReviewFormNotifierFamily._();

final class ReviewFormNotifierProvider
    extends $NotifierProvider<ReviewFormNotifier, ReviewFormState> {
  ReviewFormNotifierProvider._({
    required ReviewFormNotifierFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'reviewFormProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$reviewFormNotifierHash();

  @override
  String toString() {
    return r'reviewFormProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ReviewFormNotifier create() => ReviewFormNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReviewFormState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReviewFormState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ReviewFormNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$reviewFormNotifierHash() =>
    r'0789c44fdf33dd05e41c06f8fee8c61fc76986da';

final class ReviewFormNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          ReviewFormNotifier,
          ReviewFormState,
          ReviewFormState,
          ReviewFormState,
          int
        > {
  ReviewFormNotifierFamily._()
    : super(
        retry: null,
        name: r'reviewFormProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ReviewFormNotifierProvider call(int bookingId) =>
      ReviewFormNotifierProvider._(argument: bookingId, from: this);

  @override
  String toString() => r'reviewFormProvider';
}

abstract class _$ReviewFormNotifier extends $Notifier<ReviewFormState> {
  late final _$args = ref.$arg as int;
  int get bookingId => _$args;

  ReviewFormState build(int bookingId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ReviewFormState, ReviewFormState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ReviewFormState, ReviewFormState>,
              ReviewFormState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(ReviewSubmitNotifier)
final reviewSubmitProvider = ReviewSubmitNotifierFamily._();

final class ReviewSubmitNotifierProvider
    extends $NotifierProvider<ReviewSubmitNotifier, AsyncValue<Review?>> {
  ReviewSubmitNotifierProvider._({
    required ReviewSubmitNotifierFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'reviewSubmitProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$reviewSubmitNotifierHash();

  @override
  String toString() {
    return r'reviewSubmitProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ReviewSubmitNotifier create() => ReviewSubmitNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<Review?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<Review?>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ReviewSubmitNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$reviewSubmitNotifierHash() =>
    r'f350aa078d813f07237e4bcd2c85165219f0aba0';

final class ReviewSubmitNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          ReviewSubmitNotifier,
          AsyncValue<Review?>,
          AsyncValue<Review?>,
          AsyncValue<Review?>,
          int
        > {
  ReviewSubmitNotifierFamily._()
    : super(
        retry: null,
        name: r'reviewSubmitProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ReviewSubmitNotifierProvider call(int bookingId) =>
      ReviewSubmitNotifierProvider._(argument: bookingId, from: this);

  @override
  String toString() => r'reviewSubmitProvider';
}

abstract class _$ReviewSubmitNotifier extends $Notifier<AsyncValue<Review?>> {
  late final _$args = ref.$arg as int;
  int get bookingId => _$args;

  AsyncValue<Review?> build(int bookingId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Review?>, AsyncValue<Review?>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Review?>, AsyncValue<Review?>>,
              AsyncValue<Review?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
