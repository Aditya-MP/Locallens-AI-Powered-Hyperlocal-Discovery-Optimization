class Store {
  final String name;
  double price;
  String stockStatus; // Make mutable for dynamic updates
  final String pickupTime;
  final double carbonFootprint;
  final bool isLocal;
  final bool isSustainable;
  final String address;
  final double latitude;
  final double longitude;
  final String freshnessBadge;
  final double lat;
  final double lng;
  double distance; // Make distance mutable for GPS updates
  final String category;
  int verificationCount; // Track verification count
  String? priceRange; // Optional price range for broad category searches

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
    required this.lat,
    required this.lng,
    required this.distance,
    this.category = 'grocery',
    this.verificationCount = 0,
    this.priceRange,
  });

  factory Store.fromFirestore(Map<String, dynamic> json) => Store(
    name: json['name'] ?? 'Local Store',
    address: json['address'] ?? 'Near you',
    category: json['category'] ?? 'grocery',
    pickupTime: json['pickupTime'] ?? '15 mins',
    lat: (json['lat'] ?? 0.0).toDouble(),
    lng: (json['lng'] ?? 0.0).toDouble(),
    latitude: (json['lat'] ?? 0.0).toDouble(),
    longitude: (json['lng'] ?? 0.0).toDouble(),
    price: 45.99,
    carbonFootprint: 0.25,
    stockStatus: 'In Stock',
    isLocal: true,
    isSustainable: true,
    distance: 0.0,
    verificationCount: (json['verificationCount'] ?? 0).toInt(),
  );

  String get formattedPrice {
    if (priceRange != null && priceRange!.isNotEmpty) {
      return priceRange!;
    }
    return '₹${price.toStringAsFixed(0)}';
  }
}
