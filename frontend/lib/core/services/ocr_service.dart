import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class OcrResult {
  final String? vendorName;
  final double? amount;

  OcrResult({this.vendorName, this.amount});
}

class OcrService {
  // TODO: Replace with actual API key in production (or move to Edge Function)
  static const String _apiKey = 'YOUR_GOOGLE_CLOUD_VISION_API_KEY';

  Future<OcrResult> processReceipt(Uint8List imageBytes) async {
    if (_apiKey == 'YOUR_GOOGLE_CLOUD_VISION_API_KEY') {
      // Return a mock result for local testing without a real API key
      await Future.delayed(const Duration(seconds: 2));
      return OcrResult(vendorName: 'Mock Vendor Inc.', amount: 150.75);
    }

    final String base64Image = base64Encode(imageBytes);

    final url = Uri.parse('https://vision.googleapis.com/v1/images:annotate?key=$_apiKey');
    
    final payload = {
      "requests": [
        {
          "image": {
            "content": base64Image
          },
          "features": [
            {
              "type": "DOCUMENT_TEXT_DETECTION"
            }
          ]
        }
      ]
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to process image with Google Cloud Vision: ${response.body}');
    }

    final data = jsonDecode(response.body);
    final String fullText = data['responses']?[0]?['fullTextAnnotation']?['text'] ?? '';

    // A simple regex extraction for amounts
    // Note: In a real production app, you might use an LLM or more robust parsing.
    final amountRegEx = RegExp(r'\$?\s*(\d{1,3}(?:,\d{3})*(?:\.\d{2}))');
    final matches = amountRegEx.allMatches(fullText);
    
    double? maxAmount;
    for (var match in matches) {
      final valStr = match.group(1)?.replaceAll(',', '');
      if (valStr != null) {
        final val = double.tryParse(valStr);
        if (val != null) {
          if (maxAmount == null || val > maxAmount) {
            maxAmount = val;
          }
        }
      }
    }

    // Heuristic for vendor name: often the first line in the text
    String? vendor;
    final lines = fullText.split('\n');
    if (lines.isNotEmpty && lines[0].trim().isNotEmpty) {
      vendor = lines[0].trim();
    }

    return OcrResult(vendorName: vendor, amount: maxAmount);
  }
}
