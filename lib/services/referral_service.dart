import 'package:cloud_firestore/cloud_firestore.dart';

class ReferralService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static String? currentUserId;

  // Initialize persistent user ID using simple static variable
  static Future<void> initializeUserId() async {
    if (currentUserId != null) return;
    
    // Use a FIXED user ID for testing - replace with actual auth later
    currentUserId = 'user_test_12345'; // Fixed ID for testing
    
    print('✅ User ID initialized: $currentUserId');
  }

  // Generate unique referral code
  static Future<String> generateReferralCode() async {
    print('Generating referral code for user: $currentUserId');
    
    final userRef = _firestore.collection('users').doc(currentUserId);
    final code = '${currentUserId!.substring(5, 11)}${DateTime.now().millisecondsSinceEpoch % 10000}';
    
    print('Generated code: $code');
    print('Writing to Firebase path: users/$currentUserId');
    
    await userRef.set({
      'referralCode': code,
      'referralLink': 'https://locallens.page.link/?link=https://locallens.com/ref/$code',
      'referralsCount': 0,
      'successfulReferrals': 0,
      'referralPoints': 0,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    
    print('✅ Referral code saved to Firebase');
    return code;
  }

  // Get user's referral data
  static Future<Map<String, dynamic>> getReferralStats() async {
    print('Getting referral stats for user: $currentUserId');
    
    final doc = await _firestore.collection('users').doc(currentUserId).get();
    
    if (doc.exists) {
      print('Found existing user data: ${doc.data()}');
      return doc.data()!;
    } else {
      print('No user data found, returning defaults');
      return {
        'referralCode': 'N/A',
        'referralsCount': 0,
        'successfulReferrals': 0,
        'referralPoints': 0,
      };
    }
  }

  // Process referral (when friend opens link) - PREVENT DUPLICATES
  static Future<void> processReferral(String referralCode) async {
    // Check if this user already processed this referral code
    final existingReferral = await _firestore
        .collection('users')
        .doc(currentUserId!)
        .get();
    
    if (existingReferral.exists && existingReferral.data()!['referredBy'] == referralCode) {
      print('⚠️ Referral already processed for this user');
      return; // Prevent duplicate processing
    }

    final referrerDoc = await _firestore
        .collection('users')
        .where('referralCode', isEqualTo: referralCode)
        .limit(1)
        .get();

    if (referrerDoc.docs.isNotEmpty) {
      final referrerId = referrerDoc.docs.first.id;
      
      // Prevent self-referral
      if (referrerId == currentUserId) {
        print('⚠️ Cannot refer yourself');
        return;
      }
      
      // Credit referrer +₹50
      await _firestore.collection('users').doc(referrerId).update({
        'referralsCount': FieldValue.increment(1),
        'referralPoints': FieldValue.increment(50),
      });

      // Credit new user +₹50 and mark as referred
      await _firestore.collection('users').doc(currentUserId!).set({
        'referredBy': referralCode,
        'referralPoints': FieldValue.increment(50),
        'firstPurchase': false,
      }, SetOptions(merge: true));

      print('✅ Referral success! Both got ₹50 credit');
    }
  }

  // Check if friend made first purchase
  static Future<void> markFirstPurchase() async {
    final userDoc = _firestore.collection('users').doc(currentUserId);
    final doc = await userDoc.get();
    
    if (doc.exists && !(doc.data()!['firstPurchase'] ?? false)) {
      final referredBy = doc.data()!['referredBy'];
      
      if (referredBy != null) {
        final referrerDoc = await _firestore
            .collection('users')
            .where('referralCode', isEqualTo: referredBy)
            .limit(1)
            .get();
            
        if (referrerDoc.docs.isNotEmpty) {
          final referrerId = referrerDoc.docs.first.id;
          
          // Get referrer's total successful referrals
          final referrerData = await _firestore.collection('users').doc(referrerId).get();
          final successfulCount = (referrerData.data()?['successfulReferrals'] ?? 0) + 1;
          
          // Generate tiered discount coupon
          final discountTier = _getDiscountTier(successfulCount);
          final couponCode = _generateCouponCode(discountTier, referrerId);
          
          // Create coupon
          await _firestore.collection('coupons').add({
            'code': couponCode,
            'userId': referrerId,
            'discountPercent': discountTier,
            'maxDiscountAmount': discountTier * 50,  // 5%=₹250, 10%=₹500, 20%=₹1000
            'usesLeft': 5,  // 5 uses per coupon
            'createdAt': FieldValue.serverTimestamp(),
            'expiresAt': Timestamp.fromDate(DateTime.now().add(Duration(days: 90))),
            'tier': successfulCount,  // Track which tier unlocked it
          });
          
          // Update referrer stats
          await _firestore.collection('users').doc(referrerId).update({
            'successfulReferrals': FieldValue.increment(1),
            'referralPoints': FieldValue.increment(100),  // Bonus points
            'couponsUnlocked': FieldValue.arrayUnion([couponCode]),
          });
        }
      }
      
      await userDoc.update({'firstPurchase': true});
    }
  }

  // Tier logic
  static int _getDiscountTier(int successfulReferrals) {
    if (successfulReferrals >= 10) return 25;  // 25% OFF
    if (successfulReferrals >= 5) return 20;   // 20% OFF
    if (successfulReferrals >= 3) return 15;   // 15% OFF
    if (successfulReferrals >= 1) return 10;   // 10% OFF
    return 5;  // 5% OFF
  }

  static String _generateCouponCode(int discountPercent, String userId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(6);
    return 'LL${discountPercent}%${userId.substring(5, 9)}$timestamp';
  }

  // Get user's active coupons
  static Stream<List<Map<String, dynamic>>> getUserCouponsStream() {
    return _firestore
        .collection('coupons')
        .where('userId', isEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .where((doc) => (doc.data()['usesLeft'] ?? 0) > 0)
            .map((doc) => doc.data())
            .toList());
  }

  // Handle dynamic link
  static Future<void> handleDynamicLink(Uri deepLink) async {
    try {
      // Extract referral code from link: locallens.com/ref/123456
      String? referralCode;
      
      if (deepLink.pathSegments.contains('ref')) {
        referralCode = deepLink.pathSegments.last; // "123456"
      } else if (deepLink.queryParameters.containsKey('ref')) {
        referralCode = deepLink.queryParameters['ref'];
      }
      
      if (referralCode != null && currentUserId != null) {
        await processReferral(referralCode);
        print('✅ Processed referral: $referralCode');
      }
    } catch (e) {
      print('Dynamic link error: $e');
    }
  }

  static Future<Map<String, dynamic>> validateCoupon(String couponCode) async {
    await initializeUserId();
    
    final couponDoc = await _firestore
        .collection('coupons')
        .where('code', isEqualTo: couponCode)
        .where('usesLeft', isGreaterThan: 0)
        .limit(1)
        .get();
    
    if (couponDoc.docs.isEmpty) {
      return {'valid': false, 'error': 'Coupon not found or expired'};
    }
    
    final coupon = couponDoc.docs.first.data();
    
    // Check if coupon belongs to user
    if (coupon['userId'] != currentUserId) {
      return {'valid': false, 'error': 'Coupon not yours!'};
    }
    
    final subtotalEstimate = 500.0;  // Or calculate from cart
    final discountPercent = coupon['discountPercent'].toDouble();
    final maxDiscount = coupon['maxDiscountAmount'].toDouble();
    final discountAmount = (subtotalEstimate * discountPercent / 100).clamp(0.0, maxDiscount);
    
    return {
      'valid': true,
      'discountPercent': discountPercent,
      'discountAmount': discountAmount,
      'couponDocId': couponDoc.docs.first.id,
    };
  }

  static Future<void> redeemCoupon(String couponDocId, double discountAmount) async {
    await _firestore.collection('coupons').doc(couponDocId).update({
      'usesLeft': FieldValue.increment(-1),
      'lastUsed': FieldValue.serverTimestamp(),
    });
  }

  // Real-time stats stream
  static Stream<Map<String, dynamic>> getReferralStatsStream() {
    initializeUserId(); // Ensure user ID is loaded
    return _firestore.collection('users').doc(currentUserId!).snapshots()
        .map((doc) => doc.exists ? doc.data()! : {
          'referralCode': 'N/A',
          'referralsCount': 0,
          'successfulReferrals': 0,
          'referralPoints': 0,
        });
  }
}