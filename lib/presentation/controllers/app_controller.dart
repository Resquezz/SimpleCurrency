import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_utils.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/rate_models.dart';
import '../../data/models/wallet_models.dart';
import '../../data/repositories/analytics_repository.dart';
import '../../data/repositories/currency_repository.dart';
import '../../data/repositories/preferences_repository.dart';
import '../../data/repositories/wallet_repository.dart';
import '../../firebase_runtime.dart';

class AppController extends ChangeNotifier {
  AppController({
    required this.user,
    required CurrencyRepository currencyRepository,
    required PreferencesRepository preferencesRepository,
    required WalletRepository walletRepository,
    required AnalyticsRepository analyticsRepository,
    required FirebaseAppServices firebaseServices,
  })  : _currencyRepository = currencyRepository,
        _preferencesRepository = preferencesRepository,
        _walletRepository = walletRepository,
        _analyticsRepository = analyticsRepository,
        _firebaseServices = firebaseServices;

  final AuthenticatedUser user;
  final CurrencyRepository _currencyRepository;
  final PreferencesRepository _preferencesRepository;
  final WalletRepository _walletRepository;
  final AnalyticsRepository _analyticsRepository;
  final FirebaseAppServices _firebaseServices;

  static const _demoCategoryIds = {'food', 'transport', 'home', 'salary', 'freelance'};
  static const _demoTransactionIds = {'tx-salary', 'tx-food', 'tx-transport', 'tx-home'};
  static const _demoCategoryNames = {'Продукти', 'Транспорт', 'Житло', 'Зарплата', 'Фриланс'};
  static const _incomeCategoryNames = {'Зарплата', 'Дохід', 'Фриланс', 'Робота'};
  static final _demoExpenseAmounts = {2052.0, 855.0, 513.0};
  static final _demoIncomeAmounts = {20000.0};

  bool isLoading = true;
  bool isRefreshing = false;
  bool isOffline = true;
  bool isHistoryLoading = false;

  RateSnapshot? snapshot;
  Map<String, List<HistoryPoint>> historyCache = {};
  AppSettings _settings = AppSettings.defaults();
  List<HistoryPoint> analyticsHistory = [];
  late List<WalletCategory> categories;
  late List<WalletTransaction> transactions;
  TransactionKind selectedTransactionKind = TransactionKind.expense;
  String? selectedCategoryId;

  bool get isCloudSyncEnabled => _firebaseServices.isEnabled;
  bool get hasFirebaseError => _firebaseServices.initializationError != null;
  ThemeMode get themeMode => _settings.themeMode;
  String get baseCurrency => _settings.baseCurrency;
  String get convertFrom => _settings.convertFrom;
  String get convertTo => _settings.convertTo;
  double get converterAmount => _settings.converterAmount;
  String get analyticsBase => _settings.analyticsBase;
  String get analyticsTarget => _settings.analyticsTarget;
  int get analyticsRangeDays => _settings.analyticsRangeDays;
  List<String> get favoriteCurrencies => _settings.favoriteCurrencies;
  List<QuickPair> get quickPairs => _settings.quickPairs;
  double get convertedAmount => rateBetween(convertFrom, convertTo) * converterAmount;
  WalletCategory? get selectedCategory => selectedCategoryId == null ? null : categoryById(selectedCategoryId!);
  Iterable<WalletTransaction> get recentTransactions => transactions.take(6);

  double get totalBalance {
    return transactions.fold<double>(0, (sum, item) {
      return sum + (item.kind == TransactionKind.income ? item.amount : -item.amount);
    });
  }

  List<ExpenseSlice> get expenseBreakdown {
    final now = DateTime.now();
    final totals = <String, double>{};
    for (final transaction in transactions.where((item) =>
        item.kind == TransactionKind.expense &&
        item.createdAt.toLocal().year == now.year &&
        item.createdAt.toLocal().month == now.month)) {
      totals.update(transaction.categoryId, (value) => value + transaction.amount, ifAbsent: () => transaction.amount);
    }

    return totals.entries
        .map((entry) {
          final category = categoryById(entry.key);
          if (category == null) {
            return null;
          }
          return ExpenseSlice(category: category, amount: entry.value);
        })
        .whereType<ExpenseSlice>()
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
  }

