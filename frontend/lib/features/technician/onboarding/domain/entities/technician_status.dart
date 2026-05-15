/// The current user's technician application status. The Flutter router
/// pattern-matches on this to decide between customer home, the
/// pending-approval holding screen, the rejected screen, and the tech
/// dashboard.
///
/// Backed by `GET /api/technicians/me/status/`. The wire enum
/// (`PENDING` / `APPROVED` / `REJECTED`) maps onto the sealed variants
/// below at the data-source mapper boundary.
sealed class TechnicianStatus {
  const TechnicianStatus();
}

/// The user has never applied to be a technician — pure customer surface.
class TechnicianStatusNoProfile extends TechnicianStatus {
  const TechnicianStatusNoProfile();
}

/// Application submitted; admin has not yet decided.
class TechnicianStatusPending extends TechnicianStatus {
  const TechnicianStatusPending();
}

/// Application approved; tech can use the technician surface.
class TechnicianStatusApproved extends TechnicianStatus {
  const TechnicianStatusApproved();
}

/// Application rejected. [reason] is admin-authored free text shown
/// verbatim on the rejected holding screen; null when the admin did
/// not provide one.
class TechnicianStatusRejected extends TechnicianStatus {
  final String? reason;
  const TechnicianStatusRejected({this.reason});
}
