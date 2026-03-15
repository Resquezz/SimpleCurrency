import 'package:flutter/material.dart';

enum TransactionKind { expense, income }

class WalletCategory {
  WalletCategory({
    required this.id,
    required this.name,
    required this.kind,
    required this.iconCodePoint,
    required this.colorValue,
  });

  final String id;
  final String name;
  final TransactionKind kind;
  final int iconCodePoint;
  final int colorValue;

  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');
  Color get color => Color(colorValue);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'kind': kind.name,
        'iconCodePoint': iconCodePoint,
        'colorValue': colorValue,
      };

  factory WalletCategory.fromJson(Map<String, dynamic> json) {
    return WalletCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      kind: TransactionKind.values.firstWhere((kind) => kind.name == json['kind']),
      iconCodePoint: json['iconCodePoint'] as int,
      colorValue: json['colorValue'] as int,
    );
  }
}

class WalletTransaction {
  WalletTransaction({
    required this.id,
    required this.categoryId,
    required this.amount,
    required this.kind,
    required this.createdAt,
  });

  final String id;
  final String categoryId;
  final double amount;
  final TransactionKind kind;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'categoryId': categoryId,
        'amount': amount,
        'kind': kind.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'] as String,
      categoryId: json['categoryId'] as String,
      amount: (json['amount'] as num).toDouble(),
      kind: TransactionKind.values.firstWhere((kind) => kind.name == json['kind']),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class ExpenseSlice {
  ExpenseSlice({required this.category, required this.amount});

  final WalletCategory category;
  final double amount;
}