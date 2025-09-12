import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:motoapp_frontend/core/theme/theme_constants.dart';
import '../../services/rides/rides_service.dart';
import 'create_ride_page.dart';
import 'ride_detail_page.dart';
import 'widgets/ride_card.dart';

/// Rides ana sayfası
class RidesPage extends StatefulWidget {
  const RidesPage({super.key});

  @override
  State<RidesPage> createState() => _RidesPageState();
}

class _RidesPageState extends State<RidesPage> with TickerProviderStateMixin {
  late TabController _tabController;
  final RidesService _ridesService = RidesService();
  
  List<Ride> _allRides = [];
  List<Ride> _myRides = [];
  List<RouteFavorite> _favoriteRoutes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final futures = await Future.wait([
        _ridesService.getRides(),
        _ridesService.getMyRides(),
        _ridesService.getFavoriteRoutes(),
      ]);

      setState(() {
        _allRides = futures[0] as List<Ride>;
        _myRides = futures[1] as List<Ride>;
        _favoriteRoutes = futures[2] as List<RouteFavorite>;
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

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Yolculuklar',
          style: textTheme.headlineSmall?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: Icon(
              Icons.refresh,
              color: colorScheme.onSurface,
            ),
            tooltip: 'Yenile',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurfaceVariant,
          indicatorColor: colorScheme.primary,
          tabs: const [
            Tab(text: 'Tümü'),
            Tab(text: 'Benimkiler'),
            Tab(text: 'Favoriler'),
          ],
        ),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _error != null
              ? _buildErrorState()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildRidesList(_allRides, 'Tüm Yolculuklar'),
                    _buildRidesList(_myRides, 'Benim Yolculuklarım'),
                    _buildFavoritesList(),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreateRide,
        icon: const Icon(Icons.add),
        label: const Text('Yeni Yolculuk'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
    );
  }

  Widget _buildLoadingState() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Yolculuklar yükleniyor...',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
    final textTheme = theme.textTheme;

    return Center(
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
              onPressed: _loadData,
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
    );
  }

  Widget _buildRidesList(List<Ride> rides, String title) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    if (rides.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.route_outlined,
                color: colorScheme.onSurfaceVariant,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'Henüz yolculuk yok',
                style: textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'İlk yolculuğunuzu oluşturmak için + butonuna tıklayın',
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

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: rides.length,
        itemBuilder: (context, index) {
          final ride = rides[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: RideCard(
              ride: ride,
              onTap: () => _navigateToRideDetail(ride),
              onJoin: () => _joinRide(ride),
              onLeave: () => _leaveRide(ride),
              onToggleFavorite: () => _toggleFavorite(ride),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFavoritesList() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    if (_favoriteRoutes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite_outline,
                color: colorScheme.onSurfaceVariant,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'Henüz favori rota yok',
                style: textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Beğendiğiniz rotaları favorilere ekleyebilirsiniz',
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

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _favoriteRoutes.length,
        itemBuilder: (context, index) {
          final favorite = _favoriteRoutes[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: RideCard(
              ride: favorite.ride,
              onTap: () => _navigateToRideDetail(favorite.ride),
              onJoin: () => _joinRide(favorite.ride),
              onLeave: () => _leaveRide(favorite.ride),
              onToggleFavorite: () => _toggleFavorite(favorite.ride),
              isFavorite: true,
            ),
          );
        },
      ),
    );
  }

  void _navigateToCreateRide() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateRidePage(),
      ),
    ).then((_) => _loadData());
  }

  void _navigateToRideDetail(Ride ride) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RideDetailPage(ride: ride),
      ),
    ).then((_) => _loadData());
  }

  Future<void> _joinRide(Ride ride) async {
    try {
      await _ridesService.joinRide(ride.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${ride.title} yolculuğuna katılım isteği gönderildi'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        _loadData();
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

  Future<void> _leaveRide(Ride ride) async {
    try {
      await _ridesService.leaveRide(ride.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${ride.title} yolculuğundan ayrıldınız'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        _loadData();
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

  Future<void> _toggleFavorite(Ride ride) async {
    try {
      await _ridesService.toggleFavorite(ride.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ride.isFavorite 
                ? 'Favorilerden çıkarıldı' 
                : 'Favorilere eklendi'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        _loadData();
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
