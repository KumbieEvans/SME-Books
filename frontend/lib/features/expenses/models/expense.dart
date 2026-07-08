import 'package:decimal/decimal.dart';

class Expense {
  final String id;
  final String tenantId;
  final String vendorName;
  final Decimal amount;
  final String currencyCode;
  final String? receiptUrl;
  final DateTime expenseDate;
  final DateTime createdAt;

  Expense({
    required this.id,
    required this.tenantId,
    required this.vendorName,
    required this.amount,
    required this.currencyCode,
    this.receiptUrl,
    required this.expenseDate,
    required this.createdAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      vendorName: json['vendor_name'] as String,
      amount: Decimal.parse(json['amount'].toString()),
      currencyCode: json['currency_code'] as String,
      receiptUrl: json['receipt_url'] as String?,
      expenseDate: DateTime.parse(json['expense_date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'vendor_name': vendorName,
      'amount': amount.toString(),
      'currency_code': currencyCode,
      if (receiptUrl != null) 'receipt_url': receiptUrl,
      'expense_date': expenseDate.toIso8601String().split('T').first,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
