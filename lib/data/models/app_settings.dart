import 'package:flutter/material.dart';

import 'rate_models.dart';

class AppSettings {
  AppSettings({
    required this.baseCurrency,
    required this.convertFrom,
    required this.convertTo,
    required this.converterAmount,
    required this.analyticsBase,
    required this.analyticsTarget,
    required this.analyticsRangeDays,
    required this.themeMode,
    required this.favoriteCurrencies,
    required this.quickPairs,
  });

  final String baseCurrency;
  final String convertFrom;
  final String convertTo;
  final double converterAmount;
  final String analyticsBase;
  final String analyticsTarget;
  final int analyticsRangeDays;
  final ThemeMode themeMode;
  final List<String> favoriteCurrencies;
  final List<QuickPair> quickPairs;

  factory AppSettings.defaults() {
    return AppSettings(
      baseCurrency: 'EUR',
      convertFrom: 'USD',
      convertTo: 'UAH',
      converterAmount: 100,
      analyticsBase: 'USD',
      analyticsTarget: 'UAH',
      analyticsRangeDays: 30,
      themeMode: ThemeMode.system,
      favoriteCurrencies: const ['USD', 'EUR', 'PLN', 'GBP', 'CHF', 'UAH'],
      quickPairs: [
        QuickPair(id: 'usd-eur', from: 'USD', to: 'EUR'),
        QuickPair(id: 'eur-pln', from: 'EUR', to: 'PLN'),
        QuickPair(id: 'usd-uah', from: 'USD', to: 'UAH'),
      ],
    );
  }

  AppSettings copyWith({
    String? baseCurrency,
    String? convertFrom,
    String? convertTo,
    double? converterAmount,
    String? analyticsBase,
    String? analyticsTarget,
    int? analyticsRangeDays,
    ThemeMode? themeMode,
    List<String>? favoriteCurrencies,
    List<QuickPair>? quickPairs,
  }) {
    return AppSettings(
      baseCurrency: baseCurrency ?? this.baseCurrency,
      convertFrom: convertFrom ?? this.convertFrom,
      convertTo: convertTo ?? this.convertTo,
      converterAmount: converterAmount ?? this.converterAmount,
      analyticsBase: analyticsBase ?? this.analyticsBase,
      analyticsTarget: analyticsTarget ?? this.analyticsTarget,
      analyticsRangeDays: analyticsRangeDays ?? this.analyticsRangeDays,
      themeMode: themeMode ?? this.themeMode,
      favoriteCurrencies: favoriteCurrencies ?? this.favoriteCurrencies,
      quickPairs: quickPairs ?? this.quickPairs,
    );
  }

  Map<String, dynamic> toJson() => {
        'baseCurrency': baseCurrency,
        'convertFrom': convertFrom,
        'convertTo': convertTo,
        'converterAmount': converterAmount,
        'analyticsBase': analyticsBase,
        'analyticsTarget': analyticsTarget,
        'analyticsRangeDays': analyticsRangeDays,
        'themeMode': themeMode.name,
        'favorites': favoriteCurrencies,
        'quickPairs': quickPairs.map((item) => item.toJson()).toList(),
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      baseCurrency: json['baseCurrency'] as String? ?? 'EUR',
      convertFrom: json['convertFrom'] as String? ?? 'USD',
      convertTo: json['convertTo'] as String? ?? 'UAH',
      converterAmount: (json['converterAmount'] as num?)?.toDouble() ?? 100,
      analyticsBase: json['analyticsBase'] as String? ?? 'USD',
      analyticsTarget: json['analyticsTarget'] as String? ?? 'UAH',
      analyticsRangeDays: (json['analyticsRangeDays'] as num?)?.toInt() ?? 30,
      themeMode: ThemeMode.values.firstWhere(
        (mode) => mode.name == json['themeMode'],
        orElse: () => ThemeMode.system,
      ),
      favoriteCurrencies: ((json['favorites'] as List<dynamic>?) ?? const []).cast<String>(),
      quickPairs: (((json['quickPairs'] as List<dynamic>?) ?? const [])
              .cast<Map<String, dynamic>>())
          .map(QuickPair.fromJson)
          .toList(),
    );
  }
}

class AuthenticatedUser {
  const AuthenticatedUser({required this.id, required this.email});

  final String id;
  final String email;
}