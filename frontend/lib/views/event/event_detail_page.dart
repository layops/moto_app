// event_detail_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:motoapp_frontend/services/event/event_service.dart';
import 'package:motoapp_frontend/services/auth/auth_service.dart';
import 'event_helpers.dart';
import '../../core/theme/color_schemes.dart';
import '../map/map_page.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

class EventDetailPage extends StatefulWidget {
  final Map<String, dynamic> event;
  final String currentUsername;

  const EventDetailPage({
    super.key,
    required this.event,
    required this.currentUsername,
  });

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  late final EventService _service;
  List<dynamic> _participants = [];
  bool _loading = true;
  String? _error;
  bool _requestSent = false;

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    _service = EventService(authService: authService);
    _loadParticipants();
  }

  Future<void> _loadParticipants() async {
    try {
      final participants =
          await _service.fetchEventParticipants(widget.event['id']);
      if (!mounted) return;
      setState(() => _participants = participants);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final organizer = widget.event['organizer'] is Map
        ? widget.event['organizer'] as Map<String, dynamic>
        : null;
    final organizerName = organizer?['username'] ?? 'Bilinmiyor';
    final organizerEmail = organizer?['email'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event['title']?.toString() ?? 'Etkinlik Detayları'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Hata: $_error'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Etkinlik detayları
                      Text(
                        widget.event['title']?.toString() ??
                            'Başlıksız Etkinlik',
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      // Onay sistemi durumu
                      Row(
                        children: [
                          Chip(
                            label: Text(
                              widget.event['is_public'] == true ? 'Public' : 'Private',
                              style: const TextStyle(color: Colors.white),
                            ),
                            backgroundColor: widget.event['is_public'] == true
                                ? Colors.green
                                : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          if (widget.event['requires_approval'] == true)
                            Chip(
                              label: const Text(
                                'Onay Gerekli',
                                style: TextStyle(color: Colors.white, fontSize: 12),
                              ),
                              backgroundColor: Colors.orange,
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Etkinlik kurucusu
                      const Text(
                        'Etkinlik Kurucusu',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        leading: CircleAvatar(
                          child: Text(organizerName.isNotEmpty
                              ? organizerName[0].toUpperCase()
                              : '?'),
                        ),
                        title: Text(organizerName),
                        subtitle: organizerEmail.isNotEmpty
                            ? Text(organizerEmail)
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Etkinlik açıklaması
                      if ((widget.event['description']?.toString() ?? '')
                          .isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Açıklama',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(widget.event['description'].toString()),
                            const SizedBox(height: 16),
                          ],
                        ),

                      // Etkinlik tarih ve konum bilgileri
                      const Text(
                        'Detaylar',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                          const SizedBox(width: 8),
                          Text(formatDate(widget.event['start_time']),
                              style: TextStyle(
                                  fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if ((widget.event['location']?.toString() ?? '')
                          .isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            final pos = _parseLatLng(widget.event['location'].toString());
                            if (pos != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MapPage(
                                    initialCenter: pos,
                                    allowSelection: false,
                                    showMarker: true,
                                  ),
                                ),
                              );
                            }
                          },
                          child: Row(
                            children: [
                              Icon(Icons.location_on,
                                  size: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.event['location'].toString(),
                                  style: TextStyle(
                                      fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                      if ((widget.event['location']?.toString() ?? '')
                          .isNotEmpty)
                        _MiniMapPreview(location: widget.event['location'].toString()),
                      const SizedBox(height: 16),

                      // Katılımcılar listesi
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => _EventParticipantsPage(
                                event: widget.event,
                                participants: _participants,
                              ),
                            ),
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Katılımcılar',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Row(
                              children: [
                                Text(
                                  '${_participants.length}',
                                  style: TextStyle(
                                      fontSize: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.arrow_forward_ios,
                                    size: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      _participants.isEmpty
                          ? const Text('Henüz katılımcı yok')
                          : Column(
                              children: _participants.take(3).map((user) => ListTile(
                                        leading: CircleAvatar(
                                          backgroundImage:
                                              user['profile_picture'] != null
                                                  ? NetworkImage(
                                                      user['profile_picture'])
                                                  : null,
                                          child: user['profile_picture'] == null
                                              ? Text(user['username'][0]
                                                  .toUpperCase())
                                              : null,
                                        ),
                                        title: Text(user['username']),
                                        subtitle: user['email'] != null
                                            ? Text(user['email'])
                                            : null,
                                      )).toList(),
                            ),
                      if (_participants.length > 3)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            've ${_participants.length - 3} kişi daha...',
                            style: TextStyle(
                                fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                          ),
                        ),
                      
                      // Katılma butonu
                      const SizedBox(height: 24),
                      _buildJoinButton(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildJoinButton() {
    final isJoined = widget.event['is_joined'] as bool? ?? false;
    final participantCount = widget.event['current_participant_count'] ?? 0;
    final guestLimit = widget.event['guest_limit'] ?? '-';
    final organizerUsername = (widget.event['organizer'] as Map?)?['username'] ?? '';
    final requiresApproval = widget.event['requires_approval'] as bool? ?? false;
    final canJoin = !isJoined &&
        organizerUsername != widget.currentUsername &&
        (guestLimit == '-' || participantCount < guestLimit);

    if (!canJoin && !isJoined) {
      return const SizedBox.shrink(); // Buton gösterme
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isJoined ? _leaveEvent : _joinEvent,
        style: ElevatedButton.styleFrom(
          backgroundColor: isJoined ? Colors.red : Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          _getButtonText(isJoined, requiresApproval),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  String _getButtonText(bool isJoined, bool requiresApproval) {
    if (isJoined) {
      return 'Ayrıl';
    } else if (requiresApproval && _requestSent) {
      return 'İsteğiniz Gönderildi';
    } else if (requiresApproval) {
      return 'Katıl';
    } else {
      return 'Katıl';
    }
  }

  Future<void> _joinEvent() async {
    final requiresApproval = widget.event['requires_approval'] as bool? ?? false;
    
    if (requiresApproval) {
      // Onay gerektiren event için mesaj dialog'u göster
      final message = await _showJoinRequestDialog();
      if (message == null) return; // Kullanıcı iptal etti
      
      try {
        final updatedEvent = await _service.joinEvent(widget.event['id'], message: message);
        if (!mounted) return;
        
        // Backend'den gelen güncel event bilgisini kullan
        setState(() {
          _requestSent = true;
          // Event bilgisini güncelle
          widget.event.updateAll((key, value) => updatedEvent[key] ?? value);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Katılım isteği gönderildi. Onay bekleniyor.'),
            backgroundColor: Colors.orange,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('İstek gönderilemedi: $e')),
        );
      }
    } else {
      // Onay gerektirmeyen event için direkt katıl
      try {
        final updatedEvent = await _service.joinEvent(widget.event['id']);
        if (!mounted) return;
        
        // Backend'den gelen güncel event bilgisini kullan
        setState(() {
          // Event bilgisini güncelle
          widget.event.updateAll((key, value) => updatedEvent[key] ?? value);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Etkinliğe başarıyla katıldınız!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Sayfayı yenile
        _loadParticipants();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Katılamadı: $e')),
        );
      }
    }
  }

  Future<void> _leaveEvent() async {
    try {
      final updatedEvent = await _service.leaveEvent(widget.event['id']);
      if (!mounted) return;
      
      // Backend'den gelen güncel event bilgisini kullan
      setState(() {
        // Event bilgisini güncelle
        widget.event.updateAll((key, value) => updatedEvent[key] ?? value);
        _requestSent = false; // İstek durumunu sıfırla
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Etkinlikten ayrıldınız.'),
          backgroundColor: Colors.orange,
        ),
      );
      
      // Sayfayı yenile
      _loadParticipants();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ayrılamadı: $e')),
      );
    }
  }

  Future<String?> _showJoinRequestDialog() async {
    String message = '';
    
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Katılım İsteği'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Bu etkinliğe katılmak için organizatörden onay gerekiyor.'),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Mesaj (isteğe bağlı)',
                  hintText: 'Katılmak istediğinizi belirten bir mesaj yazabilirsiniz...',
                ),
                maxLines: 3,
                onChanged: (value) => message = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(message),
              child: const Text('Gönder'),
            ),
          ],
        );
      },
    );
  }

  LatLng? _parseLatLng(String location) {
    try {
      final parts = location.split(',');
      if (parts.length == 2) {
        final lat = double.parse(parts[0].trim());
        final lng = double.parse(parts[1].trim());
        return LatLng(lat, lng);
      }
    } catch (e) {
      // Hata durumunda null döndür
    }
    return null;
  }
}

class _DetailLocationText extends StatefulWidget {
  final String location;
  const _DetailLocationText({required this.location});

  @override
  State<_DetailLocationText> createState() => _DetailLocationTextState();
}

class _DetailLocationTextState extends State<_DetailLocationText> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.location_on,
            size: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            widget.location,
            style: TextStyle(
                fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
          ),
        ),
      ],
    );
  }
}

class _MiniMapPreview extends StatelessWidget {
  final String location;

  const _MiniMapPreview({required this.location});

  @override
  Widget build(BuildContext context) {
    final pos = _parseLatLng(location);
    if (pos == null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text('Konum bilgisi geçersiz'),
        ),
      );
    }

    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: pos,
            initialZoom: 15.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none, // Sadece görüntüleme
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.motoapp',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: pos,
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 30,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  LatLng? _parseLatLng(String location) {
    try {
      final parts = location.split(',');
      if (parts.length == 2) {
        final lat = double.parse(parts[0].trim());
        final lng = double.parse(parts[1].trim());
        return LatLng(lat, lng);
      }
    } catch (e) {
      // Hata durumunda null döndür
    }
    return null;
  }
}

class _EventParticipantsPage extends StatelessWidget {
  final Map<String, dynamic> event;
  final List<dynamic> participants;

  const _EventParticipantsPage({
    required this.event,
    required this.participants,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Katılımcılar'),
      ),
      body: participants.isEmpty
          ? const Center(child: Text('Henüz katılımcı yok'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: participants.length,
              itemBuilder: (context, index) {
                final user = participants[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: user['profile_picture'] != null
                        ? NetworkImage(user['profile_picture'])
                        : null,
                    child: user['profile_picture'] == null
                        ? Text(user['username'][0].toUpperCase())
                        : null,
                  ),
                  title: Text(user['username']),
                  subtitle: user['email'] != null ? Text(user['email']) : null,
                );
              },
            ),
    );
  }
}