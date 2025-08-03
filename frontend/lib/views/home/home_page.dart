import 'package:flutter/material.dart';
import '../home/dashboard_page.dart';
import '../groups/group_page.dart';
import '../leaderboard/leaderboard_page.dart';
import '../../widgets/custom_bottom_navbar.dart';
import '../../widgets/maps_widgets/map_page.dart';

class HomePage extends StatefulWidget {
  final String username;

  const HomePage({super.key, required this.username});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;
  final List<String> _appBarTitles = const [
    'Dashboard',
    'Sıralama', // Leaderboard için
    'Harita', // MapPage için
    'Gruplar', // GroupPage için
  ];

  @override
  void initState() {
    super.initState();
    _pages = [
      DashboardPage(username: widget.username),
      const LeaderboardPage(), // Index 1 (BottomNavBar'da "Sıralama")
      const MapPage(), // Index 2 (FAB ile erişilen)
      const GroupPage(), // Index 3 (BottomNavBar'da yok)
    ];
  }

  void _onItemTapped(int index) {
    if (index >= 0 && index < _pages.length) {
      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitles[_selectedIndex]),
        centerTitle: true,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _onItemTapped(2), // Harita sayfasına geçiş
        child: const Icon(Icons.map),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
