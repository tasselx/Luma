import 'package:flutter_test/flutter_test.dart';
import 'package:luma_browser/features/browser/models/browser_search_engine.dart';
import 'package:luma_browser/features/browser/services/browser_url_service.dart';
import 'package:luma_browser/features/browser/services/video_source_detector.dart';

void main() {
  const urlService = BrowserUrlService();
  const detector = VideoSourceDetector();
  const google = BrowserSearchEngine.fallback;

  group('parseInputToUrl', () {
    test('empty input returns null', () {
      expect(urlService.parseInputToUrl('', google), isNull);
      expect(urlService.parseInputToUrl('   ', google), isNull);
    });

    test('keeps explicit http/https', () {
      expect(
          urlService.parseInputToUrl('https://a.com', google), 'https://a.com');
      expect(
          urlService.parseInputToUrl('http://a.com', google), 'http://a.com');
    });

    test('completes bare domains to https', () {
      expect(urlService.parseInputToUrl('example.com', google),
          'https://example.com');
      expect(urlService.parseInputToUrl('www.example.com', google),
          'https://www.example.com');
    });

    test('localhost and ip use http', () {
      expect(urlService.parseInputToUrl('localhost:3000', google),
          'http://localhost:3000');
      expect(urlService.parseInputToUrl('127.0.0.1:8080', google),
          'http://127.0.0.1:8080');
      expect(urlService.parseInputToUrl('192.168.1.1', google),
          'http://192.168.1.1');
    });

    test('keywords and CJK become a search', () {
      final result = urlService.resolveInput('flutter webview', google);
      expect(result.isSearch, isTrue);
      expect(result.url, contains('google.com/search'));

      final cjk = urlService.resolveInput('你好世界', google);
      expect(cjk.isSearch, isTrue);
    });
  });

  group('VideoSourceDetector', () {
    test('detects direct media with query strings', () {
      final source = detector.detect('https://x.com/v.mp4?token=abc');
      expect(source.isDirectMedia, isTrue);
      expect(source.isDownloadSupported, isTrue);
      expect(source.isSupported, isTrue);
    });

    test('m3u8 is playable but not downloadable', () {
      final source = detector.detect('https://x.com/stream.m3u8');
      expect(source.isDirectMedia, isTrue);
      expect(source.isDownloadSupported, isFalse);
    });

    test('blob and data are unsupported', () {
      expect(detector.detect('blob:https://x.com/abc').isSupported, isFalse);
      expect(detector.detect('data:video/mp4;base64,xyz').isSupported, isFalse);
      expect(detector.detect('').isSupported, isFalse);
    });

    test('ordinary pages are not video links', () {
      expect(detector.isDirectVideoLink('https://example.com'), isFalse);
    });
  });
}
