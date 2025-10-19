import 'package:flutter/material.dart';
import '../models/store.dart';
import '../models/trip_plan.dart';

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

  // Mock API calls
  Future<void> searchProduct(String query) async {
    setLoading(true);
    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));
    _stores = [
      Store(
        name: 'Local Grocery Store',
        price: 5.99,
        stockStatus: 'In Stock',
        pickupTime: '10 min',
        carbonFootprint: 0.5,
        isLocal: true,
        isSustainable: true,
        address: '123 Main St',
        latitude: 37.7749,
        longitude: -122.4194,
        freshnessBadge: 'Verified 5 min ago',
      ),
      Store(
        name: 'Big Chain Store',
        price: 6.49,
        stockStatus: 'In Stock',
        pickupTime: '15 min',
        carbonFootprint: 2.0,
        isLocal: false,
        isSustainable: false,
        address: '456 Commerce Ave',
        latitude: 37.7849,
        longitude: -122.4094,
      ),
    ];
    setLoading(false);
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
    setLoading(true);
    // Simulate trip planning
    await Future.delayed(const Duration(seconds: 2));
    _tripPlan = TripPlan(
      stores: _stores,
      totalTime: 30.0,
      totalDistance: 5.0,
      carbonSavings: 1.5,
    );
    setLoading(false);
  }
}
