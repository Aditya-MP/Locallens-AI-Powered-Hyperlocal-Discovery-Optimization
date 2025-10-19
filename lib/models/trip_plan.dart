import 'store.dart';

class TripPlan {
  final List<Store> stores;
  final double totalTime;
  final double totalDistance;
  final double carbonSavings;

  TripPlan({
    required this.stores,
    required this.totalTime,
    required this.totalDistance,
    required this.carbonSavings,
  });
}
