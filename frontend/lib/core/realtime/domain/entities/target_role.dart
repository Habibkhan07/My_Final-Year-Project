enum TargetRole {
  customer,
  technician;

  static const Map<String, TargetRole> _lookup = {
    'customer': TargetRole.customer,
    'technician': TargetRole.technician,
  };

  static TargetRole fromString(String raw) =>
      _lookup[raw] ?? TargetRole.customer;
}
