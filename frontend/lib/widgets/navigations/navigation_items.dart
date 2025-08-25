import 'package:flutter/material.dart';
import 'bottom_nav_item.dart';

class NavigationItems {
  // Görseldeki bottom navigation yapısına göre güncelleme
  static const List<BottomNavItem> items = [
    BottomNavItem(icon: Icons.home, label: 'Home'),
    BottomNavItem(icon: Icons.map, label: 'Map'),
    BottomNavItem(icon: Icons.group, label: 'Groups'),
    BottomNavItem(icon: Icons.event, label: 'Events'),
    BottomNavItem(icon: Icons.person, label: 'Profile'),
  ];
}
