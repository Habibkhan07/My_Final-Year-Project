/// Whose perspective the orchestrator screen renders.
///
/// Derived in the data-layer mapper by comparing the authenticated user's id
/// against the booking's customer/technician participants. Server gates
/// non-participants with a 403 before the response ever reaches the mapper,
/// so the mapper can safely treat "not the customer" as "the technician".
enum BookingOrchestratorRole {
  customer,
  technician,
}
