import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:decimal/decimal.dart';
import '../../../core/theme.dart';
import '../repositories/invoice_repository.dart';
import '../../taxes/repositories/tax_repository.dart';
import '../../taxes/models/tax.dart';

class CreateInvoiceScreen extends StatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  final _invoiceRepo = InvoiceRepository(client: Supabase.instance.client);
  final _taxRepo = TaxRepository(supabaseClient: Supabase.instance.client);
  
  final _clientNameController = TextEditingController();
  final _termsController = TextEditingController();
  String? _selectedFrequency;
  
  List<Tax> _availableTaxes = [];
  bool _isLoadingTaxes = true;

  final List<_InvoiceLineInput> _lines = [];

  @override
  void initState() {
    super.initState();
    _lines.add(_InvoiceLineInput());
    _loadTaxes();
  }

  Future<void> _loadTaxes() async {
    try {
      final taxes = await _taxRepo.getTaxes();
      setState(() {
        _availableTaxes = taxes.where((t) => t.isActive).toList();
        _isLoadingTaxes = false;
      });
    } catch (e) {
      setState(() => _isLoadingTaxes = false);
    }
  }

  void _addLine() {
    setState(() {
      _lines.add(_InvoiceLineInput());
    });
  }

  void _removeLine(int index) {
    if (_lines.length > 1) {
      setState(() {
        _lines.removeAt(index);
      });
    }
  }

  Decimal get _subtotal {
    Decimal total = Decimal.zero;
    for (var line in _lines) {
      final qty = Decimal.tryParse(line.qtyController.text) ?? Decimal.zero;
      final price = Decimal.tryParse(line.priceController.text) ?? Decimal.zero;
      total += qty * price;
    }
    return total;
  }

  Decimal get _totalTax {
    Decimal total = Decimal.zero;
    for (var line in _lines) {
      final qty = Decimal.tryParse(line.qtyController.text) ?? Decimal.zero;
      final price = Decimal.tryParse(line.priceController.text) ?? Decimal.zero;
      final lineTotal = qty * price;
      
      if (line.selectedTaxId != null) {
        final tax = _availableTaxes.firstWhere((t) => t.id == line.selectedTaxId);
        total += lineTotal * tax.rate;
      }
    }
    return total;
  }

  Decimal get _grandTotal => _subtotal + _totalTax;

  Future<void> _saveInvoice() async {
    final clientName = _clientNameController.text.trim();
    if (clientName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Client name required')));
      return;
    }

    try {
      final invoiceData = {
        'invoice_number': 'INV-${DateTime.now().millisecondsSinceEpoch}',
        'client_name': clientName,
        'status': 'Draft',
        'issue_date': DateTime.now().toIso8601String().split('T').first,
        'subtotal_amount': _subtotal.toString(),
        'tax_amount': _totalTax.toString(),
        'total_amount': _grandTotal.toString(),
        'currency_code': 'USD',
        'terms': _termsController.text.trim(),
      };

      final linesData = _lines.map((line) {
        final qty = Decimal.tryParse(line.qtyController.text) ?? Decimal.zero;
        final price = Decimal.tryParse(line.priceController.text) ?? Decimal.zero;
        final lineTotal = qty * price;
        
        Decimal lineTaxAmount = Decimal.zero;
        if (line.selectedTaxId != null) {
          final tax = _availableTaxes.firstWhere((t) => t.id == line.selectedTaxId);
          lineTaxAmount = lineTotal * tax.rate;
        }

        return {
          'description': line.descController.text.trim(),
          'quantity': qty.toString(),
          'unit_price': price.toString(),
          'tax_id': line.selectedTaxId,
          'tax_amount': lineTaxAmount.toString(),
        };
      }).toList();

      await _invoiceRepo.createInvoice(
        invoiceData,
        linesData,
        recurringFrequency: _selectedFrequency,
      );

      if (mounted) {
        Navigator.pop(context, true); // true indicates success to trigger reload
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingTaxes) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('Create Invoice')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _clientNameController,
              decoration: const InputDecoration(labelText: 'Client Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _termsController,
              decoration: const InputDecoration(labelText: 'Custom Terms (e.g. Net 30)'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Make Recurring?'),
              value: _selectedFrequency,
              items: const [
                DropdownMenuItem(value: null, child: Text('No (One-time)')),
                DropdownMenuItem(value: 'Weekly', child: Text('Weekly')),
                DropdownMenuItem(value: 'Monthly', child: Text('Monthly')),
                DropdownMenuItem(value: 'Yearly', child: Text('Yearly')),
              ],
              onChanged: (val) {
                setState(() { _selectedFrequency = val; });
              },
            ),
            const SizedBox(height: 32),
            const Text('Line Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ..._lines.asMap().entries.map((entry) {
              int idx = entry.key;
              var line = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(flex: 3, child: TextField(controller: line.descController, decoration: const InputDecoration(labelText: 'Description'))),
                    const SizedBox(width: 8),
                    Expanded(flex: 1, child: TextField(controller: line.qtyController, decoration: const InputDecoration(labelText: 'Qty'), keyboardType: TextInputType.number, onChanged: (_) => setState((){}))),
                    const SizedBox(width: 8),
                    Expanded(flex: 2, child: TextField(controller: line.priceController, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number, onChanged: (_) => setState((){}))),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Tax'),
                        value: line.selectedTaxId,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('None')),
                          ..._availableTaxes.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))),
                        ],
                        onChanged: (val) {
                          setState(() { line.selectedTaxId = val; });
                        },
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _removeLine(idx)),
                  ],
                ),
              );
            }),
            TextButton.icon(onPressed: _addLine, icon: const Icon(Icons.add), label: const Text('Add Line Item')),
            
            const SizedBox(height: 32),
            Align(
              alignment: Alignment.centerRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Subtotal: \$$_subtotal', style: const TextStyle(fontSize: 16)),
                  Text('Tax: \$$_totalTax', style: const TextStyle(fontSize: 16)),
                  const Divider(),
                  Text('Total: \$$_grandTotal', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveInvoice,
                child: const Text('Save & Generate Invoice'),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _InvoiceLineInput {
  final descController = TextEditingController();
  final qtyController = TextEditingController(text: '1');
  final priceController = TextEditingController(text: '0');
  String? selectedTaxId;
}
