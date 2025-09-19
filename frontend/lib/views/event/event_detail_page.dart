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
import 'package:flutter_map/flutter_map.dart';

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
  bool _requestSent = false;

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final eventImageUrl = widget.event['event_image'] as String?;

    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Hata: $_error'))
              : CustomScrollView(
                  slivers: [
                    // Hero Header
                    SliverAppBar(
                      expandedHeight: 280,
                      pinned: true,
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      actions: [
                        // Sadece organizatör için silme butonu
                        if (_isOrganizer())
                          IconButton(
                            onPressed: _showDeleteConfirmation,
                            icon: const Icon(Icons.delete_outline),
                            tooltip: 'Etkinliği Sil',
                          ),
                      ],
                      flexibleSpace: FlexibleSpaceBar(
                        title: Text(
                          widget.event['title']?.toString() ?? 'Etkinlik Detayları',
                          style: TextStyle(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                        background: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Event Image or Gradient Background
                            if (eventImageUrl != null && eventImageUrl.isNotEmpty)
                              Image.network(
                                eventImageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => _buildGradientBackground(colorScheme),
                              )
                            else
                              _buildGradientBackground(colorScheme),
                            
                            // Gradient Overlay
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.7),
                                  ],
                                ),
                              ),
                            ),
                            
                            // Status Chips
                            Positioned(
                              top: 100,
                              left: 16,
                              right: 16,
                              child: Row(
                                children: [
                                  _buildStatusChip(
                                    widget.event['is_public'] == true ? 'Public' : 'Private',
                                    Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  if (widget.event['requires_approval'] == true)
                                    _buildStatusChip('Onay Gerekli', Theme.of(context).colorScheme.primary),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Content
                    SliverToBoxAdapter(
                      child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                            // Organizer Card
                            Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 30,
                                      backgroundColor: colorScheme.primary.withOpacity(0.1),
                                      child: Text(
                                        organizerName.isNotEmpty
                                            ? organizerName[0].toUpperCase()
                                            : '?',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                        'Etkinlik Kurucusu',
                        style: TextStyle(
                                              fontSize: 14,
                                              color: colorScheme.onSurface.withOpacity(0.6),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            organizerName,
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.onSurface,
                                            ),
                                          ),
                                          if (organizerEmail.isNotEmpty)
                                            Text(
                                              organizerEmail,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: colorScheme.onSurface.withOpacity(0.7),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),

                            // Description Card
                            if ((widget.event['description']?.toString() ?? '').isNotEmpty)
                              Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.description_outlined,
                                            color: colorScheme.primary,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                              'Açıklama',
                              style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.onSurface,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        widget.event['description'].toString(),
                        style: TextStyle(
                                          fontSize: 15,
                                          color: colorScheme.onSurface.withOpacity(0.8),
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            const SizedBox(height: 16),

                            // Event Details Card
                            Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                      Row(
                        children: [
                                        Icon(
                                          Icons.info_outline,
                                          color: colorScheme.primary,
                                          size: 20,
                                        ),
                          const SizedBox(width: 8),
                                        Text(
                                          'Etkinlik Detayları',
                              style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    
                                    // Date
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today,
                                            color: colorScheme.primary,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Tarih ve Saat',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: colorScheme.onSurface.withOpacity(0.6),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  formatDate(widget.event['start_time']),
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: colorScheme.onSurface,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    if ((widget.event['location']?.toString() ?? '').isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      
                                      // Location
                        GestureDetector(
                          onTap: () {
                            final pos = _parseLatLng(widget.event['location'].toString());
                            if (pos != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MapPage(
                                    initialCenter: pos,
                                    allowSelection: false,
                                    showMarker: true,
                                  ),
                                ),
                              );
                            }
                          },
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: colorScheme.secondary.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: colorScheme.secondary.withOpacity(0.3),
                                              width: 1,
                                            ),
                                          ),
                          child: Row(
                            children: [
                                              Icon(
                                                Icons.location_on,
                                                color: colorScheme.secondary,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 12),
                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Konum',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: colorScheme.onSurface.withOpacity(0.6),
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                  widget.event['location'].toString(),
                                  style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w600,
                                                        color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                                              Icon(
                                                Icons.arrow_forward_ios,
                                                color: colorScheme.secondary,
                                                size: 16,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                      const SizedBox(height: 16),

                            // Map Preview
                            if ((widget.event['location']?.toString() ?? '').isNotEmpty)
                              Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: _MiniMapPreview(location: widget.event['location'].toString()),
                                ),
                              ),
                            const SizedBox(height: 16),

                            // Participants Card
                            Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.people_outline,
                                          color: colorScheme.primary,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Katılımcılar',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: colorScheme.primary.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '${_participants.length}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    
                                    if (_participants.isEmpty)
                                      Container(
                                        padding: const EdgeInsets.all(24),
                                        decoration: BoxDecoration(
                                          color: colorScheme.surfaceVariant.withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Column(
                                          children: [
                                            Icon(
                                              Icons.people_outline,
                                              size: 48,
                                              color: colorScheme.onSurface.withOpacity(0.4),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Henüz katılımcı yok',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: colorScheme.onSurface.withOpacity(0.6),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else
                                      Column(
                                        children: [
                                          // First 3 participants
                                          ...(_participants.take(3).map((user) => Container(
                                            margin: const EdgeInsets.only(bottom: 8),
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: colorScheme.surfaceVariant.withOpacity(0.3),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: 20,
                                                  backgroundImage: user['profile_picture'] != null
                                                      ? NetworkImage(user['profile_picture'])
                                                      : null,
                                                  backgroundColor: colorScheme.primary.withOpacity(0.1),
                                                  child: user['profile_picture'] == null
                                                      ? Text(
                                                          user['username'][0].toUpperCase(),
                                                          style: TextStyle(
                                                            color: colorScheme.primary,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        )
                                                      : null,
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        user['username'],
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.w600,
                                                          color: colorScheme.onSurface,
                                                        ),
                                                      ),
                                                      if (user['email'] != null)
                                                        Text(
                                                          user['email'],
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            color: colorScheme.onSurface.withOpacity(0.6),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ))),
                                          
                                          // Show more button if there are more participants
                                          if (_participants.length > 3)
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => _EventParticipantsPage(
                                event: widget.event,
                                participants: _participants,
                              ),
                            ),
                          );
                        },
                                              child: Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: colorScheme.primary.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: colorScheme.primary.withOpacity(0.3),
                                                    width: 1,
                                                  ),
                                                ),
                        child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                                      've ${_participants.length - 3} kişi daha',
                                  style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w600,
                                                        color: colorScheme.primary,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Icon(
                                                      Icons.arrow_forward_ios,
                                                      size: 16,
                                                      color: colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                                            ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Join Button
                      _buildJoinButton(),
                            const SizedBox(height: 32),
                    ],
                  ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildJoinButton() {
    final isJoined = widget.event['is_joined'] as bool? ?? false;
    final participantCount = widget.event['current_participant_count'] ?? 0;
    final guestLimit = widget.event['guest_limit'] ?? '-';
    final organizerUsername = (widget.event['organizer'] as Map?)?['username'] ?? '';
    final requiresApproval = widget.event['requires_approval'] as bool? ?? false;
    final canJoin = !isJoined &&
        organizerUsername != widget.currentUsername &&
        (guestLimit == '-' || participantCount < guestLimit);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!canJoin && !isJoined) {
      return const SizedBox.shrink(); // Buton gösterme
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Participant count info
          Container(
      width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Katılımcılar: $participantCount${guestLimit != '-' ? ' / $guestLimit' : ''}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Join/Leave button
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: (isJoined ? Colors.red : colorScheme.primary).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
      child: ElevatedButton(
        onPressed: isJoined ? _leaveEvent : _joinEvent,
        style: ElevatedButton.styleFrom(
                backgroundColor: isJoined ? Colors.red : colorScheme.primary,
          foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isJoined ? Icons.exit_to_app : Icons.event_available,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _getButtonText(isJoined, requiresApproval),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Additional info for approval required events
          if (requiresApproval && !isJoined)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
        child: Text(
                      'Bu etkinliğe katılmak için organizatörden onay gerekiyor.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _getButtonText(bool isJoined, bool requiresApproval) {
    if (isJoined) {
      return 'Ayrıl';
    } else if (requiresApproval && _requestSent) {
      return 'İsteğiniz Gönderildi';
    } else if (requiresApproval) {
      return 'Katıl';
    } else {
      return 'Katıl';
    }
  }

  Future<void> _joinEvent() async {
    final requiresApproval = widget.event['requires_approval'] as bool? ?? false;
    
    if (requiresApproval) {
      // Onay gerektiren event için mesaj dialog'u göster
      final message = await _showJoinRequestDialog();
      if (message == null) return; // Kullanıcı iptal etti
      
      try {
        final updatedEvent = await _service.joinEvent(widget.event['id'], message: message);
        if (!mounted) return;
        
        // Backend'den gelen güncel event bilgisini kullan
        setState(() {
          _requestSent = true;
          // Event bilgisini güncelle
          widget.event.updateAll((key, value) => updatedEvent[key] ?? value);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Katılım isteği gönderildi. Onay bekleniyor.'),
            backgroundColor: Colors.orange,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('İstek gönderilemedi: $e')),
        );
      }
    } else {
      // Onay gerektirmeyen event için direkt katıl
      try {
        final updatedEvent = await _service.joinEvent(widget.event['id']);
        if (!mounted) return;
        
        // Backend'den gelen güncel event bilgisini kullan
        setState(() {
          // Event bilgisini güncelle
          widget.event.updateAll((key, value) => updatedEvent[key] ?? value);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Etkinliğe başarıyla katıldınız!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Sayfayı yenile
        _loadParticipants();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Katılamadı: $e')),
        );
      }
    }
  }

  Future<void> _leaveEvent() async {
    try {
      final updatedEvent = await _service.leaveEvent(widget.event['id']);
      if (!mounted) return;
      
      // Backend'den gelen güncel event bilgisini kullan
      setState(() {
        // Event bilgisini güncelle
        widget.event.updateAll((key, value) => updatedEvent[key] ?? value);
        _requestSent = false; // İstek durumunu sıfırla
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Etkinlikten ayrıldınız.'),
          backgroundColor: Colors.orange,
        ),
      );
      
      // Sayfayı yenile
      _loadParticipants();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ayrılamadı: $e')),
      );
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

  // Organizatör kontrolü
  bool _isOrganizer() {
    final organizer = widget.event['organizer'];
    if (organizer is Map<String, dynamic>) {
      return organizer['username'] == widget.currentUsername;
    }
    return false;
  }

  // Silme onayı dialogu
  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Etkinliği Sil'),
        content: const Text(
          'Bu etkinliği silmek istediğinizden emin misiniz? Bu işlem geri alınamaz ve tüm katılımcılar etkinlikten çıkarılacaktır.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteEvent();
    }
  }

  // Event silme işlemi
  Future<void> _deleteEvent() async {
    try {
      // Loading göster
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      await _service.deleteEvent(widget.event['id']);
      
      if (!mounted) return;
      
      // Loading'i kapat
      Navigator.of(context).pop();
      
      // Başarı mesajı göster
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Etkinlik başarıyla silindi'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Önceki sayfaya dön
      Navigator.of(context).pop(true); // true = event silindi
      
    } catch (e) {
      if (!mounted) return;
      
      // Loading'i kapat
      Navigator.of(context).pop();
      
      // Hata mesajı göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Etkinlik silinirken hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildGradientBackground(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.primary.withOpacity(0.8),
            colorScheme.secondary,
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  LatLng? _parseLatLng(String location) {
    try {
      final parts = location.split(',');
      if (parts.length == 2) {
        final lat = double.parse(parts[0].trim());
        final lng = double.parse(parts[1].trim());
        return LatLng(lat, lng);
      }
    } catch (e) {
      // Hata durumunda null döndür
    }
    return null;
  }
}

class _MiniMapPreview extends StatelessWidget {
  final String location;

  const _MiniMapPreview({required this.location});

  @override
  Widget build(BuildContext context) {
    final pos = _parseLatLng(location);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    if (pos == null) {
      return Container(
        height: 250,
        decoration: BoxDecoration(
          color: colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 48,
              color: colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: 8),
            Text(
              'Konum bilgisi geçersiz',
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            FlutterMap(
          options: MapOptions(
            initialCenter: pos,
            initialZoom: 15.0,
            interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.motoapp',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: pos,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                    Icons.location_on,
                          color: colorScheme.primary,
                          size: 24,
                        ),
                  ),
                ),
              ],
                ),
              ],
            ),
            
            // Tap to open full map button
            Positioned(
              top: 12,
              right: 12,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MapPage(
                        initialCenter: pos,
                        allowSelection: false,
                        showMarker: true,
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.fullscreen,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ),
              ),
            ),
            
            // Location info overlay
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: colorScheme.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Etkinlik Konumu',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.touch_app,
                      color: colorScheme.primary,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  LatLng? _parseLatLng(String location) {
    try {
      final parts = location.split(',');
      if (parts.length == 2) {
        final lat = double.parse(parts[0].trim());
        final lng = double.parse(parts[1].trim());
        return LatLng(lat, lng);
      }
    } catch (e) {
      // Hata durumunda null döndür
    }
    return null;
  }
}

class _EventParticipantsPage extends StatelessWidget {
  final Map<String, dynamic> event;
  final List<dynamic> participants;

  const _EventParticipantsPage({
    required this.event,
    required this.participants,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Katılımcılar'),
      ),
      body: participants.isEmpty
          ? const Center(child: Text('Henüz katılımcı yok'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: participants.length,
              itemBuilder: (context, index) {
                final user = participants[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: user['profile_picture'] != null
                        ? NetworkImage(user['profile_picture'])
                        : null,
                    child: user['profile_picture'] == null
                        ? Text(user['username'][0].toUpperCase())
                        : null,
                  ),
                  title: Text(user['username']),
                  subtitle: user['email'] != null ? Text(user['email']) : null,
                );
              },
            ),
    );
  }
}
