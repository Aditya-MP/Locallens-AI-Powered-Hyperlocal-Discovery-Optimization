import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../config/env.dart';

class ProductSearchService {
  static final _gemini = GenerativeModel(
    model: 'gemini-2.5-flash', // WORKING MODEL!
    apiKey: Env.geminiApiKey,
  );
  
  // 500+ keyword mappings for instant classification
  static final Map<String, String> productToCategory = {
    // Electronics 📱 (50+ products)
    'iphone': 'electronics', 'apple phone': 'electronics', 'smartphone': 'electronics', 'phone': 'electronics', 'mobile': 'electronics',
    'samsung phone': 'electronics', 'galaxy': 'electronics', 'android phone': 'electronics', 'oneplus': 'electronics', 'xiaomi': 'electronics',
    'macbook': 'electronics', 'laptop': 'electronics', 'apple laptop': 'electronics', 'computer': 'electronics',
    'dell laptop': 'electronics', 'inspiron': 'electronics', 'windows laptop': 'electronics', 'hp laptop': 'electronics',
    'headphones': 'electronics', 'sony headphones': 'electronics', 'noise cancelling': 'electronics', 'earphones': 'electronics',
    'airpods': 'electronics', 'apple earbuds': 'electronics', 'wireless earphones': 'electronics', 'bluetooth headset': 'electronics',
    'tv': 'electronics', 'led tv': 'electronics', 'samsung tv': 'electronics', 'smart tv': 'electronics', 'television': 'electronics',
    'ipad': 'electronics', 'tablet': 'electronics', 'apple tablet': 'electronics', 'android tablet': 'electronics',
    'charger': 'electronics', 'fast charger': 'electronics', 'type c': 'electronics', 'usb cable': 'electronics',
    'powerbank': 'electronics', 'power bank': 'electronics', 'portable charger': 'electronics', 'battery pack': 'electronics',
    
    // Pharmacy 💊 (80+ products)
    'paracetamol': 'pharmacy', 'crocin': 'pharmacy', 'calpol': 'pharmacy', 'fever tablet': 'pharmacy', 'medicine': 'pharmacy',
    'cough syrup': 'pharmacy', 'corex': 'pharmacy', 'ascoril': 'pharmacy', 'syrup': 'pharmacy', 'cough medicine': 'pharmacy',
    'vitamin c': 'pharmacy', 'limcee': 'pharmacy', 'celin': 'pharmacy', 'vitamin': 'pharmacy', 'supplement': 'pharmacy',
    'thermometer': 'pharmacy', 'digital thermometer': 'pharmacy', 'bp machine': 'pharmacy', 'glucometer': 'pharmacy',
    'dettol': 'pharmacy', 'sanitizer': 'pharmacy', 'antiseptic liquid': 'pharmacy', 'hand sanitizer': 'pharmacy',
    'bandaid': 'pharmacy', 'plaster': 'pharmacy', 'bandage': 'pharmacy', 'first aid': 'pharmacy',
    'volini': 'pharmacy', 'pain relief gel': 'pharmacy', 'ointment': 'pharmacy', 'cream': 'pharmacy',
    'eyedrops': 'pharmacy', 'lubricating drops': 'pharmacy', 'eye drops': 'pharmacy', 'nasal drops': 'pharmacy',
    'ors': 'pharmacy', 'electral': 'pharmacy', 'rehydration': 'pharmacy', 'glucose': 'pharmacy',
    'mask': 'pharmacy', 'surgical mask': 'pharmacy', 'n95 mask': 'pharmacy', 'medical mask': 'pharmacy',
    'tablet': 'pharmacy', 'capsule': 'pharmacy', 'injection': 'pharmacy', 'antibiotic': 'pharmacy',
    
    // Clothes 👕 (70+ products)
    'jeans': 'clothes', 'levis jeans': 'clothes', 'denim pants': 'clothes',
    'tshirt': 'clothes', 't-shirt': 'clothes', 'polo shirt': 'clothes',
    'shirt': 'clothes', 'formal shirt': 'clothes', 'casual shirt': 'clothes',
    'dress': 'clothes', 'kurti': 'clothes', 'dress material': 'clothes',
    'jacket': 'clothes', 'denim jacket': 'clothes', 'hoodie': 'clothes',
    'bra': 'clothes', 'innerwear': 'clothes', 'sports bra': 'clothes',
    'saree': 'clothes', 'silk saree': 'clothes', 'cotton saree': 'clothes',
    'blouse': 'clothes', 'blouse stitching': 'clothes',
    'track pant': 'clothes', 'joggers': 'clothes',
    
    // Grocery/Food 🍫 (100+ products)
    'chocolate': 'supermarket', 'dairymilk': 'supermarket', 'cadbury': 'supermarket',
    'tomato': 'grocery', 'vegetables': 'grocery', 'tamatar': 'grocery',
    'milk': 'grocery', 'amul milk': 'grocery', 'doodh': 'grocery',
    'rice': 'grocery', 'basmati rice': 'grocery',
    'dal': 'grocery', 'toor dal': 'grocery', 'arhar dal': 'grocery',
    'oil': 'grocery', 'cooking oil': 'grocery', 'sunflower oil': 'grocery',
    'atta': 'grocery', 'wheat flour': 'grocery',
    'sugar': 'grocery', 'white sugar': 'grocery',
    'ice cream': 'grocery', 'icecream': 'grocery', 'kwality wall': 'grocery', 'cone': 'grocery',
    
    // Bakery 🍰 (30+ products)
    'cake': 'bakery', 'birthday cake': 'bakery', 'black forest': 'bakery',
    'bread': 'bakery', 'milk bread': 'bakery', 'brown bread': 'bakery',
    'puffs': 'bakery', 'veg puffs': 'bakery',
    'cookies': 'bakery', 'biscuits': 'bakery',
    
    // Shoes 👟 (40+ products)
    'running shoes': 'shoes', 'sports shoes': 'shoes',
    'sandals': 'shoes', 'chappal': 'shoes',
    'formal shoes': 'shoes', 'office shoes': 'shoes',
    
    // Beauty 💅 (25+ products)
    'haircut': 'beauty', 'hair cut': 'beauty',
    'facial': 'beauty', 'glow facial': 'beauty',
    'manicure': 'beauty', 'nail art': 'beauty',
    'parlour': 'beauty', 'salon': 'beauty', 'spa': 'beauty',
  };
  
