import 'package:decimal/decimal.dart';

class JournalLine {
  final String id;
  final String tenantId;
  final String journalEntryId;
  final String accountId;
  final Decimal debit;
  final Decimal credit;

  JournalLine({
    required this.id,
    required this.tenantId,
    required this.journalEntryId,
    required this.accountId,
    required this.debit,
    required this.credit,
  });

  factory JournalLine.fromJson(Map<String, dynamic> json) {
    return JournalLine(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      journalEntryId: json['journal_entry_id'] as String,
      accountId: json['account_id'] as String,
      debit: Decimal.parse(json['debit'].toString()),
      credit: Decimal.parse(json['credit'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'journal_entry_id': journalEntryId,
      'account_id': accountId,
      'debit': debit.toString(),
      'credit': credit.toString(),
    };
  }
}
