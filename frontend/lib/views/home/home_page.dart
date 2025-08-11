import 'package:flutter/material.dart';
import '../../widgets/app_bars/base_app_bar.dart';
import '../groups/group_page.dart'; // GroupsPage'i import et

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
        child: ListView(
          children: [
            const DrawerHeader(
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
              leading: const Icon(Icons.home),
              title: const Text('Ana Sayfa'),
              onTap: () {
                Navigator.pop(context); // Drawer'ı kapat
                // İstersen ana sayfa zaten açıksa sadece kapatabilirsin
              },
            ),
            ListTile(
              leading: const Icon(Icons.group),
              title: const Text('Gruplar'),
              onTap: () {
                Navigator.pop(context); // Drawer'ı kapat
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GroupsPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Ayarlar'),
              onTap: () {
                Navigator.pop(context); // Drawer'ı kapat
                // Ayarlar sayfasına geçiş kodunu buraya ekleyebilirsin
              },
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
