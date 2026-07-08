import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/tax.dart';

class TaxRepository {
  final SupabaseClient _supabaseClient;

  TaxRepository({required SupabaseClient supabaseClient})
      : _supabaseClient = supabaseClient;

  Future<List<Tax>> getTaxes() async {
    final tenantId = _supabaseClient.auth.currentUser?.appMetadata['tenant_id'];
    if (tenantId == null) throw Exception('No tenant ID found');

    final response = await _supabaseClient
        .from('taxes')
        .select()
        .eq('tenant_id', tenantId)
        .order('name');

    return response.map((json) => Tax.fromJson(json)).toList();
  }

  Future<Tax> createTax(Map<String, dynamic> taxData) async {
    final tenantId = _supabaseClient.auth.currentUser?.appMetadata['tenant_id'];
    if (tenantId == null) throw Exception('No tenant ID found');

    final dataToInsert = {
      ...taxData,
      'tenant_id': tenantId,
    };

    final response = await _supabaseClient
        .from('taxes')
        .insert(dataToInsert)
        .select()
        .single();

    return Tax.fromJson(response);
  }

  Future<Tax> updateTax(String id, Map<String, dynamic> updates) async {
    final response = await _supabaseClient
        .from('taxes')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

    return Tax.fromJson(response);
  }

  Future<List<Map<String, dynamic>>> getTaxLiabilityReport(DateTime startDate, DateTime endDate) async {
    final tenantId = _supabaseClient.auth.currentUser?.appMetadata['tenant_id'];
    if (tenantId == null) throw Exception('No tenant ID found');

    final response = await _supabaseClient.rpc(
      'get_tax_liability',
      params: {
        'p_tenant_id': tenantId,
        'p_start_date': startDate.toIso8601String().split('T')[0],
        'p_end_date': endDate.toIso8601String().split('T')[0],
      },
    );

    return List<Map<String, dynamic>>.from(response);
  }
}