  Future<void> initialize() async {
    snapshot = await _preferencesRepository.loadSnapshot();
    _settings = await _preferencesRepository.loadSettings(user.id);
    historyCache = await _preferencesRepository.loadHistoryCache(user.id);
    analyticsHistory = historyCache['${analyticsBase}_${analyticsTarget}_$analyticsRangeDays'] ?? [];
    categories = await _walletRepository.loadLocalCategories(user.id);
    transactions = await _walletRepository.loadLocalTransactions(user.id);
    await _removeSeededWalletData(notify: false);
    if (categories.isEmpty) {
      categories = defaultWalletCategories();
      await _walletRepository.saveLocalCategories(user.id, categories);
    }
    await _migrateCategoryKinds();
    isOffline = false;
    isLoading = snapshot == null;
    isHistoryLoading = analyticsHistory.isEmpty;
    _ensureSelectedCategory();
    notifyListeners();

    unawaited(_bootstrapRemoteState());
  }

  Future<void> _bootstrapRemoteState() async {
    unawaited(refreshRates(silent: snapshot != null));
    unawaited(loadAnalyticsHistory());

    await _hydrateCloudState();
    await _migrateCategoryKinds();
    if (categories.isEmpty) {
      categories = defaultWalletCategories();
      await _walletRepository.saveLocalCategories(user.id, categories);
      notifyListeners();
    }
  }

