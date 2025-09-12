import 'package:flutter/material.dart';
import 'package:motoapp_frontend/core/theme/theme_constants.dart';
import '../../services/rides/rides_service.dart';

/// Yolculuk detay sayfası
class RideDetailPage extends StatefulWidget {
  final Ride ride;

  const RideDetailPage({
    super.key,
    required this.ride,
  });

  @override
  State<RideDetailPage> createState() => _RideDetailPageState();
}

class _RideDetailPageState extends State<RideDetailPage> with TickerProviderStateMixin {
  late TabController _tabController;
  final RidesService _ridesService = RidesService();
  
  Ride? _ride;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _ride = widget.ride;
    _loadRideDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRideDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final ride = await _ridesService.getRide(_ride!.id);
      setState(() {
        _ride = ride;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null || _ride == null) {
      return _buildErrorState();
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildRideInfo(),
                _buildTabBar(),
                _buildTabContent(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildLoadingState() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Yolculuk detayları yükleniyor...',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: colorScheme.error,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'Bir hata oluştu',
                style: textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error ?? 'Bilinmeyen hata',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadRideDetails,
                icon: const Icon(Icons.refresh),
                label: const Text('Tekrar Dene'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: colorScheme.surface,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          _ride!.title,
          style: textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colorScheme.primary.withOpacity(0.8),
                colorScheme.primary.withOpacity(0.4),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.route,
                  color: colorScheme.onPrimary,
                  size: 48,
                ),
                const SizedBox(height: 8),
                Text(
                  'by ${_ride!.owner}',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: _toggleFavorite,
          icon: Icon(
            _ride!.isFavorite ? Icons.favorite : Icons.favorite_border,
            color: _ride!.isFavorite ? colorScheme.error : colorScheme.onSurface,
          ),
          tooltip: _ride!.isFavorite ? 'Favorilerden çıkar' : 'Favorilere ekle',
        ),
      ],
    );
  }

