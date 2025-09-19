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
  EventService? _service;
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
    _initializeService();
  }

  void _initializeService() {
    if (_service == null) {
      final authService = Provider.of<AuthService>(context, listen: false);
      _service = EventService(authService: authService);
      _loadCurrentUsername();
      _loadEvents();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeService();
  }

  Future<void> _loadCurrentUsername() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final username = await authService.getCurrentUsername();
    if (mounted) setState(() => _currentUsername = username ?? '');
  }

  Future<void> _loadEvents() async {
    if (_service == null) return;
    
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      List<dynamic> fetchedEvents = _isGeneralPage
          ? await _service!.fetchAllEvents()
          : await _service!.fetchGroupEvents(widget.groupId!);

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

  Future<Map<String, dynamic>?> _joinEvent(int eventId, {String? message}) async {
    if (_service == null) return null;
    
    try {
      final result = await _service!.joinEvent(eventId, message: message);
      if (!mounted) return null;
      
      // Backend'ten gelen event verisini kullan
      final updatedEvent = result['event'] ?? result;
      
      setState(() {
        final index = _events.indexWhere((e) => e['id'] == eventId);
        if (index != -1) {
          _events[index] = updatedEvent;
        }
      });
      return updatedEvent;
    } catch (e) {
      // Hata mesajı EventCard'da gösterilecek
      rethrow;
    }
  }

  Future<void> _leaveEvent(int eventId) async {
    if (_service == null) return;
    
    try {
      final updatedEvent = await _service!.leaveEvent(eventId);
      if (!mounted) return;
      setState(() {
        final index = _events.indexWhere((e) => e['id'] == eventId);
        if (index != -1) {
          _events[index] = updatedEvent;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ayrılamadı: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Widget _buildLoadingState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Etkinlikler yükleniyor...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Etkinlikler Yüklenemedi',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadEvents,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text(
                'Tekrar Dene',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_outlined,
              size: 48,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Henüz etkinlik yok',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _isGeneralPage 
                  ? 'Henüz hiç etkinlik oluşturulmamış. İlk etkinliği sen oluştur!'
                  : 'Bu grupta henüz etkinlik yok. İlk etkinliği oluştur!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final created = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                      builder: (_) => AddEventPage(groupId: widget.groupId)),
                );
                if (created == true) _loadEvents();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text(
                'Etkinlik Oluştur',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isGeneralPage
              ? 'Tüm Etkinlikler'
              : (widget.groupName ?? 'Grup Etkinlikleri'),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
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
                  ? _buildLoadingState()
                  : _error != null
                      ? _buildErrorState()
                      : _events.isEmpty
                          ? _buildEmptyState()
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
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        child: const Icon(Icons.add_rounded),
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
