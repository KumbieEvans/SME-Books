import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:decimal/decimal.dart';
import '../models/account.dart';
import '../models/journal_entry.dart';
import '../models/journal_line.dart';

class LedgerRepository {
  final SupabaseClient _client;

  LedgerRepository({required SupabaseClient client}) : _client = client;

  /// Fetch all accounts for the current tenant.
  /// RLS ensures the user only sees their tenant's accounts.
  Future<List<Account>> getAccounts() async {
    final response = await _client.from('accounts').select().order('account_number');
    return (response as List).map((e) => Account.fromJson(e)).toList();
  }

  /// Fetch journal entries with pagination using range queries.
  Future<List<JournalEntry>> getJournalEntries({required int from, required int to}) async {
    final response = await _client
        .from('journal_entries')
        .select('*, lines:journal_lines(*)')
        .order('entry_date', ascending: false)
        .range(from, to);

    return (response as List).map((e) => JournalEntry.fromJson(e)).toList();
  }

  /// Create a double-entry journal transaction calling the RPC function.
  Future<String> createJournalEntry({
    required DateTime entryDate,
    required String description,
    required String currencyCode,
    required Decimal exchangeRate,
    required List<Map<String, dynamic>> lines,
  }) async {
    // lines should be a list of maps containing 'account_id', 'debit', 'credit'
    
    // We get the tenant ID from the current user's metadata to pass to the RPC.
    // The RLS policy will enforce security inside the RPC if it runs with definer or invoker rights.
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User is not authenticated');
    }
    final tenantId = user.appMetadata['tenant_id'];

    if (tenantId == null) {
      throw Exception('User has no assigned tenant_id');
    }

    final response = await _client.rpc(
      'create_journal_entry',
      params: {
        'p_tenant_id': tenantId,
        'p_entry_date': entryDate.toIso8601String().split('T').first,
        'p_description': description,
        'p_currency_code': currencyCode,
        'p_exchange_rate': exchangeRate.toString(),
        'p_lines': lines,
      },
    );

    return response.toString(); // returns the UUID of the new entry
  }
}
