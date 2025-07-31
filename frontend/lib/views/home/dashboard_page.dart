// frontend/lib/views/home/dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:motoapp_frontend/services/api_service.dart';
import 'package:motoapp_frontend/views/auth/login_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final ApiService _apiService = ApiService();
  String _username = 'Kullanıcı';
  int _selectedIndex = 0;

  // Sayfalar listesi artık 'late final' değil, bir getter olarak tanımlanıyor.
  // Bu sayede Theme.of(context) gibi InheritedWidget'lar build metodu içinde güvenle kullanılabilir.
  List<Widget> get _widgetOptions => <Widget>[
        _buildHomePage(), // Ana Sayfa içeriği
        const Center(child: Text('Gruplar Sayfası İçeriği')), // Gruplar sayfası
        const Center(
            child: Text('Sürüşler Sayfası İçeriği')), // Sürüşler sayfası
        const Center(child: Text('Profil Sayfası İçeriği')), // Profil sayfası
      ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    // _widgetOptions artık burada başlatılmıyor.
  }

  Future<void> _loadUserData() async {
    print("DEBUG Dashboard: _loadUserData çağrıldı.");
    final storedUsername = await _apiService.getUsername();
    print(
        "DEBUG Dashboard: SharedPreferences'tan okunan kullanıcı adı: $storedUsername");

    if (storedUsername != null && storedUsername.isNotEmpty) {
      setState(() {
        _username = storedUsername;
        print("DEBUG Dashboard: Kullanıcı adı güncellendi: $_username");
      });
    } else {
      print(
          "DEBUG Dashboard: Kullanıcı adı bulunamadı veya boş. Varsayılan 'Kullanıcı' kalacak.");
    }
  }

  Future<void> _logout() async {
    print("DEBUG Dashboard: Çıkış işlemi başlatıldı.");
    await _apiService.deleteAuthToken();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (Route<dynamic> route) => false,
      );
      print("DEBUG Dashboard: Çıkış başarılı, LoginPage'e yönlendirildi.");
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildHomePage() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hoş Geldin, $_username!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 28.sp,
                ),
          ),
          SizedBox(height: 20.h),
          Text(
            'Motosiklet dünyasına dalmaya hazır mısın?',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 16.sp,
                ),
          ),
          SizedBox(height: 40.h),
          Card(
            child: InkWell(
              onTap: () {
                _onItemTapped(3);
              },
              borderRadius: BorderRadius.circular(15.r),
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: Row(
                  children: [
                    Icon(Icons.person_outline,
                        size: 30.w,
                        color: Theme.of(context).colorScheme.primary),
                    SizedBox(width: 15.w),
                    Expanded(
                      child: Text(
                        'Profilimi Görüntüle',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios,
                        size: 20.w,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.5)),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 30.h),
          Text(
            'Son Sürüşlerin',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 22.sp,
                ),
          ),
          SizedBox(height: 15.h),
          Container(
            height: 120.h,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(15.r),
            ),
            alignment: Alignment.center,
            child: Text(
              'Son sürüşleriniz burada listelenecek.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
            ),
          ),
          SizedBox(height: 30.h),
          Text(
            'Yaklaşan Etkinlikler',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 22.sp,
                ),
          ),
          SizedBox(height: 15.h),
          Container(
            height: 120.h,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(15.r),
            ),
            alignment: Alignment.center,
            child: Text(
              'Yaklaşan etkinlikleriniz burada görünecek.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
            ),
          ),
          SizedBox(height: 30.h),
          Text(
            'Hızlı Erişim',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 22.sp,
                ),
          ),
          SizedBox(height: 15.h),
          ElevatedButton(
            onPressed: () {
              _onItemTapped(1);
            },
            child: const Text('Gruplar'),
          ),
          SizedBox(height: 15.h),
          ElevatedButton(
            onPressed: () {
              _onItemTapped(2);
            },
            child: const Text('Sürüşler'),
          ),
          SizedBox(height: 15.h),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Liderlik Tablosu yakında!',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
              );
            },
            child: const Text('Liderlik Tabloları'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Spiride - ${_username == 'Kullanıcı' ? 'Hoş Geldin!' : _username}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Çıkış Yap',
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ],
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Gruplar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_bike),
            label: 'Sürüşler',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
