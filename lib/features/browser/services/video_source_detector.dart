import '../models/video_source.dart';

/// Detects whether a URL points at an ordinary, publicly exposed direct video
/// file. Performs no network access, no scraping and no decryption — it only
/// inspects the URL string itself.
class VideoSourceDetector {
  const VideoSourceDetector();

  static const Map<String, String> _mimeByExt = {
    'mp4': 'video/mp4',
    'm4v': 'video/x-m4v',
    'mov': 'video/quicktime',
    'webm': 'video/webm',
    'm3u8': 'application/vnd.apple.mpegurl',
  };

  // Extensions we attempt to play natively.
  static const Set<String> _playable = {'mp4', 'm4v', 'mov', 'webm', 'm3u8'};

  // Extensions that may be downloaded as a plain direct file. m3u8 is a
  // playlist, not a single file, so it is intentionally excluded.
  static const Set<String> _downloadable = {'mp4', 'm4v', 'mov', 'webm'};

  VideoSource detect(
    String url, {
    String sourcePageUrl = '',
    String title = '',
  }) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return VideoSource.unsupported;

    final lower = trimmed.toLowerCase();
    // Never attempt blob/data sources.
    if (lower.startsWith('blob:') || lower.startsWith('data:')) {
      return VideoSource(
        url: trimmed,
        sourcePageUrl: sourcePageUrl,
        title: title,
        isSupported: false,
      );
    }

    final ext = _extensionOf(lower);
    if (ext == null || !_playable.contains(ext)) {
      return VideoSource(
        url: trimmed,
        sourcePageUrl: sourcePageUrl,
        title: title,
        isSupported: false,
      );
    }

    return VideoSource(
      url: trimmed,
      sourcePageUrl: sourcePageUrl,
      title: title,
      mimeType: _mimeByExt[ext] ?? '',
      isDirectMedia: true,
      isDownloadSupported: _downloadable.contains(ext),
      isSupported: true,
    );
  }

  /// Whether a URL is a direct video link at all (used for navigation
  /// interception).
  bool isDirectVideoLink(String url) => detect(url).isDirectMedia;

  /// Returns the lower-case file extension ignoring any query/fragment, or
  /// `null` when there isn't one.
  String? _extensionOf(String lowerUrl) {
    var path = lowerUrl;
    final queryIndex = path.indexOf('?');
    if (queryIndex != -1) path = path.substring(0, queryIndex);
    final fragIndex = path.indexOf('#');
    if (fragIndex != -1) path = path.substring(0, fragIndex);

    final lastSlash = path.lastIndexOf('/');
    final segment = lastSlash == -1 ? path : path.substring(lastSlash + 1);
    final dot = segment.lastIndexOf('.');
    if (dot == -1 || dot == segment.length - 1) return null;
    return segment.substring(dot + 1);
  }
}
