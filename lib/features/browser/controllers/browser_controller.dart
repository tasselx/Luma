import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../models/bookmark_item.dart';
import '../models/browser_history_item.dart';
import '../models/browser_search_engine.dart';
import '../models/browser_settings.dart';
import '../models/browser_tab.dart';
import '../models/download_item.dart';
import '../models/quick_site.dart';
import '../models/video_source.dart';
import '../services/browser_storage_service.dart';
import '../services/browser_url_service.dart';
import '../services/video_source_detector.dart';

const String _desktopUserAgent =
    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 '
    '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

const Set<String> _downloadExtensions = {
  'zip', 'rar', '7z', 'gz', 'tar', 'apk', 'exe', 'dmg', 'iso', 'pkg', 'deb',
  'bin', 'mp3', 'wav', 'flac', 'aac', 'ogg', // audio
};

/// Owns all browser state: tabs, their live [WebViewController]s, history,
/// bookmarks, search history, settings and downloads. The UI only reads from
/// this controller and calls its methods — it never mutates state directly.
class BrowserController extends ChangeNotifier {
  BrowserController({
    BrowserStorageService? storage,
    BrowserUrlService urlService = const BrowserUrlService(),
    VideoSourceDetector videoDetector = const VideoSourceDetector(),
  })  : _storage = storage ?? BrowserStorageService(),
        _urlService = urlService,
        _videoDetector = videoDetector;

  final BrowserStorageService _storage;
  final BrowserUrlService _urlService;
  final VideoSourceDetector _videoDetector;

  final Map<String, WebViewController> _controllers = {};
  final Set<String> _loadedTabIds = {};

  List<BrowserTab> _tabs = [];
  int _currentIndex = 0;
  List<BrowserHistoryItem> _history = [];
  List<BookmarkItem> _bookmarks = [];
  List<String> _searchHistory = [];
  List<DownloadItem> _downloads = [];
  final List<BrowserTab> _recentlyClosed = [];
  BrowserSettings _settings = const BrowserSettings();
  bool _initialized = false;
  bool _disposed = false;

  // When set, the next navigation to this exact URL skips video interception
  // (used by the "open in web page" choice of the intercept dialog).
  String? _allowVideoNavOnce;

  // UI hooks (set by the page).
  void Function(VideoSource source)? onVideoIntercept;
  void Function(String url, String fileName, String domain)?
      onDownloadIntercept;
  void Function(String message)? onMessage;

  // --- exposed services / data --------------------------------------------

  BrowserUrlService get urlService => _urlService;
  VideoSourceDetector get videoDetector => _videoDetector;

  bool get isInitialized => _initialized;
  List<BrowserTab> get tabs => List.unmodifiable(_tabs);
  List<BrowserHistoryItem> get history => List.unmodifiable(_history);
  List<BookmarkItem> get bookmarks => List.unmodifiable(_bookmarks);
  List<String> get searchHistory => List.unmodifiable(_searchHistory);
  List<DownloadItem> get downloads => List.unmodifiable(_downloads);
  List<BrowserTab> get recentlyClosed => List.unmodifiable(_recentlyClosed);
  BrowserSettings get settings => _settings;
  List<QuickSite> get quickSites => QuickSite.defaults;
  List<BrowserSearchEngine> get searchEngines => BrowserSearchEngine.all;
  BrowserSearchEngine get currentSearchEngine =>
      BrowserSearchEngine.byId(_settings.searchEngineId);

  int get currentIndex => _currentIndex;
  BrowserTab? get currentTab =>
      (_currentIndex >= 0 && _currentIndex < _tabs.length)
          ? _tabs[_currentIndex]
          : null;

