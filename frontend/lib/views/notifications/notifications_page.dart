// lib/views/notifications/notifications_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  bool _isWebSocketConnected = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    await _fetchNotifications();
    await _connectWebSocket();
  }

  Future<void> _connectWebSocket() async {
    try {
      await _notificationsService.connect(); // Yeni akıllı bağlantı metodu
      setState(() {
        _isWebSocketConnected = true;
        _errorMessage = null;
      });
      
      _notificationsService.notificationStream.listen(
        (newNotification) {
          if (mounted) {
            setState(() {
              _notifications.insert(0, newNotification);
            });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _isWebSocketConnected = false;
              _errorMessage = 'Bildirim bağlantı hatası: $error';
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isWebSocketConnected = false;
          _errorMessage = 'Bildirim bağlantı hatası: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _notificationsService.disconnect(); // Yeni disconnect metodu
    super.dispose();
  }

  Future<void> _fetchNotifications() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    
    try {
      final notifications = await _notificationsService.getNotifications();
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Bildirimler yüklenirken hata oluştu: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _notificationsService.markAllAsRead();
      if (mounted) {
        setState(() {
          _notifications = _notifications.map((n) {
            n['is_read'] = true;
            return n;
          }).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Bildirimler okundu olarak işaretlenirken hata oluştu: $e';
        });
      }
    }
  }

  Future<void> _markAsRead(int notificationId) async {
    try {
      await _notificationsService.markAsRead(notificationId);
      if (mounted) {
        setState(() {
          final index = _notifications.indexWhere((n) => n['id'] == notificationId);
          if (index != -1) {
            _notifications[index]['is_read'] = true;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Bildirim okundu olarak işaretlenirken hata oluştu: $e';
        });
      }
    }
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return 'Zaman bilgisi yok';
    
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inDays > 0) {
        return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
      } else if (difference.inHours > 0) {
        return '${difference.inHours} saat önce';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} dakika önce';
      } else {
        return 'Az önce';
      }
    } catch (e) {
      return 'Geçersiz tarih';
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n['is_read']).length;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Bildirimler'),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (_notifications.isNotEmpty)
            TextButton.icon(
              onPressed: unreadCount > 0 ? _markAllAsRead : null,
              icon: const Icon(Icons.done_all, size: 18),
              label: const Text('Tümünü Okundu'),
              style: TextButton.styleFrom(
                foregroundColor: unreadCount > 0 ? Colors.white : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          IconButton(
            onPressed: _fetchNotifications,
            icon: const Icon(Icons.refresh),
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: Column(
        children: [
          // WebSocket bağlantı durumu
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.red[50],
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red[700], fontSize: 12),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() => _errorMessage = null);
                      _connectWebSocket(); // Bu metod artık SSE kullanıyor
                    },
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            ),
          // WebSocket bağlantı durumu göstergesi
          if (!_isWebSocketConnected && _errorMessage == null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              color: Colors.orange[50],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.orange[700]!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'WebSocket bağlantısı kuruluyor...',
                    style: TextStyle(color: Colors.orange[700], fontSize: 12),
                  ),
                ],
              ),
            ),
          // Ana içerik
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Bildirimler yükleniyor...'),
                      ],
                    ),
                  )
                : _notifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_none,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Henüz bildiriminiz yok',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Yeni bildirimler burada görünecek',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchNotifications,
                        child: ListView.builder(
                          itemCount: _notifications.length,
                          itemBuilder: (context, index) {
                            final notification = _notifications[index];
                            final isRead = notification['is_read'] as bool;

                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isRead ? Colors.white : Colors.blue[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isRead ? Colors.grey[200]! : Colors.blue[200]!,
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 3,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _getNotificationColor(notification['notification_type'] ?? 'other').withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: _getNotificationIcon(notification['notification_type'] ?? 'other'),
                                ),
                                title: Text(
                                  notification['message'] ?? 'Bildirim mesajı yok',
                                  style: TextStyle(
                                    fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
                                    fontSize: 14,
                                    color: isRead ? Colors.grey[800] : Colors.black87,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    _formatTimestamp(notification['timestamp']),
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                trailing: !isRead
                                    ? Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Colors.blue,
                                          shape: BoxShape.circle,
                                        ),
                                      )
                                    : null,
                                onTap: () async {
                                  if (!isRead) {
                                    await _markAsRead(notification['id']);
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _getNotificationIcon(String type) {
    final color = _getNotificationColor(type);
    switch (type) {
      case 'message':
        return Icon(Icons.message, color: color, size: 20);
      case 'group_invite':
        return Icon(Icons.group_add, color: color, size: 20);
      case 'ride_request':
        return Icon(Icons.two_wheeler, color: color, size: 20);
      case 'ride_update':
        return Icon(Icons.route, color: color, size: 20);
      case 'group_update':
        return Icon(Icons.groups, color: color, size: 20);
      case 'friend_request':
        return Icon(Icons.person_add, color: color, size: 20);
      default:
        return Icon(Icons.notifications, color: color, size: 20);
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'message':
        return Colors.blue;
      case 'group_invite':
        return Colors.green;
      case 'ride_request':
        return Colors.red;
      case 'ride_update':
        return Colors.orange;
      case 'group_update':
        return Colors.purple;
      case 'friend_request':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }
}