  Widget _buildRideInfo() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          if (_ride!.description.isNotEmpty) ...[
            Text(
              'Açıklama',
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _ride!.description,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Route Info
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  Icons.location_on,
                  'Başlangıç',
                  _ride!.startLocation,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  Icons.flag,
                  'Bitiş',
                  _ride!.endLocation,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Stats
          Row(
            children: [
              if (_ride!.distanceKm != null) ...[
                Expanded(
                  child: _buildStatCard(
                    Icons.straighten,
                    'Mesafe',
                    '${_ride!.distanceKm!.toStringAsFixed(1)} km',
                  ),
                ),
                const SizedBox(width: 12),
              ],
              if (_ride!.estimatedDurationMinutes != null) ...[
                Expanded(
                  child: _buildStatCard(
                    Icons.access_time,
                    'Süre',
                    '${_ride!.estimatedDurationMinutes} dk',
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: _buildStatCard(
                  Icons.people,
                  'Katılımcılar',
                  '${_ride!.participants.length}${_ride!.maxParticipants != null ? '/${_ride!.maxParticipants}' : ''}',
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Ride Type & Privacy
          Row(
            children: [
              _buildTypeChip(_ride!.rideType),
              const SizedBox(width: 8),
              _buildPrivacyChip(_ride!.privacyLevel),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(ThemeConstants.borderRadiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colorScheme.primary, size: 20),
          const SizedBox(height: 8),
          Text(
            title,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String title, String value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(ThemeConstants.borderRadiusMedium),
      ),
      child: Column(
        children: [
          Icon(icon, color: colorScheme.onPrimaryContainer, size: 20),
          const SizedBox(height: 8),
          Text(
            title,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          Text(
            value,
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String type) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final typeLabels = {
      'casual': 'Günlük',
      'touring': 'Tur',
      'group': 'Grup',
      'track': 'Pist',
      'adventure': 'Macera',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        typeLabels[type] ?? type,
        style: textTheme.bodySmall?.copyWith(
          color: colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPrivacyChip(String privacy) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final privacyLabels = {
      'public': 'Açık',
      'friends': 'Arkadaşlar',
      'private': 'Özel',
    };

    final privacyColors = {
      'public': colorScheme.primaryContainer,
      'friends': colorScheme.secondaryContainer,
      'private': colorScheme.errorContainer,
    };

    final privacyTextColors = {
      'public': colorScheme.onPrimaryContainer,
      'friends': colorScheme.onSecondaryContainer,
      'private': colorScheme.onErrorContainer,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: privacyColors[privacy],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        privacyLabels[privacy] ?? privacy,
        style: textTheme.bodySmall?.copyWith(
          color: privacyTextColors[privacy],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.surface,
      child: TabBar(
        controller: _tabController,
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        indicatorColor: colorScheme.primary,
        tabs: const [
          Tab(text: 'Katılımcılar'),
          Tab(text: 'İstekler'),
          Tab(text: 'Rota'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return SizedBox(
      height: 300,
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildParticipantsTab(),
          _buildRequestsTab(),
          _buildRouteTab(),
        ],
      ),
    );
  }

  Widget _buildParticipantsTab() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _ride!.participants.length,
      itemBuilder: (context, index) {
        final participant = _ride!.participants[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: colorScheme.primaryContainer,
            child: Text(
              participant[0].toUpperCase(),
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          title: Text(participant),
          subtitle: Text('Katılımcı'),
        );
      },
    );
  }

  Widget _buildRequestsTab() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    if (_ride!.pendingRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_add_outlined,
              color: colorScheme.onSurfaceVariant,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Bekleyen istek yok',
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _ride!.pendingRequests.length,
      itemBuilder: (context, index) {
        final request = _ride!.pendingRequests[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: colorScheme.primaryContainer,
              child: Text(
                request.requester.username[0].toUpperCase(),
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            title: Text(request.requester.username),
            subtitle: Text('Katılım isteği'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _approveRequest(request.id),
                  icon: Icon(Icons.check, color: colorScheme.primary),
                  tooltip: 'Onayla',
                ),
                IconButton(
                  onPressed: () => _rejectRequest(request.id),
                  icon: Icon(Icons.close, color: colorScheme.error),
                  tooltip: 'Reddet',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRouteTab() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_outlined,
              color: colorScheme.onSurfaceVariant,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Rota Haritası',
              style: textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Harita görünümü yakında eklenecek',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final isParticipant = _ride!.participants.contains(_ride!.owner);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.onSurface.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isParticipant ? _leaveRide : _joinRide,
            icon: Icon(
              isParticipant ? Icons.exit_to_app : Icons.add,
              color: isParticipant ? colorScheme.onError : colorScheme.onPrimary,
            ),
            label: Text(
              isParticipant ? 'Yolculuktan Ayrıl' : 'Yolculuğa Katıl',
              style: textTheme.labelLarge?.copyWith(
                color: isParticipant ? colorScheme.onError : colorScheme.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isParticipant ? colorScheme.error : colorScheme.primary,
              foregroundColor: isParticipant ? colorScheme.onError : colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ThemeConstants.borderRadiusLarge),
              ),
              elevation: 0,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _toggleFavorite() async {
    try {
      await _ridesService.toggleFavorite(_ride!.id);
      await _loadRideDetails();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_ride!.isFavorite 
                ? 'Favorilerden çıkarıldı' 
                : 'Favorilere eklendi'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _joinRide() async {
    try {
      await _ridesService.joinRide(_ride!.id);
      await _loadRideDetails();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_ride!.title} yolculuğuna katılım isteği gönderildi'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _leaveRide() async {
    try {
      await _ridesService.leaveRide(_ride!.id);
      await _loadRideDetails();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_ride!.title} yolculuğundan ayrıldınız'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _approveRequest(int requestId) async {
    try {
      await _ridesService.approveRequest(_ride!.id, requestId);
      await _loadRideDetails();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Katılım isteği onaylandı'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _rejectRequest(int requestId) async {
    try {
      await _ridesService.rejectRequest(_ride!.id, requestId);
      await _loadRideDetails();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Katılım isteği reddedildi'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
