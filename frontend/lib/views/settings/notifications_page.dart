import 'package:flutter/material.dart';
import '../../services/service_locator.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  // Default values for notification toggles
  bool directMessages = true;
  bool groupMessages = true;
  bool rideReminders = true;
  bool eventUpdates = true;
  bool groupActivity = true;
  bool newMembers = true;
  bool challengesRewards = true;
  bool leaderboardUpdates = true;
  bool sound = true;
  bool vibration = true;
  
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreferences();
  }

  Future<void> _loadNotificationPreferences() async {
    try {
      final preferences = await ServiceLocator.notification.getNotificationPreferences();
      if (mounted) {
        setState(() {
          directMessages = preferences['direct_messages'] ?? true;
          groupMessages = preferences['group_messages'] ?? true;
          rideReminders = preferences['ride_reminders'] ?? true;
          eventUpdates = preferences['event_updates'] ?? true;
          groupActivity = preferences['group_activity'] ?? true;
          newMembers = preferences['new_members'] ?? true;
          challengesRewards = preferences['challenges_rewards'] ?? true;
          leaderboardUpdates = preferences['leaderboard_updates'] ?? true;
          sound = preferences['sound_enabled'] ?? true;
          vibration = preferences['vibration_enabled'] ?? true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bildirim tercihleri yüklenirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveNotificationPreferences() async {
    if (_isSaving) return;
    
    setState(() {
      _isSaving = true;
    });

    try {
      final preferences = {
        'direct_messages': directMessages,
        'group_messages': groupMessages,
        'ride_reminders': rideReminders,
        'event_updates': eventUpdates,
        'group_activity': groupActivity,
        'new_members': newMembers,
        'challenges_rewards': challengesRewards,
        'leaderboard_updates': leaderboardUpdates,
        'sound_enabled': sound,
        'vibration_enabled': vibration,
      };

      await ServiceLocator.notification.updateNotificationPreferences(preferences);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bildirim tercihleri başarıyla güncellendi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bildirim tercihleri güncellenirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Messages Section
          Text(
            'Messages',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildNotificationItem(
            title: 'Direct Messages',
            subtitle: 'New messages from other riders',
            value: directMessages,
            onChanged: (value) {
              setState(() {
                directMessages = value;
              });
              _saveNotificationPreferences();
            },
          ),
          const SizedBox(height: 12),
          _buildNotificationItem(
            title: 'Group Messages',
            subtitle: 'Notifications for group chats',
            value: groupMessages,
            onChanged: (value) {
              setState(() {
                groupMessages = value;
              });
              _saveNotificationPreferences();
            },
          ),
          const SizedBox(height: 24),

          // Events Section
          Text(
            'Events',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildNotificationItem(
            title: 'Ride Reminders',
            subtitle: 'Reminders for upcoming rides',
            value: rideReminders,
            onChanged: (value) {
              setState(() {
                rideReminders = value;
              });
              _saveNotificationPreferences();
            },
          ),
          const SizedBox(height: 12),
          _buildNotificationItem(
            title: 'Event Updates',
            subtitle: 'Updates on event details',
            value: eventUpdates,
            onChanged: (value) {
              setState(() {
                eventUpdates = value;
              });
              _saveNotificationPreferences();
            },
          ),
          const SizedBox(height: 24),

          // Groups Section
          Text(
            'Groups',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildNotificationItem(
            title: 'Group Activity',
            subtitle: 'Activity in your groups',
            value: groupActivity,
            onChanged: (value) {
              setState(() {
                groupActivity = value;
              });
              _saveNotificationPreferences();
            },
          ),
          const SizedBox(height: 12),
          _buildNotificationItem(
            title: 'New Members',
            subtitle: 'New members joining your groups',
            value: newMembers,
            onChanged: (value) {
              setState(() {
                newMembers = value;
              });
              _saveNotificationPreferences();
            },
          ),
          const SizedBox(height: 24),

          // Gamification Section
          Text(
            'Gamification',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildNotificationItem(
            title: 'Challenges & Rewards',
            subtitle: 'Notifications for challenges and rewards',
            value: challengesRewards,
            onChanged: (value) {
              setState(() {
                challengesRewards = value;
              });
              _saveNotificationPreferences();
            },
          ),
          const SizedBox(height: 12),
          _buildNotificationItem(
            title: 'Leaderboard Updates',
            subtitle: 'Updates on your leaderboard position',
            value: leaderboardUpdates,
            onChanged: (value) {
              setState(() {
                leaderboardUpdates = value;
              });
              _saveNotificationPreferences();
            },
          ),
          const SizedBox(height: 24),

          // Sound & Vibration Section
          Text(
            'Sound & Vibration',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildSimpleNotificationItem(
            title: 'Sound',
            value: sound,
            onChanged: (value) {
              setState(() {
                sound = value;
              });
              _saveNotificationPreferences();
            },
          ),
          const SizedBox(height: 12),
          _buildSimpleNotificationItem(
            title: 'Vibration',
            value: vibration,
            onChanged: (value) {
              setState(() {
                vibration = value;
              });
              _saveNotificationPreferences();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildSimpleNotificationItem({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
