library map_page;

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:motoapp_frontend/core/theme/theme_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/service_locator.dart';
import '../../services/location/location_service.dart';

part 'map_controls.dart';
part 'map_search.dart';
part 'map_route.dart';
part 'map_location_share.dart';

// Map page için LocationShare class'ı
class LocationShare {
  final int id;
  final String userName;
  final LatLng position;
  final DateTime updatedAt;
  final String shareType;
  final bool isActive;

  LocationShare({
    required this.id,
    required this.userName,
    required this.position,
    required this.updatedAt,
    required this.shareType,
    required this.isActive,
  });

  double get latitude => position.latitude;
  double get longitude => position.longitude;
}

class MapPage extends StatefulWidget {
  final LatLng? initialCenter;
  final bool allowSelection;
  final bool showMarker;

  const MapPage({
    super.key,
    this.initialCenter,
    this.allowSelection = false,
    this.showMarker = false,
  });

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _labelController = TextEditingController();

  LatLng? _currentPosition;
  LatLng? _selectedPosition;
  bool _isLoading = true;
  double _zoomLevel = 13.0;

  List<dynamic> _searchResults = [];
  Timer? _searchDebounce;
  bool _isSatelliteView = false;
  late VoidCallback _searchControllerListener;

  List<LatLng> _routePoints = [];
  bool _isRouteMode = false;
  LatLng? _startPoint;
  LatLng? _endPoint;
  double? _routeDistance; // metre cinsinden
  int? _routeDuration; // saniye cinsinden
  bool _isNavigating = false; // navigasyon modu aktif mi
  int _currentRouteIndex = 0; // mevcut rota noktası indeksi
  StreamSubscription<Position>? _positionStream; // konum takibi

  String? _selectedLocationLabel;
  List<String> _searchHistory = [];
  bool _isSearchFocused = false;

  // Konum paylaşımı için
  final LocationService _locationService = ServiceLocator.location;
  List<LocationShare> _activeLocationShares = [];
  bool _isSharingLocation = false;
  Timer? _locationUpdateTimer;

  // Grup üyeleri için
  List<dynamic> _userGroups = [];
  int? _selectedGroupId;
  List<LocationShare> _groupMembersLocations = [];
  bool _showGroupMembers = false;
  bool _showGroupSelector = false;

  // Konum paylaşımı özellikleri
  bool _showLocationShareDialog = false;
  String _shareMessage = '';
  List<dynamic> _selectedShareUsers = [];

