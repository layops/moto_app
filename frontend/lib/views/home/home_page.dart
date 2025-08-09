import 'package:flutter/material.dart';
import '../../widgets/app_bars/base_app_bar.dart';

class HomePage extends StatelessWidget {
  final String? username; // Opsiyonel kullanıcı adı

  const HomePage({
    super.key,
    this.username,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        // Menü butonu için Drawer
        child: ListView(
          children: const [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Color(0xFFd32f2f),
              ),
              child: Text(
                'Menü',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Ana Sayfa'),
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Ayarlar'),
            ),
          ],
        ),
      ),
      appBar: BaseAppBar(
        title: 'Ana Sayfa',
        leadingButtonType: LeadingButtonType.menu,
      ),
      body: Center(
        child: Text(
          'Ana Sayfa - ${username ?? "Misafir"}',
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
