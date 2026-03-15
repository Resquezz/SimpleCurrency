import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/app_utils.dart';
import '../models/rate_models.dart';

abstract class CurrencyRepository {
  Future<RateSnapshot> fetchLatestRates();

  Future<List<HistoryPoint>> fetchPairHistory({
    required String from,
    required String to,
    required int days,
  });
}

class NbuCurrencyRepository implements CurrencyRepository {
  NbuCurrencyRepository({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;
  final Map<String, Map<String, double>> _dailyRatesCache = {};
  final Map<String, Map<String, String>> _dailyNamesCache = {};

  static final _validCurrencyCode = RegExp(r'^[A-Z]{3}$');

  static const _requestHeaders = {
    'Accept': 'application/json',
    'User-Agent': 'SimpleCurrency/1.0',
  };

  @override
  Future<RateSnapshot> fetchLatestRates() async {
    final fetchedAt = DateTime.now();
    final response = await _getWithRetry(Uri.parse('https://bank.gov.ua/NBUStatService/v1/statdirectory/exchange?json'));
    if (response.statusCode != 200) {
      throw Exception('Помилка відповіді API НБУ: ${response.statusCode}');
    }

    final List<dynamic> payload = jsonDecode(response.body) as List<dynamic>;
    final rates = <String, double>{'UAH': 1.0};
    final names = <String, String>{'UAH': 'Українська гривня'};

    for (final item in payload.cast<Map<String, dynamic>>()) {
      final code = item['cc'] as String?;
      final rate = (item['rate'] as num?)?.toDouble();
      final name = item['txt'] as String?;
      if (code == null || rate == null || !_validCurrencyCode.hasMatch(code)) {
        continue;
      }
      rates[code] = rate;
      names[code] = name ?? code;
    }

    _dailyRatesCache[dateKey(fetchedAt)] = rates;
    _dailyNamesCache[dateKey(fetchedAt)] = names;

    return RateSnapshot(rates: rates, names: names, updatedAt: fetchedAt);
  }

  @override
  Future<List<HistoryPoint>> fetchPairHistory({required String from, required String to, required int days}) async {
    final dates = recentWorkingDays(days);
    final results = await Future.wait(dates.map(_fetchRatesForDate));
    return List<HistoryPoint>.generate(results.length, (index) {
      final rates = results[index].rates;
      final fromRate = rates[from] ?? 1.0;
      final toRate = rates[to] ?? 1.0;
      return HistoryPoint(date: dates[index], rate: fromRate / toRate);
    });
  }

  Future<_DailyNbuRates> _fetchRatesForDate(DateTime date) async {
    final key = dateKey(date);
    if (_dailyRatesCache.containsKey(key)) {
      return _DailyNbuRates(rates: _dailyRatesCache[key]!, names: _dailyNamesCache[key] ?? {});
    }

    final response = await _getWithRetry(Uri.parse('https://bank.gov.ua/NBUStatService/v1/statdirectory/exchange?date=$key&json'));
    if (response.statusCode != 200) {
      throw Exception('Помилка історичних даних НБУ: ${response.statusCode}');
    }

    final List<dynamic> payload = jsonDecode(response.body) as List<dynamic>;
    final rates = <String, double>{'UAH': 1.0};
    final names = <String, String>{'UAH': 'Українська гривня'};
    for (final item in payload.cast<Map<String, dynamic>>()) {
      final code = item['cc'] as String?;
      final rate = (item['rate'] as num?)?.toDouble();
      final name = item['txt'] as String?;
      if (code == null || rate == null || !_validCurrencyCode.hasMatch(code)) {
        continue;
      }
      rates[code] = rate;
      names[code] = name ?? code;
    }

    _dailyRatesCache[key] = rates;
    _dailyNamesCache[key] = names;
    return _DailyNbuRates(rates: rates, names: names);
  }

  Future<http.Response> _getWithRetry(Uri uri) async {
    try {
      return await _httpClient.get(uri, headers: _requestHeaders).timeout(const Duration(seconds: 12));
    } catch (_) {
      return _httpClient.get(uri, headers: _requestHeaders).timeout(const Duration(seconds: 12));
    }
  }
}

class _DailyNbuRates {
  _DailyNbuRates({required this.rates, required this.names});

  final Map<String, double> rates;
  final Map<String, String> names;
}