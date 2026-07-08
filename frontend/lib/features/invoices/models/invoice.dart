import 'package:decimal/decimal.dart';

class InvoiceLine {
  final String id;
  final String invoiceId;
  final String description;
  final Decimal quantity;
  final Decimal unitPrice;
  final Decimal lineTotal;
  final String? taxId;
  final Decimal taxAmount;

  InvoiceLine({
    required this.id,
    required this.invoiceId,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    this.taxId,
    required this.taxAmount,
  });

  factory InvoiceLine.fromJson(Map<String, dynamic> json) {
    return InvoiceLine(
      id: json['id'] as String,
      invoiceId: json['invoice_id'] as String,
      description: json['description'] as String,
      quantity: Decimal.parse(json['quantity'].toString()),
      unitPrice: Decimal.parse(json['unit_price'].toString()),
      lineTotal: Decimal.parse(json['line_total'].toString()),
      taxId: json['tax_id'] as String?,
      taxAmount: Decimal.parse((json['tax_amount'] ?? '0').toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoice_id': invoiceId,
      'description': description,
      'quantity': quantity.toString(),
      'unit_price': unitPrice.toString(),
      'line_total': lineTotal.toString(),
      'tax_id': taxId,
      'tax_amount': taxAmount.toString(),
    };
  }
}

class Invoice {
  final String id;
  final String tenantId;
  final String invoiceNumber;
  final String clientName;
  final String status;
  final DateTime issueDate;
  final DateTime? dueDate;
  final Decimal subtotalAmount;
  final Decimal taxAmount;
  final Decimal totalAmount;
  final String currencyCode;
  final String? terms;
  final DateTime createdAt;
  final List<InvoiceLine>? lines;

  Invoice({
    required this.id,
    required this.tenantId,
    required this.invoiceNumber,
    required this.clientName,
    required this.status,
    required this.issueDate,
    this.dueDate,
    required this.subtotalAmount,
    required this.taxAmount,
    required this.totalAmount,
    required this.currencyCode,
    this.terms,
    required this.createdAt,
    this.lines,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      invoiceNumber: json['invoice_number'] as String,
      clientName: json['client_name'] as String,
      status: json['status'] as String,
      issueDate: DateTime.parse(json['issue_date'] as String),
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date'] as String) : null,
      subtotalAmount: Decimal.parse((json['subtotal_amount'] ?? '0').toString()),
      taxAmount: Decimal.parse((json['tax_amount'] ?? '0').toString()),
      totalAmount: Decimal.parse(json['total_amount'].toString()),
      currencyCode: json['currency_code'] as String,
      terms: json['terms'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      lines: json['lines'] != null
          ? (json['lines'] as List).map((e) => InvoiceLine.fromJson(e)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'invoice_number': invoiceNumber,
      'client_name': clientName,
      'status': status,
      'issue_date': issueDate.toIso8601String().split('T').first,
      if (dueDate != null) 'due_date': dueDate!.toIso8601String().split('T').first,
      'subtotal_amount': subtotalAmount.toString(),
      'tax_amount': taxAmount.toString(),
      'total_amount': totalAmount.toString(),
      'currency_code': currencyCode,
      if (terms != null) 'terms': terms,
      'created_at': createdAt.toIso8601String(),
      if (lines != null) 'lines': lines!.map((e) => e.toJson()).toList(),
    };
  }
}
