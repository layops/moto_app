import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'bottom_nav_item.dart';

class MainWrapperNew extends StatefulWidget {
  final List<Widget> pages;
  final List<BottomNavItem> navItems;

  const MainWrapperNew({
    super.key,
    required this.pages,
    required this.navItems,
  });

  @override
  State<MainWrapperNew> createState() => _MainWrapperNewState();
}

class _MainWrapperNewState extends State<MainWrapperNew> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    
    // Debug için navigation yapısını göster (sadece debug modda)
    if (kDebugMode) {
      print("=== YENİ NAVIGATION INIT ===");
      print("NavItems sayısı: ${widget.navItems.length}");
      print("Pages sayısı: ${widget.pages.length}");
      
      for (int i = 0; i < widget.navItems.length; i++) {
        print("NavItem $i: ${widget.navItems[i].label}");
      }
      
      for (int i = 0; i < widget.pages.length; i++) {
        print("Page $i: ${widget.pages[i].runtimeType}");
      }
      print("===========================");
    }
  }

  void _onTabSelected(int index) {
    if (kDebugMode) {
      print("=== YENİ NAVIGATION DEBUG ===");
      print("Tıklanan buton index: $index");
      print("Tıklanan buton: ${widget.navItems[index].label}");
      print("Açılacak sayfa: ${widget.pages[index].runtimeType}");
      print("=============================");
    }

    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: widget.pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
        type: BottomNavigationBarType.fixed,
        items: widget.navItems.map((item) {
          return BottomNavigationBarItem(
            icon: Icon(item.icon),
            label: item.label,
          );
        }).toList(),
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        showUnselectedLabels: true,
      ),
    );
  }
}