  static const List<double> _zoomLevels = [5.0, 10.0, 13.0, 15.0, 18.0];
  static const List<String> _zoomLabels = [
    'Ülke',
    'Bölge',
    'Şehir',
    'Mahalle',
    'Sokak'
  ];

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    _searchControllerListener = () {
      setState(() {}); // Suffix icon'ın görünürlüğü için
    };
    _searchController.addListener(_searchControllerListener);
    _loadActiveLocationShares();
    _loadUserGroups();
    if (widget.initialCenter != null) {
      if (widget.allowSelection || widget.showMarker) {
        _selectedPosition = widget.initialCenter;
      }
      _isLoading = false;
    } else {
      _getCurrentLocation();
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_searchControllerListener);
    _searchController.dispose();
    _labelController.dispose();
    _searchDebounce?.cancel();
    _positionStream?.cancel();
    _locationUpdateTimer?.cancel();
    super.dispose();
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Şimdi';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} dk önce';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} saat önce';
    } else {
      return '${difference.inDays} gün önce';
    }
  }

  void _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showLocationError('Konum servisleri kapalı. Lütfen ayarlardan açın.');
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() => _isLoading = false);
            _showLocationError('Konum izni reddedildi. Uygulama varsayılan konumu kullanacak.');
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showLocationError('Konum izni kalıcı olarak reddedildi. Ayarlardan değiştirebilirsiniz.');
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      if (!mounted) return;
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showLocationError('Konum alınamadı: ${e.toString()}');
      }
    }
  }

  void _showLocationError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 4),
        backgroundColor: Theme.of(context).colorScheme.error,
        action: SnackBarAction(
          label: 'Tamam',
          textColor: Theme.of(context).colorScheme.onError,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _zoomIn() {
    if (_zoomLevel < 20) {
      _zoomLevel += 1;
      final center = _selectedPosition ?? _mapController.camera.center;
      _mapController.move(center, _zoomLevel);
    }
  }

  void _zoomOut() {
    if (_zoomLevel > 1) {
      _zoomLevel -= 1;
      final center = _selectedPosition ?? _mapController.camera.center;
      _mapController.move(center, _zoomLevel);
    }
  }

  void _goToCurrentLocation() {
    if (_currentPosition != null) {
      _zoomLevel = 15.0;
      final center = _selectedPosition ?? _currentPosition!;
      _mapController.move(center, _zoomLevel);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    const String defaultMapUrl =
        'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    const String satelliteUrl =
        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SizedBox.expand(
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: widget.initialCenter ??
                    (_currentPosition ?? const LatLng(41.0082, 28.9784)),
                initialZoom: _zoomLevel,
                onTap: (tapPosition, point) {
                  setState(() => _isSearchFocused = false);
                  if (_isRouteMode) {
                    // Rota modu aktifken allowSelection kontrolünü bypass et
                    _setRoutePoint(point);
                  } else if (widget.allowSelection) {
                    setState(() => _selectedPosition = point);
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: _isSatelliteView ? satelliteUrl : defaultMapUrl,
                  userAgentPackageName: 'com.example.frontend',
                  maxZoom: 20,
                ),
                if (_currentPosition != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _currentPosition!,
                        width: 40,
                        height: 40,
                        child: Icon(Icons.my_location,
                            color: colorScheme.primary, size: 32),
                      ),
                    ],
                  ),
                if (_selectedPosition != null && widget.showMarker)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _selectedPosition!,
                        width: 40,
                        height: 40,
                        child: Icon(Icons.location_pin,
                            color: colorScheme.error, size: 32),
                      ),
                    ],
                  ),
                if (_routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePoints,
                        color: colorScheme.primary,
                        strokeWidth: 4,
                      ),
                    ],
                  ),
                _buildLocationSharesMarkers(context),
                _buildGroupMembersMarkers(context),
                if (_isRouteMode && _startPoint != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _startPoint!,
                        width: 40,
                        height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colorScheme.onPrimary,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.play_arrow,
                            color: colorScheme.onPrimary,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                if (_isRouteMode && _endPoint != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _endPoint!,
                        width: 40,
                        height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            color: colorScheme.error,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colorScheme.onError,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.flag,
                            color: colorScheme.onError,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            _buildSearchBar(context),
            _buildMapControls(context),
            _buildLocationSharingButton(context),
            _buildLocationShareButton(),
            _buildGroupSelector(context),
            _buildGroupMembersLocations(),
            if (_selectedPosition != null) _buildLocationActions(context),
            if (_selectedPosition != null) _buildConfirmButton(context),
            _buildSearchHistory(context),
            _buildSearchResults(context),
            _buildZoomLevels(context),
            _buildRouteInfo(context),
            _buildRouteSummary(context),
            _buildNavigationUI(context),
            if (_isLoading)
              Center(
                child: CircularProgressIndicator(
                  color: colorScheme.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Konum paylaşımı fonksiyonları
  Future<void> _loadActiveLocationShares() async {
    try {
      final serviceShares = await _locationService.getActiveLocationShares();
      if (mounted) {
        setState(() {
          _activeLocationShares = serviceShares.map((share) => LocationShare(
            id: share.id,
            userName: share.user.username ?? 'Bilinmeyen',
            position: LatLng(share.latitude, share.longitude),
            updatedAt: share.updatedAt,
            shareType: share.shareType,
            isActive: share.isActive,
          )).toList();
        });
      }
    } catch (e) {
    }
  }

  Future<void> _toggleLocationSharing() async {
    try {
      if (_isSharingLocation) {
        await _locationService.stopLocationSharing();
        _stopLocationUpdates();
        setState(() {
          _isSharingLocation = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Konum paylaşımı durduruldu'),
            backgroundColor: Theme.of(context).colorScheme.onSurface,
          ),
        );
      } else {
        await _locationService.startLocationSharing(shareType: 'public');
        setState(() {
          _isSharingLocation = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Konum paylaşımı başlatıldı'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        
        // Konum paylaşımlarını yenile
        _loadActiveLocationShares();
        
        // Periyodik güncelleme başlat
        _startLocationUpdates();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Konum paylaşımı hatası: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Widget _buildLocationSharingButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Positioned(
      top: 120,
      right: 16,
      child: FloatingActionButton(
        heroTag: 'location_sharing_fab',
        onPressed: _toggleLocationSharing,
        backgroundColor: _isSharingLocation 
            ? colorScheme.error 
            : colorScheme.primary,
        child: Icon(
          _isSharingLocation ? Icons.location_off : Icons.location_on,
          color: colorScheme.onPrimary,
        ),
      ),
    );
  }

  Widget _buildLocationSharesMarkers(BuildContext context) {
    if (_activeLocationShares.isEmpty) return const SizedBox.shrink();
    
    final colorScheme = Theme.of(context).colorScheme;
    
    return MarkerLayer(
      markers: _activeLocationShares.map((share) {
        return Marker(
          point: LatLng(share.latitude, share.longitude),
          width: 30,
          height: 30,
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.secondary,
              shape: BoxShape.circle,
              border: Border.all(
                color: colorScheme.onSecondary,
                width: 2,
              ),
            ),
            child: Icon(
              Icons.motorcycle, // Motor işareti
              color: colorScheme.onSecondary,
              size: 16,
            ),
          ),
        );
      }).toList(),
    );
  }

  void _startLocationUpdates() {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _loadActiveLocationShares();
      if (_showGroupMembers && _selectedGroupId != null) {
        _loadGroupMembersLocations(_selectedGroupId!);
      }
    });
  }

  void _stopLocationUpdates() {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;
  }

  // Grup üyeleri fonksiyonları
  Future<void> _loadUserGroups() async {
    try {
      final groups = await ServiceLocator.group.fetchUserGroups();
      if (mounted) {
        setState(() {
          _userGroups = groups;
        });
      }
    } catch (e) {
    }
  }

  Future<void> _loadGroupMembersLocations(int groupId) async {
    try {
      final serviceLocations = await _locationService.getGroupMembersLocations(groupId);
      if (mounted) {
        setState(() {
          _groupMembersLocations = serviceLocations.map((location) => LocationShare(
            id: location.id,
            userName: location.user.username ?? 'Bilinmeyen',
            position: LatLng(location.latitude, location.longitude),
            updatedAt: location.updatedAt,
            shareType: location.shareType,
            isActive: location.isActive,
          )).toList();
        });
      }
    } catch (e) {
    }
  }

  void _toggleGroupMembersView() {
    setState(() {
      _showGroupMembers = !_showGroupMembers;
      if (_showGroupMembers && _selectedGroupId != null) {
        _loadGroupMembersLocations(_selectedGroupId!);
      }
    });
  }

  void _hideGroupSelector() {
    setState(() {
      _showGroupSelector = false;
      _showGroupMembers = false; // Grup seçiciyi gizlediğimizde grup üyelerini de gizle
    });
  }

  Widget _buildGroupSelector(BuildContext context) {
    if (_userGroups.isEmpty) return const SizedBox.shrink();
    
    final colorScheme = Theme.of(context).colorScheme;
    
    return Positioned(
      top: 180,
      right: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Grup seçici toggle butonu
          FloatingActionButton(
            heroTag: 'group_selector_fab',
            onPressed: () {
              if (_showGroupSelector) {
                _hideGroupSelector();
              } else {
                setState(() {
                  _showGroupSelector = true;
                });
              }
            },
            backgroundColor: _showGroupSelector 
                ? colorScheme.error 
                : colorScheme.secondary,
            child: Icon(
              _showGroupSelector ? Icons.close : Icons.group,
              color: colorScheme.onSecondary,
            ),
          ),
          const SizedBox(height: 8),
          // Grup seçici paneli
          if (_showGroupSelector)
            Container(
              width: 200,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Grup seçici
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: DropdownButtonFormField<int>(
                      value: _selectedGroupId,
                      decoration: InputDecoration(
                        labelText: 'Grup Seç',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: _userGroups.map((group) {
                        return DropdownMenuItem<int>(
                          value: group['id'],
                          child: Text(
                            group['name'] ?? 'Grup',
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (groupId) {
                        setState(() {
                          _selectedGroupId = groupId;
                        });
                        if (groupId != null) {
                          _loadGroupMembersLocations(groupId);
                        }
                      },
                    ),
                  ),
                  // Grup üyelerini göster/gizle butonu
                  if (_selectedGroupId != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ElevatedButton.icon(
                        onPressed: _toggleGroupMembersView,
                        icon: Icon(_showGroupMembers ? Icons.visibility_off : Icons.visibility),
                        label: Text(_showGroupMembers ? 'Gizle' : 'Göster'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _showGroupMembers 
                              ? colorScheme.error 
                              : colorScheme.primary,
                          foregroundColor: _showGroupMembers 
                              ? colorScheme.onError 
                              : colorScheme.onPrimary,
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

  Widget _buildGroupMembersMarkers(BuildContext context) {
    if (!_showGroupSelector || !_showGroupMembers || _groupMembersLocations.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final colorScheme = Theme.of(context).colorScheme;
    
    return MarkerLayer(
      markers: _groupMembersLocations.map((share) {
        return Marker(
          point: LatLng(share.latitude, share.longitude),
          width: 40,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.secondary,
              shape: BoxShape.circle,
              border: Border.all(
                color: colorScheme.onSecondary,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.motorcycle, // Motor işareti
              color: colorScheme.onSecondary,
              size: 20,
            ),
          ),
        );
      }).toList(),
    );
  }
}
