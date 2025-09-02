import 'package:flutter/material.dart';
import 'package:motoapp_frontend/core/theme/color_schemes.dart';
import 'package:provider/provider.dart';
import 'package:motoapp_frontend/services/event/event_service.dart';
import 'package:motoapp_frontend/services/auth/auth_service.dart';
import 'add_event_page.dart';

class EventsPage extends StatefulWidget {
  final int? groupId;
  final String? groupName;

  const EventsPage({super.key})
      : groupId = null,
        groupName = null;
  const EventsPage.forGroup({super.key, required this.groupId, this.groupName});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  late final EventService _service;
  bool _loading = true;
  List<dynamic> _events = [];
  String? _error;
  late final bool _isGeneralPage;
  int _selectedFilterIndex = 0;
  String _currentUsername = '';

  @override
  void initState() {
    super.initState();
    _isGeneralPage = widget.groupId == null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authService = Provider.of<AuthService>(context, listen: false);
    _service = EventService(authService: authService);
    _loadCurrentUsername();
    _loadEvents();
  }

  Future<void> _loadCurrentUsername() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final username = await authService.getCurrentUsername();
    if (mounted) {
      setState(() {
        _currentUsername = username ?? '';
      });
    }
  }

  Future<void> _loadEvents() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _events = _isGeneralPage
          ? await _service.fetchAllEvents()
          : await _service.fetchGroupEvents(widget.groupId!);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    try {
      final dt = DateTime.parse(iso).toLocal();
      String two(int v) => v.toString().padLeft(2, '0');
      return '${two(dt.day)}/${two(dt.month)}/${dt.year} ${two(dt.hour)}:${two(dt.minute)}';
    } catch (_) {
      return iso;
    }
  }

  Future<void> _joinEvent(int eventId) async {
    try {
      await _service.joinEvent(eventId);
      _loadEvents();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Katılamadı: $e')));
    }
  }

  Future<void> _leaveEvent(int eventId) async {
    try {
      await _service.leaveEvent(eventId);
      _loadEvents();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Ayrılamadı: $e')));
    }
  }

  Widget _buildEventChip(String label, Color color) {
    return Chip(
      label: Text(label, style: TextStyle(fontSize: 12, color: color)),
      backgroundColor: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildFilterChip(int index, String label) {
    return FilterChip(
      label: Text(label),
      selected: _selectedFilterIndex == index,
      onSelected: (selected) {
        setState(() {
          _selectedFilterIndex = selected ? index : 0;
        });
      },
      backgroundColor: Colors.transparent,
      selectedColor: AppColorSchemes.primaryColor.withOpacity(0.2),
      labelStyle: TextStyle(
        color: _selectedFilterIndex == index
            ? AppColorSchemes.primaryColor
            : AppColorSchemes.textSecondary,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: _selectedFilterIndex == index
              ? AppColorSchemes.primaryColor
              : AppColorSchemes.borderColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isGeneralPage
            ? 'Tüm Etkinlikler'
            : (widget.groupName ?? 'Grup Etkinlikleri')),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(0, 'All Events'),
                  const SizedBox(width: 8),
                  _buildFilterChip(1, 'This Week'),
                  const SizedBox(width: 8),
                  _buildFilterChip(2, 'This Month'),
                  const SizedBox(width: 8),
                  _buildFilterChip(3, 'My Events'),
                ],
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadEvents,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline,
                                    size: 48, color: Colors.red),
                                const SizedBox(height: 16),
                                Text(_error!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 16)),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                    onPressed: _loadEvents,
                                    child: const Text('Tekrar Dene')),
                              ],
                            ),
                          ),
                        )
                      : _events.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.event,
                                      size: 64, color: Colors.grey),
                                  const SizedBox(height: 16),
                                  Text(
                                      _isGeneralPage
                                          ? 'Henüz etkinlik yok'
                                          : 'Bu grupta henüz etkinlik yok',
                                      style: const TextStyle(
                                          fontSize: 18, color: Colors.grey)),
                                  const SizedBox(height: 8),
                                  Text(
                                      _isGeneralPage
                                          ? 'Kişisel etkinlik oluşturabilir veya gruplara katılabilirsiniz'
                                          : 'İlk etkinliği sen oluştur!',
                                      style:
                                          const TextStyle(color: Colors.grey),
                                      textAlign: TextAlign.center),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(8),
                              itemCount: _events.length,
                              itemBuilder: (context, index) {
                                final e = (_events[index] as Map)
                                    .cast<String, dynamic>();
                                final isJoined =
                                    e['is_joined'] as bool? ?? false;
                                final participantCount =
                                    e['participants_count'] ?? 0;
                                final guestLimit = e['guest_limit'] ?? '-';
                                final organizerUsername =
                                    (e['organizer'] as Map?)?['username'] ?? '';

                                // Katılabilir mi? Kendi etkinliği değil, dolu değil ve henüz katılmamış
                                final canJoin = !isJoined &&
                                    organizerUsername != _currentUsername &&
                                    (guestLimit == '-' ||
                                        participantCount < guestLimit);

                                return Card(
                                  elevation: 3,
                                  margin: const EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 4),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  child: InkWell(
                                    onTap: () {},
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              _buildEventChip(
                                                  e['is_public'] == true
                                                      ? 'Public'
                                                      : 'Private',
                                                  e['is_public'] == true
                                                      ? Colors.green
                                                      : Colors.red),
                                              const Spacer(),
                                              if (isJoined || canJoin)
                                                TextButton(
                                                  onPressed: isJoined
                                                      ? () =>
                                                          _leaveEvent(e['id'])
                                                      : () =>
                                                          _joinEvent(e['id']),
                                                  child: Text(isJoined
                                                      ? 'Leave'
                                                      : 'Join'),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                              e['title']?.toString() ??
                                                  'Başlıksız Etkinlik',
                                              style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold)),
                                          if ((e['description']?.toString() ??
                                                  '')
                                              .isNotEmpty)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 8),
                                              child: Text(
                                                  e['description'].toString(),
                                                  style: const TextStyle(
                                                      fontSize: 14)),
                                            ),
                                          const SizedBox(height: 12),
                                          Row(children: [
                                            const Icon(Icons.calendar_today,
                                                size: 16, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text(
                                                _formatDate(e['start_time']
                                                    ?.toString()),
                                                style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey)),
                                          ]),
                                          if ((e['location']?.toString() ?? '')
                                              .isNotEmpty)
                                            Row(
                                              children: [
                                                const Icon(Icons.location_on,
                                                    size: 16,
                                                    color: Colors.grey),
                                                const SizedBox(width: 4),
                                                Text(e['location'].toString(),
                                                    style: const TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.grey)),
                                              ],
                                            ),
                                          const SizedBox(height: 12),
                                          Text(
                                              'Katılımcılar: $participantCount / $guestLimit',
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey)),
                                          const SizedBox(height: 8),
                                          const Divider(),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Text(
                                                  'by ${(e['group'] as Map?)?['name'] ?? 'Grup'}',
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey)),
                                              const Spacer(),
                                              Text('Easy',
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey)),
                                              const SizedBox(width: 8),
                                              Text(
                                                  e['is_public'] == true
                                                      ? 'Free'
                                                      : 'Private',
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey)),
                                            ],
                                          ),
                                        ],
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
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_events',
        child: const Icon(Icons.add),
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
                builder: (_) => AddEventPage(groupId: widget.groupId)),
          );
          if (created == true) _loadEvents();
        },
      ),
    );
  }
}
