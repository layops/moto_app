import 'package:flutter/material.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final List<Map<String, dynamic>> _notifications = [
    {
      'type': 'like',
      'user': 'Sarah Chen',
      'content': 'Bay Bridge Night Ride - 95 km',
      'time': '5 minutes ago',
      'read': false,
    },
    {
      'type': 'comment',
      'user': 'Mike Johnson',
      'content': 'Awesome ride! I love that route through the hills.',
      'time': '1 hour ago',
      'read': false,
    },
    {
      'type': 'group',
      'user': 'Bay Area Riders',
      'content': 'Welcome Jessica Martinez to the group!',
      'time': '2 hours ago',
      'read': false,
    },
    {
      'type': 'event',
      'user': 'Laguna Seca Raceway',
      'content': 'Event starts tomorrow at 8:00 AM',
      'time': '3 hours ago',
      'read': true,
    },
    {
      'type': 'achievement',
      'user': 'RideSocial',
      'content':
          'You earned the "Century Rider" badge for completing 100 rides',
      'time': '1 day ago',
      'read': true,
    },
    {
      'type': 'like',
      'user': 'Alex Thompson',
      'content': 'Napa Valley Tour - 156 km',
      'time': '1 day ago',
      'read': true,
    },
    {
      'type': 'group_post',
      'user': 'Track Day Warriors',
      'content': 'Sunset Canyon Run - Who\'s interested?',
      'time': '2 days ago',
      'read': true,
    },
    {
      'type': 'comment',
      'user': 'Emma Wilson',
      'content': 'Great photos! That sunset looks incredible.',
      'time': '2 days ago',
      'read': true,
    },
  ];

  void _markAllAsRead() {
    setState(() {
      for (var notification in _notifications) {
        notification['read'] = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n['read']).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(color: Colors.blue),
              ),
            ),
        ],
      ),
      body: ListView.builder(
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          final isRead = notification['read'] as bool;

          return ListTile(
            leading: _getNotificationIcon(notification['type']),
            title: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: notification['user'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isRead ? Colors.grey : Colors.black,
                    ),
                  ),
                  TextSpan(
                    text: ' ${_getNotificationAction(notification['type'])}',
                    style: TextStyle(
                      color: isRead ? Colors.grey : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification['content'],
                  style: TextStyle(
                    color: isRead ? Colors.grey : Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notification['time'],
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            tileColor: isRead ? null : Colors.blue[50],
            onTap: () {
              setState(() {
                notification['read'] = true;
              });
            },
          );
        },
      ),
    );
  }

  Widget _getNotificationIcon(String type) {
    switch (type) {
      case 'like':
        return const Icon(Icons.favorite, color: Colors.red);
      case 'comment':
        return const Icon(Icons.comment, color: Colors.blue);
      case 'group':
        return const Icon(Icons.group, color: Colors.green);
      case 'event':
        return const Icon(Icons.event, color: Colors.orange);
      case 'achievement':
        return const Icon(Icons.emoji_events, color: Colors.amber);
      case 'group_post':
        return const Icon(Icons.post_add, color: Colors.purple);
      default:
        return const Icon(Icons.notifications, color: Colors.grey);
    }
  }

  String _getNotificationAction(String type) {
    switch (type) {
      case 'like':
        return 'liked your ride';
      case 'comment':
        return 'commented on your post';
      case 'group':
        return '';
      case 'event':
        return '';
      case 'achievement':
        return '';
      case 'group_post':
        return 'posted in group';
      default:
        return '';
    }
  }
}
