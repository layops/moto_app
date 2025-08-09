import 'package:flutter/material.dart';
import 'bottom_nav_item.dart';

class MainWrapper extends StatefulWidget {
  final List<Widget> pages;
  final List<BottomNavItem> navItems;

  const MainWrapper({
    super.key,
    required this.pages,
    required this.navItems,
  });

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar yok burada
      body: widget.pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        items: widget.navItems
            .map((item) => BottomNavigationBarItem(
                  icon: Icon(item.icon),
                  label: item.label,
                ))
            .toList(),
        onTap: _onTabSelected,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        showUnselectedLabels: true,
      ),
    );
  }
}