  String get currentUrl => currentTab?.url ?? '';
  String get currentTitle => currentTab?.title ?? '';
  bool get isCurrentLoading => currentTab?.isLoading ?? false;
  double get currentProgress => currentTab?.progress ?? 0;
  bool get canGoBack => currentTab?.canGoBack ?? false;
  bool get canGoForward => currentTab?.canGoForward ?? false;
  bool get isCurrentPrivate => currentTab?.isPrivate ?? false;
  int get tabCount => _tabs.length;

  bool isCurrentBookmarked() {
    final url = currentUrl;
    return url.isNotEmpty && _bookmarks.any((b) => b.url == url);
  }

  // --- lifecycle -----------------------------------------------------------

  Future<void> init() async {
    await _storage.init();
    _settings = _storage.loadSettings();
    _history = _storage.loadHistory();
    _bookmarks = _storage.loadBookmarks();
    _searchHistory = _storage.loadSearchHistory();
    _downloads = _storage.loadDownloads();

    if (_settings.enableTabPersistence) {
      final restored = _storage.loadTabs();
      if (restored.isNotEmpty) {
        _tabs = restored;
      }
    }
    if (_tabs.isEmpty) {
      _tabs = [BrowserTab(id: BrowserTab.generateId())];
    }
    _currentIndex = 0;
    _initialized = true;
    _safeNotify();
  }

