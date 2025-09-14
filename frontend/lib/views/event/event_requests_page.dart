// lib/views/event/event_requests_page.dart
import 'package:flutter/material.dart';
import 'package:motoapp_frontend/services/service_locator.dart';
import 'package:motoapp_frontend/services/event/event_service.dart';

class EventRequestsPage extends StatefulWidget {
  final int eventId;
  final String eventTitle;

  const EventRequestsPage({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  State<EventRequestsPage> createState() => _EventRequestsPageState();
}

class _EventRequestsPageState extends State<EventRequestsPage> {
  final EventService _eventService = ServiceLocator.event;
  List<dynamic> _requests = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEventRequests();
  }

  Future<void> _loadEventRequests() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('DEBUG: EventRequestsPage - Event ID: ${widget.eventId}');
      // Etkinlik katılım isteklerini al
      final requests = await _eventService.getEventJoinRequests(widget.eventId);
      if (mounted) {
        setState(() {
          _requests = requests;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('DEBUG: EventRequestsPage - Hata: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Katılım istekleri yüklenirken hata oluştu: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleRequest(int requestId, bool approved) async {
    try {
      await _eventService.handleJoinRequest(widget.eventId, requestId, approved);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approved ? 'Katılım isteği kabul edildi' : 'Katılım isteği reddedildi'),
            backgroundColor: approved ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Listeyi yenile
        _loadEventRequests();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('İşlem başarısız: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.event_available_rounded,
                color: Colors.purple[600],
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
                    'Katılım İstekleri',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    widget.eventTitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              onPressed: _loadEventRequests,
              icon: Icon(Icons.refresh_rounded, color: Colors.grey[600]),
              tooltip: 'Yenile',
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.purple[50],
                      shape: BoxShape.circle,
                    ),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.purple[600]!),
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Katılım istekleri yükleniyor...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 64,
                        color: Colors.red[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Hata Oluştu',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _loadEventRequests,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Tekrar Dene'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple[600],
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : _requests.isEmpty
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
                              Icons.event_available_rounded,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Henüz katılım isteği yok',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Bu etkinlik için katılım isteği bulunmuyor',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[500],
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadEventRequests,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _requests.length,
                        itemBuilder: (context, index) {
                          final request = _requests[index];
                          final user = request['user'] as Map<String, dynamic>;
                          final requestDate = request['created_at'] as String?;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.grey[200]!,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.08),
                                  spreadRadius: 0,
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Kullanıcı bilgileri
                                  Row(
                                    children: [
                                      // Profil fotoğrafı
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: Colors.purple[50],
                                          borderRadius: BorderRadius.circular(24),
                                          border: Border.all(
                                            color: Colors.purple[200]!,
                                            width: 2,
                                          ),
                                        ),
                                        child: user['profile_picture'] != null
                                            ? ClipRRect(
                                                borderRadius: BorderRadius.circular(24),
                                                child: Image.network(
                                                  user['profile_picture'],
                                                  width: 48,
                                                  height: 48,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return Icon(
                                                      Icons.person_rounded,
                                                      color: Colors.purple[600],
                                                      size: 24,
                                                    );
                                                  },
                                                ),
                                              )
                                            : Icon(
                                                Icons.person_rounded,
                                                color: Colors.purple[600],
                                                size: 24,
                                              ),
                                      ),
                                      const SizedBox(width: 12),
                                      
                                      // Kullanıcı bilgileri
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim().isEmpty
                                                  ? user['username'] ?? 'Bilinmeyen'
                                                  : '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim(),
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '@${user['username'] ?? 'bilinmeyen'}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      // İstek tarihi
                                      if (requestDate != null)
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Icon(
                                              Icons.access_time_rounded,
                                              size: 14,
                                              color: Colors.grey[500],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _formatDate(requestDate),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[500],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  // Katılım mesajı
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.purple[50],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.purple[200]!,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.event_available_rounded,
                                          color: Colors.purple[600],
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Bu etkinliğe katılmak istiyor',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.purple[700],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  // Aksiyon butonları
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () => _handleRequest(request['id'], false),
                                          icon: const Icon(Icons.close_rounded, size: 18),
                                          label: const Text('Reddet'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red[50],
                                            foregroundColor: Colors.red[600],
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              side: BorderSide(
                                                color: Colors.red[200]!,
                                                width: 1,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () => _handleRequest(request['id'], true),
                                          icon: const Icon(Icons.check_rounded, size: 18),
                                          label: const Text('Kabul Et'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green[600],
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
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
      return 'Tarih bilgisi yok';
    }
  }
}


