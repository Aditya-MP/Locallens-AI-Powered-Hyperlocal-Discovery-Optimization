import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:google_generative_ai/google_generative_ai.dart';

class VoiceSearchService {
  static final stt.SpeechToText _speech = stt.SpeechToText();
  static bool _speechEnabled = false;
  static String _lastWords = '';
  
  // Gemini AI for product classification
  static final _gemini = GenerativeModel(
    model: 'gemini-1.5-flash',
    apiKey: 'gemini_api',
  );
  
  static Future<bool> initSpeech() async {
    _speechEnabled = await _speech.initialize();
    return _speechEnabled;
  }
  
  static bool get isAvailable => _speechEnabled;
  static bool get isListening => _speech.isListening;
  static String get lastWords => _lastWords;
  
  static Future<void> startListening({
    required Function(String) onResult,
    Function(String)? onError,
  }) async {
    if (!_speechEnabled) {
      onError?.call('Speech recognition not available');
      return;
    }
    
    await _speech.listen(
      onResult: (result) {
        _lastWords = result.recognizedWords;
        if (result.finalResult) {
          onResult(_lastWords);
        }
      },
      localeId: 'en_IN', // Indian English
      listenFor: Duration(seconds: 10),
      pauseFor: Duration(seconds: 3),
      partialResults: true,
      cancelOnError: true,
      listenMode: stt.ListenMode.confirmation,
    );
  }
  
  static Future<void> stopListening() async {
    await _speech.stop();
  }
  
  static Future<String> classifyVoiceQuery(String voiceQuery) async {
    try {
      final prompt = '''
User said: "$voiceQuery"

Classify this voice search to ONE store category:

Categories: electronics, pharmacy, clothes, grocery, supermarket, bakery, shoes, beauty

Examples:
"iPhone" → electronics
"medicine for fever" → pharmacy
"buy jeans" → clothes
"tomatoes and onions" → grocery
"chocolate bar" → supermarket
"birthday cake" → bakery
"running shoes" → shoes
"haircut" → beauty

Voice Query: "$voiceQuery"
Category:''';
      
      final response = await _gemini.generateContent([Content.text(prompt)]);
      final result = response.text?.trim().toLowerCase() ?? '';
      
      // Validate result
      final validCategories = ['electronics', 'pharmacy', 'clothes', 'grocery', 'supermarket', 'bakery', 'shoes', 'beauty'];
      if (validCategories.contains(result)) {
        return result;
      }
      
      // Fallback classification
      return _fallbackClassification(voiceQuery);
    } catch (e) {
      print('Voice classification error: $e');
      return _fallbackClassification(voiceQuery);
    }
  }
  
  static String _fallbackClassification(String query) {
    final queryLower = query.toLowerCase();
    
    if (_containsAny(queryLower, ['phone', 'iphone', 'laptop', 'tv', 'electronics'])) return 'electronics';
    if (_containsAny(queryLower, ['medicine', 'tablet', 'fever', 'cough', 'pharmacy'])) return 'pharmacy';
    if (_containsAny(queryLower, ['jeans', 'shirt', 'dress', 'clothes', 'wear'])) return 'clothes';
    if (_containsAny(queryLower, ['tomato', 'onion', 'vegetables', 'fruits', 'milk'])) return 'grocery';
    if (_containsAny(queryLower, ['chocolate', 'snacks', 'chips', 'biscuit'])) return 'supermarket';
    if (_containsAny(queryLower, ['cake', 'bread', 'bakery', 'pastry'])) return 'bakery';
    if (_containsAny(queryLower, ['shoes', 'sandals', 'footwear'])) return 'shoes';
    if (_containsAny(queryLower, ['haircut', 'facial', 'salon', 'parlour', 'beauty'])) return 'beauty';
    
    return 'supermarket'; // Default
  }
  
  static bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }
}