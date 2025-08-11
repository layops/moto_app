import 'package:flutter/material.dart';

import 'bottom_nav_item.dart'; // BottomNavItem sınıfını import edin

class NavigationItems {
  // Butonların sıralaması pages listesiyle tam uyumlu olmalı
  static const List<BottomNavItem> items = [
    BottomNavItem(icon: Icons.home, label: 'Anasayfa'),
    BottomNavItem(icon: Icons.search, label: 'Ara'),
    BottomNavItem(icon: Icons.map, label: 'Harita'),
    BottomNavItem(icon: Icons.message, label: 'Mesajlar'),
    BottomNavItem(icon: Icons.person, label: 'Profil'),
  ];
}
