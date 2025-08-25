// events_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:motoapp_frontend/services/event/event_service.dart';
import 'package:motoapp_frontend/services/auth/auth_service.dart';
import 'add_event_page.dart';

class EventsPage extends StatefulWidget {
  // Ana bottom navigation için kullanılacak constructor
  const EventsPage({super.key})
      : groupId = null,
        groupName = null;

  // Grup sayfasından kullanılacak constructor
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
  bool _isGeneralPage = true;

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
      if (_isGeneralPage) {
        // Tüm etkinlikleri getir - backend'de bu endpoint yoksa boş liste dönecek
        _events = await _service.fetchAllEvents();
      } else {
        // Grup etkinliklerini getir
        _events = await _service.fetchGroupEvents(widget.groupId!);
      }
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
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
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
            : widget.groupName ?? 'Grup Etkinlikleri'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadEvents,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadEvents,
                          child: const Text('Tekrar Dene'),
                        ),
                      ],
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
                                  ? 'Henüz hiç etkinlik yok'
                                  : 'Bu grupta henüz etkinlik yok',
                              style: const TextStyle(
                                  fontSize: 18, color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            if (_isGeneralPage)
                              const Text(
                                'Gruplara katılarak etkinlikleri görebilirsiniz',
                                style: TextStyle(color: Colors.grey),
                                textAlign: TextAlign.center,
                              )
                            else
                              const Text(
                                'İlk etkinliği sen oluştur!',
                                style: TextStyle(color: Colors.grey),
                              ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _events.length,
                        itemBuilder: (context, index) {
                          final e = _events[index] as Map<String, dynamic>;
                          return Card(
                            elevation: 3,
                            margin: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 4),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: InkWell(
                              onTap: () {
                                // Etkinlik detay sayfasına yönlendirme
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Grup adı (sadece genel etkinlikler sayfasında)
                                    if (_isGeneralPage && e['group'] != null)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 8),
                                        child: Text(
                                          e['group']['name'] ?? 'Grup',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.blue,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),

                                    Text(
                                      e['title'] ?? 'Başlıksız Etkinlik',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    if ((e['description'] ?? '').isNotEmpty)
                                      Text(
                                        e['description'],
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today,
                                            size: 16, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatDate(e['start_time']),
                                          style: const TextStyle(
                                              fontSize: 14, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    if ((e['location'] ?? '').isNotEmpty)
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on,
                                              size: 16, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(
                                            e['location'],
                                            style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey),
                                          ),
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
      floatingActionButton: _isGeneralPage
          ? null // Ana etkinlikler sayfasında FAB gösterme
          : FloatingActionButton(
              child: const Icon(Icons.add),
              onPressed: () async {
                final created = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddEventPage(groupId: widget.groupId!),
                  ),
                );
                if (created == true) _loadEvents();
              },
            ),
    );
  }
}
