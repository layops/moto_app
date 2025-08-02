import 'package:flutter/material.dart';

class CustomDrawer extends StatelessWidget {
  final String username;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const CustomDrawer({
    super.key,
    required this.username,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(username),
            accountEmail: Text('$username@example.com'),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.black),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Anasayfa'),
            selected: selectedIndex == 0,
            onTap: () => onTabSelected(0),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profil'),
            selected: selectedIndex == 1,
            onTap: () => onTabSelected(1),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Ayarlar'),
            selected: selectedIndex == 2,
            onTap: () => onTabSelected(2),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Çıkış Yap'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }
}
