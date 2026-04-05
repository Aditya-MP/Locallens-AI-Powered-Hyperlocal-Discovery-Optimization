import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/community_store.dart';
import '../models/store.dart';

class CommunityService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // VERIFY STOCK (Main method for StockVerificationPage)
  static Future<void> verifyProduct(
    String storeId, 
    String product, 
    String userId, {
    bool inStock = true,
  }) async {
    try {
      final verificationData = {
        'storeId': storeId,
        'product': product,
        'userId': userId,
        'inStock': inStock,
        'verifiedDate': DateTime.now().toIso8601String(),
        'upvotes': 0,
        'downvotes': 0,
        'pointsEarned': 5, // Base points
      };

      // Add to verifications collection
      await _firestore.collection('store_verifications').add(verificationData);
      
      // Create or update store document (SET instead of UPDATE)
      await _firestore.collection('stores').doc(storeId).set({
        'id': storeId,
        'name': storeId.replaceAll('_', ' ').toUpperCase(),
        'verificationCount': FieldValue.increment(1),
        'verifiedProducts': FieldValue.arrayUnion([product]),
        'unlockTier': FieldValue.increment(1),
        'lastVerified': DateTime.now().toIso8601String(),
        'stockStatus': inStock ? 'In Stock' : 'Out of Stock',
        'category': 'general',
        'trustScore': 4.0,
      }, SetOptions(merge: true)); // MERGE instead of overwrite

      // Add user points
      await _firestore.collection('user_points').doc(userId).set({
        'points': FieldValue.increment(5),
        'verifications': FieldValue.increment(1),
        'lastActivity': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));

      print('✅ Verification saved: $product @ $storeId');
    } catch (e) {
      print('❌ Verification error: $e');
      rethrow;
    }
  }

  // Add sample stores for testing
  static Future<void> addSampleStores() async {
    // First, delete any existing fake stores
    await _deleteFakeStores();
    
    final sampleStores = [
      {
        'id': 'local_general_store',
        'name': 'Local General Store',
        'address': 'Main Road, Local Market',
        'lat': 15.0498,
        'lng': 76.2083,
        'category': 'grocery',
        'verificationCount': 0,
        'trustScore': 4.2,
      },
      {
        'id': 'kirana_store_hb',
        'name': 'Kirana Store HB',
        'address': 'Near Bus Stand',
        'lat': 15.0512,
        'lng': 76.2101,
        'category': 'grocery',
        'verificationCount': 0,
        'trustScore': 4.5,
      },
    ];

    for (var store in sampleStores) {
      await _firestore.collection('stores').doc(store['id'] as String).set(store, SetOptions(merge: true));
    }
  }

  // Delete fake stores from Firebase
  static Future<void> _deleteFakeStores() async {
    final fakeStoreIds = ['croma_hb', 'reliance_hb', 'croma_hagaribommanahalli'];
    
    for (String storeId in fakeStoreIds) {
      try {
        await _firestore.collection('stores').doc(storeId).delete();
        print('Deleted fake store: $storeId');
      } catch (e) {
        print('Error deleting $storeId: $e');
      }
    }
  }

  // Get real-time community activity feed
  static Stream<List<Map<String, dynamic>>> getRecentActivity() {
    // Combine multiple collections or use a dedicated 'activity' collection
    // For now, we'll simulate a lively feed mixed with real data
    return _firestore
        .collection('store_verifications')
        .orderBy('verifiedDate', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) {
          final activities = snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'type': 'verification',
              'user': 'User ${data['userId'].toString().substring(0, 4)}',
              'action': 'verified stock for',
              'target': data['product'],
              'time': data['verifiedDate'],
              'icon': 0xe668, // Icons.verified_user
              'color': 0xFF4CAF50, // Colors.green
            };
          }).toList();
          
          // Add some mock activities to make it look alive if empty
          if (activities.length < 5) {
            activities.addAll([
              {
                'type': 'new_store',
                'user': 'Rahul K.',
                'action': 'added a new store',
                'target': 'Fresh Mart',
                'time': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
                'icon': 0xe60e, // Icons.store
                'color': 0xFF9C27B0, // Colors.purple
              },
              {
                'type': 'verification',
                'user': 'Priya S.',
                'action': 'found',
                'target': 'Dolo 650',
                'time': DateTime.now().subtract(const Duration(minutes: 12)).toIso8601String(),
                'icon': 0xe668,
                'color': 0xFF4CAF50,
              },
              {
                'type': 'vote',
                'user': 'Amit22',
                'action': 'upvoted',
                'target': 'City Pharmacy',
                'time': DateTime.now().subtract(const Duration(minutes: 25)).toIso8601String(),
                'icon': 0xe8dc, // Icons.thumb_up
                'color': 0xFF2196F3, // Colors.blue
              },
            ]);
          }
          return activities;
        });
  }

  // Get user leaderboard
  static Stream<List<Map<String, dynamic>>> getLeaderboard() {
    return _firestore
        .collection('user_points')
        .orderBy('points', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'userId': doc.id,
                'username': data['username'] ?? 'User ${doc.id.substring(0, 6)}',
                'points': data['points'] ?? 0,
                'verifications': data['verifications'] ?? 0,
                'trustScore': data['trustScore'] ?? 0.0,
              };
            }).toList());
  }

  // Legacy methods for compatibility
  static Future<void> addCommunityStore(CommunityStore store) async {
    await _firestore.collection('stores').doc(store.id).set(store.toFirestore());
  }

  static Future<void> submitVote(String storeId, String product, String userId, bool isUpvote) async {
    await _firestore.collection('votes').add({
      'storeId': storeId,
      'product': product,
      'userId': userId,
      'isUpvote': isUpvote,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}