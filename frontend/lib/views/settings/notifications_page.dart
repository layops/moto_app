import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
