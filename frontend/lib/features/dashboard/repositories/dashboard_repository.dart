import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardRepository {
  final SupabaseClient _client;

  DashboardRepository({required SupabaseClient client}) : _client = client;

  Future<List<Map<String, dynamic>>> getCashFlowForecast(int daysAhead) async {
    final tenantId = _client.auth.currentUser?.appMetadata['tenant_id'];
    if (tenantId == null) throw Exception('No tenant ID found');

    final response = await _client.rpc('get_cash_flow_forecast', params: {
      'p_tenant_id': tenantId,
      'p_days_ahead': daysAhead,
    });

    return List<Map<String, dynamic>>.from(response);
  }
}
