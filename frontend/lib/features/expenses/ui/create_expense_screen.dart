import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/theme.dart';
import '../../../core/services/ocr_service.dart';
import '../repositories/expense_repository.dart';
import '../../../core/theme/spacing.dart';

class CreateExpenseScreen extends StatefulWidget {
  const CreateExpenseScreen({super.key});

  @override
  State<CreateExpenseScreen> createState() => _CreateExpenseScreenState();
}

class _CreateExpenseScreenState extends State<CreateExpenseScreen> {
  final _expenseRepo = ExpenseRepository(client: Supabase.instance.client);
  final _ocrService = OcrService();
  
  final _vendorController = TextEditingController();
  final _amountController = TextEditingController();
  
  Uint8List? _receiptBytes;
  String? _receiptFileName;
  
  bool _isProcessingOcr = false;
  bool _isSaving = false;

  Future<void> _pickReceipt() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _receiptBytes = result.files.single.bytes;
        _receiptFileName = result.files.single.name;
      });
      _runOcr();
    }
  }

  Future<void> _runOcr() async {
    if (_receiptBytes == null) return;
    
    setState(() => _isProcessingOcr = true);
    
    try {
      final ocrResult = await _ocrService.processReceipt(_receiptBytes!);
      
      if (mounted) {
        setState(() {
          if (ocrResult.vendorName != null && _vendorController.text.isEmpty) {
            _vendorController.text = ocrResult.vendorName!;
          }
          if (ocrResult.amount != null && _amountController.text.isEmpty) {
            _amountController.text = ocrResult.amount.toString();
          }
          _isProcessingOcr = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OCR extraction complete!')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessingOcr = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('OCR Error: $e')));
      }
    }
  }

  Future<void> _saveExpense() async {
    final vendor = _vendorController.text.trim();
    final amountStr = _amountController.text.trim();
    
    if (vendor.isEmpty || amountStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vendor and Amount are required')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      String? receiptPath;
      if (_receiptBytes != null && _receiptFileName != null) {
        final uniqueName = '${DateTime.now().millisecondsSinceEpoch}_$_receiptFileName';
        receiptPath = await _expenseRepo.uploadReceipt(_receiptBytes!, uniqueName);
      }

      await _expenseRepo.createExpense({
        'vendor_name': vendor,
        'amount': amountStr,
        'currency_code': 'USD',
        'receipt_url': receiptPath,
        'expense_date': DateTime.now().toIso8601String().split('T').first,
      });

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Expense')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _pickReceipt,
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.navyBlue, style: BorderStyle.solid),
                ),
                child: _receiptBytes == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.upload_file, size: 48, color: AppTheme.navyBlue),
                          SizedBox(height: 8),
                          Text('Tap to upload receipt (Image)', style: TextStyle(color: AppTheme.navyBlue)),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(_receiptBytes!, fit: BoxFit.contain),
                      ),
              ),
            ),
            if (_isProcessingOcr)
              const Padding(
                padding: EdgeInsets.only(top: 16.0),
                child: Row(
                  children: [
                    SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 16),
                    Text('Analyzing receipt with Google Cloud Vision...'),
                  ],
                ),
              ),
            const SizedBox(height: 32),
            TextField(
              controller: _vendorController,
              decoration: const InputDecoration(labelText: 'Vendor Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveExpense,
                child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Expense'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
