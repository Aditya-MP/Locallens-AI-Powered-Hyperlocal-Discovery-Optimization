import 'package:flutter/material.dart';
import 'dart:math';
import '../models/store.dart';
import '../models/trip_plan.dart';
import '../services/location_service.dart';
import '../services/ai_search_service.dart';
import '../services/store_service.dart';
import '../services/price_service.dart';
import '../services/voice_search_service.dart';
import '../services/product_search_service.dart';
import 'package:geolocator/geolocator.dart';

class AppProvider with ChangeNotifier {
  List<Store> _stores = [];
  TripPlan? _tripPlan;
  String _searchQuery = '';
  bool _isLoading = false;

  List<Store> get stores => _stores;
  TripPlan? get tripPlan => _tripPlan;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setStores(List<Store> stores) {
    _stores = stores;
    notifyListeners();
  }

  void setTripPlan(TripPlan? plan) {
    _tripPlan = plan;
    notifyListeners();
  }

  // AI-powered search with Firebase and accurate pricing
  Future<void> searchProduct(String query) async {
    if (query.trim().isEmpty) return;
    
    // Clear previous trip plan when starting new search
    _tripPlan = null;
    
    setLoading(true);
    try {
      print('🔍 Searching for: $query');
      
      // Step 1: Parallelize initial data gathering
      // We run classification, location, and price check AT THE SAME TIME
      String category = 'general';
      double userLat = 15.0495;
      double userLng = 76.2080;
      double productPrice = 50.0;
      
      try {
        final results = await Future.wait([
          ProductSearchService.classifyProduct(query), // Index 0
          StoreService.getUserLocation(),              // Index 1
          PriceService.getProductPrice(query),         // Index 2
        ]);
        
        category = results[0] as String;
        final position = results[1] as Position;
        userLat = position.latitude;
        userLng = position.longitude;
        productPrice = results[2] as double;
        
        print('✅ Parallel Data Fetch Complete: Category=$category, Lat=$userLat, Price=$productPrice');
      } catch (e) {
        print('⚠️ One of the parallel tasks failed: $e');
        // Fallback needed if classification fails specifically
        try {
          // If the batch failed, try minimal blocking classification as safety net
          if (category == 'general') {
            category = await ProductSearchService.classifyProduct(query);
          }
        } catch (e2) {
           print('❌ Classification fallback failed: $e2');
           // Proceed with default 'general'
        }
      }
      
      // Step 2: Search category-specific stores with the data we found
      _stores = [];
      
      try {
        _stores = await StoreService.getNearbyStores(category, userLat, userLng);
        print('🏪 Found: ${_stores.length} relevant stores for $category');
        
        // Remove duplicates based on name and location
        _stores = _removeDuplicateStores(_stores);
        
      } catch (e) {
        print('⚠️ Store search failed: $e');
      }
      
      // Step 3: Fast local filtering (NO SECOND AI CALL)
      // We rely on the initial classification and local string matching which is < 10ms
      _stores = _stores.where((store) => _isStoreRelevantForProduct(store, category, query)).toList();
      
      // Step 4: Hybrid Verification (Smart Confidence Filter)
      // Optimized for Speed & Accuracy:
      // 1. Trusted stores (obvious name match) -> Skip AI (Instant)
      // 2. Ambiguous stores (generic names) -> Verify with AI
      if (_stores.isNotEmpty) {
        List<Store> trustedStores = [];
        List<Store> ambiguousStores = [];
        
        for (var store in _stores) {
          if (_isHighConfidenceMatch(store, category, query)) {
            trustedStores.add(store);
          } else {
            ambiguousStores.add(store);
          }
        }
        
        print('⚡ Smart Filter: ${trustedStores.length} trusted (instant), ${ambiguousStores.length} ambiguous (needs AI)');
        
        if (ambiguousStores.isNotEmpty) {
           // Only verify the ambiguous ones
           // This significantly reduces API tokens and latency
           var verifiedAmbiguous = await AISearchService.filterRelevantStores(ambiguousStores, query, category);
           _stores = [...trustedStores, ...verifiedAmbiguous];
        } else {
           _stores = trustedStores;
        }
      }
      
      for (var store in _stores) {
        store.price = productPrice;
        // Add category-specific stock status
        if (category == 'electronics' && query.toLowerCase().contains('phone')) {
          store.stockStatus = store.distance < 2.0 ? 'In Stock' : 'Call to Confirm';
        } else if (category == 'pharmacy') {
          store.stockStatus = 'In Stock';
        }
      }
      
      // Sort by distance (closest first)
      _stores.sort((a, b) => a.distance.compareTo(b.distance));
      
      // Smart Pricing Logic: Range vs Fixed
      // If query is a generic category (e.g. "electronics", "pharmacy"), show range.
      // If query is specific (e.g. "iPhone", "Crocin"), show fixed price.
      final bool isCategorySearch = _isCategorySearch(query);
      
      for (var store in _stores) {
        if (isCategorySearch) {
          store.priceRange = _getPriceRangeForCategory(category);
        } else {
          store.price = productPrice;
          store.priceRange = null; // Ensure specific price is shown
        }
        
        // Add category-specific stock status
        if (category == 'electronics' && query.toLowerCase().contains('phone')) {
          store.stockStatus = store.distance < 2.0 ? 'In Stock' : 'Call to Confirm';
        } else if (category == 'pharmacy') {
          store.stockStatus = 'In Stock';
        }
      }
      
      print('✅ Search completed: ${_stores.length} relevant stores found');
      
    } catch (e) {
      print('❌ CRITICAL ERROR: $e');
      _stores = [
        Store(
          name: 'System Error',
          price: 0.0,
          stockStatus: 'Error',
          pickupTime: 'N/A',
          carbonFootprint: 0.0,
          isLocal: false,
          isSustainable: false,
          address: 'System error occurred. Please check your internet connection and try again.',
          latitude: 15.0495,
          longitude: 76.2080,
          lat: 15.0495,
          lng: 76.2080,
          distance: 0.0,
        ),
      ];
    }
    setLoading(false);
  }

