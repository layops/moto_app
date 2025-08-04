// navigation_items.dart
import 'package:flutter/material.dart';
import 'package:motoapp_frontend/widgets/navigations/bottom_nav_item.dart';

class NavigationItems {
  static const items = [
    BottomNavItem(icon: Icons.home, label: 'Ana Sayfa', index: 0),
    BottomNavItem(icon: Icons.group, label: 'Gruplar', index: 1),
    BottomNavItem(icon: Icons.map, label: 'Harita', index: 2),
    BottomNavItem(icon: Icons.person, label: 'Profil', index: 3),
    BottomNavItem(icon: Icons.settings, label: 'Ayarlar', index: 4),
  ];
}
