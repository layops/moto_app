// C:\Users\celik\OneDrive\Belgeler\Projects\moto_app\frontend\lib\views\groups\widgets\group_card.dart

import 'package:flutter/material.dart';
import 'package:motoapp_frontend/core/theme/color_schemes.dart';
import 'package:motoapp_frontend/core/theme/theme_constants.dart';
import 'package:motoapp_frontend/services/auth/auth_service.dart';
import '../group_detail_page.dart';

class GroupCard extends StatelessWidget {
  final dynamic group;
  final bool isMyGroup;
  final AuthService authService;

  const GroupCard({
    super.key,
    required this.group,
    required this.isMyGroup,
    required this.authService,
  });

  @override
  Widget build(BuildContext context) {
    if (group is! Map<String, dynamic>) {
      return const Card(
        child: ListTile(title: Text('Geçersiz grup verisi')),
      );
    }

    final groupId = (group['id'] is int)
        ? group['id'] as int
        : int.tryParse(group['id'].toString()) ?? 0;
    final groupName = group['name']?.toString() ?? 'Grup';
    final description = group['description']?.toString() ?? 'Açıklama yok';
    final profilePictureUrl = group['profile_picture_url']?.toString();
    final memberCount = group['members']?.length?.toString() ?? '0';
    final createdDate = group['created_at']?.toString() ?? '';
    
    // Debug için grup verilerini yazdır
    print('Group Card - Group ID: $groupId');
    print('Group Card - Profile Picture URL: $profilePictureUrl');
    print('Group Card - Group Data: $group');

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GroupDetailPage(
              groupId: groupId, 
              groupData: group,
              authService: authService,
            ),
          ),
        );
      },
      child: Card(
        // ... (Kalan Card widget içeriği aynı kalacak)
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeConstants.borderRadiusLarge),
        ),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profil Fotoğrafı
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: AppColorSchemes.lightBackground,
                    ),
                    child: profilePictureUrl != null && profilePictureUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: Image.network(
                              profilePictureUrl,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                          : null,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                print('Group Card Image load error: $error');
                                return Icon(
                                  Icons.group,
                                  size: 30,
                                  color: AppColorSchemes.primaryColor,
                                );
                              },
                            ),
                          )
                        : Icon(
                            Icons.group,
                            size: 30,
                            color: AppColorSchemes.primaryColor,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(groupName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 4),
                        Text(description,
                            style: TextStyle(
                                color: AppColorSchemes.textSecondary,
                                fontSize: 14),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  if (!isMyGroup)
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColorSchemes.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              ThemeConstants.borderRadiusMedium),
                        ),
                      ),
                      child: const Text('Katıl'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.people,
                      size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text('$memberCount üye',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  const Spacer(),
                  if (createdDate.isNotEmpty)
                    Text('Oluşturuldu: ${_formatDate(createdDate)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays} gün önce';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} saat önce';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} dakika önce';
      } else {
        return 'Az önce';
      }
    } catch (e) {
      return 'Bilinmeyen';
    }
  }
}