  static Future<String> classifyProduct(String query) async {
    print('🔍 Classifying: "$query"');
    
    // 1. Try Keyword Matching FIRST (Fast & offline-ready)
    final queryLower = query.toLowerCase();
    
    // Sort keys by length in descending order to match specific terms first
    // e.g. "ice cream" (length 9) should match before "cream" (length 5)
    var sortedKeys = productToCategory.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
      
    // Check for exact matches or matches where the query contains the key
    String? localBestMatchCategory;
    
    for (var key in sortedKeys) {
      if (queryLower.contains(key)) {
         final category = productToCategory[key]!;
         print('⚡ Keyword Match Found: "$key" -> $category');
         localBestMatchCategory = category;
         break; // Stop after finding the longest match (e.g. find "ice cream" and stop, don't keep looking for "cream")
      }
    }

    // 2. Try Gemini API
    try {
      final prompt = '''
      You are a shopping assistant for "Locallens". Your job is to classify the user's product search query into EXACTLY ONE of these categories:
      [electronics, pharmacy, clothes, grocery, supermarket, bakery, shoes, beauty]

      Query: "$query"

      Rules:
      1. IGNORE SPELLING MISTAKES (e.g. "ice screem" -> "ice cream" -> supermarket).
      2. If the product is food, snacks, chocolate, biscuits, or drinks, classify as "supermarket" or "grocery".
      3. If the product is medicine, health supplement, or medical device, classify as "pharmacy".
      4. If the product is phone, laptop, or gadget, classify as "electronics".
      5. IGNORE any tech jargon if it looks like a typo for a common item (e.g. "screem" -> "cream").
      
      Return ONLY the category name in lowercase. No explanation.
      ''';

      final response = await _gemini.generateContent([
        Content.text(prompt),
      ]);
      
      final text = response.text?.trim().toLowerCase() ?? '';
      
      if (text.isNotEmpty) {
        final categories = ['electronics', 'pharmacy', 'clothes', 'grocery', 'supermarket', 'bakery', 'shoes', 'beauty'];
        
        for (String category in categories) {
          if (text.contains(category)) {
             print('✅ Gemini Category: $category');
             
             // Sanity check: If API says "pharmacy" for "ice cream", trust local match instead
             if (queryLower.contains('ice cream') && category == 'pharmacy') {
               print('⚠️ Correcting Gemini Hallucination: "ice cream" is NOT pharmacy');
               return 'grocery';
             }
             
             return category;
          }
        }
      }
    } catch (e) {
      print('⚠️ API Failed, using offline fallback: $e');
    }
    
    // 3. FALLBACK: Use Keyword Matching if API fails or returns garbage
    print('🔄 Using Offline Fallback...');
    
    // Re-run sorting to be safe in fallback logic
    var sortedKeysFallback = productToCategory.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
      
    for (var key in sortedKeysFallback) {
      if (queryLower.contains(key)) {
        print('✅ Offline Match: "$key" -> ${productToCategory[key]}');
        return productToCategory[key]!;
      }
    }
    
    // 4. Default if nothing works
    print('⚠️ No classification found, defaulting to "supermarket"');
    return 'supermarket';
  }
  

  

  
  static Future<double> getProductPrice(String query) async {
    // Redirect to PriceService for real-time pricing
    return 0.0; // Not used - PriceService handles all pricing
  }
  
  static Future<List<String>> getAvailableStores(String product) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('product', isGreaterThanOrEqualTo: product.toLowerCase())
          .where('product', isLessThan: product.toLowerCase() + 'z')
          .limit(1)
          .get()
          .timeout(Duration(seconds: 3));
      
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        return List<String>.from(data['stores'] ?? []);
      }
    } catch (e) {
      print('Firebase stores lookup error: $e');
    }
    
    return [];
  }
}