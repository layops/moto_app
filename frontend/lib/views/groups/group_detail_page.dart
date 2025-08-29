// C:\Users\celik\OneDrive\Belgeler\Projects\moto_app\frontend\lib\views\groups\group_detail_page.dart

import 'package:flutter/material.dart';
import 'package:motoapp_frontend/core/theme/color_schemes.dart';
import 'package:motoapp_frontend/core/theme/theme_constants.dart';

class GroupDetailPage extends StatelessWidget {
  final int groupId;
  final Map<String, dynamic> groupData;

  const GroupDetailPage({
    super.key,
    required this.groupId,
    required this.groupData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(groupData['name'] ?? 'Grup Detayları'),
        backgroundColor: AppColorSchemes.surfaceColor,
        foregroundColor: AppColorSchemes.textPrimary,
        elevation: 0,
      ),
      body: Padding(
        padding: ThemeConstants.paddingLarge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Grup başlık bölümü
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColorSchemes.surfaceColor,
                borderRadius:
                    BorderRadius.circular(ThemeConstants.borderRadiusLarge),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    groupData['name'] ?? 'Grup Adı Yok',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    groupData['description'] ?? 'Açıklama Yok',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColorSchemes.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildInfoChip(
                        icon: Icons.people,
                        text: '${groupData['member_count'] ?? '0'} üye',
                      ),
                      const SizedBox(width: 8),
                      _buildInfoChip(
                        icon: Icons.location_on,
                        text: groupData['location'] ?? 'Konum belirtilmemiş',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Grup aksiyon butonları
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColorSchemes.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Gruba Katıl'),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () {},
                  style: IconButton.styleFrom(
                    backgroundColor: AppColorSchemes.lightBackground,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Grup içeriği bölümleri
            const Text('Grup İçeriği',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: DefaultTabController(
                length: 3,
                child: Column(
                  children: [
                    const TabBar(
                      tabs: [
                        Tab(text: 'Gönderiler'),
                        Tab(text: 'Etkinlikler'),
                        Tab(text: 'Üyeler'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildPlaceholderContent('Henüz gönderi yok'),
                          _buildPlaceholderContent('Henüz etkinlik yok'),
                          _buildPlaceholderContent('Üye listesi yükleniyor'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String text}) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(text, style: const TextStyle(fontSize: 12)),
      backgroundColor: AppColorSchemes.lightBackground,
    );
  }

  Widget _buildPlaceholderContent(String message) {
    return Center(
      child: Text(
        message,
        style: TextStyle(
          color: AppColorSchemes.textSecondary,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
