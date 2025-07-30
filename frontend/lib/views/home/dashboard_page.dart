// frontend/lib/views/home/dashboard_page.dart

import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text('Giriş Başarılı! Burası Dashboard Sayfası.'),
      ),
    );
  }
}
