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
                          const Icon(Icons.calendar_today,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(formatDate(widget.event['start_time']),
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.grey)),
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
                                  builder: (_) => MapPage(
                                    initialCenter: pos,
                                    allowSelection: false,
                                  ),
                                ),
                              );
                            }
                          },
                          child: _DetailLocationText(
                              location: widget.event['location'].toString()),
                        ),
                      const SizedBox(height: 12),
                      if ((widget.event['location']?.toString() ?? '')
                          .isNotEmpty)
                        _MiniMapPreview(location: widget.event['location'].toString()),
                      const SizedBox(height: 16),

                      // Katılımcılar listesi
                      const Text(
                        'Katılımcılar',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      _participants.isEmpty
                          ? const Text('Henüz katılımcı yok')
                          : Column(
                              children: _participants
                                  .map((user) => ListTile(
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
                                      ))
                                  .toList(),
                            ),
                    ],
                  ),
                ),
    );
  }
}

class _DetailLocationText extends StatefulWidget {
  final String location;
  const _DetailLocationText({required this.location});

  @override
  State<_DetailLocationText> createState() => _DetailLocationTextState();
}

class _DetailLocationTextState extends State<_DetailLocationText> {
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
        const SizedBox(width: 8),
        Expanded(
          child: _loading
              ? const Text('Konum yükleniyor...',
                  style: TextStyle(fontSize: 14, color: Colors.grey))
              : Text(
                  _displayName ?? '-',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
        ),
      ],
    );
  }
}

LatLng? _parseLatLng(String input) {
  final parts = input.split(',');
  if (parts.length != 2) return null;
  final lat = double.tryParse(parts[0].trim());
  final lon = double.tryParse(parts[1].trim());
  if (lat == null || lon == null) return null;
  return LatLng(lat, lon);
}

class _MiniMapPreview extends StatelessWidget {
  final String location;
  const _MiniMapPreview({required this.location});

  @override
  Widget build(BuildContext context) {
    final pos = _parseLatLng(location);
    if (pos == null) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 160,
        child: IgnorePointer(
          ignoring: true,
          child: MapPage(
            initialCenter: pos,
            allowSelection: false,
            showMarker: true,
          ),
        ),
      ),
    );
  }
}
