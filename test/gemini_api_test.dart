import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class GeminiAPITester {
  static const String apiKey = 'AIzaSyAQgMwV5fA5HcBquEabRV_RC2kxqWKdCOg'; // Your actual API key
  
  // Test different API endpoints
  static Future<void> testAllEndpoints() async {
    print('🧪 Starting Gemini API Tests...\n');
    
    final testProduct = 'iPhone 15 Pro Max';
    
    // Test different endpoints
    final endpoints = [
      'https://generativelanguage.googleapis.com/v1/models/gemini-pro:generateContent',
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent',
      'https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent',
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent',
    ];
    
    for (String endpoint in endpoints) {
      print('Testing endpoint: $endpoint');
      await _testEndpoint(endpoint, testProduct);
      print('---\n');
    }
  }
  
  static Future<void> _testEndpoint(String endpoint, String product) async {
    try {
      final response = await http.post(
        Uri.parse('$endpoint?key=$apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [{
            'parts': [{
              'text': 'Classify this product into ONE category: electronics, pharmacy, clothes, grocery, supermarket, bakery, shoes, beauty. Product: $product. Reply with ONLY the category name.'
            }]
          }]
        }),
      );
      
      print('Status Code: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print('Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ SUCCESS! Classification result: ${data['candidates']?[0]?['content']?['parts']?[0]?['text']}');
      } else {
        print('❌ FAILED with status ${response.statusCode}');
      }
      
    } catch (e) {
      print('❌ ERROR: $e');
    }
  }
  
  // Test API key validation
  static Future<void> testAPIKey() async {
    print('🔑 Testing API Key Validation...\n');
    
    try {
      final response = await http.get(
        Uri.parse('https://generativelanguage.googleapis.com/v1/models?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
      );
      
      print('API Key Test - Status: ${response.statusCode}');
      print('Response: ${response.body}');
      
      if (response.statusCode == 200) {
        print('✅ API Key is valid!');
        final data = jsonDecode(response.body);
        print('Available models: ${data['models']?.map((m) => m['name']).join(', ')}');
      } else {
        print('❌ API Key validation failed');
      }
    } catch (e) {
      print('❌ API Key test error: $e');
    }
  }
  
  // Test network connectivity
  static Future<void> testConnectivity() async {
    print('🌐 Testing Network Connectivity...\n');
    
    try {
      final response = await http.get(Uri.parse('https://www.google.com'));
      print('Google connectivity: ${response.statusCode == 200 ? '✅ OK' : '❌ Failed'}');
      
      final geminiResponse = await http.get(Uri.parse('https://generativelanguage.googleapis.com'));
      print('Gemini domain connectivity: ${geminiResponse.statusCode == 404 ? '✅ OK (404 expected)' : '❌ Unexpected: ${geminiResponse.statusCode}'}');
      
    } catch (e) {
      print('❌ Connectivity error: $e');
    }
  }
}

// Main test runner
void main() async {
  print('🚀 Gemini API Comprehensive Test Suite\n');
  
  // Test 1: Network connectivity
  await GeminiAPITester.testConnectivity();
  print('\n' + '='*50 + '\n');
  
  // Test 2: API key validation
  await GeminiAPITester.testAPIKey();
  print('\n' + '='*50 + '\n');
  
  // Test 3: All endpoints
  await GeminiAPITester.testAllEndpoints();
  
  print('🏁 Test suite completed!');
}