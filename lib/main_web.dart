import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/discovery_page.dart';
import 'providers/app_provider.dart';
import 'package:provider/provider.dart';
import 'services/referral_service.dart';
import 'test_stores.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Skip mobile-only features on web
  if (!kIsWeb) {
    try {
      // Dynamic links only work on mobile
      final dynamic = await import('package:firebase_dynamic_links/firebase_dynamic_links.dart');
      final initialLink = await dynamic.FirebaseDynamicLinks.instance.getInitialLink();
      if (initialLink != null) {
        await ReferralService.handleDynamicLink(initialLink.link);
      }
      
      dynamic.FirebaseDynamicLinks.instance.onLink.listen((dynamicLinkData) {
        ReferralService.handleDynamicLink(dynamicLinkData.link);
      }).onError((error) {
        print('Dynamic link error: $error');
      });
    } catch (e) {
      print('Dynamic links not available: $e');
    }
  }
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
      ],
      child: MaterialApp(
        title: 'LocalLens',
        home: kIsWeb ? DiscoveryPage() : TestStores(), // Skip TestStores on web
        routes: {
          '/discovery': (context) => DiscoveryPage(),
        },
      ),
    );
  }
}