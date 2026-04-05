import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:async';
import '../models/store.dart';
import '../services/store_service.dart';

class ReservationPage extends StatefulWidget {
  final Store store;
  final String productName;

  const ReservationPage({
    super.key,
    required this.store,
    required this.productName,
  });

  @override
  State<ReservationPage> createState() => _ReservationPageState();
}

class _ReservationPageState extends State<ReservationPage> {
  bool _isReserved = false;
  late Timer _timer;
  int _timeLeftInSeconds = 2 * 60 * 60; // 2 hours
  String _reservationId = '';

  @override
  void dispose() {
    if (_isReserved) {
      _timer.cancel();
    }
    super.dispose();
  }

  void _startTimer() {
    _reservationId = 'RES-${DateTime.now().millisecondsSinceEpoch}-${widget.store.name.substring(0, 3).toUpperCase()}';
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(
      oneSec,
      (Timer timer) {
        if (_timeLeftInSeconds == 0) {
          setState(() {
            timer.cancel();
            _isReserved = false; // Expire reservation
          });
        } else {
          setState(() {
            _timeLeftInSeconds--;
          });
        }
      },
    );
  }

  String _formatTime(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _confirmReservation() {
    setState(() {
      _isReserved = true;
      _startTimer();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Reservation Confirmed! (+100 Points)'),
          ],
        ),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          _isReserved ? 'Digital Pass' : 'Confirm Reservation',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isReserved ? _buildDigitalPass() : _buildConfirmationScreen(),
    );
  }

  Widget _buildConfirmationScreen() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Benefit Banner
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange[100]!, Colors.orange[50]!],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.local_offer, color: Colors.orange[800]),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Reserve now to lock the price and earn 100 Locallens points!',
                    style: TextStyle(
                      color: Colors.orange[900],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),

          // Product Card
          Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.shopping_bag, size: 40, color: Colors.green[700]),
                  ),
                  SizedBox(height: 16),
                  Text(
                    widget.productName,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'at ${widget.store.name}',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 24),
                  Divider(),
                  SizedBox(height: 16),
                  _buildDetailRow(Icons.location_on, 'Distance', '${widget.store.distance.toStringAsFixed(1)} km'),
                  SizedBox(height: 12),
                  _buildDetailRow(Icons.attach_money, 'Price', widget.store.formattedPrice),
                  SizedBox(height: 12),
                  _buildDetailRow(Icons.timer, 'Pickup In', widget.store.pickupTime),
                ],
              ),
            ),
          ),
          SizedBox(height: 32),

          // Action Button
          ElevatedButton(
            onPressed: _confirmReservation,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
            ),
            child: Text(
              'Confirm Reservation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'No payment required now. Pay at store.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildDigitalPass() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          // The Pass Ticket
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header (Green part)
                Container(
                  padding: EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Color(0xFF2E7D32),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'RESERVED',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              letterSpacing: 2,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            widget.productName,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.check, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                
                // Body (White part)
                Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Text(
                        'Show this QR code at the store',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      SizedBox(height: 24),
                      QrImageView(
                        data: _reservationId,
                        version: QrVersions.auto,
                        size: 200.0,
                        backgroundColor: Colors.white,
                      ),
                      SizedBox(height: 24),
                      Text(
                        _reservationId,
                        style: TextStyle(
                          fontFamily: 'Courier',
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 32),
                      
                      // Timer
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.red[100]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.timer, color: Colors.red[700], size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Expires in ${_formatTime(_timeLeftInSeconds)}',
                              style: TextStyle(
                                color: Colors.red[700],
                                fontWeight: FontWeight.bold,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Tear-off line visual
                Row(
                  children: List.generate(20, (index) => Expanded(
                    child: Container(
                      color: index % 2 == 0 ? Colors.transparent : Colors.grey[300],
                      height: 2,
                    ),
                  )),
                ),
                
                // Footer (Details)
                Padding(
                  padding: EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.store, color: Colors.grey[700]),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.store.name,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              widget.store.address,
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 24),
          
          // Directions Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: Icon(Icons.navigation, color: Colors.white),
              label: Text('Get Directions'),
              onPressed: () {
                 StoreService.openGoogleMapsWithAddress(
                    widget.store.lat, 
                    widget.store.lng, 
                    widget.store.name, 
                    widget.store.address
                 );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            SizedBox(width: 8),
            Text(label, style: TextStyle(color: Colors.grey[800], fontSize: 16)),
          ],
        ),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
      ],
    );
  }
}
