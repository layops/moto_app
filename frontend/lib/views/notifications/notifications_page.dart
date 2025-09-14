// lib/views/notifications/notifications_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:motoapp_frontend/services/service_locator.dart';
import 'package:motoapp_frontend/services/notifications/notifications_service.dart';
import 'package:motoapp_frontend/views/event/event_requests_page.dart';

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
  bool _isNotificationConnected = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    await _fetchNotifications();
    await _connectNotifications();
  }

  Future<void> _connectNotifications() async {
    try {
      await _notificationsService.connect(); // Yeni akıllı bağlantı metodu
      setState(() {
        _isNotificationConnected = true;
        _errorMessage = null;
      });
      
      _notificationsService.notificationStream.listen(
        (newNotification) {
          if (mounted) {
            setState(() {
              // Çift bildirim kontrolü
              final notificationId = newNotification['id'];
              final existingIndex = _notifications.indexWhere((n) => n['id'] == notificationId);
              
              if (existingIndex == -1) {
                // Yeni bildirim, en başa ekle
                _notifications.insert(0, newNotification);
                
                // Sıralamayı koru (en yeni en üstte)
                _notifications.sort((a, b) {
                  final timestampA = DateTime.tryParse(a['timestamp'] ?? '');
                  final timestampB = DateTime.tryParse(b['timestamp'] ?? '');
                  if (timestampA == null || timestampB == null) return 0;
                  return timestampB.compareTo(timestampA);
                });
              } else {
                // Çift bildirim, mevcut olanı güncelle
                _notifications[existingIndex] = newNotification;
              }
            });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _isNotificationConnected = false;
              _errorMessage = 'Bildirim bağlantı hatası: $error';
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isNotificationConnected = false;
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
          // Bildirimleri timestamp'e göre sırala (en yeni en üstte)
          _notifications = notifications;
          _notifications.sort((a, b) {
            final timestampA = DateTime.tryParse(a['timestamp'] ?? '');
            final timestampB = DateTime.tryParse(b['timestamp'] ?? '');
            if (timestampA == null || timestampB == null) return 0;
            return timestampB.compareTo(timestampA); // En yeni en üstte
          });
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

  /// Bildirime göre uygun sayfaya yönlendirme
  void _handleNotificationTap(Map<String, dynamic> notification) {
    final notificationType = notification['notification_type'] as String?;
    final contentObjectId = notification['content_object_id'] as int?;
    final sender = notification['sender'] as Map<String, dynamic>?;
    
    
    switch (notificationType) {
      case 'group_invite':
      case 'group_join_request':
        // Grup daveti veya katılım isteği - grup detay sayfasına git
        if (contentObjectId != null) {
          Navigator.pushNamed(
            context,
            '/group-detail',
            arguments: {'groupId': contentObjectId},
          );
        } else {
          _showNavigationError('Grup bilgisi bulunamadı');
        }
        break;
        
      case 'group_join_approved':
      case 'group_join_rejected':
        // Grup katılım onay/red - grup detay sayfasına git
        if (contentObjectId != null) {
          Navigator.pushNamed(
            context,
            '/group-detail',
            arguments: {'groupId': contentObjectId},
          );
        } else {
          _showNavigationError('Grup bilgisi bulunamadı');
        }
        break;
        
      case 'event_join_request':
        // Etkinlik katılım isteği - katılım istekleri sayfasına git
        if (contentObjectId != null) {
          // contentObjectId EventRequest ID'si, Event ID'sini almak için API çağrısı yap
          _navigateToEventRequestsPage(contentObjectId);
        } else {
          _showNavigationError('Etkinlik bilgisi bulunamadı');
        }
        break;
        
      case 'event_join_approved':
      case 'event_join_rejected':
        // Etkinlik katılım onay/red - etkinlik detay sayfasına git
        if (contentObjectId != null) {
          Navigator.pushNamed(
            context,
            '/event-detail',
            arguments: {'eventId': contentObjectId},
          );
        } else {
          _showNavigationError('Etkinlik bilgisi bulunamadı');
        }
        break;
        
      case 'ride_request':
      case 'ride_update':
        // Yolculuk katılım isteği/güncelleme - yolculuk detay sayfasına git
        if (contentObjectId != null) {
          Navigator.pushNamed(
            context,
            '/ride-detail',
            arguments: {'rideId': contentObjectId},
          );
        } else {
          _showNavigationError('Yolculuk bilgisi bulunamadı');
        }
        break;
        
      case 'friend_request':
        // Arkadaşlık isteği - profil sayfasına git
        if (sender != null && sender['username'] != null) {
          Navigator.pushNamed(
            context,
            '/profile',
            arguments: {'username': sender['username']},
          );
        } else {
          _showNavigationError('Kullanıcı bilgisi bulunamadı');
        }
        break;
        
      case 'follow':
        // Takip bildirimi - profil sayfasına git
        if (sender != null && sender['username'] != null) {
          Navigator.pushNamed(
            context,
            '/profile',
            arguments: {'username': sender['username']},
          );
        } else {
          _showNavigationError('Kullanıcı bilgisi bulunamadı');
        }
        break;
        
      case 'message':
        // Mesaj bildirimi - mesaj sayfasına git
        if (sender != null && sender['username'] != null) {
          Navigator.pushNamed(
            context,
            '/chat',
            arguments: {'username': sender['username']},
          );
        } else {
          _showNavigationError('Mesaj bilgisi bulunamadı');
        }
        break;
        
      case 'group_update':
        // Grup güncellemesi - grup detay sayfasına git
        if (contentObjectId != null) {
          Navigator.pushNamed(
            context,
            '/group-detail',
            arguments: {'groupId': contentObjectId},
          );
        } else {
          _showNavigationError('Grup bilgisi bulunamadı');
        }
        break;
        
      default:
        // Diğer bildirimler için genel mesaj
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bu bildirim için özel bir sayfa bulunmuyor'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
        break;
    }
  }

  /// Yönlendirme hatası göster
  void _showNavigationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// EventRequest ID'sinden Event ID'sini al ve EventRequestsPage'e git
  Future<void> _navigateToEventRequestsPage(int eventRequestId) async {
    try {
      // EventRequest ID'sinden Event ID'sini al
      final eventRequest = await ServiceLocator.event.getEventRequestById(eventRequestId);
      if (eventRequest != null && eventRequest['event_id'] != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventRequestsPage(
              eventId: eventRequest['event_id'],
              eventTitle: eventRequest['event_title'] ?? 'Etkinlik',
            ),
          ),
        );
      } else {
        _showNavigationError('Etkinlik bilgisi bulunamadı');
      }
    } catch (e) {
      print('EventRequest bilgisi alınamadı: $e');
      _showNavigationError('Etkinlik bilgisi alınamadı');
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n['is_read']).length;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.notifications_rounded,
                color: Colors.blue[600],
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Bildirimler',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (unreadCount > 0)
                    Text(
                      '$unreadCount okunmamış bildirim',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
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
          if (_notifications.isNotEmpty && unreadCount > 0)
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.blue[200]!,
                  width: 1,
                ),
              ),
              child: TextButton.icon(
                onPressed: _markAllAsRead,
                icon: Icon(Icons.done_all_rounded, size: 18, color: Colors.blue[600]),
                label: Text(
                  'Tümünü Okundu',
                  style: TextStyle(
                    color: Colors.blue[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              onPressed: _fetchNotifications,
              icon: Icon(Icons.refresh_rounded, color: Colors.grey[600]),
              tooltip: 'Yenile',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Bildirim bağlantı durumu
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
                      _connectNotifications(); // Bu metod artık SSE kullanıyor
                    },
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            ),
          // Bildirim bağlantı durumu göstergesi
          if (!_isNotificationConnected && _errorMessage == null)
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
                    'Bildirim bağlantısı kuruluyor...',
                    style: TextStyle(color: Colors.orange[700], fontSize: 12),
                  ),
                ],
              ),
            ),
          // Ana içerik
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            shape: BoxShape.circle,
                          ),
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                            strokeWidth: 3,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Bildirimler yükleniyor...',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Lütfen bekleyin',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : _notifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.notifications_none_rounded,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Henüz bildiriminiz yok',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Yeni bildirimler burada görünecek',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[500],
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: Colors.blue[200]!,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    size: 18,
                                    color: Colors.blue[600],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Bildirimler gerçek zamanlı gelir',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.blue[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
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

                            return AnimatedContainer(
                              duration: Duration(milliseconds: 300 + (index * 50)),
                              curve: Curves.easeOutCubic,
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: isRead ? Colors.white : Colors.blue[50],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isRead ? Colors.grey[200]! : Colors.blue[200]!,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isRead 
                                        ? Colors.grey.withOpacity(0.08)
                                        : Colors.blue.withOpacity(0.15),
                                    spreadRadius: 0,
                                    blurRadius: isRead ? 8 : 12,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  splashColor: Colors.blue.withOpacity(0.1),
                                  highlightColor: Colors.blue.withOpacity(0.05),
                                  onTap: () async {
                                    if (!isRead) {
                                      await _markAsRead(notification['id']);
                                    }
                                    
                                    // Bildirime göre yönlendirme
                                    _handleNotificationTap(notification);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        // Bildirim ikonu
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: _getNotificationColor(notification['notification_type'] ?? 'other').withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: _getNotificationColor(notification['notification_type'] ?? 'other').withOpacity(0.3),
                                              width: 1,
                                            ),
                                          ),
                                          child: Center(
                                            child: _getNotificationIcon(notification['notification_type'] ?? 'other'),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        
                                        // Bildirim içeriği
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Bildirim mesajı
                                              Text(
                                                notification['message'] ?? 'Bildirim mesajı yok',
                                                style: TextStyle(
                                                  fontWeight: isRead ? FontWeight.w500 : FontWeight.w600,
                                                  fontSize: 15,
                                                  color: isRead ? Colors.grey[700] : Colors.black87,
                                                  height: 1.3,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 6),
                                              
                                              // Zaman ve gönderici bilgisi
                                              Row(
                                                children: [
                                                  // Zaman
                                                  Icon(
                                                    Icons.access_time_rounded,
                                                    size: 14,
                                                    color: Colors.grey[500],
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    _formatTimestamp(notification['timestamp']),
                                                    style: TextStyle(
                                                      color: Colors.grey[500],
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                  
                                                  // Gönderici varsa
                                                  if (notification['sender'] != null) ...[
                                                    const SizedBox(width: 12),
                                                    Icon(
                                                      Icons.person_rounded,
                                                      size: 14,
                                                      color: Colors.grey[500],
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        notification['sender']['username'] ?? 'Bilinmeyen',
                                                        style: TextStyle(
                                                          color: Colors.grey[500],
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        
                                        // Okunmamış bildirim göstergesi ve ok işareti
                                        Column(
                                          children: [
                                            if (!isRead)
                                              Container(
                                                width: 12,
                                                height: 12,
                                                decoration: BoxDecoration(
                                                  color: Colors.blue,
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.blue.withOpacity(0.3),
                                                      blurRadius: 4,
                                                      spreadRadius: 1,
                                                    ),
                                                  ],
                                                ),
                                              )
                                            else
                                              const SizedBox(height: 12),
                                            const SizedBox(height: 8),
                                            Icon(
                                              Icons.arrow_forward_ios_rounded,
                                              size: 16,
                                              color: Colors.grey[400],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
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
        return Icon(Icons.chat_bubble_outline_rounded, color: color, size: 24);
      case 'group_invite':
        return Icon(Icons.group_add_rounded, color: color, size: 24);
      case 'group_join_request':
        return Icon(Icons.group_add_rounded, color: color, size: 24);
      case 'group_join_approved':
        return Icon(Icons.check_circle_outline_rounded, color: color, size: 24);
      case 'group_join_rejected':
        return Icon(Icons.cancel_outlined, color: color, size: 24);
      case 'event_join_request':
        return Icon(Icons.event_available_rounded, color: color, size: 24);
      case 'event_join_approved':
        return Icon(Icons.check_circle_outline_rounded, color: color, size: 24);
      case 'event_join_rejected':
        return Icon(Icons.cancel_outlined, color: color, size: 24);
      case 'ride_request':
        return Icon(Icons.motorcycle_rounded, color: color, size: 24);
      case 'ride_update':
        return Icon(Icons.route_rounded, color: color, size: 24);
      case 'group_update':
        return Icon(Icons.group_rounded, color: color, size: 24);
      case 'friend_request':
        return Icon(Icons.person_add_rounded, color: color, size: 24);
      case 'follow':
        return Icon(Icons.person_add_alt_1_rounded, color: color, size: 24);
      default:
        return Icon(Icons.notifications_outlined, color: color, size: 24);
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'message':
        return const Color(0xFF2196F3); // Mavi
      case 'group_invite':
      case 'group_join_request':
        return const Color(0xFF4CAF50); // Yeşil
      case 'group_join_approved':
        return const Color(0xFF4CAF50); // Yeşil
      case 'group_join_rejected':
        return const Color(0xFFF44336); // Kırmızı
      case 'event_join_request':
        return const Color(0xFF9C27B0); // Mor
      case 'event_join_approved':
        return const Color(0xFF4CAF50); // Yeşil
      case 'event_join_rejected':
        return const Color(0xFFF44336); // Kırmızı
      case 'ride_request':
        return const Color(0xFFFF9800); // Turuncu
      case 'ride_update':
        return const Color(0xFF607D8B); // Mavi-gri
      case 'group_update':
        return const Color(0xFF673AB7); // Koyu mor
      case 'friend_request':
        return const Color(0xFF3F51B5); // İndigo
      case 'follow':
        return const Color(0xFF00BCD4); // Cyan
      default:
        return const Color(0xFF9E9E9E); // Gri
    }
  }
}
