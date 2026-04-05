import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../providers/app_provider.dart';
import '../models/store.dart';
import '../models/trip_plan.dart';
import '../services/location_service.dart';
import '../services/ai_search_service.dart';
import '../services/store_service.dart';
import '../services/voice_search_service.dart';
import '../services/TripPlannerService.dart';
import '../services/trip_calculator_service.dart';
import '../services/product_search_service.dart';
import '../services/community_service.dart';
import '../models/community_store.dart';
import 'referral_page.dart';
import 'stock_verification_page.dart';
import 'leaderboard_page.dart';
import 'action_page.dart';
import 'reservation_page.dart';

import '../services/seeder_service.dart'; // Add import

class DiscoveryPage extends StatefulWidget {
  const DiscoveryPage({super.key});

  @override
  State<DiscoveryPage> createState() => _DiscoveryPageState();
}


class _DiscoveryPageState extends State<DiscoveryPage> {
  final TextEditingController _searchController = TextEditingController();
  late TextEditingController _storeNameController;
  late TextEditingController _storeAddressController;
  String _selectedCategory = 'grocery';
  final ImagePicker _picker = ImagePicker();
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  final Set<String> _selectedFilters = {};
  bool _showReferral = false;
  bool _showVerifyStock = false;
  List<String> cartProducts = []; // Trip Cart

