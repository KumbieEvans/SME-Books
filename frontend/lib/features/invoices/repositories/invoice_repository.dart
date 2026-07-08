import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/invoice.dart';

class InvoiceRepository {
  final SupabaseClient _client;

  InvoiceRepository({required SupabaseClient client}) : _client = client;

  Future<List<Invoice>> getInvoices() async {
    final response = await _client
        .from('invoices')
        .select('*, lines:invoice_lines(*)')
        .order('created_at', ascending: false);

    return (response as List).map((e) => Invoice.fromJson(e)).toList();
  }

  Future<Invoice> createInvoice(Map<String, dynamic> invoiceData, List<Map<String, dynamic>> linesData, {String? recurringFrequency}) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    
    final tenantId = user.appMetadata['tenant_id'];
    if (tenantId == null) throw Exception('No tenant_id found');

    invoiceData['tenant_id'] = tenantId;

    // Use a transaction/RPC or insert sequentially
    // Since we don't have an RPC for invoices like we do for journals,
    // we can insert the invoice first, then the lines.
    // In production, an RPC or Edge Function is preferred for atomicity.
    
    final invoiceResponse = await _client
        .from('invoices')
        .insert(invoiceData)
        .select()
        .single();
        
    final newInvoiceId = invoiceResponse['id'];

    final List<Map<String, dynamic>> linesToInsert = linesData.map((line) {
      line['tenant_id'] = tenantId;
      line['invoice_id'] = newInvoiceId;
      return line;
    }).toList();

    await _client.from('invoice_lines').insert(linesToInsert);

    if (recurringFrequency != null && recurringFrequency.isNotEmpty) {
      DateTime nextRunDate = DateTime.now();
      if (recurringFrequency == 'Weekly') {
        nextRunDate = nextRunDate.add(const Duration(days: 7));
      } else if (recurringFrequency == 'Monthly') {
        nextRunDate = DateTime(nextRunDate.year, nextRunDate.month + 1, nextRunDate.day);
      } else if (recurringFrequency == 'Yearly') {
        nextRunDate = DateTime(nextRunDate.year + 1, nextRunDate.month, nextRunDate.day);
      }

      await _client.from('recurring_invoices').insert({
        'tenant_id': tenantId,
        'base_invoice_id': newInvoiceId,
        'frequency': recurringFrequency,
        'next_run_date': nextRunDate.toIso8601String().split('T').first,
        'is_active': true,
      });
    }

    // Fetch the complete invoice with lines
    final fullInvoice = await _client
        .from('invoices')
        .select('*, lines:invoice_lines(*)')
        .eq('id', newInvoiceId)
        .single();

    return Invoice.fromJson(fullInvoice);
  }
}
