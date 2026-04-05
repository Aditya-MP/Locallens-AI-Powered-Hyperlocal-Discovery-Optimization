import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/referral_service.dart';

class ReferralPage extends StatefulWidget {
  const ReferralPage({super.key});

  @override
  State<ReferralPage> createState() => _ReferralPageState();
}

class _ReferralPageState extends State<ReferralPage> {
  String referralLink = 'Loading...';
  
  @override
  void initState() {
    super.initState();
    _initializeReferralCode();
  }

  // Initialize referral code once
  Future<void> _initializeReferralCode() async {
    try {
      await ReferralService.initializeUserId(); // Initialize persistent user ID
      final stats = await ReferralService.getReferralStats();
      String code;
      
      if (stats['referralCode'] == 'N/A' || stats['referralCode'] == null) {
        code = await ReferralService.generateReferralCode();
      } else {
        code = stats['referralCode'];
      }
      
      setState(() {
        referralLink = 'https://locallens.page.link/?link=https://locallens.com/ref/$code';
      });
    } catch (e) {
      print('Error initializing referral code: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Referral Program',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Card(
                elevation: 8,
                shadowColor: Colors.green.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.white, Color(0xFFF8F9FA)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Share Locallens & Earn 15% Off!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Invite friends to shop with Locallens. When they make their first purchase or pickup, you both get a 15% discount on your next order.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF616161),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Referral Link Section
              const Text(
                'Your Unique Referral Link',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE3F2FD), Color(0xFFE1F5FE)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.15),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              referralLink,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1976D2),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, color: Colors.white),
                            style: IconButton.styleFrom(
                              backgroundColor: Color(0xFF1976D2),
                              padding: EdgeInsets.all(12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () async {
                              await Clipboard.setData(ClipboardData(text: referralLink));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('✅ Link copied to clipboard!')),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      QrImageView(
                        data: referralLink,
                        version: QrVersions.auto,
                        size: 150.0,
                        backgroundColor: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Share Options
              const Text(
                'Share Options',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildShareButton(
                    'WhatsApp',
                    Icons.message,
                    const Color(0xFF25D366),
                    () => _shareViaWhatsApp(),
                  ),
                  _buildShareButton(
                    'SMS',
                    Icons.sms,
                    const Color(0xFF1976D2),
                    () => _shareViaSMS(),
                  ),
                  _buildShareButton(
                    'Email',
                    Icons.email,
                    const Color(0xFFEA4335),
                    () => _shareViaEmail(),
                  ),
                  _buildShareButton(
                    'Facebook',
                    Icons.facebook,
                    const Color(0xFF1877F2),
                    () => _shareViaFacebook(),
                  ),
                  _buildShareButton(
                    'Twitter',
                    Icons.alternate_email,
                    const Color(0xFF1DA1F2),
                    () => _shareViaTwitter(),
                  ),
                  _buildShareButton(
                    'More',
                    Icons.more_horiz,
                    const Color(0xFF9E9E9E),
                    () => _shareViaMore(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Real-time Referral Status
              StreamBuilder<Map<String, dynamic>>(
                stream: ReferralService.getReferralStatsStream(),
                builder: (context, snapshot) {
                  final stats = snapshot.data ?? {'referralsCount': 0, 'successfulReferrals': 0, 'referralPoints': 0};
                  final referralsCount = stats['referralsCount'] ?? 0;
                  final successfulReferrals = stats['successfulReferrals'] ?? 0;
                  final referralPoints = stats['referralPoints'] ?? 0;
                  final progress = successfulReferrals >= 3 ? 1.0 : successfulReferrals / 3.0;
                  
                  return Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Referral Status',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFEF6C00),
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () async {
                                  final code = referralLink.split('/').last;
                                  await ReferralService.processReferral(code);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('✅ Referral processed!')),
                                  );
                                },
                                child: snapshot.connectionState == ConnectionState.waiting
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.sync, color: Colors.green, size: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Invited: $referralsCount friends | Success: $successfulReferrals | Points: ₹$referralPoints',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF616161),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildRewardChip(Icons.people, '$referralsCount invites', Colors.blue),
                              _buildRewardChip(Icons.shopping_cart, '$successfulReferrals success', Colors.green),
                              _buildRewardChip(Icons.monetization_on, '₹$referralPoints', Colors.orange),
                            ],
                          ),
                          const SizedBox(height: 16),
                          LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.grey[300],
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFEF6C00)),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Next reward: ${3 - successfulReferrals} more successful referrals',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF757575),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Stats Card
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('users').doc(ReferralService.currentUserId).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();
                      
                      final data = snapshot.data!.data() as Map<String, dynamic>?;
                      final couponsUnlocked = (data?['couponsUnlocked'] as List?)?.length ?? 0;
                      final successfulReferrals = data?['successfulReferrals'] ?? 0;
                      
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _statTile('Friends', successfulReferrals.toString(), Icons.people),
                          _statTile('Coupons', couponsUnlocked.toString(), Icons.card_giftcard),
                          _statTile('Points', '${data?['referralPoints'] ?? 0}', Icons.star),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Discount Coupons Section
              const Text(
                '🎫 Your Discount Coupons',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 16),
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: ReferralService.getUserCouponsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 100,
                      child: Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50))),
                    );
                  }
                  
                  final coupons = snapshot.data ?? [];
                  
                  if (coupons.isEmpty) {
                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.grey[100]!, Colors.white],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.card_giftcard_outlined, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No Active Coupons',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Invite friends to unlock 5-25% OFF coupons!',
                              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  
                  return Column(
                    children: coupons.map((coupon) {
                      final expiresAt = (coupon['expiresAt'] as Timestamp?)?.toDate();
                      final daysLeft = expiresAt != null ? expiresAt.difference(DateTime.now()).inDays : 0;
                      return _buildCouponCard(
                        coupon['code'],
                        coupon['discountPercent'],
                        coupon['usesLeft'],
                        coupon['maxDiscountAmount'],
                        daysLeft,
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 24),

              // How It Works
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.white, Color(0xFFF8F9FA)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'How It Works',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildStep('Step 1: Share your link', Icons.share),
                      _buildStep('Step 2: Friend shops or picks up', Icons.shopping_cart),
                      _buildStep('Step 3: You both get 15% off', Icons.discount),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Terms & Conditions
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to terms page
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Terms & Conditions',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShareButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, color: Colors.white),
          label: Text(
            label,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF4CAF50), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF616161),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // REAL share functions
  void _shareViaWhatsApp() {
    final message = 'Try Locallens for smarter local shopping! Use my link for ₹50 off: $referralLink';
    Share.share(message, subject: 'Locallens Referral');
  }

  void _shareViaSMS() {
    final message = 'Download Locallens & get ₹50 off! $referralLink';
    Share.share(message);
  }

  void _shareViaEmail() {
    final message = 'Hey! Check out Locallens - hyperlocal shopping with real-time stock verification. Use my referral for ₹50 off both ways: $referralLink';
    Share.share(message, subject: 'Locallens Referral - ₹50 OFF');
  }

  void _shareViaFacebook() {
    final message = 'Try Locallens for smarter local shopping! Use my link for ₹50 off: $referralLink';
    Share.share(message, subject: 'Locallens Referral');
  }

  void _shareViaTwitter() {
    final message = 'Try Locallens for smarter local shopping! Use my link for ₹50 off: $referralLink';
    Share.share(message, subject: 'Locallens Referral');
  }

  void _shareViaMore() {
    final message = 'Try Locallens for smarter local shopping! Use my link for ₹50 off: $referralLink';
    Share.share(message, subject: 'Locallens Referral');
  }

  Widget _statTile(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF4CAF50), size: 28),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildCouponCard(String code, int percent, int usesLeft, int maxAmount, int daysLeft) {
    final color = _getCouponColor(percent);
    
    return Card(
      elevation: 8,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [color, color.withOpacity(0.8)]),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 12)],
              ),
              child: const Icon(
                Icons.local_offer,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '$percent% OFF',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: color,
                          shadows: const [Shadow(color: Colors.black26, offset: Offset(1, 1), blurRadius: 2)],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'ANY SHOP!',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Max ₹$maxAmount • $usesLeft uses left',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700], fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Code: $code',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                      fontFamily: 'monospace',
                    ),
                  ),
                  if (daysLeft < 7) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_amber, size: 14, color: Colors.orange[800]),
                          const SizedBox(width: 4),
                          Text('$daysLeft days left', style: TextStyle(fontSize: 11, color: Colors.orange[800])),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _copyCouponCode(code),
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('Copy'),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCouponColor(int percent) {
    if (percent >= 20) return Colors.purple;
    if (percent >= 10) return Colors.orange;
    return Colors.green;
  }

  void _copyCouponCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Coupon copied!'),
          ],
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildRewardChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 12)),
        ],
      ),
    );
  }
}
