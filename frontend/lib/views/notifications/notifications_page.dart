// lib/views/notifications/notifications_page.dart
import 'package:flutter/material.dart';
import 'package:motoapp_frontend/services/service_locator.dart';
import 'package:motoapp_frontend/services/notifications/notifications_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationsService _notificationsService =
      ServiceLocator.notification;
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
    _notificationsService.connectWebSocket();
    _notificationsService.notificationStream.listen((newNotification) {
      setState(() {
        _notifications.insert(0, newNotification);
      });
    });
  }

  @override
  void dispose() {
    _notificationsService.disconnectWebSocket();
    super.dispose();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final notifications = await _notificationsService.getNotifications();
      setState(() => _notifications = notifications);
    } catch (e) {
      print('Hata: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllAsRead() async {
    await _notificationsService.markAllAsRead();
    setState(() {
      _notifications = _notifications.map((n) {
        n['is_read'] = true;
        return n;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n['is_read']).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirimler'),
        actions: [
          if (_notifications.isNotEmpty)
            TextButton(
              onPressed: unreadCount > 0 ? _markAllAsRead : null,
              child: Text(
                'Tümünü Okundu',
                style: TextStyle(
                  color: unreadCount > 0 ? Colors.white : Colors.grey[400],
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(child: Text('Henüz bildiriminiz yok.'))
              : ListView.builder(
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    final isRead = notification['is_read'] as bool;

                    return ListTile(
                      leading: _getNotificationIcon(
                          notification['notification_type'] ?? 'other'),
                      title: Text(
                        notification['message'],
                        style: TextStyle(
                          fontWeight:
                              isRead ? FontWeight.normal : FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        notification['timestamp'] ?? 'Zaman bilgisi yok',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                      tileColor: isRead ? null : Colors.blue[50],
                      onTap: () async {
                        if (!isRead) {
                          await _notificationsService
                              .markAsRead(notification['id']);
                          setState(() => notification['is_read'] = true);
                        }
                      },
                    );
                  },
                ),
    );
  }

  Widget _getNotificationIcon(String type) {
    switch (type) {
      case 'message':
        return const Icon(Icons.message, color: Colors.blue);
      case 'group_invite':
        return const Icon(Icons.group_add, color: Colors.green);
      case 'ride_request':
        return const Icon(Icons.two_wheeler, color: Colors.red);
      case 'ride_update':
        return const Icon(Icons.route, color: Colors.orange);
      case 'group_update':
        return const Icon(Icons.groups, color: Colors.purple);
      case 'friend_request':
        return const Icon(Icons.person_add, color: Colors.indigo);
      default:
        return const Icon(Icons.notifications, color: Colors.grey);
    }
  }
}
