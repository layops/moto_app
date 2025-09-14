import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'event_helpers.dart';
import 'event_detail_page.dart'; // Yeni sayfa için import
import '../../core/theme/color_schemes.dart';

class ButtonState {
  final bool showButton;
  final bool enabled;
  final String text;
  final VoidCallback? onPressed;
  
  ButtonState({
    required this.showButton,
    required this.enabled,
    required this.text,
    this.onPressed,
  });
}

class EventCard extends StatefulWidget {
  final Map<String, dynamic> event;
  final String currentUsername;
  final Future<Map<String, dynamic>?> Function(int, {String? message}) onJoin;
  final Future<void> Function(int) onLeave;

  const EventCard({
    super.key,
    required this.event,
    required this.currentUsername,
    required this.onJoin,
    required this.onLeave,
  });

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  bool _requestSent = false;
  Map<String, dynamic> _currentEvent = {};

  @override
  void initState() {
    super.initState();
    _currentEvent = Map<String, dynamic>.from(widget.event);
  }

  @override
  Widget build(BuildContext context) {
    final isJoined = _currentEvent['is_joined'] as bool? ?? false;
    final participantCount = _currentEvent['current_participant_count'] ?? 0;
    final guestLimit = _currentEvent['guest_limit'] ?? '-';
    final organizerUsername = (_currentEvent['organizer'] as Map?)?['username'] ?? '';
    final requiresApproval = _currentEvent['requires_approval'] as bool? ?? false;
    final requestStatus = _currentEvent['request_status'] as String?;
    final isFull = _currentEvent['is_full'] as bool? ?? false;
    final coverImageUrl = _currentEvent['cover_image'] as String?;
    
    // Button durumunu belirle
    final buttonState = _getButtonState(isJoined, requiresApproval, requestStatus, isFull, organizerUsername);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EventDetailPage(
              event: _currentEvent,
              currentUsername: widget.currentUsername,
            ),
          ),
        );
      },
      child: Card(
        elevation: 3,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kapak resmi
            if (coverImageUrl != null && coverImageUrl.isNotEmpty)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: CachedNetworkImage(
                  imageUrl: coverImageUrl,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 150,
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 150,
                    color: Colors.grey[200],
                    child: const Icon(Icons.error),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Chip(
                        label: Text(
                          _currentEvent['is_public'] == true ? 'Public' : 'Private',
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: _currentEvent['is_public'] == true
                            ? Colors.green
                            : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      if (requiresApproval)
                        Chip(
                          label: const Text(
                            'Onay Gerekli',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          backgroundColor: Colors.orange,
                        ),
                      const Spacer(),
                      if (buttonState.showButton)
                        TextButton(
                          onPressed: buttonState.enabled ? buttonState.onPressed : null,
                          child: Text(
                            buttonState.text,
                            style: TextStyle(
                              color: buttonState.enabled ? null : Colors.grey,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentEvent['title']?.toString() ?? 'Başlıksız Etkinlik',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if ((_currentEvent['description']?.toString() ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(_currentEvent['description'].toString(),
                          style: const TextStyle(fontSize: 14)),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(formatDate(_currentEvent['start_time']),
                          style: const TextStyle(
                              fontSize: 14, color: Colors.grey)),
                    ],
                  ),
                  if ((_currentEvent['location']?.toString() ?? '').isNotEmpty)
                    LocationText(location: _currentEvent['location'].toString()),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'Katılımcılar: $participantCount / $guestLimit',
                        style: TextStyle(
                          fontSize: 12, 
                          color: isFull ? Colors.red : Colors.grey,
                          fontWeight: isFull ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      if (isFull) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.warning, size: 16, color: Colors.red),
                        const Text(
                          'Kontenjan Doldu',
                          style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  ButtonState _getButtonState(bool isJoined, bool requiresApproval, String? requestStatus, bool isFull, String organizerUsername) {
    // Organizatör ise button gösterme
    if (organizerUsername == widget.currentUsername) {
      return ButtonState(
        showButton: false,
        enabled: false,
        text: '',
        onPressed: null,
      );
    }
    
    // Zaten katılıyor
    if (isJoined) {
      return ButtonState(
        showButton: true,
        enabled: true,
        text: 'Ayrıl',
        onPressed: () => widget.onLeave(_currentEvent['id']),
      );
    }
    
    // Kontenjan dolmuş
    if (isFull) {
      return ButtonState(
        showButton: true,
        enabled: false,
        text: 'Kontenjan Doldu',
        onPressed: null,
      );
    }
    
    // Onay gerektiren etkinlik için istek durumu kontrolü
    if (requiresApproval) {
      switch (requestStatus) {
        case 'pending':
          return ButtonState(
            showButton: true,
            enabled: false,
            text: 'Onay Bekleniyor',
            onPressed: null,
          );
        case 'rejected':
          return ButtonState(
            showButton: true,
            enabled: true,
            text: 'Tekrar İstek Gönder',
            onPressed: () => _handleJoin(),
          );
        default:
          return ButtonState(
            showButton: true,
            enabled: true,
            text: 'Katıl',
            onPressed: () => _handleJoin(),
          );
      }
    }
    
    // Normal etkinlik
    return ButtonState(
      showButton: true,
      enabled: true,
      text: 'Katıl',
      onPressed: () => _handleJoin(),
    );
  }

  Future<void> _handleJoin() async {
    final requiresApproval = _currentEvent['requires_approval'] as bool? ?? false;
    
    if (requiresApproval) {
      // Onay gerektiren event için mesaj dialog'u göster
      final message = await _showJoinRequestDialog();
      if (message != null) {
        try {
          final result = await widget.onJoin(_currentEvent['id'], message: message);
          if (result != null) {
            setState(() {
              _currentEvent = result;
            });
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Katılım isteği gönderildi. Onay bekleniyor.'),
              backgroundColor: Colors.green,
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('İstek gönderilemedi: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      // Onay gerektirmeyen event için direkt katıl
      try {
        final result = await widget.onJoin(_currentEvent['id']);
        if (result != null) {
          setState(() {
            _currentEvent = result;
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Etkinliğe başarıyla katıldınız!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Katılamadı: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
}

class LocationText extends StatefulWidget {
  final String location;
  const LocationText({super.key, required this.location});

  @override
  State<LocationText> createState() => _LocationTextState();
}

class _LocationTextState extends State<LocationText> {
  String? _displayName;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _resolveAddress();
  }

  Future<void> _resolveAddress() async {
    final parts = widget.location.split(',');
    if (parts.length != 2) {
      setState(() {
        _displayName = widget.location;
        _loading = false;
      });
      return;
    }
    final String lat = parts[0].trim();
    final String lon = parts[1].trim();
    try {
      final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json');
      final response = await http.get(uri, headers: {
        'User-Agent': 'motoapp-front/1.0 (reverse-geocode)'
      });
      if (!mounted) return;
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        setState(() {
          _displayName = data['display_name']?.toString() ?? widget.location;
          _loading = false;
        });
      } else {
        setState(() {
          _displayName = widget.location;
          _loading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _displayName = widget.location;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.location_on, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Expanded(
          child: _loading
              ? const Text('Konum yükleniyor...',
                  style: TextStyle(fontSize: 14, color: Colors.grey))
              : Text(_displayName ?? '-',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, color: Colors.grey)),
        ),
      ],
    );
  }
}
