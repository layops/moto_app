import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../services/service_locator.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  List<Map<String, dynamic>> _leaderboardData = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedCategory = 'all'; // all, rides, events, posts

  @override
  void initState() {
    super.initState();
    _fetchLeaderboardData();
  }

  Future<void> _fetchLeaderboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await ServiceLocator.token.getToken();
      if (token != null) {
        // TODO: Backend'ten leaderboard verilerini çek
        // final data = await ServiceLocator.leaderboard.getLeaderboard(token, _selectedCategory);
        
        // Şimdilik mock data kullanıyoruz
        await Future.delayed(const Duration(seconds: 1)); // Simulated API call
        
        setState(() {
          _leaderboardData = _getMockData();
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Liderlik tablosu yüklenirken hata oluştu: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getMockData() {
    return [
      {
        'rank': 1,
        'username': 'moto_king',
        'displayName': 'Moto Kralı',
        'avatar': null,
        'points': 1250,
        'rides': 45,
        'events': 12,
        'posts': 23,
      },
      {
        'rank': 2,
        'username': 'speed_demon',
        'displayName': 'Hız Şeytanı',
        'avatar': null,
        'points': 1180,
        'rides': 38,
        'events': 15,
        'posts': 18,
      },
      {
        'rank': 3,
        'username': 'road_warrior',
        'displayName': 'Yol Savaşçısı',
        'avatar': null,
        'points': 1100,
        'rides': 42,
        'events': 8,
        'posts': 31,
      },
      {
        'rank': 4,
        'username': 'bike_master',
        'displayName': 'Bisiklet Ustası',
        'avatar': null,
        'points': 950,
        'rides': 35,
        'events': 10,
        'posts': 15,
      },
      {
        'rank': 5,
        'username': 'adventure_seeker',
        'displayName': 'Macera Arayıcısı',
        'avatar': null,
        'points': 880,
        'rides': 28,
        'events': 14,
        'posts': 22,
      },
    ];
  }

  Widget _buildCategorySelector() {
    final categories = [
      {'key': 'all', 'label': 'Genel'},
      {'key': 'rides', 'label': 'Sürüşler'},
      {'key': 'events', 'label': 'Etkinlikler'},
      {'key': 'posts', 'label': 'Gönderiler'},
    ];

    return Container(
      height: 50.h,
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category['key'];
          
          return Container(
            margin: EdgeInsets.only(right: 8.w),
            child: FilterChip(
              label: Text(
                category['label']!,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontSize: 14.sp,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedCategory = category['key']!;
                  });
                  _fetchLeaderboardData();
                }
              },
              backgroundColor: Colors.grey[200],
              selectedColor: Theme.of(context).primaryColor,
              checkmarkColor: Colors.white,
            ),
          );
        },
      ),
    );
  }

  Widget _buildLeaderboardItem(Map<String, dynamic> user, int index) {
    final isTopThree = user['rank'] <= 3;
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isTopThree ? Colors.amber[50] : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isTopThree ? Colors.amber[300]! : Colors.grey[300]!,
          width: isTopThree ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: isTopThree ? Colors.amber[400] : Colors.grey[400],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${user['rank']}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          SizedBox(width: 12.w),
          
          // Avatar
          CircleAvatar(
            radius: 25.r,
            backgroundColor: Colors.grey[300],
            child: user['avatar'] != null
                ? ClipOval(
                    child: Image.network(
                      user['avatar'],
                      width: 50.w,
                      height: 50.w,
                      fit: BoxFit.cover,
                    ),
                  )
                : Icon(
                    Icons.person,
                    size: 30.w,
                    color: Colors.grey[600],
                  ),
          ),
          
          SizedBox(width: 12.w),
          
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['displayName'],
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  '@${user['username']}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(Icons.stars, size: 16.w, color: Colors.amber[600]),
                    SizedBox(width: 4.w),
                    Text(
                      '${user['points']} puan',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber[700],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Stats
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildStatItem('Sürüş', user['rides']),
              _buildStatItem('Etkinlik', user['events']),
              _buildStatItem('Gönderi', user['posts']),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Text(
        '$value $label',
        style: TextStyle(
          fontSize: 11.sp,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liderlik Tablosu'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchLeaderboardData,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCategorySelector(),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64.w,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 16.h),
                            ElevatedButton(
                              onPressed: _fetchLeaderboardData,
                              child: const Text('Tekrar Dene'),
                            ),
                          ],
                        ),
                      )
                    : _leaderboardData.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.emoji_events_outlined,
                                  size: 64.w,
                                  color: Colors.grey[400],
                                ),
                                SizedBox(height: 16.h),
                                Text(
                                  'Henüz liderlik verisi yok',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _leaderboardData.length,
                            itemBuilder: (context, index) {
                              return _buildLeaderboardItem(_leaderboardData[index], index);
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
