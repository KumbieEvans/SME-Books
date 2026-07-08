import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/expense.dart';

class ExpenseRepository {
  final SupabaseClient _client;

  ExpenseRepository({required SupabaseClient client}) : _client = client;

  Future<List<Expense>> getExpenses() async {
    final tenantId = _client.auth.currentUser?.appMetadata['tenant_id'];
    if (tenantId == null) throw Exception('No tenant ID found');

    final response = await _client
        .from('expenses')
        .select()
        .eq('tenant_id', tenantId)
        .order('expense_date', ascending: false);

    return response.map((json) => Expense.fromJson(json)).toList();
  }

  Future<String?> uploadReceipt(Uint8List fileBytes, String fileName) async {
    final tenantId = _client.auth.currentUser?.appMetadata['tenant_id'];
    if (tenantId == null) throw Exception('No tenant ID found');

    final path = '$tenantId/$fileName';
    
    await _client.storage.from('receipts').uploadBinary(
      path,
      fileBytes,
      fileOptions: const FileOptions(upsert: true),
    );

    return path;
  }

  Future<Expense> createExpense(Map<String, dynamic> expenseData) async {
    final tenantId = _client.auth.currentUser?.appMetadata['tenant_id'];
    if (tenantId == null) throw Exception('No tenant ID found');

    expenseData['tenant_id'] = tenantId;

    final response = await _client
        .from('expenses')
        .insert(expenseData)
        .select()
        .single();

    return Expense.fromJson(response);
  }

  String getPublicUrl(String path) {
    return _client.storage.from('receipts').getPublicUrl(path);
  }
}
