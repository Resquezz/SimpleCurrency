import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/app_settings.dart';
import '../../data/models/rate_models.dart';
import '../../firebase_runtime.dart';

class PreferencesRepository {
  PreferencesRepository(this._services);

  final FirebaseAppServices _services;

  static const _localCacheUserIdKey = 'local_cache_user_id';
  static const snapshotKey = 'snapshot';
  static const settingsKey = 'settings';
  static const historyCacheKey = 'history_cache';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<RateSnapshot?> loadSnapshot() async {
    final prefs = await _prefs;
    final raw = prefs.getString(snapshotKey);
    if (raw == null) {
      return null;
    }
    return RateSnapshot.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveSnapshot(RateSnapshot? snapshot) async {
    final prefs = await _prefs;
    if (snapshot == null) {
      await prefs.remove(snapshotKey);
      return;
    }
    await prefs.setString(snapshotKey, jsonEncode(snapshot.toJson()));
  }

  Future<AppSettings> loadSettings(String userId) async {
    final prefs = await _prefs;
    final scopedKey = _scopedKey(settingsKey, userId);
    final raw = prefs.getString(scopedKey);
    if (raw != null) {
      return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    }

    final legacyRaw = prefs.getString(settingsKey);
    if (legacyRaw != null && _canUseLegacyCache(prefs, userId)) {
      await prefs.setString(scopedKey, legacyRaw);
      return AppSettings.fromJson(jsonDecode(legacyRaw) as Map<String, dynamic>);
    }

    if (raw == null) {
      return AppSettings.defaults();
    }
    return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveSettings(String userId, AppSettings settings) async {
    final prefs = await _prefs;
    await prefs.setString(_localCacheUserIdKey, userId);
    await prefs.setString(_scopedKey(settingsKey, userId), jsonEncode(settings.toJson()));
  }

  Future<Map<String, List<HistoryPoint>>> loadHistoryCache(String userId) async {
    final prefs = await _prefs;
    final scopedKey = _scopedKey(historyCacheKey, userId);
    final raw = prefs.getString(scopedKey);
    if (raw == null) {
      final legacyRaw = prefs.getString(historyCacheKey);
      if (legacyRaw == null || !_canUseLegacyCache(prefs, userId)) {
        return {};
      }
      await prefs.setString(scopedKey, legacyRaw);
      return _decodeHistoryCache(legacyRaw);
    }
    return _decodeHistoryCache(raw);
  }

  Future<void> saveHistoryCache(String userId, Map<String, List<HistoryPoint>> cache) async {
    final prefs = await _prefs;
    await prefs.setString(_localCacheUserIdKey, userId);
    await prefs.setString(
      _scopedKey(historyCacheKey, userId),
      jsonEncode(cache.map((key, value) => MapEntry(key, value.map((item) => item.toJson()).toList()))),
    );
  }

  bool _canUseLegacyCache(SharedPreferences prefs, String userId) {
    return prefs.getString(_localCacheUserIdKey) == userId;
  }

  String _scopedKey(String baseKey, String userId) => '$baseKey::$userId';

  Map<String, List<HistoryPoint>> _decodeHistoryCache(String raw) {
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map(
      (key, value) => MapEntry(
        key,
        (value as List<dynamic>).cast<Map<String, dynamic>>().map(HistoryPoint.fromJson).toList(),
      ),
    );
  }

  Future<Map<String, dynamic>?> fetchCloudSettings(String userId) {
    return _services.fetchPreferences(userId);
  }

  Future<void> saveCloudSettings(String userId, AppSettings settings) {
    return _services.savePreferences(userId, settings.toJson());
  }
}