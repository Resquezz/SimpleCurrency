class RateSnapshot {
  RateSnapshot({required this.rates, required this.names, required this.updatedAt});

  final Map<String, double> rates;
  final Map<String, String> names;
  final DateTime updatedAt;

  String get formattedUpdatedAt {
    final local = updatedAt.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hours = local.hour.toString().padLeft(2, '0');
    final minutes = local.minute.toString().padLeft(2, '0');
    return '$day.$month.${local.year} $hours:$minutes';
  }

  Map<String, dynamic> toJson() => {
        'rates': rates,
        'names': names,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory RateSnapshot.fromJson(Map<String, dynamic> json) {
    return RateSnapshot(
      rates: (json['rates'] as Map<String, dynamic>).map((key, value) => MapEntry(key, (value as num).toDouble())),
      names: (json['names'] as Map<String, dynamic>).map((key, value) => MapEntry(key, value as String)),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

class HistoryPoint {
  HistoryPoint({required this.date, required this.rate});

  final DateTime date;
  final double rate;

  String get label => '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}';

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'rate': rate,
      };

  factory HistoryPoint.fromJson(Map<String, dynamic> json) {
    return HistoryPoint(
      date: DateTime.parse(json['date'] as String),
      rate: (json['rate'] as num).toDouble(),
    );
  }
}

class QuickPair {
  QuickPair({required this.id, required this.from, required this.to});

  final String id;
  final String from;
  final String to;

  Map<String, dynamic> toJson() => {
        'id': id,
        'from': from,
        'to': to,
      };

  factory QuickPair.fromJson(Map<String, dynamic> json) {
    return QuickPair(
      id: json['id'] as String,
      from: json['from'] as String,
      to: json['to'] as String,
    );
  }
}