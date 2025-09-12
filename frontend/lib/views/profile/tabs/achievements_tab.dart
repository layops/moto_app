import 'package:flutter/material.dart';

class AchievementsTab extends StatelessWidget {
  final List<dynamic>? achievements;

  const AchievementsTab({
    super.key,
    this.achievements,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Yolculuk bazlı başarımlar - gerçek uygulamada backend'den gelecek
    final sampleAchievements = [
      {
        'id': 1,
        'title': 'İlk Yolculuk',
        'description': 'İlk motosiklet yolculuğunuzu tamamladınız',
        'icon': Icons.two_wheeler,
        'isUnlocked': true,
        'unlockedDate': '2024-01-15',
        'points': 10,
        'progress': 1,
        'target': 1,
      },
      {
        'id': 2,
        'title': 'Yolcu',
        'description': '10 yolculuk tamamladınız',
        'icon': Icons.directions_bike,
        'isUnlocked': true,
        'unlockedDate': '2024-01-20',
        'points': 25,
        'progress': 10,
        'target': 10,
      },
      {
        'id': 3,
        'title': 'Deneyimli Sürücü',
        'description': '50 yolculuk tamamladınız',
        'icon': Icons.motorcycle,
        'isUnlocked': false,
        'unlockedDate': null,
        'points': 50,
        'progress': 23,
        'target': 50,
      },
      {
        'id': 4,
        'title': 'Usta Sürücü',
        'description': '100 yolculuk tamamladınız',
        'icon': Icons.speed,
        'isUnlocked': false,
        'unlockedDate': null,
        'points': 100,
        'progress': 23,
        'target': 100,
      },
      {
        'id': 5,
        'title': 'Mesafe Avcısı',
        'description': '1000 km yol katettiniz',
        'icon': Icons.straighten,
        'isUnlocked': false,
        'unlockedDate': null,
        'points': 75,
        'progress': 450,
        'target': 1000,
      },
      {
        'id': 6,
        'title': 'Hız Tutkunu',
        'description': '120 km/h hıza ulaştınız',
        'icon': Icons.flash_on,
        'isUnlocked': false,
        'unlockedDate': null,
        'points': 60,
        'progress': 95,
        'target': 120,
      },
      {
        'id': 7,
        'title': 'Günlük Sürücü',
        'description': '7 gün üst üste yolculuk yaptınız',
        'icon': Icons.calendar_today,
        'isUnlocked': false,
        'unlockedDate': null,
        'points': 40,
        'progress': 3,
        'target': 7,
      },
      {
        'id': 8,
        'title': 'Gece Sürücüsü',
        'description': '10 gece yolculuğu tamamladınız',
        'icon': Icons.nightlight_round,
        'isUnlocked': false,
        'unlockedDate': null,
        'points': 35,
        'progress': 2,
        'target': 10,
      },
    ];

    // Backend'den gelen veriyi frontend formatına çevir
    List<dynamic> achievementsList;
    if (achievements != null && achievements!.isNotEmpty) {
      achievementsList = achievements!.map((achievement) {
        return {
          'id': achievement['id'],
          'title': achievement['name'],
          'description': achievement['description'],
          'icon': _getIconFromString(achievement['icon']),
          'isUnlocked': false, // Şimdilik hepsi kilitli
          'unlockedDate': null,
          'points': achievement['points'],
          'progress': 0, // Şimdilik 0
          'target': achievement['target_value'],
        };
      }).toList();
    } else {
      achievementsList = [];
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık ve istatistikler
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary.withOpacity(0.1),
                  colorScheme.secondary.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outline.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.emoji_events,
                    color: colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Yolculuk Başarımları',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${achievementsList.where((a) => a['isUnlocked'] == true).length}/${achievementsList.length} başarım kazandınız',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${achievementsList.where((a) => a['isUnlocked'] == true).fold(0, (sum, a) => sum + (a['points'] as int))} puan',
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Başarımlar listesi
          if (achievementsList.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.emoji_events_outlined,
                    size: 64,
                    color: colorScheme.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Henüz başarım bulunmuyor',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Yolculuk yaparak başarımlar kazanabilirsiniz',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.5),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ] else ...[
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: achievementsList.length,
              itemBuilder: (context, index) {
                final achievement = achievementsList[index];
                final isUnlocked = achievement['isUnlocked'] as bool;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isUnlocked 
                        ? colorScheme.surface
                        : colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isUnlocked 
                          ? colorScheme.primary.withOpacity(0.2)
                          : colorScheme.outline.withOpacity(0.1),
                      width: 1,
                    ),
                    boxShadow: isUnlocked ? [
                      BoxShadow(
                        color: colorScheme.shadow.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ] : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isUnlocked 
                              ? colorScheme.primary.withOpacity(0.1)
                              : colorScheme.surfaceVariant.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          achievement['icon'] as IconData,
                          color: isUnlocked 
                              ? colorScheme.primary
                              : colorScheme.onSurface.withOpacity(0.4),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    achievement['title'] as String,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: isUnlocked 
                                          ? colorScheme.onSurface
                                          : colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                ),
                                if (isUnlocked)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '+${achievement['points']}',
                                      style: TextStyle(
                                        color: colorScheme.onPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              achievement['description'] as String,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isUnlocked 
                                    ? colorScheme.onSurface.withOpacity(0.7)
                                    : colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                            if (isUnlocked && achievement['unlockedDate'] != null) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 14,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Kazanıldı: ${achievement['unlockedDate']}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ] else if (!isUnlocked) ...[
                              const SizedBox(height: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${achievement['progress']}/${achievement['target']}',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurface.withOpacity(0.6),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        '${((achievement['progress'] as int) / (achievement['target'] as int) * 100).round()}%',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurface.withOpacity(0.6),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  LinearProgressIndicator(
                                    value: (achievement['progress'] as int) / (achievement['target'] as int),
                                    backgroundColor: colorScheme.surfaceVariant.withOpacity(0.3),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      colorScheme.primary.withOpacity(0.6),
                                    ),
                                    minHeight: 4,
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'two_wheeler':
        return Icons.two_wheeler;
      case 'directions_bike':
        return Icons.directions_bike;
      case 'motorcycle':
        return Icons.motorcycle;
      case 'speed':
        return Icons.speed;
      case 'straighten':
        return Icons.straighten;
      case 'flash_on':
        return Icons.flash_on;
      case 'calendar_today':
        return Icons.calendar_today;
      case 'nightlight_round':
        return Icons.nightlight_round;
      case 'emoji_events':
        return Icons.emoji_events;
      default:
        return Icons.emoji_events;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}
