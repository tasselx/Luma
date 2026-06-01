import '../models/browser_search_engine.dart';

/// The outcome of resolving raw address-bar input.
class ParsedInput {
  const ParsedInput({required this.url, required this.isSearch, this.query});

  /// The resolved URL, or null when the input was empty.
  final String? url;

  /// True when the input was treated as a search query.
  final bool isSearch;

  /// The raw search keyword when [isSearch] is true.
  final String? query;

  static const ParsedInput empty =
      ParsedInput(url: null, isSearch: false, query: null);
}

/// Pure URL parsing / building helpers. Stateless and side-effect free so it is
/// trivial to test and reason about.
class BrowserUrlService {
  const BrowserUrlService();

  static final RegExp _localhost =
      RegExp(r'^localhost(:\d+)?(/.*)?$', caseSensitive: false);
  static final RegExp _ipv4 = RegExp(r'^(\d{1,3})(\.\d{1,3}){3}(:\d+)?(/.*)?$');
  // host(.host)+ optionally with port / path, ASCII only (no spaces, no CJK).
  static final RegExp _domain = RegExp(
    r'^[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?'
    r'(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?)+'
    r'(:\d+)?(/.*)?$',
  );

  /// Converts arbitrary user input into a loadable URL, or `null` when the
  /// input is empty. Anything that is not a recognisable address becomes a
  /// search on the supplied [engine].
  String? parseInputToUrl(String raw, BrowserSearchEngine engine) {
    return resolveInput(raw, engine).url;
  }

  /// Like [parseInputToUrl] but also reports whether the input was treated as a
  /// search (so the caller can record search history).
  ParsedInput resolveInput(String raw, BrowserSearchEngine engine) {
    final input = raw.trim();
    if (input.isEmpty) return ParsedInput.empty;

    final lower = input.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return ParsedInput(url: input, isSearch: false);
    }
    if (lower.startsWith('about:') || lower.startsWith('file:')) {
      return ParsedInput(url: input, isSearch: false);
    }

    // localhost / IPv4 (with optional port + path) -> http.
    if (_localhost.hasMatch(input) || _ipv4.hasMatch(input)) {
      return ParsedInput(url: 'http://$input', isSearch: false);
    }

    // Whitespace or non-ASCII (e.g. Chinese) -> treat as a search query.
    if (input.contains(RegExp(r'\s')) || _hasNonAscii(input)) {
      return ParsedInput(
          url: buildSearchUrl(input, engine), isSearch: true, query: input);
    }

    // Looks like a bare domain (contains a dot, valid host chars) -> https.
    if (_domain.hasMatch(input)) {
      return ParsedInput(url: 'https://$input', isSearch: false);
    }

    return ParsedInput(
        url: buildSearchUrl(input, engine), isSearch: true, query: input);
  }

  /// Builds a search results URL for [query] on [engine], URL-encoding the
  /// query. Falls back to Google when the engine pattern is malformed.
  String buildSearchUrl(String query, BrowserSearchEngine engine) {
    final encoded = Uri.encodeQueryComponent(query);
    final pattern = engine.searchUrlPattern.contains('{query}')
        ? engine.searchUrlPattern
        : BrowserSearchEngine.fallback.searchUrlPattern;
    return pattern.replaceAll('{query}', encoded);
  }

  /// Extracts a host/domain from a URL, returning '' when it cannot be parsed.
  String extractDomain(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return '';
    try {
      final hasScheme = trimmed.contains('://');
      final uri = Uri.parse(hasScheme ? trimmed : 'https://$trimmed');
      final host = uri.host;
      if (host.isEmpty) return '';
      return host.startsWith('www.') ? host.substring(4) : host;
    } catch (_) {
      return '';
    }
  }

  /// Derives a readable file name from a URL (used as a video/download title
  /// fallback). Returns '' when nothing usable can be derived.
  String fileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.pathSegments.isNotEmpty) {
        final last = uri.pathSegments.last;
        if (last.isNotEmpty) return last;
      }
      return uri.host;
    } catch (_) {
      return '';
    }
  }

  bool _hasNonAscii(String input) {
    for (final code in input.codeUnits) {
      if (code > 127) return true;
    }
    return false;
  }
}
