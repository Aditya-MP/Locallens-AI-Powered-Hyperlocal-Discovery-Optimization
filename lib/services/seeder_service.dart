import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/store.dart';
import 'dart:math';

class SeederService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Bengaluru Data Center Points
  static const double indiranagarLat = 12.9716;
  static const double indiranagarLng = 77.6412;
  static const double koramangalaLat = 12.9352;
  static const double koramangalaLng = 77.6245;
  static const double hsrLat = 12.9121;
  static const double hsrLng = 77.6446;
  static const double whitefieldLat = 12.9698;
  static const double whitefieldLng = 77.7500;
  static const double jayanagarLat = 12.9304;
  static const double jayanagarLng = 77.5774;

  static final List<Map<String, dynamic>> _bengaluruStores = [
    // --- INDIRANAGAR ---
    {
      'id': 'blr_ind_g1',
      'name': 'Nature\'s Basket Indiranagar',
      'category': 'grocery',
      'address': '12th Main Rd, Indiranagar',
      'lat': indiranagarLat + 0.002,
      'lng': indiranagarLng - 0.001,
      'price': 120.0,
      'pickupTime': '15 mins',
      'isLocal': false,
      'isSustainable': true,
      'stockStatus': 'In Stock',
      'verificationCount': 45,
    },
    {
      'id': 'blr_ind_e1',
      'name': 'Imagine Store (Apple)',
      'category': 'electronics',
      'address': '100 Feet Rd, Indiranagar',
      'lat': indiranagarLat - 0.001,
      'lng': indiranagarLng + 0.002,
      'price': 85000.0,
      'pickupTime': '30 mins',
      'isLocal': false,
      'isSustainable': true,
      'stockStatus': 'In Stock',
      'verificationCount': 120,
    },
    {
      'id': 'blr_ind_p1',
      'name': 'Apollo Pharmacy 100ft',
      'category': 'pharmacy',
      'address': 'Stage 2, Indiranagar',
      'lat': indiranagarLat + 0.003,
      'lng': indiranagarLng + 0.001,
      'price': 45.0,
      'pickupTime': '10 mins',
      'isLocal': false,
      'isSustainable': true,
      'stockStatus': 'In Stock',
      'verificationCount': 85,
    },
    {
      'id': 'blr_ind_b1',
      'name': 'Glen\'s Bakehouse',
      'category': 'bakery',
      'address': 'Lavelle Road, Indiranagar', // Intentional slight mismatch for "near" feel
      'lat': indiranagarLat - 0.002,
      'lng': indiranagarLng - 0.002,
      'price': 250.0,
      'pickupTime': '20 mins',
      'isLocal': true,
      'isSustainable': false,
      'stockStatus': 'In Stock',
      'verificationCount': 350,
    },

    // --- KORAMANGALA ---
    {
      'id': 'blr_kor_g1',
      'name': 'Organic World',
      'category': 'grocery',
      'address': '5th Block, Koramangala',
      'lat': koramangalaLat + 0.001,
      'lng': koramangalaLng + 0.001,
      'price': 95.0,
      'pickupTime': '12 mins',
      'isLocal': true,
      'isSustainable': true,
      'stockStatus': 'In Stock',
      'verificationCount': 22,
    },
    {
      'id': 'blr_kor_c1',
      'name': 'H&M Koramangala',
      'category': 'clothes',
      'address': 'Forum Mall, Koramangala',
      'lat': koramangalaLat - 0.005,
      'lng': koramangalaLng - 0.002,
      'price': 1500.0,
      'pickupTime': '45 mins',
      'isLocal': false,
      'isSustainable': true,
      'stockStatus': 'In Stock',
      'verificationCount': 210,
    },
    {
      'id': 'blr_kor_be1',
      'name': 'Bodycraft Salon',
      'category': 'beauty_parlour',
      'address': '6th Block, Koramangala',
      'lat': koramangalaLat + 0.003,
      'lng': koramangalaLng - 0.001,
      'price': 1200.0,
      'pickupTime': '60 mins', // Booking usually
      'isLocal': true,
      'isSustainable': false,
      'stockStatus': 'Available',
      'verificationCount': 65,
    },

    // --- HSR LAYOUT ---
    {
      'id': 'blr_hsr_g1',
      'name': 'MK Retail',
      'category': 'supermarket',
      'address': 'Sector 2, HSR Layout',
      'lat': hsrLat,
      'lng': hsrLng,
      'price': 55.0,
      'pickupTime': '15 mins',
      'isLocal': true,
      'isSustainable': false,
      'stockStatus': 'In Stock',
      'verificationCount': 98,
    },
    {
      'id': 'blr_hsr_e1',
      'name': 'Sangeetha Mobiles',
      'category': 'electronics',
      'address': '27th Main, HSR Layout',
      'lat': hsrLat + 0.001,
      'lng': hsrLng + 0.002,
      'price': 15000.0,
      'pickupTime': '20 mins',
      'isLocal': true,
      'isSustainable': false,
      'stockStatus': 'In Stock',
      'verificationCount': 42,
    },

    // --- JAYANAGAR ---
    {
      'id': 'blr_jay_b1',
      'name': 'Iyengar Bakery',
      'category': 'bakery',
      'address': '4th Block, Jayanagar',
      'lat': jayanagarLat,
      'lng': jayanagarLng,
      'price': 30.0,
      'pickupTime': '5 mins',
      'isLocal': true,
      'isSustainable': true,
      'stockStatus': 'In Stock',
      'verificationCount': 500,
    },
    {
      'id': 'blr_jay_s1',
      'name': 'Bata Showroom',
      'category': 'shoes',
      'address': '3rd Block, Jayanagar',
      'lat': jayanagarLat + 0.002,
      'lng': jayanagarLng + 0.001,
      'price': 999.0,
      'pickupTime': '25 mins',
      'isLocal': false,
      'isSustainable': true,
      'stockStatus': 'In Stock',
      'verificationCount': 150,
    },
     
     // --- USER'S DEFAULT LOCATION (Adding coverage for default 15.04, 76.20 if they use emulator there) ---
     {
      'id': 'def_loc_1',
      'name': 'Demo Supermarket',
      'category': 'supermarket',
      'address': 'Main Market Road',
      'lat': 15.0500,
      'lng': 76.2100,
      'price': 60.0,
      'pickupTime': '10 mins',
      'isLocal': true,
      'isSustainable': false,
      'stockStatus': 'In Stock',
      'verificationCount': 10,
    },
  ];



  static Future<int> seedBengaluruStores() async {
    int addedCount = 0;
    final random = Random();
    
    try {
      final batch = _firestore.batch();
      
      for (final storeData in _bengaluruStores) {
        final docRef = _firestore.collection('stores').doc(storeData['id'] as String);
        
        // Vary carbon footprint between 0.5 kg and 3.5 kg
        final double randomCarbon = 0.5 + random.nextDouble() * 3.0;

        // We use set with merge to avoiding overwriting if it exists, 
        // but we want to ensure our new properties are there.
        batch.set(docRef, {
          'name': storeData['name'],
          'category': storeData['category'],
          'address': storeData['address'],
          'lat': storeData['lat'],
          'lng': storeData['lng'],
          'price': storeData['price'],
          'pickupTime': storeData['pickupTime'],
          'isLocal': storeData['isLocal'],
          'isSustainable': storeData['isSustainable'],
          'carbonFootprint': double.parse(randomCarbon.toStringAsFixed(2)),
          'stockStatus': storeData['stockStatus'],
          'verificationCount': storeData['verificationCount'],
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
        addedCount++;
      }
      
      await batch.commit();
      print('✅ Successfully seeded $addedCount stores to Firestore.');
      return addedCount;
    } catch (e) {
      print('❌ Error seeding stores: $e');
      rethrow;
    }
  }
}
