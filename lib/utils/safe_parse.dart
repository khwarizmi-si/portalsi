/// Tolerant parsing helpers for JSON coming off the API / websocket.
///
/// Realtime payloads sometimes arrive with a partial shape (missing or null
/// fields), and `DateTime.parse(null)` / force-unwraps crash the whole list
/// render. These helpers degrade gracefully instead of throwing.
library;

/// Parses a date string, returning [fallback] (defaults to `DateTime.now()`)
/// when the value is null, empty, or malformed.
DateTime safeParseDate(dynamic value, {DateTime? fallback}) {
  final parsed = DateTime.tryParse(value?.toString().trim() ?? '');
  return parsed ?? fallback ?? DateTime.now();
}

/// Parses an optional date string, returning null when absent or malformed.
DateTime? safeParseDateOrNull(dynamic value) {
  return DateTime.tryParse(value?.toString().trim() ?? '');
}
