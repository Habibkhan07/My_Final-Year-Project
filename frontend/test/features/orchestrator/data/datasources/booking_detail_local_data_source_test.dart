// Tests for `BookingDetailLocalDataSource`.
//
// Regression vectors:
//   * Cache round-trip preserves the wire model bit-for-bit so the
//     repository can re-decode without lossy intermediate types.
//   * Corrupted entry returns null (not throws) — guards against
//     schema bumps where an old `_v1_` row would otherwise crash the
//     mapper. The repository depends on this for its evict-and-retry.
//   * Cache key prefix is `orchestrator_booking_detail_v1_` —
//     bumping `_v1_` is the schema-migration safety valve, so the
//     prefix is contract.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/orchestrator/data/datasources/booking_detail_local_data_source.dart';
import 'package:frontend/features/orchestrator/data/models/booking_detail_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../_helpers/booking_detail_fixture.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<BookingDetailLocalDataSource> newDs() async {
    final prefs = await SharedPreferences.getInstance();
    return BookingDetailLocalDataSource(prefs);
  }

  test('cache → read round-trip returns the same model', () async {
    final ds = await newDs();
    final original =
        BookingDetailModel.fromJson(bookingDetailJson(id: 42, customerId: 7));

    await ds.cache(42, original);
    final out = await ds.read(42);

    expect(out, isNotNull);
    expect(out!.id, 42);
    expect(out.customer.id, 7);
  });

  test('read returns null when no entry exists for the booking id', () async {
    final ds = await newDs();
    expect(await ds.read(99), isNull);
  });

  test('clear removes the entry', () async {
    final ds = await newDs();
    final m = BookingDetailModel.fromJson(bookingDetailJson(id: 42));
    await ds.cache(42, m);
    expect(await ds.read(42), isNotNull);

    await ds.clear(42);
    expect(await ds.read(42), isNull);
  });

  test('clear is a no-op when entry is absent', () async {
    final ds = await newDs();
    // Just shouldn't throw.
    await ds.clear(999);
  });

  test('corrupted entry returns null instead of throwing (#B-16/#B-17)',
      () async {
    // Simulate schema drift / partial write — the repository depends
    // on this null fallback to short-circuit to BookingDetailOfflineNoCache
    // instead of bubbling a JSON parse error to the screen.
    SharedPreferences.setMockInitialValues({
      'orchestrator_booking_detail_v1_42': '{not valid json',
    });
    final prefs = await SharedPreferences.getInstance();
    final ds = BookingDetailLocalDataSource(prefs);

    expect(await ds.read(42), isNull);
  });

  test('cache key uses orchestrator_booking_detail_v1_ prefix (contract)',
      () async {
    // The `_v1_` segment is the schema-bump escape hatch — bumping it
    // invalidates every cached row in one shot. Pin the exact prefix.
    final ds = await newDs();
    await ds.cache(42, BookingDetailModel.fromJson(bookingDetailJson()));
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    expect(keys, contains('orchestrator_booking_detail_v1_42'));
  });

  test('cache writes JSON-encoded payload (re-decodable as Map)', () async {
    // Sanity: the repository expects to call `BookingDetailModel.fromJson`
    // on the raw stored string. If the cache writer ever switched to
    // a binary or wrapped format, every offline read would fail.
    final ds = await newDs();
    await ds.cache(42, BookingDetailModel.fromJson(bookingDetailJson()));
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('orchestrator_booking_detail_v1_42');
    expect(raw, isNotNull);
    final decoded = jsonDecode(raw!);
    expect(decoded, isA<Map<String, dynamic>>());
    expect(decoded['id'], 42);
  });

  test('different booking ids are isolated', () async {
    final ds = await newDs();
    final a = BookingDetailModel.fromJson(bookingDetailJson(id: 1));
    final b = BookingDetailModel.fromJson(bookingDetailJson(id: 2));
    await ds.cache(1, a);
    await ds.cache(2, b);

    expect((await ds.read(1))!.id, 1);
    expect((await ds.read(2))!.id, 2);

    await ds.clear(1);
    expect(await ds.read(1), isNull);
    expect((await ds.read(2))!.id, 2); // unaffected
  });
}
