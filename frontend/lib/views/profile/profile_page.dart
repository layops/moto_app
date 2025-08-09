import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../settings/settings_page.dart';

class ProfilePage extends StatefulWidget {
  final String email;
  final void Function(File)? onImageUploaded;

  const ProfilePage({
    super.key,
    required this.email,
    this.onImageUploaded,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _imageFile;
  int _selectedTab = 0;

  void _signOut(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFFd32f2f)),
              child: Text(
                'Profil Menüsü',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Profil Düzenle'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Ayarlar'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Çıkış Yap'),
              onTap: () => _signOut(context),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.transparent,
                  backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
                  child: _imageFile == null
                      ? Icon(Icons.account_circle, size: 100, color: Colors.grey[400])
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  widget.email,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text('Takip Et'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text('Mesaj'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            height: 55,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedTab = 0),
                    child: Container(
                      color: _selectedTab == 0 ? Colors.grey[200] : null,
                      height: 45,
                      child: Icon(
                        Icons.post_add,
                        color: _selectedTab == 0 
                            ? Theme.of(context).primaryColor 
                            : Colors.grey,
                        size: 30,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedTab = 1),
                    child: Container(
                      color: _selectedTab == 1 ? Colors.grey[200] : null,
                      height: 45,
                      child: Icon(
                        Icons.photo_library,
                        color: _selectedTab == 1 
                            ? Theme.of(context).primaryColor 
                            : Colors.grey,
                        size: 30,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedTab = 2),
                    child: Container(
                      color: _selectedTab == 2 ? Colors.grey[200] : null,
                      height: 45,
                      child: Icon(
                        Icons.info,
                        color: _selectedTab == 2 
                            ? Theme.of(context).primaryColor 
                            : Colors.grey,
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _selectedTab == 0
                ? _buildPostsContent()
                : _selectedTab == 1
                    ? _buildMediaContent()
                    : _buildProfileInfoContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsContent() {
    return const Center(
      child: Text('Postlar Burada Gösterilecek', style: TextStyle(fontSize: 18)),
    );
  }

  Widget _buildMediaContent() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        return Container(
          color: Colors.grey[200],
          child: Center(
            child: Icon(
              index % 3 == 0 ? Icons.videocam : Icons.photo,
              size: 40,
              color: Colors.grey[600],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileInfoContent() {
    return ListView(
      children: const [
        ListTile(
          leading: Icon(Icons.email),
          title: Text('Email'),
          subtitle: Text('user@example.com'),
        ),
        ListTile(
          leading: Icon(Icons.calendar_today),
          title: Text('Üyelik Tarihi'),
          subtitle: Text('1 Ocak 2023'),
        ),
        ListTile(
          leading: Icon(Icons.location_on),
          title: Text('Konum'),
          subtitle: Text('İstanbul, Türkiye'),
        ),
        ListTile(
          leading: Icon(Icons.motorcycle),
          title: Text('Motor Modeli'),
          subtitle: Text('Yamaha MT-07'),
        ),
      ],
    );
  }
}