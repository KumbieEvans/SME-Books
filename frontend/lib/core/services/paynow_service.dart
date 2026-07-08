import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:decimal/decimal.dart';

class PaynowService {
  // In a real application, you would store credentials securely on the backend
  // and initiate the transaction from an Edge Function to avoid leaking keys.
  // This is a simplified frontend integration stub.
  static const String _integrationId = 'YOUR_PAYNOW_INTEGRATION_ID';
  static const String _integrationKey = 'YOUR_PAYNOW_INTEGRATION_KEY';
  static const String _paynowUrl = 'https://www.paynow.co.zw/interface/initiatetransaction';

  /// Initiates a payment request with Paynow and returns a redirect URL to their hosted checkout.
  Future<String?> initiatePayment({
    required String invoiceNumber,
    required Decimal amount,
    required String email,
  }) async {
    // Note: A true Paynow integration requires computing a SHA512 hash of the payload 
    // using the Integration Key. We simulate the request here.
    
    if (_integrationId == 'YOUR_PAYNOW_INTEGRATION_ID') {
      // Return a mock checkout URL for local testing
      await Future.delayed(const Duration(seconds: 1));
      return 'https://www.paynow.co.zw/payment/link/mock_transaction_123';
    }

    final payload = {
      'resulturl': 'https://your-api.com/webhooks/paynow/result',
      'returnurl': 'https://your-app.com/invoices/success',
      'reference': invoiceNumber,
      'amount': amount.toString(),
      'id': _integrationId,
      'additionalinfo': 'Payment for $invoiceNumber',
      'authemail': email,
      'status': 'Message',
    };

    // Construct the Hash (simplified stub)
    // payload['hash'] = generatePaynowHash(payload, _integrationKey);

    final response = await http.post(
      Uri.parse(_paynowUrl),
      body: payload,
    );

    if (response.statusCode == 200) {
      // Parse the Paynow form-urlencoded response
      // e.g., status=Ok&browserurl=https://...
      final bodyStr = response.body;
      final uri = Uri(query: bodyStr);
      final params = uri.queryParameters;
      
      if (params['status'] == 'Ok') {
        return params['browserurl'];
      } else {
        throw Exception('Paynow Error: ${params['error']}');
      }
    } else {
      throw Exception('Failed to communicate with Paynow. HTTP ${response.statusCode}');
    }
  }
}