  // Remove duplicate stores based on name and location
  List<Store> _removeDuplicateStores(List<Store> stores) {
    final Map<String, Store> uniqueStores = {};
    
    for (final store in stores) {
      // Create unique key based on name and approximate location
      final key = '${store.name.toLowerCase().trim()}_${store.lat.toStringAsFixed(3)}_${store.lng.toStringAsFixed(3)}';
      
      // Keep the first occurrence
      if (!uniqueStores.containsKey(key)) {
        uniqueStores[key] = store;
      }
    }
    
    return uniqueStores.values.toList();
  }

  List<Store> _createFallbackStores(String query, String category, double lat, double lng, double price) {
    switch (category) {
      case 'pharmacy':
        return [
          Store(
            name: 'Local Pharmacy',
            price: price,
            stockStatus: 'In Stock',
            pickupTime: '15 mins',
            carbonFootprint: 0.2,
            isLocal: true,
            isSustainable: true,
            address: '800m from your location',
            latitude: lat + 0.001,
            longitude: lng + 0.001,
            lat: lat + 0.001,
            lng: lng + 0.001,
            distance: 0.8,
          ),
        ];
      case 'electronics':
        return [
          Store(
            name: 'Tech Store',
            price: price,
            stockStatus: 'In Stock',
            pickupTime: '25 mins',
            carbonFootprint: 0.5,
            isLocal: true,
            isSustainable: false,
            address: '2km from your location',
            latitude: lat + 0.002,
            longitude: lng + 0.002,
            lat: lat + 0.002,
            lng: lng + 0.002,
            distance: 2.0,
          ),
        ];
      default:
        return [
          Store(
            name: 'Local Store',
            price: price,
            stockStatus: 'In Stock',
            pickupTime: '10 mins',
            carbonFootprint: 0.1,
            isLocal: true,
            isSustainable: true,
            address: '500m from your location',
            latitude: lat + 0.0005,
            longitude: lng + 0.0005,
            lat: lat + 0.0005,
            lng: lng + 0.0005,
            distance: 0.5,
          ),
          Store(
            name: 'Nearby Shop',
            price: price + 5,
            stockStatus: 'Low Stock',
            pickupTime: '20 mins',
            carbonFootprint: 0.3,
            isLocal: false,
            isSustainable: true,
            address: '1.5km from your location',
            latitude: lat + 0.0015,
            longitude: lng + 0.0015,
            lat: lat + 0.0015,
            lng: lng + 0.0015,
            distance: 1.5,
          ),
        ];
    }
  }
  
