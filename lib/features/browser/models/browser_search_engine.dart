/// A search engine definition. [searchUrlPattern] contains a `{query}`
/// placeholder that is replaced by the URL-encoded search term.
class BrowserSearchEngine {
  const BrowserSearchEngine({
    required this.id,
    required this.name,
    required this.searchUrlPattern,
  });

  final String id;
  final String name;
  final String searchUrlPattern;

  String buildSearchUrl(String encodedQuery) {
    return searchUrlPattern.replaceAll('{query}', encodedQuery);
  }

  /// Built-in engines. Google is the default and acts as the fallback.
  static const List<BrowserSearchEngine> all = [
    BrowserSearchEngine(
      id: 'google',
      name: 'Google',
      searchUrlPattern: 'https://www.google.com/search?q={query}',
    ),
    BrowserSearchEngine(
      id: 'bing',
      name: 'Bing',
      searchUrlPattern: 'https://www.bing.com/search?q={query}',
    ),
    BrowserSearchEngine(
      id: 'duckduckgo',
      name: 'DuckDuckGo',
      searchUrlPattern: 'https://duckduckgo.com/?q={query}',
    ),
    BrowserSearchEngine(
      id: 'baidu',
      name: 'Baidu',
      searchUrlPattern: 'https://www.baidu.com/s?wd={query}',
    ),
  ];

  static const BrowserSearchEngine fallback = BrowserSearchEngine(
    id: 'google',
    name: 'Google',
    searchUrlPattern: 'https://www.google.com/search?q={query}',
  );

  static BrowserSearchEngine byId(String? id) {
    return all.firstWhere(
      (e) => e.id == id,
      orElse: () => fallback,
    );
  }
}
