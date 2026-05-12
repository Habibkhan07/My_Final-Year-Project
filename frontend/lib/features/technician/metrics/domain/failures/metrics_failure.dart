sealed class MetricsFailure implements Exception {
  const MetricsFailure();
}

class MetricsNetworkFailure extends MetricsFailure {
  const MetricsNetworkFailure();
}

class MetricsPermissionFailure extends MetricsFailure {
  const MetricsPermissionFailure();
}

class MetricsServerFailure extends MetricsFailure {
  const MetricsServerFailure();
}
