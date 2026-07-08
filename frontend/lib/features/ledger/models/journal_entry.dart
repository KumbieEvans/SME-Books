import 'journal_line.dart';
import 'package:decimal/decimal.dart';

class JournalEntry {
  final String id;
  final String tenantId;
  final DateTime entryDate;
  final String description;
  final String currencyCode;
  final Decimal exchangeRate;
  final DateTime createdAt;
  final List<JournalLine>? lines;

  JournalEntry({
    required this.id,
    required this.tenantId,
    required this.entryDate,
    required this.description,
    required this.currencyCode,
    required this.exchangeRate,
    required this.createdAt,
    this.lines,
  });

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      entryDate: DateTime.parse(json['entry_date'] as String),
      description: json['description'] as String? ?? '',
      currencyCode: json['currency_code'] as String? ?? 'USD',
      exchangeRate: Decimal.parse(json['exchange_rate']?.toString() ?? '1.0'),
      createdAt: DateTime.parse(json['created_at'] as String),
      lines: json['lines'] != null
          ? (json['lines'] as List).map((e) => JournalLine.fromJson(e)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'entry_date': entryDate.toIso8601String().split('T').first,
      'description': description,
      'currency_code': currencyCode,
      'exchange_rate': exchangeRate.toString(),
      'created_at': createdAt.toIso8601String(),
      if (lines != null) 'lines': lines!.map((e) => e.toJson()).toList(),
    };
  }
}

