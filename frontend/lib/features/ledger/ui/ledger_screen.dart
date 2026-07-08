import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme.dart';
import '../models/journal_entry.dart';
import '../repositories/ledger_repository.dart';
import 'create_journal_entry_screen.dart';

class LedgerScreen extends StatefulWidget {
  const LedgerScreen({super.key});

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> {
  late LedgerRepository _repository;
  List<JournalEntry> _entries = [];
  bool _isLoading = true;
  String? _error;

  int _currentPage = 0;
  final int _pageSize = 50;

  @override
  void initState() {
    super.initState();
    _repository = LedgerRepository(client: Supabase.instance.client);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final from = _currentPage * _pageSize;
      final to = from + _pageSize - 1;
      final entries = await _repository.getJournalEntries(from: from, to: to);
      setState(() {
        _entries = entries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _nextPage() {
    if (_entries.length == _pageSize) {
      setState(() {
        _currentPage++;
      });
      _loadData();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
      _loadData();
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
                'General Ledger',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.navyBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateJournalEntryScreen()),
                  );
                  if (result == true) {
                    _loadData();
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('New Entry'),
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
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Description', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Currency', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Rate', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                            rows: _entries.map((entry) {
                              return DataRow(cells: [
                                DataCell(Text(entry.entryDate.toIso8601String().split('T').first)),
                                DataCell(Text(entry.description)),
                                DataCell(Text(entry.currencyCode)),
                                DataCell(Text(entry.exchangeRate.toString())),
                                DataCell(
                                  TextButton(
                                    onPressed: () {
                                      // View details
                                    },
                                    child: const Text('View Lines'),
                                  ),
                                ),
                              ]);
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: _currentPage > 0 ? _previousPage : null,
                          ),
                          Text('Page ${_currentPage + 1}'),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: _entries.length == _pageSize ? _nextPage : null,
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            )
        ],
      ),
    );
  }
}
