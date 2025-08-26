import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:motoapp_frontend/services/event/event_service.dart';
import 'package:motoapp_frontend/services/auth/auth_service.dart';
import 'add_event_page.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key})
      : groupId = null,
        groupName = null;
  const EventsPage.forGroup({super.key, required this.groupId, this.groupName});

  final int? groupId;
  final String? groupName;

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  late final EventService _service;
  bool _loading = true;
  List<dynamic> _events = [];
  String? _error;
  late final bool _isGeneralPage;

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
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_isGeneralPage)
        _events = await _service.fetchAllEvents();
      else
        _events = await _service.fetchGroupEvents(widget.groupId!);
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
      final two = (int v) => v.toString().padLeft(2, '0');
      return '${two(dt.day)}/${two(dt.month)}/${dt.year} ${two(dt.hour)}:${two(dt.minute)}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(_isGeneralPage
              ? 'Tüm Etkinlikler'
              : (widget.groupName ?? 'Grup Etkinlikleri'))),
      body: RefreshIndicator(
        onRefresh: _loadEvents,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text('Hata: $_error'))
                : _events.isEmpty
                    ? const Center(child: Text('Henüz etkinlik yok'))
                    : ListView.builder(
                        itemCount: _events.length,
                        itemBuilder: (context, index) {
                          final e =
                              (_events[index] as Map).cast<String, dynamic>();
                          return Card(
                            child: ListTile(
                              title: Text(e['title'] ?? 'Başlıksız Etkinlik'),
                              subtitle: Text(
                                  _formatDate(e['start_time']?.toString())),
                              onTap: () {},
                            ),
                          );
                        },
                      ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
                builder: (_) => AddEventPage(groupId: widget.groupId ?? 0)),
          );
          if (created == true) _loadEvents();
        },
      ),
    );
  }
}
