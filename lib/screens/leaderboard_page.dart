import 'package:flutter/material.dart';
import '../services/community_service.dart';

class LeaderboardPage extends StatefulWidget {
  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🏆 Community Leaderboard'),
        backgroundColor: Color(0xFF4CAF50),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _getLeaderboardStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          
          final leaderboard = snapshot.data!;
          
          return ListView.builder(
            padding: EdgeInsets.all(20),
            itemCount: leaderboard.length,
            itemBuilder: (context, index) {
              final user = leaderboard[index];
              return Card(
                margin: EdgeInsets.only(bottom: 12),
                elevation: 4,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: index == 0 ? Colors.amber : Colors.grey,
                    child: Text('${index + 1}', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  title: Text(user['username'] ?? 'User ${user['userId']}'),
                  subtitle: Text('${user['verifications']} verifications • ${user['trustScore'].toStringAsFixed(1)}⭐'),
                  trailing: Text('${user['points']} pts', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4CAF50))),
                ),
              );
            },
          );
        },
      ),
    );
  }
  
  // Replace mock data with real Firebase stream
  Stream<List<Map<String, dynamic>>> _getLeaderboardStream() {
    return CommunityService.getLeaderboard();
  }
}