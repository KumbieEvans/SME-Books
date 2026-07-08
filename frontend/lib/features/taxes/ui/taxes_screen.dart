import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:decimal/decimal.dart';
import '../../../core/theme.dart';
import '../models/tax.dart';
import '../repositories/tax_repository.dart';

class TaxesScreen extends StatefulWidget {
  const TaxesScreen({super.key});

  @override
  State<TaxesScreen> createState() => _TaxesScreenState();
}

class _TaxesScreenState extends State<TaxesScreen> {
  final _taxRepo = TaxRepository(supabaseClient: Supabase.instance.client);
  
  List<Tax> _taxes = [];
  List<Map<String, dynamic>> _liabilityReport = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final taxes = await _taxRepo.getTaxes();
      
      final startDate = DateTime.now().subtract(const Duration(days: 30));
      final endDate = DateTime.now();
      final liability = await _taxRepo.getTaxLiabilityReport(startDate, endDate);

      if (mounted) {
        setState(() {
          _taxes = taxes;
          _liabilityReport = liability;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading taxes: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAddTaxDialog() {
    final nameController = TextEditingController();
    final rateController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Tax Rate'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Tax Name (e.g. VAT)'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: rateController,
                decoration: const InputDecoration(labelText: 'Rate % (e.g. 15)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final ratePercent = double.tryParse(rateController.text.trim()) ?? 0;
                if (name.isEmpty || ratePercent <= 0) return;

                Navigator.pop(context);
                try {
                  await _taxRepo.createTax({
                    'name': name,
                    'rate': ratePercent / 100.0,
                    'is_active': true,
                  });
                  _loadData();
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Save'),
            )
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tax Compliance Dashboard',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.navyBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showAddTaxDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add Tax Rate'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryTeal,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          Text(
            'Configured Tax Rates',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.navyBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildTaxesTable(),

          const SizedBox(height: 48),

          Text(
            'Tax Liability (Last 30 Days)',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.navyBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildLiabilityTable(),
        ],
      ),
    );
  }

  Widget _buildTaxesTable() {
    if (_taxes.isEmpty) {
      return const Text('No taxes configured.');
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Tax Name', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Rate (%)', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: _taxes.map((t) {
          final ratePercent = (t.rate * Decimal.parse('100')).toStringAsFixed(2);
          return DataRow(cells: [
            DataCell(Text(t.name)),
            DataCell(Text('$ratePercent%')),
            DataCell(
              Chip(
                label: Text(t.isActive ? 'Active' : 'Inactive'),
                backgroundColor: t.isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                labelStyle: TextStyle(color: t.isActive ? Colors.green : Colors.red),
              )
            ),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildLiabilityTable() {
    if (_liabilityReport.isEmpty) {
      return const Text('No tax liabilities recorded for this period.');
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Tax Name', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Taxable Amount', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Tax Collected', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: _liabilityReport.map((row) {
          return DataRow(cells: [
            DataCell(Text(row['tax_name'])),
            DataCell(Text('\$${row['total_taxable_amount']}')),
            DataCell(Text('\$${row['total_tax_collected']}')),
          ]);
        }).toList(),
      ),
    );
  }
}
