import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/bookmark_item.dart';
import '../models/browser_history_item.dart';
import '../models/browser_settings.dart';
import '../models/browser_tab.dart';
import '../models/download_item.dart';

/// Centralised local persistence backed by [SharedPreferences]. Every read/write
/// is wrapped in try/catch and a JSON decode failure simply returns the default
/// value (usually an empty list) so the app can never crash on corrupt data.
///
/// If [SharedPreferences] itself is unavailable, an in-memory map is used as a
/// fallback so the rest of the app keeps working for the session.
class BrowserStorageService {
  static const String _kHistory = 'browser.history';
  static const String _kBookmarks = 'browser.bookmarks';
  static const String _kSearchHistory = 'browser.searchHistory';
  static const String _kSettings = 'browser.settings';
  static const String _kTabs = 'browser.tabs';
  static const String _kDownloads = 'browser.downloads';

  static const int maxHistory = 500;
  static const int maxSearchHistory = 50;

  SharedPreferences? _prefs;
  final Map<String, String> _memory = {};

  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      _prefs = null;
      debugPrint('BrowserStorageService: prefs unavailable, using memory: $e');
    }
  }

  // --- raw helpers ---------------------------------------------------------

  String? _readString(String key) {
    try {
      return _prefs?.getString(key) ?? _memory[key];
    } catch (e) {
      return _memory[key];
    }
  }

  Future<void> _writeString(String key, String value) async {
    _memory[key] = value;
    try {
      await _prefs?.setString(key, value);
    } catch (e) {
      debugPrint('BrowserStorageService: write failed for $key: $e');
    }
  }

  Future<void> _remove(String key) async {
    _memory.remove(key);
    try {
      await _prefs?.remove(key);
    } catch (e) {
      debugPrint('BrowserStorageService: remove failed for $key: $e');
    }
  }

  List<Map<String, dynamic>> _decodeList(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.whereType<Map>().map((e) {
          return e.map((k, v) => MapEntry(k.toString(), v));
        }).toList();
      }
      return [];
    } catch (e) {
      debugPrint('BrowserStorageService: decode failed: $e');
      return [];
    }
  }

  // --- history -------------------------------------------------------------

  List<BrowserHistoryItem> loadHistory() {
    return _decodeList(_readString(_kHistory))
        .map(BrowserHistoryItem.fromJson)
        .toList();
  }

  Future<void> saveHistory(List<BrowserHistoryItem> items) async {
    final capped =
        items.length > maxHistory ? items.sublist(0, maxHistory) : items;
    await _writeString(
        _kHistory, jsonEncode(capped.map((e) => e.toJson()).toList()));
  }

  Future<void> clearHistory() => _remove(_kHistory);

  // --- bookmarks -----------------------------------------------------------

  List<BookmarkItem> loadBookmarks() {
    return _decodeList(_readString(_kBookmarks))
        .map(BookmarkItem.fromJson)
        .toList();
  }

  Future<void> saveBookmarks(List<BookmarkItem> items) async {
    await _writeString(
        _kBookmarks, jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  Future<void> clearBookmarks() => _remove(_kBookmarks);

  // --- search history ------------------------------------------------------

  List<String> loadSearchHistory() {
    final raw = _readString(_kSearchHistory);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
      return [];
    } catch (e) {
      debugPrint('BrowserStorageService: search history decode failed: $e');
      return [];
    }
  }

  Future<void> saveSearchHistory(List<String> items) async {
    final capped = items.length > maxSearchHistory
        ? items.sublist(0, maxSearchHistory)
        : items;
    await _writeString(_kSearchHistory, jsonEncode(capped));
  }

  Future<void> clearSearchHistory() => _remove(_kSearchHistory);

  // --- settings ------------------------------------------------------------

  BrowserSettings loadSettings() {
    final raw = _readString(_kSettings);
    if (raw == null || raw.isEmpty) return const BrowserSettings();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return BrowserSettings.fromJson(
            decoded.map((k, v) => MapEntry(k.toString(), v)));
      }
      return const BrowserSettings();
    } catch (e) {
      debugPrint('BrowserStorageService: settings decode failed: $e');
      return const BrowserSettings();
    }
  }

  Future<void> saveSettings(BrowserSettings settings) async {
    await _writeString(_kSettings, jsonEncode(settings.toJson()));
  }

  // --- non-private tabs (optional persistence) -----------------------------

  List<BrowserTab> loadTabs() {
    return _decodeList(_readString(_kTabs)).map(BrowserTab.fromJson).toList();
  }

  Future<void> saveTabs(List<BrowserTab> tabs) async {
    // Never persist private tabs.
    final normal = tabs.where((t) => !t.isPrivate).toList();
    await _writeString(
        _kTabs, jsonEncode(normal.map((e) => e.toJson()).toList()));
  }

  Future<void> clearTabs() => _remove(_kTabs);

  // --- downloads -----------------------------------------------------------

  List<DownloadItem> loadDownloads() {
    return _decodeList(_readString(_kDownloads))
        .map(DownloadItem.fromJson)
        .toList();
  }

  Future<void> saveDownloads(List<DownloadItem> items) async {
    await _writeString(
        _kDownloads, jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  Future<void> clearDownloads() => _remove(_kDownloads);

  /// Clears all browsing data in one shot.
  Future<void> clearBrowsingData() async {
    await Future.wait([
      clearHistory(),
      clearSearchHistory(),
      clearTabs(),
      clearDownloads(),
    ]);
  }
}
