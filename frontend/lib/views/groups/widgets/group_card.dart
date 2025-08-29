// C:\Users\celik\OneDrive\Belgeler\Projects\moto_app\frontend\lib\views\groups\widgets\group_card.dart

import 'package:flutter/material.dart';
import 'package:motoapp_frontend/core/theme/color_schemes.dart';
import 'package:motoapp_frontend/core/theme/theme_constants.dart';
import '../group_detail_page.dart';

class GroupCard extends StatelessWidget {
  final dynamic group;
  final bool isMyGroup;

  const GroupCard({
    super.key,
    required this.group,
    required this.isMyGroup,
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
    final location = group['location']?.toString() ?? 'San Francisco, CA';
    final memberCount = group['member_count']?.toString() ?? '1,247';
    final activeTime = group['active_time']?.toString() ?? '2 hours ago';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                GroupDetailPage(groupId: groupId, groupData: group),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(groupName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 8),
                        Text(description,
                            style: TextStyle(
                                color: AppColorSchemes.textSecondary,
                                fontSize: 14)),
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
                      child: const Text('Join'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on,
                      size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(location,
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  const Spacer(),
                  Text('$memberCount members',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
              const SizedBox(height: 8),
              Text('Active $activeTime',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }
}
