import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import '../models/store.dart';

import '../config/env.dart';

class AISearchService {
  static final _gemini = GenerativeModel(
    model: 'gemini-2.5-flash',
    apiKey: Env.geminiApiKey,
  );

  static Future<String> classifyProductCategory(String product) async {
    final prompt = 'For product "$product", return the exact store type where it is sold. Choose ONLY one from: supermarket, pharmacy, convenience, grocery, bakery, clothes, electronics, hardware, books, sports. For medicine/drugs return pharmacy, for food/snacks/chocolate/fruits return supermarket.';
    
    final response = await _gemini.generateContent([Content.text(prompt)]);
    String result = response.text!.trim().toLowerCase();
    print('Gemini classified "$product" as: $result');
    return result;
  }

  static Future<List<Store>> searchRealStores(String category, double lat, double lng) async {
    print('🌍 Searching real stores for $category near $lat, $lng');
    
    // Category-specific Overpass queries for better accuracy
    String overpassQuery = _buildCategoryQuery(category, lat, lng);
    
    try {
      final url = 'https://overpass-api.de/api/interpreter?data=${Uri.encodeComponent(overpassQuery)}';
      final response = await http.get(Uri.parse(url)).timeout(Duration(seconds: 12));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['elements'] as List;
        print('📍 Found ${data.length} real stores for $category');
        
        if (data.isNotEmpty) {
          List<Store> stores = data.map<Store>((store) {
            final tags = Map<String, dynamic>.from(store['tags'] ?? {});
            final storeLat = (store['lat'] ?? lat).toDouble();
            final storeLng = (store['lon'] ?? lng).toDouble();
            
            return Store(
              name: _getStoreName(tags, category),
              address: _buildStoreAddress(tags),
              lat: storeLat,
              lng: storeLng,
              latitude: storeLat,
              longitude: storeLng,
              category: category,
              price: _getCategoryPrice(category),
              carbonFootprint: 0.25,
              pickupTime: _getPickupTime(lat, lng, storeLat, storeLng),
              stockStatus: 'In Stock',
              isLocal: true,
              isSustainable: true,
              distance: _calculateDistance(lat, lng, storeLat, storeLng),
            );
          }).toList();
          
          // Filter and sort by distance
          stores = stores.where((store) => store.distance <= 10.0).toList();
          stores.sort((a, b) => a.distance.compareTo(b.distance));
          
          return stores.take(10).toList();
        }
      }
    } catch (e) {
      print('Real store search error: $e');
    }
    
