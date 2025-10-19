import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ReferralPage extends StatelessWidget {
  const ReferralPage({super.key});

  final String referralLink = 'https://locallens.com/referral/12345'; // Mock referral link

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
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
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
                            icon: const Icon(Icons.copy, color: Color(0xFF1976D2)),
                            onPressed: () {
                              // Copy to clipboard functionality
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Link copied to clipboard!')),
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
                    () => _shareVia('WhatsApp'),
                  ),
                  _buildShareButton(
                    'SMS',
                    Icons.sms,
                    const Color(0xFF1976D2),
                    () => _shareVia('SMS'),
                  ),
                  _buildShareButton(
                    'Email',
                    Icons.email,
                    const Color(0xFFEA4335),
                    () => _shareVia('Email'),
                  ),
                  _buildShareButton(
                    'Facebook',
                    Icons.facebook,
                    const Color(0xFF1877F2),
                    () => _shareVia('Facebook'),
                  ),
                  _buildShareButton(
                    'Twitter',
                    Icons.alternate_email,
                    const Color(0xFF1DA1F2),
                    () => _shareVia('Twitter'),
                  ),
                  _buildShareButton(
                    'More',
                    Icons.more_horiz,
                    const Color(0xFF9E9E9E),
                    () => _shareVia('More'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Referral Status
              Card(
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
                      const Text(
                        'Referral Status',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFEF6C00),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'You\'ve invited 3 friends. 1 has made a purchase. You\'ve earned 1 reward!',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF616161),
                        ),
                      ),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: 0.33, // 1 out of 3
                        backgroundColor: Colors.grey[300],
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFEF6C00)),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Progress to next reward: 2 more referrals',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF757575),
                        ),
                      ),
                    ],
                  ),
                ),
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
                child: TextButton(
                  onPressed: () {
                    // Navigate to terms page
                  },
                  child: const Text(
                    'Terms & Conditions',
                    style: TextStyle(
                      color: Color(0xFF1976D2),
                      decoration: TextDecoration.underline,
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
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, color: color),
          label: Text(
            label,
            style: TextStyle(color: color),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
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

  void _shareVia(String platform) {
    final message = 'Try Locallens for smarter local shopping! Use my link for 15% off: $referralLink';
    Share.share(message, subject: 'Locallens Referral');
  }
}
