import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import '../models/store.dart';
import 'product_search_service.dart';

import '../config/env.dart';

class StoreService {
  static final _gemini = GenerativeModel(
    model: 'gemini-2.5-flash',
    apiKey: Env.geminiApiKey,
  );
  
  // Get real user GPS location
  static Future<Position> getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Return default location if GPS disabled
        return Position(
          latitude: 15.0495,
          longitude: 76.2080,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Return default location if permission denied
          return Position(
            latitude: 15.0495,
            longitude: 76.2080,
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
          );
        }
      }

      return await Geolocator.getCurrentPosition();
    } catch (e) {
      print('Location error: $e');
      // Return default location on any error
      return Position(
        latitude: 15.0495,
        longitude: 76.2080,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
    }
  }
  
  // Calculate distance using Geolocator
  static double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    try {
      return Geolocator.distanceBetween(lat1, lng1, lat2, lng2) / 1000; // Convert to km
    } catch (e) {
      // Fallback distance calculation
      const double earthRadius = 6371;
      final dLat = _degreesToRadians(lat2 - lat1);
      final dLng = _degreesToRadians(lng2 - lng1);
      final a = sin(dLat / 2) * sin(dLat / 2) +
          cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) * 
          sin(dLng / 2) * sin(dLng / 2);
      final c = 2 * asin(sqrt(a));
      return earthRadius * c;
    }
  }
  
  static double _degreesToRadians(double degrees) => degrees * (pi / 180);
  
  static Future<String> classifyProduct(String product) async {
    try {
      // Use the new universal product search service
      return await ProductSearchService.classifyProduct(product);
    } catch (e) {
      print('Classification error: $e');
      // Simple fallback classification
      final productLower = product.toLowerCase();
      if (productLower.contains('milk') || productLower.contains('bread') || productLower.contains('rice')) {
        return 'kirana';
      } else if (productLower.contains('medicine') || productLower.contains('tablet')) {
        return 'pharmacy';
      } else if (productLower.contains('phone') || productLower.contains('laptop')) {
        return 'electronics';
      }
      return 'kirana'; // Default fallback
    }
  }
  
  static bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }
  
  static Future<List<Store>> getNearbyStores(String category, double? userLat, double? userLng) async {
    try {
      // Get real user location if not provided
      Position? userPosition;
      if (userLat == null || userLng == null) {
        userPosition = await getUserLocation();
        userLat = userPosition.latitude;
        userLng = userPosition.longitude;
      }
      
      print('🔍 Searching for $category stores near $userLat, $userLng');
      
      // Category-specific store mapping for accurate results
      List<String> storeTypes = _getStoreTypesForCategory(category);
      print('📍 Looking for store types: $storeTypes');
      
      // Try Firebase first with timeout
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('stores')
            .where('category', whereIn: storeTypes)
            .get()
            .timeout(Duration(seconds: 8));
        
        final allStores = snapshot.docs
            .map((doc) => Store.fromFirestore(doc.data()))
            .where((store) => !_isFakeStore(store) && _isRelevantStore(store, category))
            .toList();
        
        // Calculate real distances and filter within 15km
        final nearbyStores = <Store>[];
        for (final store in allStores) {
          final distance = calculateDistance(userLat!, userLng!, store.lat, store.lng);
          if (distance <= 15.0) {
            store.distance = distance;
            nearbyStores.add(store);
          }
        }
        
        // Sort by real distance from user GPS location (closest first)
        nearbyStores.sort((a, b) => a.distance.compareTo(b.distance));
        
        if (nearbyStores.isNotEmpty) {
          print('✅ Found ${nearbyStores.length} relevant stores from Firebase');
          return nearbyStores.take(15).toList();
        }
      } catch (e) {
        print('Firebase timeout or error: $e');
      }
      
      // Try real-world API search for specific categories
      if (category == 'electronics' || category == 'pharmacy') {
        try {
          final realStores = await _searchRealWorldStores(category, userLat!, userLng!);
          if (realStores.isNotEmpty) {
            print('✅ Found ${realStores.length} real-world stores');
            return realStores;
          }
        } catch (e) {
          print('Real-world search failed: $e');
        }
      }
      
      // Fallback to category-specific mock stores
      return _getCategorySpecificStores(userLat ?? 15.0495, userLng ?? 76.2080, category);
    } catch (e) {
      print('Location/Firebase error: $e');
      return _getCategorySpecificStores(userLat ?? 15.0495, userLng ?? 76.2080, category);
    }
  }
  

  
  static double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    return calculateDistance(lat1, lng1, lat2, lng2); // Use the new method
  }
  
  static Future<void> openGoogleMaps(double lat, double lng, String storeName) async {
    // Use store name and coordinates for better accuracy
    final encodedStoreName = Uri.encodeComponent(storeName);
    final url = 'https://www.google.com/maps/search/$encodedStoreName/@$lat,$lng,17z';
    final uri = Uri.parse(url);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
  
  static Future<void> openGoogleMapsWithAddress(double lat, double lng, String storeName, String address) async {
    // Use full address for maximum accuracy
    final encodedQuery = Uri.encodeComponent('$storeName, $address');
    final url = 'https://www.google.com/maps/search/$encodedQuery/@$lat,$lng,18z';
    final uri = Uri.parse(url);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // Filter out fake Firebase entries
  static bool _isFakeStore(Store store) {
    final name = store.name.toLowerCase();
    // Remove fake Croma and other test entries
    if (name.contains('croma')) return true;  // Remove ALL Croma entries
    if (name.contains('test') || name.contains('fake')) return true;
    if (store.lat == 0.0 || store.lng == 0.0) return true;
    return false;
  }
  
  // Get store types for each product category
  static List<String> _getStoreTypesForCategory(String category) {
    switch (category) {
      case 'electronics':
        return ['electronics', 'mobile_shop', 'computer_store', 'tech_store'];
      case 'pharmacy':
        return ['pharmacy', 'medical_store', 'chemist', 'drug_store'];
      case 'clothes':
        return ['clothes', 'fashion', 'garments', 'textile', 'boutique'];
      case 'grocery':
        return ['grocery', 'kirana', 'general_store', 'provision_store'];
      case 'supermarket':
        return ['supermarket', 'hypermarket', 'departmental_store', 'grocery'];
      case 'bakery':
        return ['bakery', 'cake_shop', 'confectionery', 'pastry_shop'];
      case 'shoes':
        return ['shoes', 'footwear', 'shoe_store', 'sandal_shop'];
      case 'beauty':
        return ['beauty', 'salon', 'parlour', 'spa', 'beauty_parlour'];
      default:
        return [category, 'general_store', 'kirana'];
    }
  }
  
  // Check if store is relevant for the searched category
  static bool _isRelevantStore(Store store, String category) {
    final storeName = store.name.toLowerCase();
    final storeCategory = store.category?.toLowerCase() ?? '';
    
    switch (category) {
      case 'electronics':
        return storeName.contains('mobile') || storeName.contains('electronics') || 
               storeName.contains('phone') || storeName.contains('computer') ||
               storeCategory.contains('electronics');
      case 'pharmacy':
        return storeName.contains('pharmacy') || storeName.contains('medical') || 
               storeName.contains('chemist') || storeName.contains('apollo') ||
               storeCategory.contains('pharmacy');
      case 'clothes':
        return storeName.contains('fashion') || storeName.contains('garments') || 
               storeName.contains('textile') || storeName.contains('boutique') ||
               storeCategory.contains('clothes');
      case 'grocery':
        return storeName.contains('kirana') || storeName.contains('grocery') || 
               storeName.contains('general') || storeName.contains('provision') ||
               storeCategory.contains('grocery');
      case 'supermarket':
        return storeName.contains('supermarket') || storeName.contains('hypermarket') || 
               storeName.contains('departmental') || storeName.contains('big bazaar') ||
               storeCategory.contains('supermarket');
      default:
        return true; // Allow all stores for other categories
    }
  }
  
  // Search real-world stores using Overpass API
  static Future<List<Store>> _searchRealWorldStores(String category, double lat, double lng) async {
    String overpassQuery = _buildOverpassQuery(category, lat, lng);
    
    try {
      final url = 'https://overpass-api.de/api/interpreter?data=${Uri.encodeComponent(overpassQuery)}';
      final response = await http.get(Uri.parse(url)).timeout(Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['elements'] as List;
        print('Found ${data.length} real stores for $category');
        
        return data.map<Store>((store) {
          final tags = Map<String, dynamic>.from(store['tags'] ?? {});
          final storeLat = (store['lat'] ?? lat).toDouble();
          final storeLng = (store['lon'] ?? lng).toDouble();
          
          return Store(
            name: tags['name'] ?? _getDefaultStoreName(category),
            address: _buildAddress(tags),
            lat: storeLat,
            lng: storeLng,
            latitude: storeLat,
            longitude: storeLng,
            category: category,
            price: _getDefaultPrice(category),
            carbonFootprint: 0.25,
            pickupTime: '15 mins',
            stockStatus: 'In Stock',
            isLocal: true,
            isSustainable: true,
            distance: calculateDistance(lat, lng, storeLat, storeLng),
          );
        }).toList();
      }
    } catch (e) {
      print('Overpass API error: $e');
    }
    
    return [];
  }
  
  // Build Overpass query for specific categories
  static String _buildOverpassQuery(String category, double lat, double lng) {
    switch (category) {
      case 'electronics':
        return '[out:json][timeout:25];(nwr["shop"="electronics"](around:5000,$lat,$lng);nwr["shop"="mobile_phone"](around:5000,$lat,$lng);nwr["shop"="computer"](around:5000,$lat,$lng););out center;';
      case 'pharmacy':
        return '[out:json][timeout:25];(nwr["amenity"="pharmacy"](around:5000,$lat,$lng);nwr["shop"="chemist"](around:5000,$lat,$lng););out center;';
      case 'clothes':
        return '[out:json][timeout:25];(nwr["shop"="clothes"](around:5000,$lat,$lng);nwr["shop"="fashion"](around:5000,$lat,$lng););out center;';
      default:
        return '[out:json][timeout:25];(nwr["shop"="supermarket"](around:5000,$lat,$lng);nwr["shop"="convenience"](around:5000,$lat,$lng););out center;';
    }
  }
  
  // Get default store name for category
  static String _getDefaultStoreName(String category) {
    switch (category) {
      case 'electronics': return 'Electronics Store';
      case 'pharmacy': return 'Medical Store';
      case 'clothes': return 'Fashion Store';
      case 'grocery': return 'Kirana Store';
      case 'supermarket': return 'Supermarket';
      case 'bakery': return 'Bakery';
      case 'shoes': return 'Footwear Store';
      case 'beauty': return 'Beauty Parlour';
      default: return 'Local Store';
    }
  }
  
  // Get default price for category
  static double _getDefaultPrice(String category) {
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
  
  // Build address from OSM tags
  static String _buildAddress(Map<String, dynamic> tags) {
    List<String> addressParts = [];
    if (tags['addr:street'] != null) addressParts.add(tags['addr:street']);
    if (tags['addr:city'] != null) addressParts.add(tags['addr:city']);
    if (addressParts.isEmpty && tags['addr:full'] != null) addressParts.add(tags['addr:full']);
    return addressParts.isNotEmpty ? addressParts.join(', ') : 'Near you';
  }
  
  // Category-specific fallback stores
  // Category-specific fallback stores
  // Category-specific fallback stores
  static List<Store> _getCategorySpecificStores(double lat, double lng, String category) {
    // Helper to create a store with relative location
    Store createStore({
      required String name,
      required String address,
      required double latOffset,
      required double lngOffset,
      required String category,
      required String pickupTime,
      required double price,
      required double carbonFootprint,
      required String stockStatus,
      required bool isLocal,
      required bool isSustainable,
    }) {
      final storeLat = lat + latOffset;
      final storeLng = lng + lngOffset;
      final dist = calculateDistance(lat, lng, storeLat, storeLng);
      
      return Store(
        name: name,
        address: address,
        lat: storeLat,
        lng: storeLng,
        latitude: storeLat,
        longitude: storeLng,
        category: category,
        pickupTime: pickupTime,
        price: price,
        carbonFootprint: carbonFootprint,
        stockStatus: stockStatus,
        isLocal: isLocal,
        isSustainable: isSustainable,
        distance: dist,
      );
    }

    switch (category) {
      case 'electronics':
        return [
          createStore(
            name: 'Mobile World',
            address: 'Electronics & Mobile Store',
            latOffset: 0.012, // ~1.3km
            lngOffset: 0.005,
            category: 'electronics',
            pickupTime: '20 mins',
            price: 15000.00,
            carbonFootprint: 0.50,
            stockStatus: 'In Stock',
            isLocal: true,
            isSustainable: false,
          ),
          createStore(
            name: 'Tech Hub',
            address: 'Computers & Accessories',
            latOffset: 0.020, // ~2.2km
            lngOffset: 0.015,
            category: 'electronics',
            pickupTime: '30 mins',
            price: 14500.00,
            carbonFootprint: 0.60,
            stockStatus: 'In Stock',
            isLocal: false,
            isSustainable: true,
          ),
        ];
      case 'pharmacy':
        return [
          createStore(
            name: 'City Medical Store',
            address: '24/7 Pharmacy',
            latOffset: 0.005, // ~500m
            lngOffset: 0.002,
            category: 'pharmacy',
            pickupTime: '10 mins',
            price: 85.00,
            carbonFootprint: 0.12,
            stockStatus: 'In Stock',
            isLocal: true,
            isSustainable: true,
          ),
          createStore(
            name: 'Apollo Pharmacy',
            address: 'Trusted Healthcare',
            latOffset: 0.015, // ~1.6km
            lngOffset: 0.008,
            category: 'pharmacy',
            pickupTime: '18 mins',
            price: 82.00,
            carbonFootprint: 0.18,
            stockStatus: 'In Stock',
            isLocal: false,
            isSustainable: true,
          ),
        ];
      case 'clothes':
        return [
          createStore(
            name: 'Fashion Point',
            address: 'Trendy Clothing',
            latOffset: 0.010, // ~1.1km
            lngOffset: 0.005,
            category: 'clothes',
            pickupTime: '15 mins',
            price: 1200.00,
            carbonFootprint: 0.25,
            stockStatus: 'In Stock',
            isLocal: true,
            isSustainable: true,
          ),
        ];
      case 'grocery':
      case 'kirana':
        return [
          createStore(
            name: 'Local Kirana Store',
            address: 'Fresh Groceries',
            latOffset: 0.004, // ~400m
            lngOffset: 0.001,
            category: 'grocery',
            pickupTime: '8 mins',
            price: 44.50,
            carbonFootprint: 0.10,
            stockStatus: 'In Stock',
            isLocal: true,
            isSustainable: true,
          ),
          createStore(
            name: 'Neighborhood Grocery',
            address: 'Daily Essentials',
            latOffset: 0.008, // ~900m
            lngOffset: 0.004,
            category: 'grocery',
            pickupTime: '12 mins',
            price: 42.00,
            carbonFootprint: 0.15,
            stockStatus: 'In Stock',
            isLocal: true,
            isSustainable: true,
          ),
        ];
      case 'supermarket':
        return [
          createStore(
            name: 'Big Bazaar',
            address: 'Hypermarket',
            latOffset: 0.025, // ~2.7km
            lngOffset: 0.015,
            category: 'supermarket',
            pickupTime: '25 mins',
            price: 65.00,
            carbonFootprint: 0.35,
            stockStatus: 'In Stock',
            isLocal: false,
            isSustainable: true,
          ),
        ];
      case 'bakery':
        return [
          createStore(
            name: 'Fresh Bakes',
            address: 'Cakes & Pastries',
            latOffset: 0.006, // ~600m
            lngOffset: 0.003,
            category: 'bakery',
            pickupTime: '12 mins',
            price: 150.00,
            carbonFootprint: 0.15,
            stockStatus: 'In Stock',
            isLocal: true,
            isSustainable: true,
          ),
        ];
      case 'shoes':
        return [
          createStore(
            name: 'Shoe Palace',
            address: 'Footwear Collection',
            latOffset: 0.018, // ~2km
            lngOffset: 0.010,
            category: 'shoes',
            pickupTime: '22 mins',
            price: 2500.00,
            carbonFootprint: 0.40,
            stockStatus: 'In Stock',
            isLocal: true,
            isSustainable: false,
          ),
        ];
      case 'beauty':
        return [
          createStore(
            name: 'Glamour Beauty Parlour',
            address: 'Hair & Beauty Services',
            latOffset: 0.009, // ~1km
            lngOffset: 0.005,
            category: 'beauty',
            pickupTime: '14 mins',
            price: 800.00,
            carbonFootprint: 0.20,
            stockStatus: 'Available',
            isLocal: true,
            isSustainable: true,
          ),
        ];
      default:
        return [
          createStore(
            name: 'Local Store',
            address: 'General Items',
            latOffset: 0.010, // ~1.1km
            lngOffset: 0.005,
            category: category,
            pickupTime: '15 mins',
            price: 50.00,
            carbonFootprint: 0.20,
            stockStatus: 'In Stock',
            isLocal: true,
            isSustainable: true,
          ),
        ];
    }
  }
}