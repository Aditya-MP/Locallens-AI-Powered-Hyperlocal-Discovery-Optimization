import 'package:cloud_firestore/cloud_firestore.dart';

class StoreUploader {
  static final stores = [
    {"name": "Sangeetha Mobiles", "address": "Sree Guru Plaza, Main Road, Near Railway Station, Hagaribommanahalli 583212", "lat": 15.0489, "lng": 76.2075, "category": "electronics", "pickupTime": "10 mins", "city": "Hagaribommanahalli", "phone": "+91 80444 64500", "hours": "Mon-Sun 9:45AM-9:45PM"},
    {"name": "Focus Mart", "address": "Main Road, Near Basaveshwara Bazar, Hagaribommanahalli 583212", "lat": 15.0483, "lng": 76.2076, "category": "supermarket", "pickupTime": "5 mins", "city": "Hagaribommanahalli", "phone": "+91 98450 12345", "hours": "Sat-Wed 9AM-9PM"},
    {"name": "Ram Tulasi Family Garden Restaurant", "address": "Old H B Halli Road, Hagaribommanahalli 583212", "lat": 15.0510, "lng": 76.2055, "category": "grocery", "pickupTime": "20 mins", "city": "Hagaribommanahalli", "phone": "+91 98800 12345", "hours": "Mon-Sun 11AM-10:30PM"},
    {"name": "Apollo Pharmacy Ramanagara", "address": "Ward No 7, Ramanagara, Hagaribommanahalli 583212", "lat": 15.0445, "lng": 76.2120, "category": "pharmacy", "pickupTime": "12 mins", "city": "Hagaribommanahalli", "phone": "+91 83942 24055", "hours": "Open 24 Hours"},
    {"name": "Rajdhani Textiles", "address": "Basaveshwara Bazar, SH 25, Hagaribommanahalli 583212", "lat": 15.0472, "lng": 76.2088, "category": "clothes", "pickupTime": "10 mins", "city": "Hagaribommanahalli", "phone": "+91 94481 00223", "hours": "Mon-Sun 9AM-9PM"},
    {"name": "Vikas Mobiles Sales & Service", "address": "Netaji Road, Hagaribommanahalli 583212", "lat": 15.0492, "lng": 76.2090, "category": "electronics", "pickupTime": "8 mins", "city": "Hagaribommanahalli", "phone": "+91 97420 55667", "hours": "Mon-Sat 10AM-8PM"},
    {"name": "Gama Gama Pure Veg Hotel", "address": "Near KSRTC Bus Stand, Harihar Road, Hagaribommanahalli 583212", "lat": 15.0498, "lng": 76.2065, "category": "grocery", "pickupTime": "15 mins", "city": "Hagaribommanahalli", "phone": "+91 91410 88776", "hours": "Mon-Sun 7AM-10PM"},
    {"name": "Manu Medical & General Store", "address": "Shimoga Harihar Hospet Road, Near Kottureshwara Talkies, Hagaribommanahalli 583212", "lat": 15.0505, "lng": 76.2070, "category": "pharmacy", "pickupTime": "10 mins", "city": "Hagaribommanahalli", "phone": "+91 83942 40112", "hours": "Mon-Sun 9AM-10PM"},
    {"name": "Chiranjeevi Super Mart", "address": "Kottur Road, Hagaribommanahalli 583212", "lat": 15.0440, "lng": 76.2130, "category": "supermarket", "pickupTime": "15 mins", "city": "Hagaribommanahalli", "phone": "+91 94480 33445", "hours": "Mon-Sun 8AM-9PM"},
    {"name": "Sri Nandishwara Fashions", "address": "SH 25, Hagaribommanahalli 583212", "lat": 15.0470, "lng": 76.2095, "category": "clothes", "pickupTime": "12 mins", "city": "Hagaribommanahalli", "phone": "+91 99002 11223", "hours": "Mon-Sun 10AM-9PM"},
    {"name": "Basaveshwara Khanavali", "address": "Opposite Old Bus Stand, New KSRTC Bus Stand Road, Hagaribommanahalli 583212", "lat": 15.0495, "lng": 76.2060, "category": "grocery", "pickupTime": "10 mins", "city": "Hagaribommanahalli", "phone": "+91 94810 55443", "hours": "Mon-Sun 12PM-4PM, 7PM-10PM"},
    {"name": "Shri Siddaganga Medicals", "address": "Hospet Harihar Road, Hagaribommanahalli 583212", "lat": 15.0485, "lng": 76.2082, "category": "pharmacy", "pickupTime": "8 mins", "city": "Hagaribommanahalli", "phone": "+91 91132 44556", "hours": "Mon-Sun 8:30AM-10:30PM"},
    {"name": "Hotel New Royal Treat", "address": "Hospet Main Road, Near Karnataka Bank, Hagaribommanahalli 583212", "lat": 15.0502, "lng": 76.2072, "category": "grocery", "pickupTime": "20 mins", "city": "Hagaribommanahalli", "phone": "+91 83942 24556", "hours": "Mon-Sun 11AM-11PM"},
    {"name": "Mangal Deep Textiles", "address": "Main Bazar, Hagaribommanahalli 583212", "lat": 15.0475, "lng": 76.2085, "category": "clothes", "pickupTime": "10 mins", "city": "Hagaribommanahalli", "phone": "+91 94485 22334", "hours": "Mon-Sun 9:30AM-9PM"},
    {"name": "Vinay Electricals & Hardware", "address": "Main Bazar Road, Hagaribommanahalli 583212", "lat": 15.0488, "lng": 76.2074, "category": "electronics", "pickupTime": "15 mins", "city": "Hagaribommanahalli", "phone": "+91 98860 11223", "hours": "Mon-Sat 9AM-8PM"},
    {"name": "Gajanana Drug House", "address": "Basaveshwara Bazar, State Highway 25, Hagaribommanahalli 583212", "lat": 15.0468, "lng": 76.2080, "category": "pharmacy", "pickupTime": "10 mins", "city": "Hagaribommanahalli", "phone": "+91 83942 25001", "hours": "Mon-Sun 9AM-9:30PM"},
    {"name": "Anushree Garden & Restaurant", "address": "SH 25, Shivajyothi Nagar, Hagaribommanahalli 583212", "lat": 15.0525, "lng": 76.2045, "category": "grocery", "pickupTime": "25 mins", "city": "Hagaribommanahalli", "phone": "+91 97405 66778", "hours": "Mon-Sun 11AM-10:30PM"},
    {"name": "Family Super Market", "address": "Netaji Road, Hagaribommanahalli 583212", "lat": 15.0490, "lng": 76.2092, "category": "supermarket", "pickupTime": "7 mins", "city": "Hagaribommanahalli", "phone": "+91 94490 88776", "hours": "Mon-Sun 8AM-9:30PM"},
    {"name": "Janani Mobiles", "address": "Vinayaka Nagar, Kadlebalu Road, Hagaribommanahalli 583212", "lat": 15.0530, "lng": 76.2100, "category": "electronics", "pickupTime": "18 mins", "city": "Hagaribommanahalli", "phone": "+91 90085 44332", "hours": "Mon-Sat 10AM-8:30PM"},
    {"name": "Sri Vinayaka Medical & General Stores", "address": "Main Bazar, Hagaribommanahalli 583212", "lat": 15.0482, "lng": 76.2078, "category": "pharmacy", "pickupTime": "5 mins", "city": "Hagaribommanahalli", "phone": "+91 91415 66778", "hours": "Mon-Sun 8AM-10PM"},
    {"name": "Darling Smart Phone Galaxy", "address": "Beside Karvi Office, Byasidgeri, Hagaribommanahalli 583212", "lat": 15.0465, "lng": 76.2115, "category": "electronics", "pickupTime": "12 mins", "city": "Hagaribommanahalli", "phone": "+91 88844 55667", "hours": "Mon-Sat 10AM-9PM"},
    {"name": "Kaveri Silk Palace", "address": "Near SBI Bank, Hagaribommanahalli 583212", "lat": 15.0480, "lng": 76.2062, "category": "clothes", "pickupTime": "15 mins", "city": "Hagaribommanahalli", "phone": "+91 94480 11224", "hours": "Mon-Sun 10AM-10PM"},
    {"name": "Krishna Hotel", "address": "Basaveshwara Bazar, Near Taluk Office, Hagaribommanahalli 583212", "lat": 15.0460, "lng": 76.2085, "category": "grocery", "pickupTime": "10 mins", "city": "Hagaribommanahalli", "phone": "+91 83942 22045", "hours": "Mon-Sun 6:30AM-9PM"},
    {"name": "Jan Aushadhi Kendra", "address": "Hospet Harihar Road, Near Basaveshwara Circle, Hagaribommanahalli 583212", "lat": 15.0485, "lng": 76.2080, "category": "pharmacy", "pickupTime": "7 mins", "city": "Hagaribommanahalli", "phone": "N/A", "hours": "Mon-Sat 9AM-8PM"},
    {"name": "Tanvi Mobile", "address": "Basaveshwar Circle Road, Hagaribommanahalli 583212", "lat": 15.0486, "lng": 76.2081, "category": "electronics", "pickupTime": "5 mins", "city": "Hagaribommanahalli", "phone": "+91 96115 44332", "hours": "Mon-Sat 10AM-9PM"},
    {"name": "Sri Rama General Store", "address": "Main Bazar, Hagaribommanahalli 583212", "lat": 15.0488, "lng": 76.2077, "category": "supermarket", "pickupTime": "5 mins", "city": "Hagaribommanahalli", "phone": "+91 94801 22334", "hours": "Mon-Sun 8AM-9PM"},
    {"name": "Uppina Tharappanavarra Angadi", "address": "Basaveshwara Bazar, Hagaribommanahalli 583212", "lat": 15.0470, "lng": 76.2086, "category": "supermarket", "pickupTime": "10 mins", "city": "Hagaribommanahalli", "phone": "+91 98455 11223", "hours": "Mon-Sun 8AM-8:30PM"},
    {"name": "Mallige Medicals", "address": "Main Bazar, Hagaribommanahalli 583212", "lat": 15.0484, "lng": 76.2073, "category": "pharmacy", "pickupTime": "5 mins", "city": "Hagaribommanahalli", "phone": "+91 83942 22889", "hours": "Mon-Sun 8:30AM-10PM"},
    {"name": "Apsara Fashion", "address": "Basaveshwara Bazar, SH 25, Hagaribommanahalli 583212", "lat": 15.0471, "lng": 76.2089, "category": "clothes", "pickupTime": "8 mins", "city": "Hagaribommanahalli", "phone": "+91 91104 33445", "hours": "Mon-Sat 9AM-9PM"},
    {"name": "Raghavendra Hardware & Plywood", "address": "Main Road, Hagaribommanahalli 583212", "lat": 15.0494, "lng": 76.2070, "category": "electronics", "pickupTime": "12 mins", "city": "Hagaribommanahalli", "phone": "+91 99805 11223", "hours": "Mon-Sat 9:30AM-8PM"},
    {"name": "Sunil Restaurant & Function Hall", "address": "Kudligi Road, Hagaribommanahalli 583212", "lat": 15.0430, "lng": 76.2165, "category": "grocery", "pickupTime": "20 mins", "city": "Hagaribommanahalli", "phone": "+91 94485 12344", "hours": "Mon-Sun 10AM-10PM"},
    {"name": "Padmavati Stores", "address": "Main Road, Hagaribommanahalli 583212", "lat": 15.0489, "lng": 76.2079, "category": "supermarket", "pickupTime": "5 mins", "city": "Hagaribommanahalli", "phone": "+91 98452 44556", "hours": "Mon-Sun 8AM-9PM"},
    {"name": "Nivedita Medicals", "address": "Behind Kottureshwara Theater, Near Old Busstand, Hagaribommanahalli 583212", "lat": 15.0500, "lng": 76.2068, "category": "pharmacy", "pickupTime": "12 mins", "city": "Hagaribommanahalli", "phone": "+91 83942 22110", "hours": "Mon-Sat 9AM-9:30PM"},
    {"name": "Mangaldeep Textiles New", "address": "SH 25, Hagaribommanahalli 583212", "lat": 15.0474, "lng": 76.2084, "category": "clothes", "pickupTime": "8 mins", "city": "Hagaribommanahalli", "phone": "+91 94482 11334", "hours": "Mon-Sun 9AM-9PM"},
    {"name": "Hanuma Hardware & Plywood", "address": "Main Road, Hagaribommanahalli 583212", "lat": 15.0496, "lng": 76.2072, "category": "electronics", "pickupTime": "10 mins", "city": "Hagaribommanahalli", "phone": "+91 91108 55443", "hours": "Mon-Sat 9:30AM-8:30PM"},
    {"name": "Guru Kottureshwara Hotel", "address": "Kottur Road, Hagaribommanahalli 583212", "lat": 15.0435, "lng": 76.2140, "category": "grocery", "pickupTime": "15 mins", "city": "Hagaribommanahalli", "phone": "+91 94490 22113", "hours": "Mon-Sun 7AM-9:30PM"},
    {"name": "Saanvi Medicals", "address": "Main Road, Hagaribommanahalli 583212", "lat": 15.0487, "lng": 76.2076, "category": "pharmacy", "pickupTime": "5 mins", "city": "Hagaribommanahalli", "phone": "+91 91102 11002", "hours": "Mon-Sun 8AM-10PM"},
    {"name": "Parivar Trends", "address": "Opposite Railway Station, Hagaribommanahalli 583212", "lat": 15.0545, "lng": 76.2025, "category": "clothes", "pickupTime": "15 mins", "city": "Hagaribommanahalli", "phone": "+91 98801 22334", "hours": "Mon-Sun 10AM-8:30PM"},
    {"name": "Maruti General Store", "address": "Opposite Govt Higher Primary School, Hagaribommanahalli 583212", "lat": 15.0450, "lng": 76.2125, "category": "supermarket", "pickupTime": "12 mins", "city": "Hagaribommanahalli", "phone": "+91 99001 22334", "hours": "Mon-Sun 8AM-9PM"},
    {"name": "Sandeep Provision Store", "address": "Main Road Area, Hagaribommanahalli 583212", "lat": 15.0491, "lng": 76.2074, "category": "supermarket", "pickupTime": "5 mins", "city": "Hagaribommanahalli", "phone": "+91 94482 55667", "hours": "Mon-Sun 8AM-9:30PM"},
    {"name": "Rajputana Fancy Stores", "address": "Main Bazar, Hagaribommanahalli 583212", "lat": 15.0481, "lng": 76.2079, "category": "clothes", "pickupTime": "5 mins", "city": "Hagaribommanahalli", "phone": "+91 99005 66778", "hours": "Mon-Sun 9AM-9PM"},
    {"name": "Vinod General Store", "address": "Basapura Thanda Main Road, Hagaribommanahalli 583212", "lat": 15.0550, "lng": 76.2150, "category": "supermarket", "pickupTime": "25 mins", "city": "Hagaribommanahalli", "phone": "+91 97422 11009", "hours": "Mon-Sun 8AM-8PM"},
    {"name": "Majisa Fashion", "address": "SH 25, Hagaribommanahalli 583212", "lat": 15.0473, "lng": 76.2087, "category": "clothes", "pickupTime": "10 mins", "city": "Hagaribommanahalli", "phone": "+91 91104 22331", "hours": "Mon-Sun 9AM-9PM"},
    {"name": "Hkgn Tailor", "address": "Shop No 1, Ballari Road, Hagaribommanahalli 583212", "lat": 15.0493, "lng": 76.2071, "category": "clothes", "pickupTime": "8 mins", "city": "Hagaribommanahalli", "phone": "+91 97425 66001", "hours": "Mon-Sat 10AM-8PM"},
    {"name": "Shivakumar General Store", "address": "Main Bazar Area, Hagaribommanahalli 583212", "lat": 15.0485, "lng": 76.2075, "category": "supermarket", "pickupTime": "5 mins", "city": "Hagaribommanahalli", "phone": "+91 98451 22334", "hours": "Mon-Sun 8AM-9PM"},
    {"name": "Mk Mens Wear", "address": "Main Road, Hagaribommanahalli 583212", "lat": 15.0491, "lng": 76.2073, "category": "clothes", "pickupTime": "7 mins", "city": "Hagaribommanahalli", "phone": "+91 91105 44332", "hours": "Mon-Sun 10AM-10PM"},
    {"name": "Divya Textiles", "address": "Main Road, Hagaribommanahalli 583212", "lat": 15.0488, "lng": 76.2072, "category": "clothes", "pickupTime": "5 mins", "city": "Hagaribommanahalli", "phone": "+91 94483 11001", "hours": "Mon-Sun 10AM-10PM"},
    {"name": "R.G. Garments", "address": "Main Road Area, Hagaribommanahalli 583212", "lat": 15.0492, "lng": 76.2075, "category": "clothes", "pickupTime": "5 mins", "city": "Hagaribommanahalli", "phone": "+91 97421 22334", "hours": "Mon-Sun 10AM-11:59PM"},
    {"name": "Bangloor Saree Center", "address": "SH 25, Hagaribommanahalli 583212", "lat": 15.0476, "lng": 76.2082, "category": "clothes", "pickupTime": "8 mins", "city": "Hagaribommanahalli", "phone": "+91 91102 11001", "hours": "Mon-Sun 9AM-9PM"},
    {"name": "Ambe General Stores", "address": "SH 25, Hagaribommanahalli 583212", "lat": 15.0478, "lng": 76.2081, "category": "supermarket", "pickupTime": "5 mins", "city": "Hagaribommanahalli", "phone": "+91 94481 22001", "hours": "Mon-Sun 8AM-9PM"},
    {"name": "Vigneshwara General Store", "address": "Ballari Road, Hagaribommanahalli 583212", "lat": 15.0490, "lng": 76.2085, "category": "supermarket", "pickupTime": "10 mins", "city": "Hagaribommanahalli", "phone": "+91 98860 22334", "hours": "Mon-Sun 8AM-9PM"}
  ];
  
  static Future<void> uploadToFirebase() async {
    final firestore = FirebaseFirestore.instance;
    int success = 0;
    
    for (var store in stores) {
      try {
        await firestore.collection('stores').add({
          'name': store['name'],
          'address': store['address'],
          'lat': store['lat'],
          'lng': store['lng'],
          'category': store['category'],
          'pickupTime': store['pickupTime'],
          'city': store['city'],
          'phone': store['phone'],
          'hours': store['hours'],
          'stockStatus': 'In Stock',
          'createdAt': FieldValue.serverTimestamp(),
        });
        success++;
        print('✅ ${store['name']}');
      } catch (e) {
        print('❌ ${store['name']}: $e');
      }
    }
    
    print('\n🎉 Uploaded $success/${stores.length} stores to Firebase!');
  }
}

void main() async {
  await StoreUploader.uploadToFirebase();
}