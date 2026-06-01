/// User-configurable browser settings. All fields have safe defaults so a
/// missing or corrupt persisted value falls back gracefully.
class BrowserSettings {
  const BrowserSettings({
    this.searchEngineId = 'google',
    this.showQuickSites = true,
    this.enableNativeVideoPlayer = true,
    this.askBeforeOpeningNativeVideo = true,
    this.showDownloadButton = true,
    this.enableTabPersistence = true,
    this.desktopMode = false,
  });

  final String searchEngineId;
  final bool showQuickSites;
  final bool enableNativeVideoPlayer;
  final bool askBeforeOpeningNativeVideo;
  final bool showDownloadButton;
  final bool enableTabPersistence;
  final bool desktopMode;

  BrowserSettings copyWith({
    String? searchEngineId,
    bool? showQuickSites,
    bool? enableNativeVideoPlayer,
    bool? askBeforeOpeningNativeVideo,
    bool? showDownloadButton,
    bool? enableTabPersistence,
    bool? desktopMode,
  }) {
    return BrowserSettings(
      searchEngineId: searchEngineId ?? this.searchEngineId,
      showQuickSites: showQuickSites ?? this.showQuickSites,
      enableNativeVideoPlayer:
          enableNativeVideoPlayer ?? this.enableNativeVideoPlayer,
      askBeforeOpeningNativeVideo:
          askBeforeOpeningNativeVideo ?? this.askBeforeOpeningNativeVideo,
      showDownloadButton: showDownloadButton ?? this.showDownloadButton,
      enableTabPersistence: enableTabPersistence ?? this.enableTabPersistence,
      desktopMode: desktopMode ?? this.desktopMode,
    );
  }

  Map<String, dynamic> toJson() => {
        'searchEngineId': searchEngineId,
        'showQuickSites': showQuickSites,
        'enableNativeVideoPlayer': enableNativeVideoPlayer,
        'askBeforeOpeningNativeVideo': askBeforeOpeningNativeVideo,
        'showDownloadButton': showDownloadButton,
        'enableTabPersistence': enableTabPersistence,
        'desktopMode': desktopMode,
      };

  factory BrowserSettings.fromJson(Map<String, dynamic> json) {
    return BrowserSettings(
      searchEngineId: (json['searchEngineId'] as String?) ?? 'google',
      showQuickSites: (json['showQuickSites'] as bool?) ?? true,
      enableNativeVideoPlayer:
          (json['enableNativeVideoPlayer'] as bool?) ?? true,
      askBeforeOpeningNativeVideo:
          (json['askBeforeOpeningNativeVideo'] as bool?) ?? true,
      showDownloadButton: (json['showDownloadButton'] as bool?) ?? true,
      enableTabPersistence: (json['enableTabPersistence'] as bool?) ?? true,
      desktopMode: (json['desktopMode'] as bool?) ?? false,
    );
  }
}
