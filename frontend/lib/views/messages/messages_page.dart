import 'package:flutter/material.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: 15,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.person),
              ),
              title: Text('User ${index + 1}'),
              subtitle: const Text('Last message preview...'),
              trailing: const Text('12:30 PM'),
              onTap: () {
                // Mesaj detayına git
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'messages_fab',
        child: const Icon(Icons.message),
        onPressed: () {
          // Yeni mesaj oluştur
        },
      ),
    );
  }
}