  // Get default price based on category
  double _getDefaultPriceForCategory(String category) {
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
  
  // Check if store is relevant for the searched product
  bool _isStoreRelevantForProduct(Store store, String category, String query) {
    final storeName = store.name.toLowerCase();
    final queryLower = query.toLowerCase();
    
    // Always allow stores that match the category
    if (store.category?.toLowerCase() == category) return true;
    
    // Category-specific relevance checks
    switch (category) {
      case 'electronics':
        if (queryLower.contains('phone') || queryLower.contains('mobile')) {
          return storeName.contains('mobile') || storeName.contains('phone') || 
                 storeName.contains('electronics') || storeName.contains('tech');
        }
        return storeName.contains('electronics') || storeName.contains('computer') || 
               storeName.contains('tech') || storeName.contains('mobile');
      
      case 'pharmacy':
        return storeName.contains('pharmacy') || storeName.contains('medical') || 
               storeName.contains('chemist') || storeName.contains('apollo') ||
               storeName.contains('drug') || storeName.contains('health');
      
      case 'clothes':
        return storeName.contains('fashion') || storeName.contains('garments') || 
               storeName.contains('textile') || storeName.contains('boutique') ||
               storeName.contains('clothes') || storeName.contains('apparel');
      
      case 'grocery':
        return storeName.contains('kirana') || storeName.contains('grocery') || 
               storeName.contains('general') || storeName.contains('provision') ||
               storeName.contains('fresh') || storeName.contains('mart');
      
      case 'supermarket':
        // Supermarkets can sell snacks, chocolates, etc.
        return storeName.contains('supermarket') || storeName.contains('hypermarket') || 
               storeName.contains('departmental') || storeName.contains('big bazaar') ||
               storeName.contains('reliance') || storeName.contains('more') ||
               storeName.contains('grocery') || storeName.contains('mart');
      
      case 'bakery':
        return storeName.contains('bakery') || storeName.contains('cake') || 
               storeName.contains('pastry') || storeName.contains('bread') ||
               storeName.contains('confectionery');
      
      case 'shoes':
        return storeName.contains('shoe') || storeName.contains('footwear') || 
               storeName.contains('sandal') || storeName.contains('nike') ||
               storeName.contains('adidas') || storeName.contains('bata');
      
      case 'beauty':
        return storeName.contains('beauty') || storeName.contains('salon') || 
               storeName.contains('parlour') || storeName.contains('spa') ||
               storeName.contains('hair') || storeName.contains('cosmetic');
      
      default:
        return true; // Allow all stores for unknown categories
    }
  }

  // Check if a store is a "Trusted" match (skip AI verification)
  bool _isHighConfidenceMatch(Store store, String category, String query) {
     final name = store.name.toLowerCase();
     
     // 1. Exact Category Name Match in Store Name
     // e.g. "Apollo Pharmacy" contains "pharmacy"
     if (name.contains(category.toLowerCase())) return true;
     
     // 2. Strong Category Keywords
     switch (category) {
       case 'pharmacy':
         return name.contains('medical') || name.contains('chemist') || name.contains('drug') || name.contains('health');
       case 'grocery':
         return name.contains('supermarket') || name.contains('kirana') || name.contains('provision') || name.contains('mart');
       case 'electronics':
         return name.contains('mobile') || name.contains('digi') || name.contains('tech');
       case 'bakery':
         return name.contains('cake') || name.contains('bread') || name.contains('sweet');
     }
     
     return false;
  }

  // Check if the user query is just a broad category name
  bool _isCategorySearch(String query) {
    final q = query.toLowerCase().trim();
    final categories = [
      'grocery', 'groceries', 'supermarket', 'mart',
      'pharmacy', 'medicine', 'medical', 'drug store',
      'electronics', 'gadgets', 'phone store',
      'clothes', 'fashion', 'apparel',
      'bakery', 'cake shop', 'sweets',
      'shoes', 'footwear',
      'beauty', 'salon', 'parlour'
    ];
    return categories.contains(q) || categories.any((c) => q.contains(c) && q.length < c.length + 5);
  }

  // Get display price range for broad categories
  String _getPriceRangeForCategory(String category) {
    switch (category) {
      case 'electronics': return '₹500 - ₹1L+';
      case 'pharmacy': return '₹20 - ₹5000';
      case 'clothes': return '₹300 - ₹5000';
      case 'grocery': return '₹20 - ₹2000';
      case 'supermarket': return '₹10 - ₹5000+';
      case 'bakery': return '₹50 - ₹1000';
      case 'shoes': return '₹500 - ₹5000';
      case 'beauty': return '₹200 - ₹5000';
      default: return 'Starts @ ₹50';
    }
  }

  Future<void> uploadImage(String imagePath) async {
    setLoading(true);
    // Simulate image processing
    await Future.delayed(const Duration(seconds: 2));
    await searchProduct('identified product');
  }

  Future<void> voiceSearch() async {
    setLoading(true);
    // Simulate voice processing
    await Future.delayed(const Duration(seconds: 2));
    await searchProduct('voice identified product');
  }

  Future<void> planTrip() async {
    if (_stores.isEmpty) return;
    
    // Always clear previous trip plan for fresh calculation
    _tripPlan = null;
    notifyListeners();
    
    setLoading(true);
    
    try {
      // Get current location for accurate calculations
      double userLat = 15.0495;
      double userLng = 76.2080;
      try {
        final position = await StoreService.getUserLocation();
        userLat = position.latitude;
        userLng = position.longitude;
      } catch (e) {
        print('Using default location for trip planning');
      }
      
      // Calculate real distances and optimize route
      List<Store> optimizedStores = List.from(_stores);
      
      // Sort by distance from user location for optimal route
      optimizedStores.sort((a, b) {
        double distA = _calculateRealDistance(userLat, userLng, a.lat, a.lng);
        double distB = _calculateRealDistance(userLat, userLng, b.lat, b.lng);
        return distA.compareTo(distB);
      });
      
      // Calculate total trip metrics with timestamp for uniqueness
      double totalDistance = 0.0;
      double totalTime = 0.0;
      double carbonSavings = 0.0;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      print('🕐 Trip calculation started at: $timestamp');
      
      // Add random variation to prevent caching (0.1-0.3km)
      double randomVariation = (timestamp % 200) / 1000.0;
      
      // Distance from user to first store
      if (optimizedStores.isNotEmpty) {
        double firstStoreDistance = _calculateRealDistance(userLat, userLng, optimizedStores[0].lat, optimizedStores[0].lng);
        totalDistance += firstStoreDistance + randomVariation;
        print('🏠→🏪 User to first store: ${firstStoreDistance.toStringAsFixed(2)}km + ${randomVariation.toStringAsFixed(3)}km variation');
      }
      
      // Distance between consecutive stores
      for (int i = 0; i < optimizedStores.length - 1; i++) {
        double segmentDistance = _calculateRealDistance(
          optimizedStores[i].lat, optimizedStores[i].lng,
          optimizedStores[i + 1].lat, optimizedStores[i + 1].lng
        );
        totalDistance += segmentDistance;
        print('🏪→🏪 Store ${i+1} to ${i+2}: ${segmentDistance.toStringAsFixed(2)}km');
      }
      
      print('📏 Final calculated distance: ${totalDistance.toStringAsFixed(2)}km');
      
      // Calculate realistic travel time (accounting for traffic, stops)
      totalTime = _calculateTravelTime(totalDistance, optimizedStores.length);
      
      // Calculate carbon savings (vs driving to each store separately)
      carbonSavings = _calculateCarbonSavings(totalDistance, optimizedStores.length);
      
      _tripPlan = TripPlan(
        stores: optimizedStores,
        totalTime: totalTime,
        totalDistance: totalDistance,
        carbonSavings: carbonSavings,
      );
      
      print('🚗 Trip calculated: ${totalDistance.toStringAsFixed(1)}km, ${totalTime.toStringAsFixed(0)}min, ${carbonSavings.toStringAsFixed(1)}kg CO2 saved');
      
    } catch (e) {
      print('Trip planning error: $e');
      // Fallback with basic calculations
      _tripPlan = TripPlan(
        stores: _stores,
        totalTime: _stores.length * 8.0 + 15.0,
        totalDistance: _stores.length * 1.2 + 0.8,
        carbonSavings: _stores.length * 0.3,
      );
    }
    
    setLoading(false);
  }
  
  // Calculate real distance using Haversine formula
  double _calculateRealDistance(double lat1, double lng1, double lat2, double lng2) {
    if (lat1 == lat2 && lng1 == lng2) return 0.0; // Same location
    
    const double earthRadius = 6371; // km
    final dLat = (lat2 - lat1) * (pi / 180);
    final dLng = (lng2 - lng1) * (pi / 180);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180)) * cos(lat2 * (pi / 180)) * 
        sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * asin(sqrt(a));
    final distance = earthRadius * c;
    
