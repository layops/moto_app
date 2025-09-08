import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:motoapp_frontend/services/event/event_service.dart';
import 'package:motoapp_frontend/services/auth/auth_service.dart';
import 'add_event_page.dart';
import 'event_card.dart';
import 'event_filter_chips.dart';
import 'event_helpers.dart';

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
    if (mounted) setState(() => _currentUsername = username ?? '');
  }

  Future<void> _loadEvents() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      List<dynamic> fetchedEvents = _isGeneralPage
          ? await _service.fetchAllEvents()
          : await _service.fetchGroupEvents(widget.groupId!);

      final now = DateTime.now();
      if (!mounted) return;
      
      setState(() {
        _events = fetchedEvents.where((e) {
          try {
            final start = DateTime.parse(e['start_time']).toLocal();
            switch (_selectedFilterIndex) {
              case 1:
                return start.isAfter(now) && start.difference(now).inDays <= 7;
              case 2:
                return start.year == now.year && start.month == now.month;
              case 3:
                return (e['organizer'] as Map?)?['username'] == _currentUsername;
              default:
                return true;
            }
          } catch (e) {
            // Geçersiz tarih formatı olan etkinlikleri atla
            print('Geçersiz tarih formatı: ${e.toString()}');
            return false;
          }
        }).toList();
      });
    } catch (e) {
      if (!mounted) return;
      
      // Daha kullanıcı dostu hata mesajları
      String errorMessage;
      if (e.toString().contains('Authentication token not available')) {
        errorMessage = 'Oturum süreniz dolmuş. Lütfen tekrar giriş yapın.';
      } else if (e.toString().contains('Network error')) {
        errorMessage = 'İnternet bağlantınızı kontrol edin ve tekrar deneyin.';
      } else if (e.toString().contains('500')) {
        errorMessage = 'Sunucu hatası oluştu. Lütfen daha sonra tekrar deneyin.';
      } else {
        errorMessage = 'Etkinlikler yüklenirken bir hata oluştu: ${e.toString()}';
      }
      
      setState(() => _error = errorMessage);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _joinEvent(int eventId) async {
    try {
      final updatedEvent = await _service.joinEvent(eventId);
      if (!mounted) return;
      setState(() {
        final index = _events.indexWhere((e) => e['id'] == eventId);
        if (index != -1) {
          _events[index] = updatedEvent;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Katılamadı: $e')));
    }
  }

  Future<void> _leaveEvent(int eventId) async {
    try {
      final updatedEvent = await _service.leaveEvent(eventId);
      if (!mounted) return;
      setState(() {
        final index = _events.indexWhere((e) => e['id'] == eventId);
        if (index != -1) {
          _events[index] = updatedEvent;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Ayrılamadı: $e')));
    }
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
                  EventFilterChips(
                    selectedIndex: _selectedFilterIndex,
                    onSelected: (index) {
                      setState(() => _selectedFilterIndex = index);
                      _loadEvents();
                    },
                  )
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
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: Theme.of(context).colorScheme.error.withOpacity(0.7),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Etkinlikler Yüklenemedi',
                                  style: Theme.of(context).textTheme.headlineSmall,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _error!,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _loadEvents,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Tekrar Dene'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _events.isEmpty
                          ? Center(child: Text('Henüz etkinlik yok'))
                          : ListView.builder(
                              padding: const EdgeInsets.all(8),
                              itemCount: _events.length,
                              itemBuilder: (context, index) {
                                final e = (_events[index] as Map)
                                    .cast<String, dynamic>();
                                return EventCard(
                                  event: e,
                                  currentUsername: _currentUsername,
                                  onJoin: _joinEvent,
                                  onLeave: _leaveEvent,
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
