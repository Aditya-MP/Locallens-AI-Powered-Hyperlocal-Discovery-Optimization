class Store {
  final String name;
  final double price;
  final String stockStatus;
  final String pickupTime;
  final double carbonFootprint;
  final bool isLocal;
  final bool isSustainable;
  final String address;
  final double latitude;
  final double longitude;
  final String freshnessBadge;

  Store({
    required this.name,
    required this.price,
    required this.stockStatus,
    required this.pickupTime,
    required this.carbonFootprint,
    required this.isLocal,
    required this.isSustainable,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.freshnessBadge = '',
  });
}
