/// Describes a candidate video resource discovered from a URL or a page's
/// `<video>` element. Only ordinary, publicly exposed direct media is treated
/// as supported; blob/data/DRM/encrypted streams are explicitly unsupported.
class VideoSource {
  const VideoSource({
    required this.url,
    this.title = '',
    this.sourcePageUrl = '',
    this.mimeType = '',
    this.isDirectMedia = false,
    this.isDownloadSupported = false,
    this.isSupported = false,
  });

  final String url;
  final String title;
  final String sourcePageUrl;
  final String mimeType;

  /// True when [url] points at an ordinary direct media file.
  final bool isDirectMedia;

  /// True when the resource may be downloaded as a plain direct file.
  final bool isDownloadSupported;

  /// True when the native player should attempt playback.
  final bool isSupported;

  VideoSource copyWith({
    String? title,
    String? sourcePageUrl,
  }) {
    return VideoSource(
      url: url,
      title: title ?? this.title,
      sourcePageUrl: sourcePageUrl ?? this.sourcePageUrl,
      mimeType: mimeType,
      isDirectMedia: isDirectMedia,
      isDownloadSupported: isDownloadSupported,
      isSupported: isSupported,
    );
  }

  Map<String, dynamic> toJson() => {
        'url': url,
        'title': title,
        'sourcePageUrl': sourcePageUrl,
        'mimeType': mimeType,
        'isDirectMedia': isDirectMedia,
        'isDownloadSupported': isDownloadSupported,
        'isSupported': isSupported,
      };

  factory VideoSource.fromJson(Map<String, dynamic> json) {
    return VideoSource(
      url: (json['url'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      sourcePageUrl: (json['sourcePageUrl'] as String?) ?? '',
      mimeType: (json['mimeType'] as String?) ?? '',
      isDirectMedia: (json['isDirectMedia'] as bool?) ?? false,
      isDownloadSupported: (json['isDownloadSupported'] as bool?) ?? false,
      isSupported: (json['isSupported'] as bool?) ?? false,
    );
  }

  static const VideoSource unsupported = VideoSource(url: '');
}
