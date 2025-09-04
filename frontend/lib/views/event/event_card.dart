import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'event_helpers.dart';
import 'event_detail_page.dart'; // Yeni sayfa için import
import '../../core/theme/color_schemes.dart';

class EventCard extends StatelessWidget {
  final Map<String, dynamic> event;
  final String currentUsername;
  final Future<void> Function(int) onJoin;
  final Future<void> Function(int) onLeave;

  const EventCard({
    super.key,
    required this.event,
    required this.currentUsername,
    required this.onJoin,
    required this.onLeave,
  });

  @override
  Widget build(BuildContext context) {
    final isJoined = event['is_joined'] as bool? ?? false;
    final participantCount = event['current_participant_count'] ?? 0;
    final guestLimit = event['guest_limit'] ?? '-';
    final organizerUsername = (event['organizer'] as Map?)?['username'] ?? '';
    final canJoin = !isJoined &&
        organizerUsername != currentUsername &&
        (guestLimit == '-' || participantCount < guestLimit);
    final coverImageUrl = event['cover_image'] as String?;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EventDetailPage(
              event: event,
              currentUsername: currentUsername,
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
                          event['is_public'] == true ? 'Public' : 'Private',
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: event['is_public'] == true
                            ? Colors.green
                            : Colors.red,
                      ),
                      const Spacer(),
                      if (isJoined || canJoin)
                        TextButton(
                          onPressed: isJoined
                              ? () => onLeave(event['id'])
                              : () => onJoin(event['id']),
                          child: Text(isJoined ? 'Ayrıl' : 'Katıl'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event['title']?.toString() ?? 'Başlıksız Etkinlik',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if ((event['description']?.toString() ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(event['description'].toString(),
                          style: const TextStyle(fontSize: 14)),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(formatDate(event['start_time']),
                          style: const TextStyle(
                              fontSize: 14, color: Colors.grey)),
                    ],
                  ),
                  if ((event['location']?.toString() ?? '').isNotEmpty)
                    LocationText(location: event['location'].toString()),
                  const SizedBox(height: 12),
                  Text(
                    'Katılımcılar: $participantCount / $guestLimit',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
