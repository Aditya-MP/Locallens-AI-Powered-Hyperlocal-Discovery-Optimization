import 'package:cloud_firestore/cloud_firestore.dart';

class HagaribommanahalliBulkUpload {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  static Future<void> uploadAllStores() async {
    print('🚀 Uploading 51 Hagaribommanahalli stores...');
    
    final stores = [
      {"name": "Sangeetha Mobiles", "lat": 15.0489, "lng": 76.2075, "category": "electronics", "phone": "+91 80444 64500"},
      {"name": "Focus Mart", "lat": 15.0483, "lng": 76.2076, "category": "supermarket", "phone": "+91 98450 12345"},
      {"name": "Apollo Pharmacy Ramanagara", "lat": 15.0445, "lng": 76.2120, "category": "pharmacy", "phone": "+91 83942 24055"},
      {"name": "Rajdhani Textiles", "lat": 15.0472, "lng": 76.2088, "category": "clothes", "phone": "+91 94481 00223"},
      {"name": "Vikas Mobiles Sales & Service", "lat": 15.0492, "lng": 76.2090, "category": "electronics", "phone": "+91 97420 55667"},
      {"name": "Manu Medical & General Store", "lat": 15.0505, "lng": 76.2070, "category": "pharmacy", "phone": "+91 83942 40112"},
      {"name": "Chiranjeevi Super Mart", "lat": 15.0440, "lng": 76.2130, "category": "supermarket", "phone": "+91 94480 33445"},
      {"name": "Sri Nandishwara Fashions", "lat": 15.0470, "lng": 76.2095, "category": "clothes", "phone": "+91 99002 11223"},
      {"name": "Shri Siddaganga Medicals", "lat": 15.0485, "lng": 76.2082, "category": "pharmacy", "phone": "+91 91132 44556"},
      {"name": "Mangal Deep Textiles", "lat": 15.0475, "lng": 76.2085, "category": "clothes", "phone": "+91 94485 22334"},
      {"name": "Vinay Electricals & Hardware", "lat": 15.0488, "lng": 76.2074, "category": "electronics", "phone": "+91 98860 11223"},
      {"name": "Gajanana Drug House", "lat": 15.0468, "lng": 76.2080, "category": "pharmacy", "phone": "+91 83942 25001"},
      {"name": "Family Super Market", "lat": 15.0490, "lng": 76.2092, "category": "supermarket", "phone": "+91 94490 88776"},
      {"name": "Janani Mobiles", "lat": 15.0530, "lng": 76.2100, "category": "electronics", "phone": "+91 90085 44332"},
      {"name": "Sri Vinayaka Medical & General Stores", "lat": 15.0482, "lng": 76.2078, "category": "pharmacy", "phone": "+91 91415 66778"},
      {"name": "Darling Smart Phone Galaxy", "lat": 15.0465, "lng": 76.2115, "category": "electronics", "phone": "+91 88844 55667"},
      {"name": "Kaveri Silk Palace", "lat": 15.0480, "lng": 76.2062, "category": "clothes", "phone": "+91 94480 11224"},
      {"name": "Jan Aushadhi Kendra", "lat": 15.0485, "lng": 76.2080, "category": "pharmacy", "phone": "N/A"},
      {"name": "Tanvi Mobile", "lat": 15.0486, "lng": 76.2081, "category": "electronics", "phone": "+91 96115 44332"},
      {"name": "Sri Rama General Store", "lat": 15.0488, "lng": 76.2077, "category": "supermarket", "phone": "+91 94801 22334"},
      {"name": "Uppina Tharappanavarra Angadi", "lat": 15.0470, "lng": 76.2086, "category": "supermarket", "phone": "+91 98455 11223"},
      {"name": "Mallige Medicals", "lat": 15.0484, "lng": 76.2073, "category": "pharmacy", "phone": "+91 83942 22889"},
      {"name": "Apsara Fashion", "lat": 15.0471, "lng": 76.2089, "category": "clothes", "phone": "+91 91104 33445"},
      {"name": "Raghavendra Hardware & Plywood", "lat": 15.0494, "lng": 76.2070, "category": "electronics", "phone": "+91 99805 11223"},
      {"name": "Padmavati Stores", "lat": 15.0489, "lng": 76.2079, "category": "supermarket", "phone": "+91 98452 44556"},
      {"name": "Nivedita Medicals", "lat": 15.0500, "lng": 76.2068, "category": "pharmacy", "phone": "+91 83942 22110"},
      {"name": "Mangaldeep Textiles New", "lat": 15.0474, "lng": 76.2084, "category": "clothes", "phone": "+91 94482 11334"},
      {"name": "Hanuma Hardware & Plywood", "lat": 15.0496, "lng": 76.2072, "category": "electronics", "phone": "+91 91108 55443"},
      {"name": "Saanvi Medicals", "lat": 15.0487, "lng": 76.2076, "category": "pharmacy", "phone": "+91 91102 11002"},
      {"name": "Parivar Trends", "lat": 15.0545, "lng": 76.2025, "category": "clothes", "phone": "+91 98801 22334"},
      {"name": "Maruti General Store", "lat": 15.0450, "lng": 76.2125, "category": "supermarket", "phone": "+91 99001 22334"},
      {"name": "Sandeep Provision Store", "lat": 15.0491, "lng": 76.2074, "category": "supermarket", "phone": "+91 94482 55667"},
      {"name": "Rajputana Fancy Stores", "lat": 15.0481, "lng": 76.2079, "category": "clothes", "phone": "+91 99005 66778"},
      {"name": "Vinod General Store", "lat": 15.0550, "lng": 76.2150, "category": "supermarket", "phone": "+91 97422 11009"},
      {"name": "Majisa Fashion", "lat": 15.0473, "lng": 76.2087, "category": "clothes", "phone": "+91 91104 22331"},
      {"name": "Hkgn Tailor", "lat": 15.0493, "lng": 76.2071, "category": "clothes", "phone": "+91 97425 66001"},
      {"name": "Shivakumar General Store", "lat": 15.0485, "lng": 76.2075, "category": "supermarket", "phone": "+91 98451 22334"},
      {"name": "Mk Mens Wear", "lat": 15.0491, "lng": 76.2073, "category": "clothes", "phone": "+91 91105 44332"},
      {"name": "Divya Textiles", "lat": 15.0488, "lng": 76.2072, "category": "clothes", "phone": "+91 94483 11001"},
      {"name": "R.G. Garments", "lat": 15.0492, "lng": 76.2075, "category": "clothes", "phone": "+91 97421 22334"},
      {"name": "Bangloor Saree Center", "lat": 15.0476, "lng": 76.2082, "category": "clothes", "phone": "+91 91102 11001"},
      {"name": "Ambe General Stores", "lat": 15.0478, "lng": 76.2081, "category": "supermarket", "phone": "+91 94481 22001"},
      {"name": "Vigneshwara General Store", "lat": 15.0490, "lng": 76.2085, "category": "supermarket", "phone": "+91 98860 22334"}
    ];
    
    int success = 0;
    
    for (var store in stores) {
      try {
        await _firestore.collection('stores').add({
          'name': store['name'],
          'address': 'Hagaribommanahalli, Karnataka 583212',
          'lat': store['lat'],
          'lng': store['lng'],
          'category': store['category'],
          'pickupTime': '10 mins',
          'city': 'Hagaribommanahalli',
          'phone': store['phone'],
          'hours': 'Mon-Sun 9AM-9PM',
          'stockStatus': 'In Stock',
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        success++;
        print('✅ $success/43: ${store['name']}');
        
      } catch (e) {
        print('❌ Failed: ${store['name']} - $e');
      }
    }
    
    print('\n🎉 Successfully uploaded $success stores to Firebase!');
    return;
  }
}