  @override
  void dispose() {
    _disposed = true;
    _controllers.clear();
    super.dispose();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  BrowserTab? _tabById(String id) {
    for (final tab in _tabs) {
      if (tab.id == id) return tab;
    }
    return null;
  }

  // --- WebView controllers -------------------------------------------------

  /// Returns (creating if needed) the [WebViewController] bound to [tab]. A
  /// freshly created controller for a restored tab loads its URL once.
  WebViewController webViewControllerFor(BrowserTab tab) {
    final controller =
        _controllers.putIfAbsent(tab.id, () => _createController(tab));
    if (!_loadedTabIds.contains(tab.id) && tab.url.trim().isNotEmpty) {
      _loadedTabIds.add(tab.id);
      _loadInController(controller, tab.url);
    }
    return controller;
  }

  WebViewController _createController(BrowserTab tab) {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) => _onProgress(tab.id, p),
          onPageStarted: (url) => _onPageStarted(tab.id, url),
          onPageFinished: (url) => _onPageFinished(tab.id, url),
          onWebResourceError: (err) => _onWebResourceError(tab.id, err),
          onNavigationRequest: (req) => _onNavigationRequest(tab.id, req),
        ),
      );
    if (_settings.desktopMode) {
      controller.setUserAgent(_desktopUserAgent);
    }
    return controller;
  }

  void _loadInController(WebViewController controller, String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      controller.loadRequest(uri);
    } catch (e) {
      debugPrint('BrowserController: loadRequest failed: $e');
    }
  }

  // --- navigation callbacks ------------------------------------------------

  void _onProgress(String tabId, int progress) {
    final tab = _tabById(tabId);
    if (tab == null) return;
    tab.progress = progress / 100.0;
    tab.isLoading = progress < 100;
    _safeNotify();
  }

  void _onPageStarted(String tabId, String url) {
    final tab = _tabById(tabId);
    if (tab == null) return;
    tab.url = url;
    tab.isLoading = true;
    tab.progress = 0;
    tab.errorMessage = null;
    tab.updatedAt = DateTime.now();
    _safeNotify();
  }

  Future<void> _onPageFinished(String tabId, String url) async {
    final tab = _tabById(tabId);
    if (tab == null) return;
    tab.isLoading = false;
    tab.progress = 1.0;
    tab.url = url;

    final controller = _controllers[tabId];
    String title = tab.title;
    bool back = false;
    bool forward = false;
    try {
      title = await controller?.getTitle() ?? tab.title;
    } catch (_) {}
    try {
      back = await controller?.canGoBack() ?? false;
    } catch (_) {}
    try {
      forward = await controller?.canGoForward() ?? false;
    } catch (_) {}

    if (_disposed) return;
    final resolvedTab = _tabById(tabId);
    if (resolvedTab == null) return;
    resolvedTab.title =
        title.trim().isEmpty ? _urlService.extractDomain(url) : title;
    resolvedTab.canGoBack = back;
    resolvedTab.canGoForward = forward;
    resolvedTab.updatedAt = DateTime.now();

    if (!resolvedTab.isPrivate && url.trim().isNotEmpty) {
      _recordHistory(resolvedTab.title, url);
    }
    _persistTabs();
    _safeNotify();
  }

  void _onWebResourceError(String tabId, WebResourceError error) {
    // Ignore sub-resource failures and iOS "request cancelled" noise.
    if (error.isForMainFrame == false) return;
    if (error.errorCode == -999) return;
    final tab = _tabById(tabId);
    if (tab == null) return;
    tab.isLoading = false;
    tab.errorMessage = _describeError(error);
    _safeNotify();
  }

  NavigationDecision _onNavigationRequest(
      String tabId, NavigationRequest request) {
    final url = request.url;
    final lower = url.toLowerCase();

    // Allow a one-shot navigation to a video URL inside the web view.
    if (_allowVideoNavOnce != null && url == _allowVideoNavOnce) {
      _allowVideoNavOnce = null;
      return NavigationDecision.navigate;
    }

    // Non-web schemes (mailto:, tel:, intent:, custom apps) -> open externally.
    final isWeb = lower.startsWith('http://') ||
        lower.startsWith('https://') ||
        lower.startsWith('about:') ||
        lower.startsWith('file:');
    if (!isWeb) {
      _handleExternal(url);
      return NavigationDecision.prevent;
    }

    // Direct video link -> intercept for native playback.
    if (_settings.enableNativeVideoPlayer) {
      final source = _videoDetector.detect(url);
      if (source.isDirectMedia) {
        final pageUrl = _tabById(tabId)?.url ?? '';
        onVideoIntercept?.call(source.copyWith(sourcePageUrl: pageUrl));
        return NavigationDecision.prevent;
      }
    }

    // Plain downloadable file -> hand to the download confirm flow.
    if (_looksLikeDownload(url)) {
      final domain = _urlService.extractDomain(url);
      final fileName = _urlService.fileNameFromUrl(url);
      onDownloadIntercept?.call(url, fileName, domain);
      return NavigationDecision.prevent;
    }

    return NavigationDecision.navigate;
  }

  Future<void> _handleExternal(String url) async {
    final ok = await openExternalUrl(url);
    if (!ok) {
      onMessage?.call('无法打开外部链接');
    }
  }

  bool _looksLikeDownload(String url) {
    final detector = _videoDetector;
    if (detector.isDirectVideoLink(url)) return false;
    var path = url.toLowerCase();
    final q = path.indexOf('?');
    if (q != -1) path = path.substring(0, q);
    final dot = path.lastIndexOf('.');
    if (dot == -1) return false;
    final ext = path.substring(dot + 1);
    return _downloadExtensions.contains(ext);
  }

  String _describeError(WebResourceError error) {
    final type = error.errorType;
    if (type == WebResourceErrorType.hostLookup ||
        type == WebResourceErrorType.connect ||
        type == WebResourceErrorType.timeout ||
        type == WebResourceErrorType.io) {
      return '网络连接失败，请检查网络后重试。';
    }
    if (type == WebResourceErrorType.failedSslHandshake) {
      return '安全连接失败（SSL 错误）。';
    }
    final desc = error.description.trim();
    return desc.isEmpty ? '页面加载失败。' : desc;
  }

  // --- input / navigation actions -----------------------------------------

  /// Resolves arbitrary address-bar input and opens it in the current tab.
  void openInput(String raw) {
    final tab = currentTab;
    if (tab == null) return;
    final result = _urlService.resolveInput(raw, currentSearchEngine);
    if (result.url == null) return;
    if (result.isSearch && !tab.isPrivate && result.query != null) {
      _addSearchHistory(result.query!);
    }
    openUrl(result.url!);
  }

  /// Loads [url] (assumed already a valid URL) in the current tab.
  void openUrl(String url) {
    final tab = currentTab;
    if (tab == null || url.trim().isEmpty) return;
    tab.url = url;
    tab.errorMessage = null;
    tab.isLoading = true;
    tab.progress = 0;
    tab.updatedAt = DateTime.now();
    final controller =
        _controllers.putIfAbsent(tab.id, () => _createController(tab));
    _loadedTabIds.add(tab.id);
    _loadInController(controller, url);
    _safeNotify();
  }

  /// Loads [url] in the current tab while allowing a video direct link to load
  /// inside the web view (skips native-player interception once).
  void openUrlAllowingVideo(String url) {
    _allowVideoNavOnce = url;
    openUrl(url);
  }

  /// Returns the current tab to the home page, discarding its loaded URL.
  void goHomeCurrentTab() {
    final tab = currentTab;
    if (tab == null) return;
    tab.url = '';
    tab.title = '';
    tab.errorMessage = null;
    tab.isLoading = false;
    tab.progress = 0;
    tab.canGoBack = false;
    tab.canGoForward = false;
    tab.updatedAt = DateTime.now();
    _persistTabs();
    _safeNotify();
  }

  void reload() {
    final tab = currentTab;
    if (tab == null) return;
    if (tab.url.trim().isEmpty) return;
    final controller = _controllers[tab.id];
    if (controller == null) {
      openUrl(tab.url);
      return;
    }
    try {
      controller.reload();
    } catch (e) {
      debugPrint('BrowserController: reload failed: $e');
    }
  }

  void stopLoading() {
    final controller = _controllers[currentTab?.id];
    if (controller == null) return;
    // The cross-platform controller has no stopLoading; window.stop() is the
    // portable equivalent.
    try {
      controller.runJavaScript('window.stop();');
    } catch (_) {}
    final tab = currentTab;
    if (tab != null) {
      tab.isLoading = false;
      _safeNotify();
    }
  }

  Future<void> goBack() async {
    final controller = _controllers[currentTab?.id];
    if (controller == null) return;
    try {
      if (await controller.canGoBack()) await controller.goBack();
    } catch (e) {
      debugPrint('BrowserController: goBack failed: $e');
    }
  }

  Future<void> goForward() async {
    final controller = _controllers[currentTab?.id];
    if (controller == null) return;
    try {
      if (await controller.canGoForward()) await controller.goForward();
    } catch (e) {
      debugPrint('BrowserController: goForward failed: $e');
    }
  }

  /// Handles the Android back button. Returns true when it was consumed
  /// (web view went back), false when the app should handle it.
  Future<bool> handleBackButton() async {
    final tab = currentTab;
    if (tab == null) return false;
    final controller = _controllers[tab.id];
    if (controller != null) {
      try {
        if (await controller.canGoBack()) {
          await controller.goBack();
          return true;
        }
      } catch (_) {}
    }
    return false;
  }

  Future<bool> openExternalUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    try {
      // Imported lazily to keep the controller free of UI deps; uses
      // url_launcher under the hood via the download service helper.
      return await _externalLauncher(uri);
    } catch (e) {
      debugPrint('BrowserController: external launch failed: $e');
      return false;
    }
  }

  // Indirection so tests can override; defaults to url_launcher.
  Future<bool> Function(Uri uri) _externalLauncher = _defaultLauncher;
  set externalLauncher(Future<bool> Function(Uri uri) launcher) =>
      _externalLauncher = launcher;

  // --- tabs ----------------------------------------------------------------

  BrowserTab newTab({bool private = false}) {
    final tab = BrowserTab(id: BrowserTab.generateId(), isPrivate: private);
    _tabs.add(tab);
    _currentIndex = _tabs.length - 1;
    _persistTabs();
    _safeNotify();
    return tab;
  }

  BrowserTab newPrivateTab() => newTab(private: true);

  void switchTab(String id) {
    final index = _tabs.indexWhere((t) => t.id == id);
    if (index == -1 || index == _currentIndex) return;
    _currentIndex = index;
    _safeNotify();
  }

  void closeTab(String id) {
    final index = _tabs.indexWhere((t) => t.id == id);
    if (index == -1) return;
    final tab = _tabs[index];
    if (!tab.isPrivate && tab.url.trim().isNotEmpty) {
      _recentlyClosed.insert(0, tab);
      if (_recentlyClosed.length > 10) {
        _recentlyClosed.removeRange(10, _recentlyClosed.length);
      }
    }
    _controllers.remove(id);
    _loadedTabIds.remove(id);
    _tabs.removeAt(index);

    if (_tabs.isEmpty) {
      _tabs.add(BrowserTab(id: BrowserTab.generateId()));
      _currentIndex = 0;
    } else if (_currentIndex >= _tabs.length) {
      _currentIndex = _tabs.length - 1;
    } else if (index < _currentIndex) {
      _currentIndex -= 1;
    }
    _persistTabs();
    _safeNotify();
  }

  void closeOtherTabs(String keepId) {
    final keep = _tabById(keepId);
    if (keep == null) return;
    for (final tab in _tabs) {
      if (tab.id != keepId) {
        _controllers.remove(tab.id);
        _loadedTabIds.remove(tab.id);
      }
    }
    _tabs = [keep];
    _currentIndex = 0;
    _persistTabs();
    _safeNotify();
  }

  void closeAllNormalTabs() {
    final remaining = _tabs.where((t) => t.isPrivate).toList();
    for (final tab in _tabs) {
      if (!tab.isPrivate) {
        _controllers.remove(tab.id);
        _loadedTabIds.remove(tab.id);
      }
    }
    if (remaining.isEmpty) {
      remaining.add(BrowserTab(id: BrowserTab.generateId()));
    }
    _tabs = remaining;
    _currentIndex = 0;
    _persistTabs();
    _safeNotify();
  }

  void restoreRecentlyClosed() {
    if (_recentlyClosed.isEmpty) return;
    final tab = _recentlyClosed.removeAt(0);
    final restored = BrowserTab(id: BrowserTab.generateId());
    _tabs.add(restored);
    _currentIndex = _tabs.length - 1;
    _safeNotify();
    openUrl(tab.url);
  }

  void _persistTabs() {
    if (!_settings.enableTabPersistence) return;
    _storage.saveTabs(_tabs);
  }

  // --- history -------------------------------------------------------------

  void _recordHistory(String title, String url) {
    final domain = _urlService.extractDomain(url);
    final existing = _history.indexWhere((h) => h.url == url);
    if (existing != -1) {
      final updated = _history[existing].copyWith(
        title: title.trim().isEmpty ? null : title,
        visitedAt: DateTime.now(),
      );
      _history.removeAt(existing);
      _history.insert(0, updated);
    } else {
      _history.insert(
        0,
        BrowserHistoryItem(title: title, url: url, domain: domain),
      );
    }
    if (_history.length > BrowserStorageService.maxHistory) {
      _history = _history.sublist(0, BrowserStorageService.maxHistory);
    }
    _storage.saveHistory(_history);
  }

  void removeHistory(String url) {
    final before = _history.length;
    _history.removeWhere((h) => h.url == url);
    if (_history.length != before) {
      _storage.saveHistory(_history);
      _safeNotify();
    }
  }

  Future<void> clearHistory() async {
    _history = [];
    await _storage.clearHistory();
    _safeNotify();
  }

  // --- bookmarks -----------------------------------------------------------

  /// Toggles the bookmark for the current page. Returns true when the page is
  /// now bookmarked, false when it was removed (or no-op).
  bool toggleBookmark() {
    final tab = currentTab;
    if (tab == null || tab.url.trim().isEmpty) return false;
    final url = tab.url;
    final index = _bookmarks.indexWhere((b) => b.url == url);
    if (index != -1) {
      _bookmarks.removeAt(index);
      _storage.saveBookmarks(_bookmarks);
      _safeNotify();
      return false;
    }
    final domain = _urlService.extractDomain(url);
    final title =
        tab.title.trim().isEmpty ? (domain.isEmpty ? url : domain) : tab.title;
    _bookmarks.insert(
      0,
      BookmarkItem(title: title, url: url, domain: domain),
    );
    _storage.saveBookmarks(_bookmarks);
    _safeNotify();
    return true;
  }

  void removeBookmark(String url) {
    final before = _bookmarks.length;
    _bookmarks.removeWhere((b) => b.url == url);
    if (_bookmarks.length != before) {
      _storage.saveBookmarks(_bookmarks);
      _safeNotify();
    }
  }

  Future<void> clearBookmarks() async {
    _bookmarks = [];
    await _storage.clearBookmarks();
    _safeNotify();
  }

  // --- search history ------------------------------------------------------

  void _addSearchHistory(String query) {
    final keyword = query.trim();
    if (keyword.isEmpty) return;
    _searchHistory.removeWhere((k) => k == keyword);
    _searchHistory.insert(0, keyword);
    if (_searchHistory.length > BrowserStorageService.maxSearchHistory) {
      _searchHistory =
          _searchHistory.sublist(0, BrowserStorageService.maxSearchHistory);
    }
    _storage.saveSearchHistory(_searchHistory);
  }

  void removeSearchHistory(String keyword) {
    final before = _searchHistory.length;
    _searchHistory.removeWhere((k) => k == keyword);
    if (_searchHistory.length != before) {
      _storage.saveSearchHistory(_searchHistory);
      _safeNotify();
    }
  }

  Future<void> clearSearchHistory() async {
    _searchHistory = [];
    await _storage.clearSearchHistory();
    _safeNotify();
  }

  // --- settings ------------------------------------------------------------

  Future<void> updateSettings(BrowserSettings settings) async {
    final desktopChanged = settings.desktopMode != _settings.desktopMode;
    _settings = settings;
    await _storage.saveSettings(settings);
    if (desktopChanged) {
      for (final controller in _controllers.values) {
        controller
            .setUserAgent(settings.desktopMode ? _desktopUserAgent : null);
      }
    }
    if (!settings.enableTabPersistence) {
      _storage.clearTabs();
    } else {
      _persistTabs();
    }
    _safeNotify();
  }

  Future<void> clearBrowsingData() async {
    _history = [];
    _searchHistory = [];
    _downloads = [];
    await _storage.clearHistory();
    await _storage.clearSearchHistory();
    await _storage.clearDownloads();
    _safeNotify();
  }

  // --- downloads -----------------------------------------------------------

  void addDownloadRecord(DownloadItem item) {
    if (isCurrentPrivate) return;
    _downloads.insert(0, item);
    _storage.saveDownloads(_downloads);
    _safeNotify();
  }

  Future<void> clearDownloads() async {
    _downloads = [];
    await _storage.clearDownloads();
    _safeNotify();
  }

  // --- enhancements --------------------------------------------------------

  /// Runs an in-page find using window.find when available.
  Future<void> findInPage(String query) async {
    final controller = _controllers[currentTab?.id];
    if (controller == null || query.trim().isEmpty) {
      onMessage?.call('当前页面不支持查找');
      return;
    }
    try {
      final escaped = query.replaceAll("'", "\\'");
      await controller.runJavaScript("window.find && window.find('$escaped');");
    } catch (_) {
      onMessage?.call('当前页面不支持查找');
    }
  }
}

Future<bool> _defaultLauncher(Uri uri) async {
  if (await canLaunchUrl(uri)) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
