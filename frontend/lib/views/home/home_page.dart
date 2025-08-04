import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  final String? username; // Nullable yapın

  const HomePage({
    super.key,
    this.username, // Artık required değil
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Ana Sayfa - ${username ?? "Misafir"}'),
      ),
    );
  }
}
