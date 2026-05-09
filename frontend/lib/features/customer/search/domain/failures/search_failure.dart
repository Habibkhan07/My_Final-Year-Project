sealed class SearchFailure implements Exception {
  final String message;
  const SearchFailure(this.message);
}

class SearchNetworkFailure extends SearchFailure {
  const SearchNetworkFailure([
    super.message = "No internet connection. Please check your settings.",
  ]);
}

class SearchServerFailure extends SearchFailure {
  const SearchServerFailure([
    super.message = "An unexpected error occurred during search.",
  ]);
}

class SearchParsingFailure extends SearchFailure {
  const SearchParsingFailure([
    super.message = "Invalid response format from server.",
  ]);
}
