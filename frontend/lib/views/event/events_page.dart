import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:motoapp_frontend/services/event/event_service.dart';
import 'package:motoapp_frontend/services/auth/auth_service.dart';
import 'add_event_page.dart';

class EventsPage extends StatefulWidget {
  final int groupId;
  final String? groupName;

  const EventsPage({super.key, required this.groupId, this.groupName});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  late final EventService _service;
  bool _loading = true;
  List<dynamic> _events = [];
  String? _error;

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
      final data = await _service.fetchGroupEvents(widget.groupId);
      setState(() => _events = data);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  String _formatDate(String? iso) {
    if (iso == null) return '-';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.groupName ?? 'Etkinlikler')),
      body: RefreshIndicator(
        onRefresh: _loadEvents,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: 120),
                      Center(child: Text('Hata: $_error'))
                    ],
                  )
                : _events.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 120),
                          Center(
                              child: Text(
                                  'Henüz etkinlik yok. + butonuna basarak ekleyin.')),
                        ],
                      )
                    : ListView.builder(
                        itemCount: _events.length,
                        itemBuilder: (context, index) {
                          final e = _events[index] as Map<String, dynamic>;
                          return ListTile(
                            title: Text(e['title'] ?? 'Başlıksız'),
                            subtitle: Text(_formatDate(e['start_time'])),
                            onTap: () {},
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
              builder: (_) => AddEventPage(groupId: widget.groupId),
            ),
          );
          if (created == true) _loadEvents();
        },
      ),
    );
  }
}
