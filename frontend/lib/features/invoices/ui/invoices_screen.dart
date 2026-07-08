import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme.dart';
import '../../../core/services/paynow_service.dart';
import '../models/invoice.dart';
import '../repositories/invoice_repository.dart';
import 'create_invoice_screen.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  late InvoiceRepository _repository;
  List<Invoice> _invoices = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = InvoiceRepository(client: Supabase.instance.client);
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final invoices = await _repository.getInvoices();
      setState(() {
        _invoices = invoices;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _payWithPaynow(Invoice invoice) async {
    try {
      final paynow = PaynowService();
      final url = await paynow.initiatePayment(
        invoiceNumber: invoice.invoiceNumber,
        amount: invoice.totalAmount,
        email: 'test@client.com', // In a real app, from the client's record
      );
      
      if (url != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Redirecting to Paynow: $url'),
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Open',
                onPressed: () {
                  // Use url_launcher to open the browser in a real app
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Invoices',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.navyBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CreateInvoiceScreen()),
                      );
                      if (result == true) {
                        _loadInvoices();
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('New Invoice'),
                  ),
                ],
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
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    )
                  ],
                ),
                child: SingleChildScrollView(
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Invoice #', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Client', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: _invoices.map((inv) {
                      return DataRow(cells: [
                        DataCell(Text(inv.invoiceNumber)),
                        DataCell(Text(inv.clientName)),
                        DataCell(Text('${inv.currencyCode} ${inv.totalAmount}')),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: inv.status == 'Paid' ? Colors.green.withOpacity(0.1) : (inv.status == 'Sent' ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.1)),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              inv.status,
                              style: TextStyle(
                                color: inv.status == 'Paid' ? Colors.green : (inv.status == 'Sent' ? Colors.blue : Colors.grey),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        ),
                        DataCell(
                          Row(
                            children: [
                              TextButton(
                                onPressed: () {},
                                child: const Text('View'),
                              ),
                              if (inv.status != 'Paid')
                                TextButton.icon(
                                  onPressed: () => _payWithPaynow(inv),
                                  icon: const Icon(Icons.payment, size: 16),
                                  label: const Text('Pay'),
                                  style: TextButton.styleFrom(foregroundColor: AppTheme.primaryTeal),
                                ),
                            ],
                          ),
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
