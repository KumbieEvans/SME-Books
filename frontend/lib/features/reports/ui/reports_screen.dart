import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme.dart';
import 'report_chart_widget.dart';
import '../../../core/theme/spacing.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _reportData = [];
  String _currentReportType = 'Balance Sheet'; // or 'Income Statement'

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');
      final tenantId = user.appMetadata['tenant_id'];

      String rpcName = _currentReportType == 'Balance Sheet' 
          ? 'get_account_balances' 
          : 'get_income_statement';

      final params = <String, dynamic>{
        'p_tenant_id': tenantId,
      };

      if (_currentReportType == 'Balance Sheet') {
        params['p_as_of_date'] = DateTime.now().toIso8601String().split('T').first;
      } else {
        final now = DateTime.now();
        params['p_start_date'] = DateTime(now.year, now.month, 1).toIso8601String().split('T').first;
        params['p_end_date'] = DateTime(now.year, now.month + 1, 0).toIso8601String().split('T').first;
      }

      final response = await _client.rpc(rpcName, params: params);
      setState(() {
        _reportData = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Financial Reports',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.navyBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              DropdownButton<String>(
                value: _currentReportType,
                items: const [
                  DropdownMenuItem(value: 'Balance Sheet', child: Text('Balance Sheet')),
                  DropdownMenuItem(value: 'Income Statement', child: Text('Income Statement')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _currentReportType = val;
                    });
                    _loadReport();
                  }
                },
              )
            ],
          ),
          const SizedBox(height: 24),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)))
          else
            Expanded(
              child: Card(
                child: Column(
                  children: [
                    SizedBox(
                      height: 250,
                      child: ReportChartWidget(
                        data: _reportData,
                        reportType: _currentReportType,
                      ),
                    ),
                    const Divider(),
                    Expanded(
                      child: SingleChildScrollView(
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Account Number', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Balance', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: _reportData.map((row) {
                            return DataRow(cells: [
                              DataCell(Text(row['account_number'].toString())),
                              DataCell(Text(row['account_name'].toString())),
                              DataCell(Text(row['account_type'].toString())),
                              DataCell(
                                Text(
                                  row['balance']?.toString() ?? '0.00',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryTeal),
                                )
                              ),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
        ],
      ),
    );
  }
}
