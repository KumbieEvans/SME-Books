import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme.dart';
import '../models/expense.dart';
import '../repositories/expense_repository.dart';
import 'create_expense_screen.dart';
import '../../../core/theme/spacing.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  late ExpenseRepository _repository;
  List<Expense> _expenses = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = ExpenseRepository(client: Supabase.instance.client);
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final expenses = await _repository.getExpenses();
      if (mounted) {
        setState(() {
          _expenses = expenses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _viewReceipt(String path) {
    final url = _repository.getPublicUrl(path);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: Image.network(url),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          )
        ],
      ),
    );
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
                'Expenses & Receipts',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.navyBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateExpenseScreen()),
                  );
                  if (result == true) {
                    _loadExpenses();
                  }
                },
                icon: const Icon(Icons.add_a_photo),
                label: const Text('Capture Receipt'),
              )
            ],
          ),
          const SizedBox(height: 24),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)))
          else if (_expenses.isEmpty)
            const Expanded(child: Center(child: Text('No expenses recorded yet.')))
          else
            Expanded(
              child: Card(
                child: SingleChildScrollView(
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Vendor', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Receipt', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: _expenses.map((exp) {
                      return DataRow(cells: [
                        DataCell(Text(exp.expenseDate.toIso8601String().split('T').first)),
                        DataCell(Text(exp.vendorName)),
                        DataCell(Text('${exp.currencyCode} ${exp.amount}')),
                        DataCell(
                          exp.receiptUrl != null
                              ? IconButton(
                                  icon: const Icon(Icons.receipt, color: AppTheme.primaryTeal),
                                  onPressed: () => _viewReceipt(exp.receiptUrl!),
                                  tooltip: 'View Receipt',
                                )
                              : const Text('No Receipt'),
                        ),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            )
        ],
      ),
    );
  }
}
