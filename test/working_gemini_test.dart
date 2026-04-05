import 'dart:convert';
import 'package:http/http.dart' as http;

class WorkingGeminiTest {
  static const String apiKey = 'AIzaSyAQgMwV5fA5HcBquEabRV_RC2kxqWKdCOg';
  
  static Future<void> testWorkingModels() async {
    print('🚀 Testing WORKING Gemini Models...\n');
    
    // Test with current available models
    final workingModels = [
      'gemini-2.5-flash',
      'gemini-2.0-flash',
      'gemini-2.5-pro',
    ];
    
    for (String model in workingModels) {
      await _testModel(model, 'iPhone 15 Pro Max');
    }
  }
  
  static Future<void> _testModel(String model, String product) async {
    print('Testing model: $model');
    
    try {
      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1/models/$model:generateContent?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{
            'parts': [{
              'text': 'Classify "$product" into ONE category: electronics, pharmacy, clothes, grocery, supermarket, bakery, shoes, beauty. Reply with ONLY the category name.'
            }]
          }]
        }),
      );
      
      print('Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = data['candidates']?[0]?['content']?['parts']?[0]?['text']?.toString().trim();
        print('✅ SUCCESS! Result: "$result"');
        print('✅ Model $model is WORKING!\n');
      } else {
        print('❌ Failed: ${response.body}\n');
      }
      
    } catch (e) {
      print('❌ Error: $e\n');
    }
  }
}

void main() async {
  await WorkingGeminiTest.testWorkingModels();
  print('🎉 Test completed! Use the working models above.');
}