    // Ensure minimum realistic distance for city travel
    return distance < 0.1 ? 0.1 : distance;
  }
  
  // Calculate realistic travel time
  double _calculateTravelTime(double distance, int storeCount) {
    // Base travel time: 25 km/h average speed in city
    double travelTime = (distance / 25.0) * 60; // minutes
    
    // Add time for each store visit (5-10 minutes per store)
    double storeTime = storeCount * 7.5;
    
    // Add buffer for traffic, parking, etc.
    double bufferTime = distance * 2.0; // 2 minutes per km for city traffic
    
    return travelTime + storeTime + bufferTime;
  }
  
  // Calculate carbon savings vs individual trips
  double _calculateCarbonSavings(double optimizedDistance, int storeCount) {
    // Average individual trip distance per store
    double individualTripsDistance = storeCount * 3.5; // 3.5km average per store
    
    // Carbon emission: 0.21 kg CO2 per km for average car
    double optimizedEmissions = optimizedDistance * 0.21;
    double individualEmissions = individualTripsDistance * 0.21;
    
    return individualEmissions - optimizedEmissions;
  }
  
  // Force refresh trip plan with new calculations
  void refreshTripPlan() {
    _tripPlan = null;
    notifyListeners();
    if (_stores.isNotEmpty) {
      planTrip();
    }
  }
}