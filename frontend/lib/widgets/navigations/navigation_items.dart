import 'package:flutter/material.dart';
import 'bottom_nav_item.dart';

class NavigationItems {
  // Bottom navigation bar için item'lar - sıralama önemli!
  static const List<BottomNavItem> items = [
    BottomNavItem(icon: Icons.home, label: 'Home'),        // Index 0
    BottomNavItem(icon: Icons.map, label: 'Map'),          // Index 1
    BottomNavItem(icon: Icons.group, label: 'Groups'),     // Index 2
    BottomNavItem(icon: Icons.event, label: 'Events'),     // Index 3
    BottomNavItem(icon: Icons.message, label: 'Messages'), // Index 4
    BottomNavItem(icon: Icons.person, label: 'Profile'),   // Index 5
  ];
}
