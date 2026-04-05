class CommunityStore {
  final String id;
  final String name;
  final String address;
  final double lat, lng;
  final String category;
  final String addedBy;
  final DateTime addedDate;
  final int verificationCount;
  final double trustScore;
  final List<String> verifiedProducts;
  final int upvotes, downvotes;

  CommunityStore({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.category,
    required this.addedBy,
    required this.addedDate,
    this.verificationCount = 0,
    this.trustScore = 0.0,
    this.verifiedProducts = const [],
    this.upvotes = 0,
    this.downvotes = 0,
  });

  factory CommunityStore.fromFirestore(Map<String, dynamic> json) {
    return CommunityStore(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unnamed Store',
      address: json['address'] ?? '',
      lat: (json['lat'] ?? 0.0).toDouble(),
      lng: (json['lng'] ?? 0.0).toDouble(),
      category: json['category'] ?? 'grocery',
      addedBy: json['addedBy'] ?? '',
      addedDate: DateTime.parse(json['addedDate'] ?? DateTime.now().toIso8601String()),
      verificationCount: json['verificationCount'] ?? 0,
      trustScore: (json['trustScore'] ?? 0.0).toDouble(),
      verifiedProducts: List<String>.from(json['verifiedProducts'] ?? []),
      upvotes: json['upvotes'] ?? 0,
      downvotes: json['downvotes'] ?? 0,
    );
  }

  // Factory for creating from Firestore with document ID
  factory CommunityStore.fromFirestoreWithId(Map<String, dynamic> json, String id) {
    return CommunityStore(
      id: id,
      name: json['name'] ?? 'Unnamed Store',
      address: json['address'] ?? '',
      lat: (json['lat'] ?? 0.0).toDouble(),
      lng: (json['lng'] ?? 0.0).toDouble(),
      category: json['category'] ?? 'unknown',
      addedBy: json['addedBy'] ?? '',
      addedDate: DateTime.parse(json['addedDate'] ?? DateTime.now().toIso8601String()),
      verificationCount: json['verificationCount'] ?? 0,
      trustScore: (json['trustScore'] ?? 0.0).toDouble(),
      verifiedProducts: List<String>.from(json['verifiedProducts'] ?? []),
      upvotes: json['upvotes'] ?? 0,
      downvotes: json['downvotes'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'lat': lat,
      'lng': lng,
      'category': category,
      'addedBy': addedBy,
      'addedDate': addedDate.toIso8601String(),
      'verificationCount': verificationCount,
      'trustScore': trustScore,
      'verifiedProducts': verifiedProducts,
      'upvotes': upvotes,
      'downvotes': downvotes,
    };
  }
}