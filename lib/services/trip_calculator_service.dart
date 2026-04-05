import '../models/store.dart';
import '../models/trip_plan.dart';
import 'dart:math';

class TripCalculatorService {
  // Calculate real distance between two points using Haversine formula
  static double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371;
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLng = _degreesToRadians(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) * 
        sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * asin(sqrt(a));
    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) => degrees * (pi / 180);

  // Calculate REAL trip distance from actual stores
  static double calculateRealTripDistance(List<Store> tripStores, TripPlan? finalTripPlan) {
    if (tripStores.isEmpty) return 0.0;
    
    // Use actual trip plan data if available
    if (finalTripPlan != null) {
      return finalTripPlan.totalDistance;
    }
    
    // Calculate real distance between stores
    double totalDistance = 0.0;
    for (int i = 0; i < tripStores.length; i++) {
      if (i == 0) {
        // Distance from user to first store
        totalDistance += tripStores[i].distance;
      } else {
        // Distance between consecutive stores
        totalDistance += calculateDistance(
          tripStores[i-1].lat, tripStores[i-1].lng,
          tripStores[i].lat, tripStores[i].lng
        );
      }
    }
    return totalDistance;
  }

  // Calculate REAL trip time from actual routes
  static int calculateRealTripTime(List<Store> tripStores, TripPlan? finalTripPlan) {
    if (tripStores.isEmpty) return 0;
    
    // Use actual trip plan data if available
    if (finalTripPlan != null) {
      return finalTripPlan.totalTime.round();
    }
    
    // Calculate realistic time: 4 min per km + 12 min per store
    double distance = calculateRealTripDistance(tripStores, finalTripPlan);
    int travelTime = (distance * 4).round(); // 4 min per km
    int storeTime = tripStores.length * 12; // 12 min per store
    return travelTime + storeTime;
  }

  // Calculate REAL CO2 savings from actual trip
  static double calculateRealCO2Savings(List<Store> tripStores, TripPlan? finalTripPlan) {
    if (tripStores.isEmpty) return 0.0;
    
    // Use actual trip plan data if available
    if (finalTripPlan != null) {
      return finalTripPlan.carbonSavings;
    }
    
    // Real CO2 calculation: savings vs individual trips
    double tripDistance = calculateRealTripDistance(tripStores, finalTripPlan);
    double individualTripsDistance = tripStores.length * 7.5; // 7.5km average per individual trip
    double savedDistance = individualTripsDistance - tripDistance;
    return savedDistance * 0.21; // 0.21kg CO2 per km saved
  }

  // Calculate estimates for discovery page (before trip is planned)
  static double calculateEstimatedDistance(List<String> cartProducts) {
    if (cartProducts.isEmpty) return 0.0;
    // Estimate stores needed based on product diversity
    int estimatedStores = (cartProducts.length / 2.5).ceil().clamp(1, 4);
    return estimatedStores * 3.2; // 3.2km average per store
  }

  static int calculateEstimatedTime(List<String> cartProducts) {
    if (cartProducts.isEmpty) return 0;
    int estimatedStores = (cartProducts.length / 2.5).ceil().clamp(1, 4);
    int travelTime = (estimatedStores * 3.2 * 4).round(); // 4 min per km
    int shoppingTime = cartProducts.length * 10; // 10 min per product
    return travelTime + shoppingTime + 20; // +20 min buffer
  }

  static double calculateEstimatedCO2Savings(List<String> cartProducts) {
    if (cartProducts.isEmpty) return 0.0;
    double tripDistance = calculateEstimatedDistance(cartProducts);
    double individualTripsDistance = cartProducts.length * 7.5; // 7.5km per individual trip
    double savedDistance = individualTripsDistance - tripDistance;
    return savedDistance * 0.21; // 0.21kg CO2 per km saved
  }
}