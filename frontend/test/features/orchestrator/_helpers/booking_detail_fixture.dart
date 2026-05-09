// Shared fixture builder for orchestrator tests.
//
// Returns a wire-shaped JSON map (the same shape produced by
// `BookingDetailResponseSerializer.to_representation`). The JSON is the
// most realistic input for `BookingDetailMapper.toDomain` and matches
// what the local cache and remote data source both emit.
//
// Pass overrides to vary individual fields; the structure stays
// identical so tests stay faithful to the wire contract.
Map<String, dynamic> bookingDetailJson({
  int id = 42,
  String status = 'CONFIRMED',
  int customerId = 7,
  int technicianId = 99,
  int? parentBookingId,
  int? childBookingId,
  String? cancelReason,
  Map<String, dynamic>? activeQuote,
  List<Map<String, dynamic>> bookingItems = const [],
  Map<String, dynamic>? uiOverride,
}) {
  return <String, dynamic>{
    'id': id,
    'status': status,
    'service': {'id': 1, 'name': 'Plumbing', 'icon_name': 'plumbing'},
    'sub_service': null,
    'technician': {
      'id': technicianId,
      'display_name': 'Ali Raza',
      'profile_picture_url': 'http://testserver/media/tech_profiles/ali.jpg',
    },
    'customer': {
      'id': customerId,
      'full_name': 'Sara Customer',
      'phone_no': '+923001234567',
    },
    'address': {
      'label': 'Home',
      'latitude': '31.520400',
      'longitude': '74.358700',
      'address_text': 'House 1, Street 1, Lahore',
    },
    'address_snapshot': 'House 1, Street 1, Lahore',
    'scheduled_start': '2026-05-09T10:00:00Z',
    'scheduled_end': '2026-05-09T11:00:00Z',
    'phase_timestamps': {
      'accepted_at': '2026-05-09T09:30:00Z',
      'en_route_started_at': null,
      'arrived_at': null,
      'inspection_started_at': null,
      'quote_first_submitted_at': null,
      'work_started_at': null,
      'completed_at': null,
    },
    'pricing': {
      'inspection_fee': '500.00',
      'base_services_total': null,
      'discount_applied': null,
      'final_cash_to_collect': null,
      'promo_code_snapshot': null,
      'promo_discount_snapshot': null,
    },
    'cash_collection': {
      'amount': null,
      'at': null,
      'method': 'cash',
    },
    'parent_booking_id': parentBookingId,
    'child_booking_id': childBookingId,
    'cancel_reason': cancelReason,
    'no_show_actor': null,
    'active_quote': activeQuote,
    'booking_items': bookingItems,
    'open_tickets_count': 0,
    'ui': uiOverride ??
        {
          'status_label': 'Confirmed',
          'body_text': 'On the way at 10:00.',
          'primary_action': null,
          'secondary_actions': <Map<String, dynamic>>[],
          'show_tracking': false,
          'show_quote_card': false,
          'show_dispute_button': false,
          'tone': 'positive',
        },
    'available_transitions': <String>['cancel_by_customer'],
  };
}
