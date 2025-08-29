// C:\Users\celik\OneDrive\Belgeler\Projects\moto_app\frontend\lib\views\groups\widgets\group_list_section.dart

import 'package:flutter/material.dart';
import 'package:motoapp_frontend/core/theme/color_schemes.dart';
import 'package:motoapp_frontend/core/theme/theme_constants.dart';
import 'group_card.dart';

class GroupListSection extends StatelessWidget {
  final String title;
  final List<dynamic> groups;
  final bool isMyGroupsSection;
  final Widget? emptyStateWidget;

  const GroupListSection({
    super.key,
    required this.title,
    required this.groups,
    this.isMyGroupsSection = false,
    this.emptyStateWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColorSchemes.textPrimary,
              ),
        ),
        const SizedBox(height: 16),
        if (groups.isEmpty)
          emptyStateWidget ??
              Container(
                padding: ThemeConstants.paddingLarge,
                decoration: BoxDecoration(
                  color: AppColorSchemes.lightBackground,
                  borderRadius:
                      BorderRadius.circular(ThemeConstants.borderRadiusMedium),
                ),
                child: Center(
                  child: Text(
                    'Grup bulunamadı',
                    style: TextStyle(color: AppColorSchemes.textSecondary),
                  ),
                ),
              )
        else
          Column(
            children: groups
                .map((group) => GroupCard(
                      group: group,
                      isMyGroup: isMyGroupsSection,
                    ))
                .toList(),
          ),
      ],
    );
  }
}
