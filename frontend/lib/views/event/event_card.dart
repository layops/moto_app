import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'event_helpers.dart';
import 'event_detail_page.dart';
import '../../core/theme/theme_constants.dart';

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
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(ThemeConstants.borderRadiusLarge),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kapak resmi
            if (coverImageUrl != null && coverImageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(ThemeConstants.borderRadiusLarge),
                ),
                child: CachedNetworkImage(
                  imageUrl: coverImageUrl,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 120,
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 120,
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    child: Icon(
                      Icons.image_not_supported,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Etiketler ve buton
                  Row(
                    children: [
                      _buildStatusChip(
                        _currentEvent['is_public'] == true ? 'Public' : 'Private',
                        Theme.of(context).colorScheme.primary,
                      ),
                      if (requiresApproval) ...[
                        const SizedBox(width: 6),
                        _buildStatusChip(
                          'Onay Gerekli',
                          Theme.of(context).colorScheme.primary,
                        ),
                      ],
                      if (requestStatus == 'pending') ...[
                        const SizedBox(width: 6),
                        _buildStatusChip(
                          'Bekleniyor',
                          Theme.of(context).colorScheme.secondary,
                        ),
                      ],
                      const Spacer(),
                      if (buttonState.showButton)
                        _buildActionButton(buttonState),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Başlık
                  Text(
                    _currentEvent['title']?.toString() ?? 'Başlıksız Etkinlik',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  // Açıklama
                  if ((_currentEvent['description']?.toString() ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      _currentEvent['description'].toString(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  // Tarih
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        formatDate(_currentEvent['start_time']),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  // Konum
                  if ((_currentEvent['location']?.toString() ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    LocationText(location: _currentEvent['location'].toString()),
                  ],
                  const SizedBox(height: 12),
                  // Katılımcı bilgisi
                  Row(
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$participantCount / $guestLimit',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isFull 
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: isFull ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      if (isFull) ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.warning_amber_outlined,
                          size: 14,
                          color: Theme.of(context).colorScheme.error,
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

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildActionButton(ButtonState buttonState) {
    return Container(
      height: 32,
      child: ElevatedButton(
        onPressed: buttonState.enabled ? buttonState.onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          minimumSize: const Size(0, 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Text(
          buttonState.text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.w500,
          ),
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
            showButton: false, // Button gösterme
            enabled: false,
            text: '',
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
            SnackBar(
              content: const Text('Katılım isteği gönderildi. Onay bekleniyor.'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('İstek gönderilemedi: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
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
          SnackBar(
            content: const Text('Etkinliğe başarıyla katıldınız!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Katılamadı: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
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
        Icon(
          Icons.location_on_outlined,
          size: 14,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: _loading
              ? Text(
                  'Konum yükleniyor...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                )
              : Text(
                  _displayName ?? '-',
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
        ),
      ],
    );
  }
}
