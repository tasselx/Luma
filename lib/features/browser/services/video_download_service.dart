import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Handles "downloading" of plain direct media. A full download manager with
/// local file writing + permissions is intentionally out of scope; instead we
/// hand the URL to the system (browser / download manager) which is the safe,
/// portable fallback the spec asks for. Callers should fall back to copying the
/// link when [openExternally] returns false.
class VideoDownloadService {
  const VideoDownloadService();

  /// Opens [url] with an external application (system browser / download
  /// manager). Returns true on success.
  Future<bool> openExternally(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      // Some platforms return false from canLaunchUrl even when launching
      // works; attempt anyway as a best effort.
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('VideoDownloadService: external open failed: $e');
      return false;
    }
  }
}
