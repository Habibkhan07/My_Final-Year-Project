/// Discriminator the technician's app uses to switch the on-site flow.
///
/// Mirrors the backend's `booking_type` field on the `job_new_request` event
/// payload (see `backend/bookings/api/BOOKINGS_API.md` §1.2). Wire values are
/// `"INSPECTION"`, `"FIXED_GIG"`, `"LABOR_GIG"` — translation lives in the
/// data-layer mapper, not here.
///
/// On replay of pre-rollout `EventLog` rows, the wire field can be missing;
/// the mapper defaults to [laborGig] (the §2.5 "neutral layout" choice — Mark
/// Complete + optional upsell). Keeping this enum non-nullable in the domain
/// means widgets always receive a typed value.
enum BookingType {
  /// Customer booked the parent service for an inspection visit. Technician's
  /// on-site flow is "Build Quote"; the headline payout is the visit fee, not
  /// the whole job.
  inspection,

  /// Customer picked a fixed-price gig. Technician's flow is "Mark Complete";
  /// payout shown is the full job payout.
  fixedGig,

  /// Customer agreed labor terms up front. Same shape as [fixedGig] for the
  /// completion flow; distinct because the payout source is the technician's
  /// labor rate rather than a sub-service fixed price.
  laborGig,
}
