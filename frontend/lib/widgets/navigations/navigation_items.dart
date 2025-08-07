import 'package:flutter/material.dart';
import 'package:motoapp_frontend/widgets/navigations/bottom_nav_item.dart';

class NavigationItems {
  static const items = [
    BottomNavItem(icon: Icons.home_outlined, label: 'Home', index: 0),
    BottomNavItem(icon: Icons.search, label: 'Search', index: 1),
    BottomNavItem(icon: Icons.map_outlined, label: 'Map', index: 2),
    BottomNavItem(icon: Icons.message_outlined, label: 'Messages', index: 3),
    BottomNavItem(icon: Icons.person_outlined, label: 'Profile', index: 4),
  ];
}
