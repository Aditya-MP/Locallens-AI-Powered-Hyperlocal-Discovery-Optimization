import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/store.dart';
import 'store_service.dart';
import 'product_search_service.dart';

class TripPlannerService {
  // MAIN FUNCTION: products → optimized stores → Google Maps URL
  static Future<void> planTrip(List<String> products, {bool optimize = true}) async {
    print('🗺️ Planning trip for: $products');
    
    // 1. Get USER current location
    final userPosition = await StoreService.getUserLocation();
    
    // 2. Classify each product → category
    List<String> categories = [];
    for (String product in products) {
      String category = await ProductSearchService.classifyProduct(product);
      categories.add(category);
      print('📦 "$product" → $category');
    }
    
    // 3. Get BEST store for each category (closest to user)
    List<Store> selectedStores = [];
    Set<String> uniqueCategories = categories.toSet(); // Avoid duplicates
    
    for (String category in uniqueCategories) {
      List<Store> categoryStores = await StoreService.getNearbyStores(category, userPosition.latitude, userPosition.longitude);
      if (categoryStores.isNotEmpty) {
        selectedStores.add(categoryStores.first); // Closest store
        print('🏪 $category → ${categoryStores.first.name} (${categoryStores.first.distance.toStringAsFixed(1)}km)');
      }
    }
    
    // 4. Optimize route (simple: sort by distance from user)
    if (optimize) {
      selectedStores.sort((a, b) => 
        StoreService.calculateDistance(userPosition.latitude, userPosition.longitude, a.lat, a.lng)
          .compareTo(StoreService.calculateDistance(userPosition.latitude, userPosition.longitude, b.lat, b.lng))
      );
    }
    
    // 5. Build Google Maps multi-stop URL
    String mapsUrl = await _buildMapsUrl(userPosition, selectedStores);
    
    // 6. Launch Maps
    await launchUrl(Uri.parse(mapsUrl), mode: LaunchMode.externalApplication);
    
    print('✅ Trip planned! ${selectedStores.length} stores → Maps opened');
  }
  
  // Build Google Maps Directions URL with multiple waypoints
  static Future<String> _buildMapsUrl(Position userPos, List<Store> stores) async {
    if (stores.isEmpty) {
      return 'https://www.google.com/maps/search/?api=1&query=${userPos.latitude},${userPos.longitude}';
    }
    
    String waypoints = '';
    for (int i = 0; i < stores.length - 1 && i < 8; i++) { // Max 9 waypoints
      waypoints += '${stores[i].lat},${stores[i].lng}|';
    }
    
    // Last store as destination
    final destination = stores.last;
    
    return 'https://www.google.com/maps/dir/?api=1'
        '&origin=${userPos.latitude},${userPos.longitude}'
        '&destination=${destination.lat},${destination.lng}'
        '&waypoints=$waypoints'
        '&travelmode=driving';
  }
}