// home_empty_state.dart
import 'package:flutter/material.dart';

class HomeEmptyState extends StatelessWidget {
  const HomeEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.feed, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          const Text(
            'Henüz hiç gönderi yok',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          const Text(
            'İlk gönderiyi sen paylaş!',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Create post sayfasına yönlendirme
            },
            child: const Text('Gönderi Oluştur'),
          ),
        ],
      ),
    );
  }
}