  Future<void> refreshRates({bool silent = false}) async {
    if (silent) {
      isRefreshing = true;
    } else {
      isLoading = true;
    }
    notifyListeners();

    try {
      final freshSnapshot = await _currencyRepository.fetchLatestRates();
      snapshot = freshSnapshot;
      isOffline = false;
      _sanitizeSelections();
      await _preferencesRepository.saveSnapshot(freshSnapshot);
      try {
        await _analyticsRepository.logEvent('rates_refresh', {'source': 'nbu', 'offline': false});
      } catch (_) {}
    } catch (_) {
      isOffline = true;
      snapshot ??= await _preferencesRepository.loadSnapshot();
      if (snapshot != null) {
        _sanitizeSelections();
      }
    } finally {
      isLoading = false;
      isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> loadAnalyticsHistory() async {
    final cacheKey = '${analyticsBase}_${analyticsTarget}_$analyticsRangeDays';
    isHistoryLoading = true;
    notifyListeners();
    try {
      analyticsHistory = await _currencyRepository.fetchPairHistory(from: analyticsBase, to: analyticsTarget, days: analyticsRangeDays);
      historyCache[cacheKey] = analyticsHistory;
      await _preferencesRepository.saveHistoryCache(user.id, historyCache);
    } catch (_) {
      analyticsHistory = historyCache[cacheKey] ?? analyticsHistory;
    } finally {
      isHistoryLoading = false;
      notifyListeners();
    }
  }

  List<String> get availableCodes {
    final codes = (snapshot?.rates.keys.toList() ?? ['UAH', 'USD', 'EUR', 'PLN'])
      ..sort((a, b) {
        final aFeatured = featuredCodes.contains(a);
        final bFeatured = featuredCodes.contains(b);
        if (aFeatured && !bFeatured) {
          return -1;
        }
        if (!aFeatured && bFeatured) {
          return 1;
        }
        return a.compareTo(b);
      });
    return codes;
  }

  List<WalletCategory> categoriesFor(TransactionKind kind) {
    return categories.where((category) => category.kind == kind).toList();
  }

  WalletCategory? categoryById(String id) {
    for (final category in categories) {
      if (category.id == id) {
        return category;
      }
    }
    return null;
  }

  String currencyName(String code) => snapshot?.names[code] ?? code;

  String currencyLabel(String code) => '${currencyPrefix(code)} $code';

  String currencyOptionLabel(String code) => '${currencyPrefix(code)} $code';

  String formatRate(double value) {
    if (value == 0) {
      return '0.000';
    }
    final decimals = value >= 100 ? 2 : value >= 1 ? 3 : 4;
    return value.toStringAsFixed(decimals);
  }

  String formatAmount(double value) => formatNumber(value);

  double rateBetween(String from, String to) {
    final rates = snapshot?.rates;
    if (rates == null) {
      return 0;
    }
    final fromRate = rates[from] ?? 1.0;
    final toRate = rates[to] ?? 1.0;
    return fromRate / toRate;
  }

  void setBaseCurrency(String code) {
    _settings = _settings.copyWith(baseCurrency: code);
    unawaited(_persistSettings('base_currency_changed', {'currency': code}));
    notifyListeners();
  }

  void setConvertFrom(String code) {
    var nextTo = convertTo;
    if (code == nextTo) {
      nextTo = 'UAH';
    }
    _settings = _settings.copyWith(convertFrom: code, convertTo: nextTo);
    unawaited(_persistSettings('converter_pair_changed', {'from': code, 'to': nextTo}));
    notifyListeners();
  }

  void setConvertTo(String code) {
    var nextFrom = convertFrom;
    if (nextFrom == code) {
      nextFrom = 'USD';
    }
    _settings = _settings.copyWith(convertFrom: nextFrom, convertTo: code);
    unawaited(_persistSettings('converter_pair_changed', {'from': nextFrom, 'to': code}));
    notifyListeners();
  }

  void setConverterAmount(String raw) {
    final amount = double.tryParse(raw.replaceAll(',', '.'));
    if (amount == null) {
      return;
    }
    _settings = _settings.copyWith(converterAmount: amount);
    notifyListeners();
  }

  void swapCurrencies() {
    final oldFrom = convertFrom;
    final oldTo = convertTo;
    _settings = _settings.copyWith(convertFrom: oldTo, convertTo: oldFrom);
    unawaited(_persistSettings('converter_swapped', {'from': oldTo, 'to': oldFrom}));
    notifyListeners();
  }

  void setConversionPair(String from, String to) {
    _settings = _settings.copyWith(convertFrom: from, convertTo: to);
    unawaited(_persistSettings('quick_pair_applied', {'from': from, 'to': to}));
    notifyListeners();
  }

  Future<void> setAnalyticsBase(String code) async {
    final nextTarget = code == analyticsTarget ? 'UAH' : analyticsTarget;
    _settings = _settings.copyWith(analyticsBase: code, analyticsTarget: nextTarget);
    await _persistSettings('analytics_pair_changed', {'base': code, 'target': nextTarget});
    notifyListeners();
    await loadAnalyticsHistory();
  }

  Future<void> setAnalyticsTarget(String code) async {
    final nextBase = code == analyticsBase ? 'USD' : analyticsBase;
    _settings = _settings.copyWith(analyticsBase: nextBase, analyticsTarget: code);
    await _persistSettings('analytics_pair_changed', {'base': nextBase, 'target': code});
    notifyListeners();
    await loadAnalyticsHistory();
  }

  Future<void> setAnalyticsRangeDays(int days) async {
    if (days == analyticsRangeDays) {
      return;
    }
    _settings = _settings.copyWith(analyticsRangeDays: days);
    await _persistSettings('analytics_range_changed', {'days': days});
    notifyListeners();
    await loadAnalyticsHistory();
  }

  void toggleFavoriteCurrency(String code) {
    final favorites = [...favoriteCurrencies];
    if (favorites.contains(code)) {
      favorites.remove(code);
    } else {
      favorites.add(code);
    }
    _settings = _settings.copyWith(favoriteCurrencies: favorites);
    unawaited(_persistSettings('favorite_toggled', {'currency': code, 'selected': favorites.contains(code)}));
    notifyListeners();
  }

  void addQuickPair(QuickPair pair) {
    if (quickPairs.any((item) => item.from == pair.from && item.to == pair.to)) {
      return;
    }
    _settings = _settings.copyWith(quickPairs: [...quickPairs, pair]);
    unawaited(_persistSettings('quick_pair_added', {'from': pair.from, 'to': pair.to}));
    notifyListeners();
  }

  void removeQuickPair(String id) {
    _settings = _settings.copyWith(quickPairs: quickPairs.where((pair) => pair.id != id).toList());
    unawaited(_persistSettings('quick_pair_removed'));
    notifyListeners();
  }

  void setTransactionKind(TransactionKind kind) {
    selectedTransactionKind = kind;
    _ensureSelectedCategory();
    notifyListeners();
  }

  void selectCategory(String id) {
    selectedCategoryId = id;
    notifyListeners();
  }

  Future<void> addCategory(WalletCategory category) async {
    categories = [category, ...categories];
    selectedCategoryId = category.id;
    await _walletRepository.saveLocalCategories(user.id, categories);
    await _walletRepository.upsertCategory(user.id, category);
    await _analyticsRepository.logEvent('wallet_category_saved', {'kind': category.kind.name});
    notifyListeners();
  }

  Future<void> updateCategory(WalletCategory category) async {
    final index = categories.indexWhere((item) => item.id == category.id);
    if (index == -1) {
      return;
    }
    categories[index] = category;
    await _walletRepository.saveLocalCategories(user.id, categories);
    await _walletRepository.upsertCategory(user.id, category);
    await _analyticsRepository.logEvent('wallet_category_updated', {'kind': category.kind.name});
    notifyListeners();
  }

  Future<String?> addTransaction(String rawAmount) async {
    final amount = double.tryParse(rawAmount.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      return 'Вкажіть коректну суму.';
    }
    if (selectedCategoryId == null) {
      return 'Оберіть категорію.';
    }

    final transaction = WalletTransaction(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      categoryId: selectedCategoryId!,
      amount: amount,
      kind: selectedTransactionKind,
      createdAt: DateTime.now(),
    );
    transactions = [transaction, ...transactions];
    await _walletRepository.saveLocalTransactions(user.id, transactions);
    final category = categoryById(transaction.categoryId);
    if (category != null) {
      await _walletRepository.upsertCategory(user.id, category);
    }
    await _walletRepository.upsertTransaction(user.id, transaction);
    await _analyticsRepository.logEvent('wallet_transaction_saved', {'kind': selectedTransactionKind.name, 'amount': amount});
    notifyListeners();
    return null;
  }

  void setThemeMode(ThemeMode mode) {
    _settings = _settings.copyWith(themeMode: mode);
    unawaited(_persistSettings('theme_mode_changed', {'mode': mode.name}));
    notifyListeners();
  }

  Future<void> logScreen(String screenName) {
    return _analyticsRepository.logScreen(screenName);
  }

  Future<void> _hydrateCloudState() async {
    if (!_firebaseServices.isEnabled) {
      return;
    }
    try {
      final remoteSettings = await _preferencesRepository.fetchCloudSettings(user.id);
      if (remoteSettings != null && remoteSettings.isNotEmpty) {
        _settings = AppSettings.fromJson(remoteSettings);
      } else {
        await _preferencesRepository.saveCloudSettings(user.id, _settings);
      }

      final remoteCategories = await _walletRepository.fetchCloudCategories(user.id);
      if (remoteCategories.isNotEmpty) {
        categories = remoteCategories;
      }

      final remoteTransactions = await _walletRepository.fetchCloudTransactions(user.id);
      if (remoteTransactions.isNotEmpty) {
        transactions = remoteTransactions..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }

      _ensureSelectedCategory();
      await _preferencesRepository.saveSettings(user.id, _settings);
      await _walletRepository.saveLocalCategories(user.id, categories);
      await _walletRepository.saveLocalTransactions(user.id, transactions);
      await _analyticsRepository.logEvent('firebase_bootstrap_completed');
      notifyListeners();
    } catch (_) {
      await _analyticsRepository.logEvent('firebase_bootstrap_failed');
    }
  }

  Future<void> _persistSettings(String eventName, [Map<String, Object?> parameters = const {}]) async {
    await _preferencesRepository.saveSettings(user.id, _settings);
    await _preferencesRepository.saveCloudSettings(user.id, _settings);
    await _analyticsRepository.logEvent(eventName, parameters);
  }

  Future<void> _migrateCategoryKinds() async {
    var changed = false;
    final migrated = categories.map((category) {
      if (category.kind == TransactionKind.expense && _incomeCategoryNames.contains(category.name)) {
        changed = true;
        return WalletCategory(
          id: category.id,
          name: category.name,
          kind: TransactionKind.income,
          iconCodePoint: category.iconCodePoint,
          colorValue: category.colorValue,
        );
      }
      return category;
    }).toList(growable: false);

    if (!changed) {
      return;
    }

    categories = migrated;
  await _walletRepository.saveLocalCategories(user.id, categories);
    if (_firebaseServices.isEnabled) {
      for (final category in categories.where((item) => _incomeCategoryNames.contains(item.name))) {
        await _walletRepository.upsertCategory(user.id, category);
      }
    }
  }

  Future<void> _removeSeededWalletData({bool notify = true}) async {
    final seededCategoryIds = categories
      .where((category) => _isDemoCategory(category))
      .map((category) => category.id)
      .toList(growable: false);
    final seededTransactionIds = transactions
      .where((transaction) => _isDemoTransaction(transaction))
      .map((transaction) => transaction.id)
      .toList(growable: false);

    if (seededCategoryIds.isEmpty && seededTransactionIds.isEmpty) {
      return;
    }

    categories = categories.where((category) => !_isDemoCategory(category)).toList();
    transactions = transactions.where((transaction) => !_isDemoTransaction(transaction)).toList();
    _ensureSelectedCategory();

    await _walletRepository.saveLocalCategories(user.id, categories);
    await _walletRepository.saveLocalTransactions(user.id, transactions);

    if (_firebaseServices.isEnabled) {
      for (final categoryId in seededCategoryIds) {
        await _walletRepository.deleteCategory(user.id, categoryId);
      }
      for (final transactionId in seededTransactionIds) {
        await _walletRepository.deleteTransaction(user.id, transactionId);
      }
    }

    if (notify) {
      notifyListeners();
    }
  }

  bool _isDemoCategory(WalletCategory category) {
    return _demoCategoryIds.contains(category.id) || _demoCategoryNames.contains(category.name);
  }

  bool _isDemoTransaction(WalletTransaction transaction) {
    final amount = transaction.amount;
    final looksLikeDemoAmount = transaction.kind == TransactionKind.income
        ? _demoIncomeAmounts.contains(amount)
        : _demoExpenseAmounts.contains(amount);

    return _demoTransactionIds.contains(transaction.id) ||
        _demoCategoryIds.contains(transaction.categoryId) ||
        looksLikeDemoAmount;
  }

  void _sanitizeSelections() {
    final codes = availableCodes;
    var next = _settings;
    if (!codes.contains(next.baseCurrency)) {
      next = next.copyWith(baseCurrency: 'EUR');
    }
    if (!codes.contains(next.convertFrom)) {
      next = next.copyWith(convertFrom: 'USD');
    }
    if (!codes.contains(next.convertTo)) {
      next = next.copyWith(convertTo: 'UAH');
    }
    if (!codes.contains(next.analyticsBase)) {
      next = next.copyWith(analyticsBase: 'USD');
    }
    if (!codes.contains(next.analyticsTarget)) {
      next = next.copyWith(analyticsTarget: 'UAH');
    }
    _settings = next;
  }

  void _ensureSelectedCategory() {
    final current = categoriesFor(selectedTransactionKind);
    if (current.isEmpty) {
      selectedCategoryId = null;
      return;
    }
    if (selectedCategoryId == null || !current.any((category) => category.id == selectedCategoryId)) {
      selectedCategoryId = current.first.id;
    }
  }
}