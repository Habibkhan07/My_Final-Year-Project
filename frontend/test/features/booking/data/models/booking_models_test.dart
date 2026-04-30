import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/booking/data/models/booking_models.dart';
import 'package:frontend/features/booking/domain/entities/booking_entities.dart';

void main() {
  // ---------------------------------------------------------------------------
  // TechnicianProfileModel
  // ---------------------------------------------------------------------------
  group('TechnicianProfileModel', () {
    const tSkillJson = {
      'name': 'AC Repair',
      'icon_name': 'ac_repair',
    };

    const tReviewJson = {
      'reviewer_name': 'Sara',
      'rating': 5,
      'text': 'Good',
    };

    final tProfileJson = {
      'id': 1,
      'full_name': 'Ali Raza',
      'city': 'LHR',
      'profile_picture': 'https://example.com/pic.jpg',
      'rating_average': 4.9,
      'review_count': 120,
      'experience_years': 5,
      'bio': 'Test bio',
      'distance_km': 2.4,
      'bayesian_score': 4.8,
      'is_active': true,
      'ui_rating_text': '⭐ 4.9 (120 jobs)',
      'primary_price': 'Rs. 1,200',
      'primary_price_raw': '1000.00',
      'price_context': 'Labor Fee',
      'promo_tag': '20% OFF',
      'skills': [tSkillJson],
      'recent_reviews': [tReviewJson],
    };

    final tModel = TechnicianProfileModel(
      id: 1,
      fullName: 'Ali Raza',
      city: 'LHR',
      profilePicture: 'https://example.com/pic.jpg',
      ratingAverage: 4.9,
      reviewCount: 120,
      experienceYears: 5,
      bio: 'Test bio',
      distanceKm: 2.4,
      bayesianScore: 4.8,
      isActive: true,
      uiRatingText: '⭐ 4.9 (120 jobs)',
      primaryPrice: 'Rs. 1,200',
      primaryPriceRaw: '1000.00',
      priceContext: 'Labor Fee',
      promoTag: '20% OFF',
      skills: const [TechnicianSkillModel(name: 'AC Repair', iconName: 'ac_repair')],
      recentReviews: const [TechnicianReviewModel(reviewerName: 'Sara', rating: 5, text: 'Good')],
    );

    test('fromJson parses full profile with primary_price_raw correctly', () {
      final result = TechnicianProfileModel.fromJson(tProfileJson);
      expect(result, tModel);
    });

    test('toEntity maps all fields including primaryPriceRaw', () {
      final entity = tModel.toEntity();
      expect(entity.id, tModel.id);
      expect(entity.fullName, tModel.fullName);
      expect(entity.primaryPrice, tModel.primaryPrice);
      expect(entity.primaryPriceRaw, tModel.primaryPriceRaw);
      expect(entity.priceContext, tModel.priceContext);
      expect(entity.skills.first.name, 'AC Repair');
    });
  });

  // ---------------------------------------------------------------------------
  // AvailabilitySlotModel
  // ---------------------------------------------------------------------------
  group('AvailabilitySlotModel', () {
    const tJson = {
      'time_string': '9:00 AM',
      'iso_start': '2026-04-07T09:00:00+05:00',
      'iso_end': '2026-04-07T10:00:00+05:00',
      'period': 'AM',
    };

    const tModel = AvailabilitySlotModel(
      timeString: '9:00 AM',
      isoStart: '2026-04-07T09:00:00+05:00',
      isoEnd: '2026-04-07T10:00:00+05:00',
      period: 'AM',
    );

    test('fromJson parses snake_case keys correctly', () {
      final result = AvailabilitySlotModel.fromJson(tJson);
      expect(result, tModel);
    });

    test('toEntity maps to AvailabilitySlotEntity with identical fields', () {
      final entity = tModel.toEntity();
      expect(entity, isA<AvailabilitySlotEntity>());
      expect(entity.timeString, tModel.timeString);
      expect(entity.isoStart, tModel.isoStart);
      expect(entity.isoEnd, tModel.isoEnd);
      expect(entity.period, tModel.period);
    });
  });

  // ---------------------------------------------------------------------------
  // InstantBookingRequestModel
  //
  // Four scenarios per BOOKINGS_API.md §1.1 / §2.1. The optional FK fields
  // (sub_service_id, promotion_id) must be omitted from the wire when null,
  // not serialized as `null`. Neither price_context nor price_amount belong
  // on the request body — both are server-derived from the catalog FKs.
  // ---------------------------------------------------------------------------
  group('InstantBookingRequestModel', () {
    test('Scenario A — fixed-price gig: includes service_id + sub_service_id, '
        'omits promotion_id, price_context, price_amount', () {
      const model = InstantBookingRequestModel(
        technicianId: 42,
        addressId: 7,
        serviceId: 3,
        subServiceId: 17,
        scheduledStart: '2026-04-08T10:00:00+05:00',
        scheduledEnd: '2026-04-08T11:00:00+05:00',
      );
      final json = model.toJson();
      expect(json['technician_id'], 42);
      expect(json['address_id'], 7);
      expect(json['service_id'], 3);
      expect(json['sub_service_id'], 17);
      expect(json['scheduled_start'], '2026-04-08T10:00:00+05:00');
      expect(json['scheduled_end'], '2026-04-08T11:00:00+05:00');
      expect(json.containsKey('promotion_id'), isFalse);
      expect(json.containsKey('price_context'), isFalse);
      expect(json.containsKey('price_amount'), isFalse);
    });

    test('Scenario B — labor gig from search: same shape as A', () {
      const model = InstantBookingRequestModel(
        technicianId: 42,
        addressId: 7,
        serviceId: 3,
        subServiceId: 17,
        scheduledStart: '2026-04-08T10:00:00+05:00',
        scheduledEnd: '2026-04-08T11:00:00+05:00',
      );
      final json = model.toJson();
      expect(json['service_id'], 3);
      expect(json['sub_service_id'], 17);
      expect(json.containsKey('promotion_id'), isFalse);
      expect(json.containsKey('price_context'), isFalse);
      expect(json.containsKey('price_amount'), isFalse);
    });

    test('Scenario C — inspection / parent-category: omits sub_service_id '
        'and promotion_id', () {
      const model = InstantBookingRequestModel(
        technicianId: 42,
        addressId: 7,
        serviceId: 3,
        scheduledStart: '2026-04-08T10:00:00+05:00',
        scheduledEnd: '2026-04-08T11:00:00+05:00',
      );
      final json = model.toJson();
      expect(json['service_id'], 3);
      expect(json.containsKey('sub_service_id'), isFalse);
      expect(json.containsKey('promotion_id'), isFalse);
      expect(json.containsKey('price_context'), isFalse);
      expect(json.containsKey('price_amount'), isFalse);
    });

    test('Scenario D — promo on parent service: includes promotion_id, '
        'omits sub_service_id', () {
      const model = InstantBookingRequestModel(
        technicianId: 42,
        addressId: 7,
        serviceId: 3,
        promotionId: 9,
        scheduledStart: '2026-04-08T10:00:00+05:00',
        scheduledEnd: '2026-04-08T11:00:00+05:00',
      );
      final json = model.toJson();
      expect(json['service_id'], 3);
      expect(json['promotion_id'], 9);
      expect(json.containsKey('sub_service_id'), isFalse);
      expect(json.containsKey('price_context'), isFalse);
      expect(json.containsKey('price_amount'), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // InstantBookingResponseModel
  // ---------------------------------------------------------------------------
  group('InstantBookingResponseModel', () {
    const tJson = {'booking_id': 123};

    test('fromJson parses booking_id correctly', () {
      final result = InstantBookingResponseModel.fromJson(tJson);
      expect(result.bookingId, 123);
    });

    test('toEntity returns CreatedBookingEntity with correct bookingId', () {
      const tModel = InstantBookingResponseModel(bookingId: 99);
      final entity = tModel.toEntity();
      expect(entity, isA<CreatedBookingEntity>());
      expect(entity.bookingId, 99);
    });
  });
}
