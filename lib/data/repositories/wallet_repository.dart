import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/wallet_models.dart';
import '../../firebase_runtime.dart';

class WalletRepository {
  WalletRepository(this._services);

  final FirebaseAppServices _services;

  static const _localCacheUserIdKey = 'local_cache_user_id';
  static const categoriesKey = 'wallet_categories';
  static const transactionsKey = 'wallet_transactions';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<List<WalletCategory>> loadLocalCategories(String userId) async {
    final prefs = await _prefs;
    final scopedKey = _scopedKey(categoriesKey, userId);
    final raw = prefs.getString(scopedKey);
    if (raw != null) {
      return _decodeCategories(raw);
    }
    final legacyRaw = prefs.getString(categoriesKey);
    if (legacyRaw == null || !_canUseLegacyCache(prefs, userId)) {
      return [];
    }
    await prefs.setString(scopedKey, legacyRaw);
    return _decodeCategories(legacyRaw);
  }

  Future<void> saveLocalCategories(String userId, List<WalletCategory> categories) async {
    final prefs = await _prefs;
    await prefs.setString(_localCacheUserIdKey, userId);
    await prefs.setString(_scopedKey(categoriesKey, userId), jsonEncode(categories.map((item) => item.toJson()).toList()));
  }

  Future<List<WalletTransaction>> loadLocalTransactions(String userId) async {
    final prefs = await _prefs;
    final scopedKey = _scopedKey(transactionsKey, userId);
    final raw = prefs.getString(scopedKey);
    if (raw != null) {
      return _decodeTransactions(raw);
    }
    final legacyRaw = prefs.getString(transactionsKey);
    if (legacyRaw == null || !_canUseLegacyCache(prefs, userId)) {
      return [];
    }
    await prefs.setString(scopedKey, legacyRaw);
    return _decodeTransactions(legacyRaw);
  }

  Future<void> saveLocalTransactions(String userId, List<WalletTransaction> transactions) async {
    final prefs = await _prefs;
    await prefs.setString(_localCacheUserIdKey, userId);
    await prefs.setString(_scopedKey(transactionsKey, userId), jsonEncode(transactions.map((item) => item.toJson()).toList()));
  }

  bool _canUseLegacyCache(SharedPreferences prefs, String userId) {
    return prefs.getString(_localCacheUserIdKey) == userId;
  }

  String _scopedKey(String baseKey, String userId) => '$baseKey::$userId';

  List<WalletCategory> _decodeCategories(String raw) {
    return (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>().map(WalletCategory.fromJson).toList();
  }

  List<WalletTransaction> _decodeTransactions(String raw) {
    return (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>().map(WalletTransaction.fromJson).toList();
  }

  Future<List<WalletCategory>> fetchCloudCategories(String userId) async {
    final data = await _services.fetchCategories(userId);
    return data.map(WalletCategory.fromJson).toList();
  }

  Future<List<WalletTransaction>> fetchCloudTransactions(String userId) async {
    final data = await _services.fetchTransactions(userId);
    return data.map(WalletTransaction.fromJson).toList();
  }

  Future<void> upsertCategory(String userId, WalletCategory category) {
    return _services.upsertCategory(userId, category.toJson());
  }

  Future<void> deleteCategory(String userId, String categoryId) {
    return _services.deleteCategory(userId, categoryId);
  }

  Future<void> upsertTransaction(String userId, WalletTransaction transaction) {
    return _services.upsertTransaction(userId, transaction.toJson());
  }

  Future<void> deleteTransaction(String userId, String transactionId) {
    return _services.deleteTransaction(userId, transactionId);
  }
}