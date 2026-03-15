import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/models/wallet_models.dart';

const featuredCodes = {
  'UAH',
  'USD',
  'EUR',
  'PLN',
  'GBP',
  'CHF',
  'CAD',
  'CZK',
  'AUD',
  'JPY',
  'CNY',
  'TRY',
};

String currencyPrefix(String code) {
  return switch (code) {
    'UAH' => 'UA',
    'USD' => 'US',
    'EUR' => 'EU',
    'PLN' => 'PL',
    'GBP' => 'GB',
    'CHF' => 'CH',
    'CAD' => 'CA',
    'JPY' => 'JP',
    'CNY' => 'CN',
    'AUD' => 'AU',
    'NZD' => 'NZ',
    'TRY' => 'TR',
    'CZK' => 'CZ',
    'SEK' => 'SE',
    'NOK' => 'NO',
    'DKK' => 'DK',
    'RON' => 'RO',
    'HUF' => 'HU',
    'INR' => 'IN',
    'KZT' => 'KZ',
    _ => code.substring(0, min(2, code.length)),
  };
}

String formatNumber(double value) {
  final formatter = NumberFormat('#,##0.00', 'en_US');
  return formatter.format(value).replaceAll(',', ' ');
}

String formatTransactionDate(DateTime value) {
  final localValue = value.toLocal();
  final now = DateTime.now();
  final sameDay = now.year == localValue.year && now.month == localValue.month && now.day == localValue.day;
  final time = '${localValue.hour.toString().padLeft(2, '0')}:${localValue.minute.toString().padLeft(2, '0')}';
  if (sameDay) {
    return 'Сьогодні, $time';
  }
  return '${localValue.day.toString().padLeft(2, '0')}.${localValue.month.toString().padLeft(2, '0')}, $time';
}

DateTime parseNbuDate(String? value) {
  if (value == null || value.isEmpty) {
    return DateTime.now();
  }
  final parts = value.split('.');
  if (parts.length != 3) {
    return DateTime.now();
  }
  return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
}

String dateKey(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
}

List<DateTime> recentWorkingDays(int count) {
  final dates = <DateTime>[];
  var cursor = DateTime.now();
  while (dates.length < count) {
    if (cursor.weekday != DateTime.saturday && cursor.weekday != DateTime.sunday) {
      dates.add(DateTime(cursor.year, cursor.month, cursor.day));
    }
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return dates.reversed.toList();
}

List<WalletCategory> defaultWalletCategories() {
  return [
    WalletCategory(
      id: 'preset-food',
      name: 'Покупки',
      kind: TransactionKind.expense,
      iconCodePoint: Icons.shopping_basket_rounded.codePoint,
      colorValue: const Color(0xFF2F67E8).toARGB32(),
    ),
    WalletCategory(
      id: 'preset-transport',
      name: 'Транспорт',
      kind: TransactionKind.expense,
      iconCodePoint: Icons.directions_bus_rounded.codePoint,
      colorValue: const Color(0xFF17B890).toARGB32(),
    ),
    WalletCategory(
      id: 'preset-health',
      name: 'Здоровʼя',
      kind: TransactionKind.expense,
      iconCodePoint: Icons.medication_rounded.codePoint,
      colorValue: const Color(0xFFFF7A59).toARGB32(),
    ),
    WalletCategory(
      id: 'preset-home',
      name: 'Дім',
      kind: TransactionKind.expense,
      iconCodePoint: Icons.home_rounded.codePoint,
      colorValue: const Color(0xFFFFA600).toARGB32(),
    ),
    WalletCategory(
      id: 'preset-salary',
      name: 'Зарплата',
      kind: TransactionKind.income,
      iconCodePoint: Icons.payments_rounded.codePoint,
      colorValue: const Color(0xFF38C172).toARGB32(),
    ),
    WalletCategory(
      id: 'preset-freelance',
      name: 'Фриланс',
      kind: TransactionKind.income,
      iconCodePoint: Icons.work_rounded.codePoint,
      colorValue: const Color(0xFF7A5CFA).toARGB32(),
    ),
  ];
}

class CategoryPreset {
  const CategoryPreset(this.label, this.icon, this.color, this.kind);

  final String label;
  final IconData icon;
  final Color color;
  final TransactionKind kind;
}

List<CategoryPreset> presetsForCategoryKind(TransactionKind kind) {
  return categoryPresets.where((preset) => preset.kind == kind).toList(growable: false);
}

const categoryPresets = [
  CategoryPreset('Покупки', Icons.shopping_basket_rounded, Color(0xFF2F67E8), TransactionKind.expense),
  CategoryPreset('Транспорт', Icons.directions_bus_rounded, Color(0xFF17B890), TransactionKind.expense),
  CategoryPreset('Здоровʼя', Icons.medication_rounded, Color(0xFFFF7A59), TransactionKind.expense),
  CategoryPreset('Дім', Icons.home_rounded, Color(0xFFFFA600), TransactionKind.expense),
  CategoryPreset('Зарплата', Icons.payments_rounded, Color(0xFF38C172), TransactionKind.income),
  CategoryPreset('Фриланс', Icons.work_rounded, Color(0xFF7A5CFA), TransactionKind.income),
];