import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:decimal/decimal.dart';
import '../../../core/theme.dart';
import '../models/account.dart';
import '../repositories/ledger_repository.dart';

class CreateJournalEntryScreen extends StatefulWidget {
  const CreateJournalEntryScreen({super.key});

  @override
  State<CreateJournalEntryScreen> createState() => _CreateJournalEntryScreenState();
}

class _LineItem {
  String? accountId;
  Decimal debit = Decimal.zero;
  Decimal credit = Decimal.zero;
}

class _CreateJournalEntryScreenState extends State<CreateJournalEntryScreen> {
  late LedgerRepository _repository;
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _currencyController = TextEditingController(text: 'USD');
  final _exchangeRateController = TextEditingController(text: '1.0');
  DateTime _entryDate = DateTime.now();

  List<Account> _accounts = [];
  final List<_LineItem> _lines = [_LineItem(), _LineItem()]; // Start with 2 lines

  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _repository = LedgerRepository(client: Supabase.instance.client);
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    try {
      final accounts = await _repository.getAccounts();
      setState(() {
        _accounts = accounts;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      setState(() => _isLoading = false);
    }
  }

  void _addLine() {
    setState(() {
      _lines.add(_LineItem());
    });
  }

  void _removeLine(int index) {
    setState(() {
      _lines.removeAt(index);
    });
  }

  Decimal get _totalDebit {
    return _lines.fold(Decimal.zero, (prev, line) => prev + line.debit);
  }

  Decimal get _totalCredit {
    return _lines.fold(Decimal.zero, (prev, line) => prev + line.credit);
  }

  bool get _isBalanced {
    return _totalDebit == _totalCredit && _totalDebit > Decimal.zero;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isBalanced) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Journal entry must be balanced (Total Debits = Total Credits).')),
      );
      return;
    }

    if (_lines.any((line) => line.accountId == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an account for all lines.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final linesData = _lines.map((line) => {
        'account_id': line.accountId,
        'debit': line.debit.toString(),
        'credit': line.credit.toString(),
      }).toList();

      await _repository.createJournalEntry(
        entryDate: _entryDate,
        description: _descriptionController.text.trim(),
        currencyCode: _currencyController.text.trim().toUpperCase(),
        exchangeRate: Decimal.parse(_exchangeRateController.text.trim()),
        lines: linesData,
      );

      if (mounted) {
        Navigator.pop(context, true); // Return true to signal success
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Journal Entry'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSubmitting ? null : _submit,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(labelText: 'Description'),
                            validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _entryDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (date != null) {
                                setState(() => _entryDate = date);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'Entry Date'),
                              child: Text(_entryDate.toIso8601String().split('T').first),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _currencyController,
                            decoration: const InputDecoration(labelText: 'Currency Code (e.g., USD, ZWG)'),
                            validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _exchangeRateController,
                            decoration: const InputDecoration(labelText: 'Exchange Rate'),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Required';
                              if (Decimal.tryParse(val) == null) return 'Invalid rate';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text('Journal Lines', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.navyBlue)),
                    const SizedBox(height: 16),
                    ..._lines.asMap().entries.map((entry) {
                      final index = entry.key;
                      final line = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<String>(
                                value: line.accountId,
                                decoration: const InputDecoration(labelText: 'Account'),
                                items: _accounts.map((a) => DropdownMenuItem(
                                  value: a.id,
                                  child: Text('${a.accountNumber} - ${a.name}'),
                                )).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    line.accountId = val;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                decoration: const InputDecoration(labelText: 'Debit'),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                initialValue: line.debit == Decimal.zero ? '' : line.debit.toString(),
                                onChanged: (val) {
                                  setState(() {
                                    line.debit = Decimal.tryParse(val) ?? Decimal.zero;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                decoration: const InputDecoration(labelText: 'Credit'),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                initialValue: line.credit == Decimal.zero ? '' : line.credit.toString(),
                                onChanged: (val) {
                                  setState(() {
                                    line.credit = Decimal.tryParse(val) ?? Decimal.zero;
                                  });
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle, color: Colors.red),
                              onPressed: _lines.length > 2 ? () => _removeLine(index) : null,
                            )
                          ],
                        ),
                      );
                    }).toList(),
                    TextButton.icon(
                      onPressed: _addLine,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Line'),
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('Total Debit: $_totalDebit', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(width: 24),
                        Text('Total Credit: $_totalCredit', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    if (!_isBalanced)
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text('Not Balanced', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
