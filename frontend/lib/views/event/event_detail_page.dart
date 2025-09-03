// event_detail_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:motoapp_frontend/services/event/event_service.dart';
import 'package:motoapp_frontend/services/auth/auth_service.dart';
import 'event_helpers.dart';
import '../../core/theme/color_schemes.dart';

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
      setState(() => _participants = participants);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      if ((widget.event['description']?.toString() ?? '')
                          .isNotEmpty)
                        Text(widget.event['description'].toString()),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(formatDate(widget.event['start_time']),
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if ((widget.event['location']?.toString() ?? '')
                          .isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(widget.event['location'].toString(),
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.grey)),
                          ],
                        ),
                      const SizedBox(height: 16),

                      // Katılımcılar listesi
                      const Text(
                        'Katılımcılar',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ..._participants.map((user) => ListTile(
                            leading: CircleAvatar(
                              backgroundImage: user['profile_picture'] != null
                                  ? NetworkImage(user['profile_picture'])
                                  : null,
                              child: user['profile_picture'] == null
                                  ? Text(user['username'][0].toUpperCase())
                                  : null,
                            ),
                            title: Text(user['username']),
                            subtitle: Text(user['email'] ?? ''),
                          )),
                    ],
                  ),
                ),
    );
  }
}