    // Enhanced fallback with category-specific stores
    return _getCategoryFallbackStores(lat, lng, category);
  }


  static double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371;
    double dLat = _degToRad(lat2 - lat1);
    double dLng = _degToRad(lng2 - lng1);
    double a = sin(dLat / 2) * sin(dLat / 2) +
               cos(_degToRad(lat1)) * cos(_degToRad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    double c = 2 * asin(sqrt(a));
    return earthRadius * c;
  }

  static double _degToRad(double deg) => deg * (pi / 180.0);
  
  // Build category-specific Overpass queries
  static String _buildCategoryQuery(String category, double lat, double lng) {
    switch (category) {
      case 'electronics':
        return '[out:json][timeout:25];(nwr["shop"="electronics"](around:5000,$lat,$lng);nwr["shop"="mobile_phone"](around:5000,$lat,$lng);nwr["shop"="computer"](around:5000,$lat,$lng););out center;';
      case 'pharmacy':
        return '[out:json][timeout:25];(nwr["amenity"="pharmacy"](around:5000,$lat,$lng);nwr["shop"="chemist"](around:5000,$lat,$lng););out center;';
      case 'clothes':
        return '[out:json][timeout:25];(nwr["shop"="clothes"](around:5000,$lat,$lng);nwr["shop"="fashion"](around:5000,$lat,$lng););out center;';
      case 'grocery':
        return '[out:json][timeout:25];(nwr["shop"="grocery"](around:5000,$lat,$lng);nwr["shop"="convenience"](around:5000,$lat,$lng););out center;';
      case 'supermarket':
        return '[out:json][timeout:25];(nwr["shop"="supermarket"](around:5000,$lat,$lng);nwr["shop"="department_store"](around:5000,$lat,$lng););out center;';
      case 'bakery':
        return '[out:json][timeout:25];(nwr["shop"="bakery"](around:5000,$lat,$lng);nwr["shop"="confectionery"](around:5000,$lat,$lng););out center;';
      case 'shoes':
        return '[out:json][timeout:25];(nwr["shop"="shoes"](around:5000,$lat,$lng););out center;';
      case 'beauty':
        return '[out:json][timeout:25];(nwr["shop"="beauty"](around:5000,$lat,$lng);nwr["shop"="hairdresser"](around:5000,$lat,$lng););out center;';
      default:
        return '[out:json][timeout:25];(nwr["shop"="general"](around:5000,$lat,$lng);nwr["shop"="convenience"](around:5000,$lat,$lng););out center;';
    }
  }
  
  // Get appropriate store name based on tags and category
  static String _getStoreName(Map<String, dynamic> tags, String category) {
    if (tags['name'] != null && tags['name'].toString().isNotEmpty) {
      return tags['name'];
    }
    
    String shopType = tags['shop'] ?? tags['amenity'] ?? '';
    switch (category) {
      case 'electronics':
        return shopType.contains('mobile') ? 'Mobile Store' : 'Electronics Store';
      case 'pharmacy':
        return 'Medical Store';
      case 'clothes':
        return 'Fashion Store';
      case 'grocery':
        return 'Grocery Store';
      case 'supermarket':
        return 'Supermarket';
      case 'bakery':
        return 'Bakery';
      case 'shoes':
        return 'Footwear Store';
      case 'beauty':
        return 'Beauty Salon';
      default:
        return 'Local Store';
    }
  }
  
  // Build store address from OSM tags
  static String _buildStoreAddress(Map<String, dynamic> tags) {
    List<String> addressParts = [];
    if (tags['addr:street'] != null) addressParts.add(tags['addr:street']);
    if (tags['addr:city'] != null) addressParts.add(tags['addr:city']);
    if (addressParts.isEmpty && tags['addr:full'] != null) addressParts.add(tags['addr:full']);
    return addressParts.isNotEmpty ? addressParts.join(', ') : 'Near you';
  }
  
  // Get category-specific pricing
  static double _getCategoryPrice(String category) {
    switch (category) {
      case 'electronics': return 15000.0;
      case 'pharmacy': return 85.0;
      case 'clothes': return 1200.0;
      case 'grocery': return 45.0;
      case 'supermarket': return 65.0;
      case 'bakery': return 150.0;
      case 'shoes': return 2500.0;
      case 'beauty': return 800.0;
      default: return 50.0;
    }
  }
  
  // Calculate pickup time based on distance
  static String _getPickupTime(double userLat, double userLng, double storeLat, double storeLng) {
    double distance = _calculateDistance(userLat, userLng, storeLat, storeLng);
    int minutes = (distance * 8 + 5).round(); // 8 mins per km + 5 mins base
    return '$minutes mins';
  }
  



  // Filter stores using Gemini for strict relevance
  static Future<List<Store>> filterRelevantStores(List<Store> stores, String query, String category) async {
    if (stores.isEmpty) return [];
    
    // Optimization: Only verify the top 15 candidates to save time/tokens
    final candidates = stores.take(15).toList();
    final remaining = stores.skip(15).toList();
    
    print('🤖 Gemini Verifying ${candidates.length} stores for query: "$query" (Category: $category)');
    
    try {
      final storeList = candidates.map((s) => s.name).toList();
      final prompt = '''
      You are a strict data validator for a shopping app.
      User Query: "$query"
      Category: "$category"
      
      Store List:
      ${storeList.asMap().entries.map((e) => "${e.key}: ${e.value}").join('\n')}
      
      Task: Return a JSON list of INDICES (integers) of stores that are RELEVANT to selling the product in the query.
      
      Rules:
      1. EXCLUDE banks, ATMs, post offices, schools, corporate offices, and residential buildings.
      2. EXCLUDE unmatched categories (e.g. if query is "medicine", exclude "Electronics Store").
      3. INCLUDE general stores, supermarkets, and relevant specialty stores.
      4. If unsure, err on the side of EXCLUDING.
      
      Example Output format: [0, 2, 5]
      Return ONLY the JSON list.
      ''';

      final response = await _gemini.generateContent([Content.text(prompt)]);
      final text = response.text?.trim() ?? '[]';
      
      print('🤖 Verification Response: $text');
      
      // Parse response to get indices
      final cleanText = text.replaceAll(RegExp(r'[^\d,\[\]]'), ''); // Remove markdown code blocks if any
      final List<dynamic> indicesJson = jsonDecode(cleanText);
      final Set<int> validIndices = indicesJson.map((e) => e as int).toSet();
      
      final filteredStores = <Store>[];
      for (int i = 0; i < candidates.length; i++) {
        if (validIndices.contains(i)) {
          filteredStores.add(candidates[i]);
        }
      }
      
      // Add back any stores we skipped from verification (optional, but safer to assume they are okay if we didn't check? or safer to drop? Let's drop for strictness if we have enough results)
      // Since user wants "verification", we should only show verified ones if possible.
      // But if we filtered excessively, we might show nothing.
      // Let's verify the top 15 and return them.
      
      print('✅ Verification complete: Kept ${filteredStores.length}/${candidates.length} stores');
      return filteredStores;
      
    } catch (e) {
      print('❌ AI Verification failed: $e');
      // Fallback: Return original candidates if AI fails to avoid empty screen
      return candidates;
    }
  }

  // Category-specific fallback stores
  static List<Store> _getCategoryFallbackStores(double lat, double lng, String category) {
    switch (category) {
      case 'electronics':
        return [
          Store(
            name: 'Mobile World',
            address: '1.2km - Electronics & Mobile',
            lat: lat + 0.002,
            lng: lng + 0.001,
            latitude: lat + 0.002,
            longitude: lng + 0.001,
            category: category,
            price: 15000.0,
            carbonFootprint: 0.3,
            pickupTime: '18 mins',
            stockStatus: 'In Stock',
            isLocal: true,
            isSustainable: true,
            distance: _calculateDistance(lat, lng, lat + 0.002, lng + 0.001),
          ),
        ];
      case 'pharmacy':
        return [
          Store(
            name: 'City Medical Store',
            address: '800m - 24/7 Pharmacy',
            lat: lat + 0.0015,
            lng: lng + 0.0005,
            latitude: lat + 0.0015,
            longitude: lng + 0.0005,
            category: category,
            price: 85.0,
            carbonFootprint: 0.15,
            pickupTime: '12 mins',
            stockStatus: 'In Stock',
            isLocal: true,
            isSustainable: true,
            distance: _calculateDistance(lat, lng, lat + 0.0015, lng + 0.0005),
          ),
        ];
      default:
        return [
          Store(
            name: 'Local Store',
            address: '500m walk',
            lat: lat + 0.001,
            lng: lng,
            latitude: lat + 0.001,
            longitude: lng,
            category: category,
            price: 50.0,
            carbonFootprint: 0.1,
            pickupTime: '8 mins',
            stockStatus: 'In Stock',
            isLocal: true,
            isSustainable: true,
            distance: _calculateDistance(lat, lng, lat + 0.001, lng),
          ),
        ];
    }
  }
}