  Future<void> _seedData() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Seeding Bengaluru store data...')),
      );
      
      final count = await SeederService.seedBengaluruStores();
      
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('✅ Added $count stores to database!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error seeding data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _storeNameController = TextEditingController();
    _storeAddressController = TextEditingController();
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _storeAddressController.dispose();
    super.dispose();
  }

  void _initSpeech() async {
    _speechEnabled = await VoiceSearchService.initSpeech();
    setState(() {});
  }

  void _startListening() async {
    if (!_speechEnabled) return;
    
    setState(() {
      _isListening = true;
    });
    
    await VoiceSearchService.startListening(
      onResult: (result) async {
        setState(() {
          _searchController.text = result;
          _isListening = false;
        });
        
        // Auto-search when voice input is complete
        final provider = Provider.of<AppProvider>(context, listen: false);
        await provider.searchProduct(result);
      },
      onError: (error) {
        setState(() {
          _isListening = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Voice search error: $error')),
        );
      },
    );
  }

  void _stopListening() async {
    await VoiceSearchService.stopListening();
    setState(() {
      _isListening = false;
    });
  }

  void _toggleFilter(String filter) {
    setState(() {
      if (_selectedFilters.contains(filter)) {
        _selectedFilters.remove(filter);
      } else {
        _selectedFilters.add(filter);
      }
    });
  }

  void _toggleReferral() {
    setState(() {
      _showReferral = !_showReferral;
      _showVerifyStock = false;
    });
  }

  void _toggleVerifyStock() {
    setState(() {
      _showVerifyStock = !_showVerifyStock;
      _showReferral = false;
    });
  }

  void _addToTripCart(String product) {
    setState(() {
      cartProducts.add(product);
    });
  }

  void _showCartDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.orange[600]!, Colors.orange[800]!]),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              Icon(Icons.shopping_cart, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Shopping Cart (${cartProducts.length} items)',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 350,
          child: cartProducts.isEmpty
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[400]),
                    SizedBox(height: 16),
                    Text(
                      'Your cart is empty',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Add products to start planning your trip',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: cartProducts.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.orange[200]!),
                            ),
                            child: ListTile(
                              leading: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [Colors.orange[400]!, Colors.orange[600]!]),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(
                                cartProducts[index],
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                              ),
                              subtitle: Text(
                                'Added to trip plan',
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              ),
                              trailing: Container(
                                decoration: BoxDecoration(
                                  color: Colors.red[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: IconButton(
                                  icon: Icon(Icons.delete_outline, color: Colors.red[700]),
                                  onPressed: () {
                                    setState(() {
                                      cartProducts.removeAt(index);
                                    });
                                    Navigator.pop(context);
                                    if (cartProducts.isNotEmpty) {
                                      _showCartDialog();
                                    }
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            Icon(Icons.check_circle, color: Colors.white),
                                            SizedBox(width: 8),
                                            Text('Item removed from cart'),
                                          ],
                                        ),
                                        backgroundColor: Colors.green,
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  tooltip: 'Remove from cart',
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (cartProducts.isNotEmpty) ...[
                      Divider(thickness: 1, color: Colors.orange[200]),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Items:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [Colors.orange[600]!, Colors.orange[800]!]),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Text(
                                '${cartProducts.length}',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
        ),
        actions: [
          if (cartProducts.isNotEmpty)
            TextButton.icon(
              icon: Icon(Icons.clear_all, color: Colors.red),
              label: Text('Clear All', style: TextStyle(color: Colors.red)),
              onPressed: () {
                setState(() {
                  cartProducts.clear();
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.info, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Cart cleared'),
                      ],
                    ),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: Colors.grey[700])),
          ),
          if (cartProducts.isNotEmpty)
            ElevatedButton.icon(
              icon: Icon(Icons.route, color: Colors.white),
              label: Text('Plan Trip'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[700],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ActionPage(
                      cartProducts: List.from(cartProducts),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _showCommunityBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: -5,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.purple, Colors.purple[700]!]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(Icons.people, color: Colors.white, size: 28),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Community Hub',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4A148C),
                          ),
                        ),
                        Text(
                          'Add stores & verify stock for everyone',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 24),
              
              Text(
                '👥 Add New Store',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              
              TextField(
                controller: _storeNameController,
                decoration: InputDecoration(
                  labelText: 'Store Name',
                  prefixIcon: Icon(Icons.store, color: Colors.purple),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  filled: true,
                  fillColor: Colors.purple[50],
                ),
              ),
              SizedBox(height: 16),
              
              TextField(
                controller: _storeAddressController,
                decoration: InputDecoration(
                  labelText: 'Address',
                  prefixIcon: Icon(Icons.location_on, color: Colors.green),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  filled: true,
                  fillColor: Colors.green[50],
                ),
              ),
              SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category, color: Colors.orange),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  filled: true,
                  fillColor: Colors.orange[50],
                ),
                items: ['grocery', 'pharmacy', 'electronics', 'clothes', 'bakery', 'beauty_parlour']
                    .map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(category.toUpperCase()),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedCategory = value!),
              ),
              SizedBox(height: 24),
              
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.add, color: Colors.white),
                      label: Text('Add Store'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 8,
                      ),
                      onPressed: () {
                        _addCommunityStore();
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  SizedBox(width: 12),
                  ElevatedButton.icon(
                    icon: Icon(Icons.verified_user, color: Colors.grey[700]),
                    label: Text('Verify Stock'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                      foregroundColor: Colors.grey[800],
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);  // Close bottom sheet
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => StockVerificationPage()),  // NO parameters!
                      );
                    },
                  ),
                ],
              ),
              SizedBox(height: 24),
              const Text(
                '🏆 Top Community Members',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildLeaderboardPreview(),
              
              const SizedBox(height: 24),
              const Text(
                '⚡ Live Community Feed',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: CommunityService.getRecentActivity(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final activities = snapshot.data!;
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: activities.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = activities[index];
                        // Parsing time is simple relative time for now
                        final time = DateTime.parse(item['time']);
                        final timeAgo = '${DateTime.now().difference(time).inMinutes}m ago';
                        
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Color(item['color'] as int).withOpacity(0.1),
                            child: Icon(
                              const IconData(0xe7fd, fontFamily: 'MaterialIcons'),
                              color: Color(item['color'] as int),
                              size: 20,
                            ),
                          ),
                          title: RichText(
                            text: TextSpan(
                              style: const TextStyle(fontSize: 14, color: Colors.black87),
                              children: [
                                TextSpan(text: '${item['user']} ', style: const TextStyle(fontWeight: FontWeight.bold)),
                                TextSpan(text: '${item['action']} '),
                                TextSpan(text: '${item['target']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                              ],
                            ),
                          ),
                          trailing: Text(
                            timeAgo,
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          ),
                          dense: true,
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }

  Future<void> _addCommunityStore() async {
    try {
      final userPos = await LocationService.getCurrentLocation();
      
      final store = CommunityStore(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _storeNameController.text.isNotEmpty ? _storeNameController.text : 'New Store',
        address: _storeAddressController.text,
        lat: userPos.latitude,
        lng: userPos.longitude,
        category: _selectedCategory,
        addedBy: 'user_${DateTime.now().millisecondsSinceEpoch}',
        addedDate: DateTime.now(),
      );
      
      await CommunityService.addCommunityStore(store);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle, color: Colors.green, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Store Added! (+50 Points)',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${_storeNameController.text} is now live.',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ),
      );
      
      _storeNameController.clear();
      _storeAddressController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showVerifyStockSheet() async {
    final userPos = await LocationService.getCurrentLocation();
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const StockVerificationPage(),
      ),
    );
  }

  void _showProductVerification(dynamic store) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.verified_user, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Expanded(child: Text('${store.name}')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('What products are available here?'),
            SizedBox(height: 16),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...cartProducts.map((product) => _buildProductChip(product, store)),
                _buildProductChip('iPhone 15', store),
                _buildProductChip('Paracetamol', store),
                _buildProductChip('Fresh Cake', store),
                _buildProductChip('Milk 1L', store),
              ],
            ),
            
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: 'Type product name...',
                prefixIcon: Icon(Icons.add),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  _verifyProduct(store, value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductChip(String product, dynamic store) {
    return ActionChip(
      label: Text(product),
      backgroundColor: Colors.grey[100],
      onPressed: () {
        _verifyProduct(store, product);
        Navigator.pop(context);
      },
    );
  }

  Future<void> _verifyProduct(dynamic store, String product) async {
    try {
      await CommunityService.verifyProduct(store.id, product, 'current_user');
      _showVotingDialog(store.id, product);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showVotingDialog(String storeId, String product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.thumb_up, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Expanded(child: Text('Verify $product?')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$product is available at this store?'),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () => _submitVote(storeId, product, true),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.green, Colors.green[600]!]),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 10)],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.thumb_up, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Yes (👍)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _submitVote(storeId, product, false),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.red, Colors.red[600]!]),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 10)],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.thumb_down, color: Colors.white),
                        SizedBox(width: 8),
                        Text('No (👎)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitVote(String storeId, String product, bool isUpvote) async {
    Navigator.pop(context);
    
    try {
      await CommunityService.submitVote(storeId, product, 'current_user', isUpvote);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(isUpvote ? Icons.thumb_up : Icons.thumb_down, color: Colors.white),
              SizedBox(width: 12),
              Text(isUpvote ? '✅ Upvoted!' : '❌ Downvoted!'),
            ],
          ),
          backgroundColor: isUpvote ? Colors.green : Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vote failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showLeaderboard() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LeaderboardPage()),
    );
  }

  Widget _buildLeaderboardPreview() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.purple[50],
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.purple,
                child: Text('1', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('You', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('15 verifications', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
              Spacer(),
              Text('🥇', style: TextStyle(fontSize: 24)),
            ],
          ),
        ),
        SizedBox(height: 8),
        TextButton.icon(
          icon: Icon(Icons.leaderboard),
          label: Text('See Full Leaderboard'),
          onPressed: () {
            Navigator.pop(context);
            _showLeaderboard();
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Locallens',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.cloud_upload, color: Colors.white),
            tooltip: 'Seed Demo Data',
            onPressed: _seedData,
          ),
          IconButton(
            icon: Stack(
              children: [
                Icon(Icons.people, color: Colors.white),
                Positioned(
                  right: 0,
                  child: CircleAvatar(
                    radius: 8,
                    backgroundColor: Colors.purple,
                    child: Text('C', style: TextStyle(color: Colors.white, fontSize: 10)),
                  ),
                ),
              ],
            ),
            onPressed: _showCommunityBottomSheet,
            tooltip: 'Community Stores',
          ),
          // Enhanced Cart Icon - Always visible with better design
          Container(
            margin: EdgeInsets.only(right: 8),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: cartProducts.isEmpty ? Colors.white.withOpacity(0.2) : Colors.orange[600],
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: cartProducts.isNotEmpty ? [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ] : null,
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.shopping_cart,
                      color: cartProducts.isEmpty ? Colors.white : Colors.white,
                      size: 24,
                    ),
                    onPressed: _showCartDialog,
                    tooltip: 'Shopping Cart (${cartProducts.length} items)',
                  ),
                ),
                if (cartProducts.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red[600],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      constraints: BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Text(
                        '${cartProducts.length}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE8F5E8), Color(0xFFF1F8E9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Consumer<AppProvider>(
          builder: (context, provider, child) => SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search section with card
                Card(
                  elevation: 12,
                  shadowColor: Colors.black.withOpacity(0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.white, const Color(0xFFF0F7F0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.location_on, color: const Color(0xFF2E7D32), size: 28),
                            const SizedBox(width: 8),
                            const Text(
                              'Find Local Gems',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1B5E20),
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Premium Search bar
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.15),
                                spreadRadius: 2,
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                            border: Border.all(color: Colors.grey.withOpacity(0.1)),
                          ),
                          child: Row(
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(left: 16),
                                child: Icon(Icons.search, color: Colors.grey),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    hintText: 'Search products (e.g., milk, phone, shoes)...',
                                    hintStyle: TextStyle(color: Colors.grey.shade400),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  ),
                                ),
                              ),
                              Container(
                                color: Colors.grey.withOpacity(0.2),
                                width: 1,
                                height: 30,
                              ),
                              IconButton(
                                icon: Icon(
                                  _isListening ? Icons.mic : Icons.mic_none,
                                  color: _isListening ? Colors.red : const Color(0xFF4CAF50),
                                  size: 26,
                                ),
                                onPressed: _speechEnabled
                                    ? (_isListening ? _stopListening : _startListening)
                                    : null,
                                tooltip: _isListening ? 'Stop listening' : 'Voice search',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4CAF50).withOpacity(0.4),
                                spreadRadius: 2,
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              provider.searchProduct(_searchController.text);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'Find Products Nearby',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Filter chips
                const Text(
                  'Quick Filters',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12.0,
                  runSpacing: 8.0,
                  children: [
                    _buildFilterChip('Local First', Icons.location_on),
                    _buildFilterChip('Sustainable', Icons.eco),
                    _buildFilterChip('Best Price', Icons.attach_money),
                    _buildFilterChip('Urgent Pickup', Icons.schedule),
                  ],
                ),
                const SizedBox(height: 24),
                if (provider.isLoading)
                  const Center(
                    child: Card(
                      elevation: 4,
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                        ),
                      ),
                    ),
                  )
                else if (provider.stores.isNotEmpty)
                  _buildComparisonTable(context, provider.stores),
                Card(
                  elevation: 6,
                  margin: const EdgeInsets.only(top: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ExpansionTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.route, color: Color(0xFFEF6C00)),
                      ),
                      title: const Text(
                        'Ultimate Trip Planner',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFBF360C),
                        ),
                      ),
                      subtitle: Text(
                        cartProducts.isEmpty 
                            ? 'Start adding items to plan your trip' 
                            : '${cartProducts.length} items ready for optimization',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: cartProducts.isEmpty 
                              ? Column(
                                  children: [
                                    Icon(Icons.shopping_cart_outlined, size: 48, color: Colors.orange[300]),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Your Trip Cart is Empty',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.brown),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Search for products above and click "Add" on any store to start planning your optimized shopping route.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.brown[700]),
                                    ),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Added Products:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Color(0xFFEF6C00),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: cartProducts.map((product) => Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade100,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: Colors.orange.shade300),
                                        ),
                                        child: Text(
                                          product,
                                          style: TextStyle(
                                            color: Colors.orange.shade800,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      )).toList(),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        _buildTripStat('Distance', '${(cartProducts.length * 0.8 + 0.5).toStringAsFixed(1)} km', Icons.directions),
                                        _buildTripStat('Time', '${((cartProducts.length * 0.8 + 0.5)*4.2).round()} min', Icons.access_time),
                                        _buildTripStat('CO2 Saved', '${((cartProducts.length * 0.8 + 0.5)*0.35).toStringAsFixed(1)} kg', Icons.eco),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            height: 45,
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [Color(0xFFEF6C00), Color(0xFFE65100)],
                                              ),
                                              borderRadius: BorderRadius.circular(22.5),
                                            ),
                                            child: ElevatedButton(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => ActionPage(
                                                      cartProducts: List.from(cartProducts),
                                                    ),
                                                  ),
                                                );
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.transparent,
                                                shadowColor: Colors.transparent,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(22.5),
                                                ),
                                              ),
                                              child: const Text(
                                                'Plan Trip',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Bottom actions
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ReferralPage(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.share, color: Color(0xFF1976D2)),
                            label: const Text(
                              'Referral/Share',
                              style: TextStyle(color: Color(0xFF1976D2)),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF3E5F5), Color(0xFFE1BEE7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const StockVerificationPage(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.verified, color: Color(0xFF7B1FA2)),
                            label: const Text(
                              'Verify Stock',
                              style: TextStyle(color: Color(0xFF7B1FA2)),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: null,
    );
  }

  void _showStoreDetails(Store store) {
    // Generate likely products based on category for demo
    // Generate likely products based on category with synced icons
    final List<Map<String, String>> likelyProducts = _getLikelyProductsForCategory(store.category);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: EdgeInsets.only(top: 12),
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(Icons.store, color: Colors.orange, size: 40),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                store.name,
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.location_on, size: 16, color: Colors.grey),
                                  SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      store.address,
                                      style: TextStyle(color: Colors.grey[600]),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 24),
                    
                    // Stats Grid
                    Row(
                      children: [
                        _buildDetailStat(Icons.directions_walk, '${store.distance.toStringAsFixed(1)} km', 'Distance'),
                        _buildDetailStat(Icons.timer, store.pickupTime, 'Pickup'),
                        _buildDetailStat(Icons.eco, '${store.carbonFootprint} kg', 'CO2 Saved'),
                      ],
                    ),
                    
                    SizedBox(height: 32),
                    Text(
                      'Probably Available Here',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Based on store category & history',
                      style: TextStyle(color: Colors.grey),
                    ),
                    SizedBox(height: 16),
                    
                    // Product Grid (The "Unique Way")
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.85,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: likelyProducts.length,
                      itemBuilder: (context, index) {
                        final product = likelyProducts[index];
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[50], 
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.orange.shade100),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  product['icon']!, 
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                product['name']!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'In Stock',
                                style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            // Bottom Action Bar
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
              ),
              child: Row(
                children: [
                   Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: Text('Close'),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                         Navigator.pop(context);
                         _addToTripCart('Visit ${store.name}');
                         ScaffoldMessenger.of(context).showSnackBar(
                           SnackBar(
                             content: Text('Added visit to ${store.name} to Trip Plan!'),
                             backgroundColor: Colors.green,
                             behavior: SnackBarBehavior.floating,
                             margin: const EdgeInsets.all(10),
                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                           )
                         );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: Text('Visit Store'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailStat(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4),
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.orange),
            SizedBox(height: 4),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(label, style: TextStyle(color: Colors.grey, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  List<Map<String, String>> _getLikelyProductsForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'pharmacy':
        return [
          {'name': 'Paracetamol', 'icon': '💊'},
          {'name': 'Vitamins', 'icon': '🧴'},
          {'name': 'Bandages', 'icon': '🩹'},
          {'name': 'Cough Syrup', 'icon': '🧪'},
          {'name': 'Masks', 'icon': '😷'},
          {'name': 'Thermometer', 'icon': '🌡️'},
          {'name': 'Sanitizer', 'icon': '🧼'},
        ];
      case 'grocery':
      case 'supermarket':
        return [
          {'name': 'Rice', 'icon': '🍚'},
          {'name': 'Milk', 'icon': '🥛'},
          {'name': 'Bread', 'icon': '🍞'},
          {'name': 'Eggs', 'icon': '🥚'},
          {'name': 'Vegetables', 'icon': '🥦'},
          {'name': 'Spices', 'icon': '🌶️'},
          {'name': 'Fruits', 'icon': '🍎'},
          {'name': 'Oil', 'icon': '🫗'},
        ];
      case 'electronics':
        return [
          {'name': 'Charger', 'icon': '🔌'},
          {'name': 'Headphones', 'icon': '🎧'},
          {'name': 'Batteries', 'icon': '🔋'},
          {'name': 'Screen Guard', 'icon': '📱'},
          {'name': 'Cables', 'icon': '🔗'},
          {'name': 'Mouse', 'icon': '🖱️'},
          {'name': 'Keyboard', 'icon': '⌨️'},
        ];
      case 'bakery':
        return [
          {'name': 'Cake', 'icon': '🎂'},
          {'name': 'Puffs', 'icon': '🥐'},
          {'name': 'Bread', 'icon': '🍞'},
          {'name': 'Biscuits', 'icon': '🍪'},
          {'name': 'Donuts', 'icon': '🍩'},
          {'name': 'Pastry', 'icon': '🍰'},
        ];
      case 'clothes':
      case 'fashion':
        return [
          {'name': 'T-Shirt', 'icon': '👕'},
          {'name': 'Jeans', 'icon': '👖'},
          {'name': 'Socks', 'icon': '🧦'},
          {'name': 'Jacket', 'icon': '🧥'},
          {'name': 'Shirt', 'icon': '👔'},
          {'name': 'Shoes', 'icon': '👟'},
        ];
      default:
        return [
          {'name': 'Top Selling Store', 'icon': '🏆'},
          {'name': 'Essentials', 'icon': '🎒'},
          {'name': 'New Arrival', 'icon': '🆕'},
          {'name': 'Discounted', 'icon': '🏷️'},
        ];
    }
  }

  Widget _buildFilterChip(String label, IconData icon) {
    final bool isSelected = _selectedFilters.contains(label);
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: isSelected ? Colors.white : const Color(0xFF2E7D32)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF2E7D32),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) => _toggleFilter(label),
      backgroundColor: isSelected ? const Color(0xFF4CAF50) : const Color(0xFFE8F5E8),
      selectedColor: const Color(0xFF4CAF50),
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
        side: BorderSide(
          color: isSelected ? Colors.transparent : const Color(0xFF4CAF50),
          width: 1,
        ),
      ),
    );
  }

  Widget _buildComparisonTable(BuildContext context, List<Store> stores) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04), // Softer shadow
            offset: const Offset(0, 3),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Compact Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade50.withOpacity(0.5), Colors.white],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              children: [
                Icon(Icons.compare_arrows, color: Colors.orange.shade800, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'Quick Compare', // Shorter title
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          
          // Scrollable Table content
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.grey.shade50),
              child: DataTable(
                columnSpacing: 16, // Reduced spacing
                horizontalMargin: 16,
                headingRowColor: MaterialStateProperty.all(Colors.transparent),
                headingRowHeight: 40, // Reduced header height
                dataRowMinHeight: 52, // Compact row height
                dataRowMaxHeight: 52,
                columns: [
                  _buildHeaderColumn('STORE', Icons.store),
                  _buildHeaderColumn('DIST', Icons.near_me), // Abbreviated
                  _buildHeaderColumn('PRICE', Icons.attach_money),
                  _buildHeaderColumn('STOCK', Icons.inventory_2),
                  _buildHeaderColumn('TIME', Icons.schedule),
                  _buildHeaderColumn('CO2', Icons.eco),
                  const DataColumn(label: Text('ACTIONS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.grey))),
                ],
                rows: stores.map((store) {
                  return DataRow(
                    cells: [
                      DataCell(
                        InkWell(
                          onTap: () => _showStoreDetails(store),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 10, // Smaller avatar
                                backgroundColor: Colors.orange.shade50,
                                child: Text(store.name[0], style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold, fontSize: 10)),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    store.name.length > 15 ? '${store.name.substring(0, 13)}...' : store.name, // Truncate long names
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.black87),
                                  ),
                                  // Removed address for compactness
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          '${store.distance.toStringAsFixed(1)}km',
                          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blue.shade700, fontSize: 11),
                        ),
                      ),
                      DataCell(
                        Text(
                          store.formattedPrice,
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700, fontSize: 11),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: store.stockStatus == 'In Stock' ? Colors.green.shade50 : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: store.stockStatus == 'In Stock' ? Colors.green.shade100 : Colors.red.shade100,
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            store.stockStatus == 'In Stock' ? 'In Stock' : 'Out',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: store.stockStatus == 'In Stock' ? Colors.green.shade700 : Colors.red.shade700,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Text(store.pickupTime, style: const TextStyle(fontSize: 11)),
                      ),
                      DataCell(
                        Text('${store.carbonFootprint}kg', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: Colors.grey.shade700)),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                             _buildActionButton(
                              icon: Icons.visibility_outlined,
                              color: Colors.grey.shade700,
                              bg: Colors.transparent,
                              size: 28,
                              iconSize: 16,
                              onTap: () => _showStoreDetails(store),
                            ),
                            const SizedBox(width: 4), // Tighter spacing
                            _buildActionButton(
                              icon: Icons.add_shopping_cart,
                              color: Colors.orange.shade700,
                              bg: Colors.orange.shade50,
                              size: 28,
                              iconSize: 16,
                              onTap: () => _addToTripCart('Items from ${store.name}'),
                            ),
                            const SizedBox(width: 4),
                            _buildActionButton(
                              icon: Icons.shopping_bag,
                              color: Colors.green.shade700,
                              bg: Colors.green.shade50,
                              size: 28,
                              iconSize: 16,
                              onTap: () => _navigateToReservation(store),
                            ),
                            const SizedBox(width: 4),
                            _buildActionButton(
                              icon: Icons.navigation_outlined,
                              color: Colors.blue.shade700,
                              bg: Colors.blue.shade50,
                              size: 28,
                              iconSize: 16,
                              onTap: () => StoreService.openGoogleMapsWithAddress(
                                store.lat, store.lng, store.name, store.address
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Updated Helper for consistent headers
  DataColumn _buildHeaderColumn(String label, IconData icon) {
    return DataColumn(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade400), // Smaller icon
          const SizedBox(width: 4),
          Text(
            label, 
            style: TextStyle(
              fontWeight: FontWeight.bold, 
              fontSize: 10, // Smaller font
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // Updated Helper for action buttons
  Widget _buildActionButton({
    required IconData icon, 
    required Color color, 
    required Color bg, 
    required VoidCallback onTap,
    double size = 32,
    double iconSize = 18,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: iconSize, color: color),
      ),
    );
  }

  Widget _buildTripStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFEF6C00), size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFFEF6C00),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  void _navigateToReservation(Store store) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReservationPage(
          store: store,
          productName: _searchController.text.isNotEmpty ? _searchController.text : 'Product',
        ),
      ),
    );
  }

}
