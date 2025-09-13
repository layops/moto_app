part of map_page;

extension MapRoute on _MapPageState {
  void _toggleRouteMode() {
    setState(() {
      _isRouteMode = !_isRouteMode;
      if (!_isRouteMode) {
        _routePoints.clear();
        _startPoint = null;
        _endPoint = null;
        _routeDistance = null;
        _routeDuration = null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rota modu kapatıldı'),
            duration: Duration(seconds: 2),
            backgroundColor: Theme.of(context).colorScheme.onSurface,
          ),
        );
      } else {
        // Rota modu açıldığında bilgi mesajı göster
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rota modu aktif! Map\'e tıklayarak başlangıç noktasını seçin.'),
            duration: Duration(seconds: 4),
            backgroundColor: Theme.of(context).colorScheme.primary,
            action: SnackBarAction(
              label: 'Tamam',
              textColor: Theme.of(context).colorScheme.onPrimary,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    });
  }

  void _setRoutePoint(LatLng point) {
    if (!_isRouteMode) return;

    setState(() {
      if (_startPoint == null) {
        _startPoint = point;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Başlangıç noktası seçildi. Şimdi bitiş noktasını seçin.'),
            duration: Duration(seconds: 2),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      } else if (_endPoint == null) {
        _endPoint = point;
        _calculateRoute();
      } else {
        _startPoint = point;
        _endPoint = null;
        _routePoints.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Yeni başlangıç noktası seçildi. Bitiş noktasını seçin.'),
            duration: Duration(seconds: 2),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    });
  }

  Future<void> _calculateRoute() async {
    if (_startPoint == null || _endPoint == null) return;

    setState(() => _isLoading = true);

    try {
      // OSRM (Open Source Routing Machine) API kullanarak rota hesaplama
      final uri = Uri.https(
        'router.project-osrm.org',
        '/route/v1/driving/${_startPoint!.longitude},${_startPoint!.latitude};${_endPoint!.longitude},${_endPoint!.latitude}',
        {
          'overview': 'full',
          'geometries': 'geojson',
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'MotoApp/1.0',
        },
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['code'] == 'Ok' && data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final coordinates = route['geometry']['coordinates'] as List;
          final distance = route['distance'] as double; // metre
          final duration = route['duration'] as double; // saniye
          
          setState(() {
            _routePoints = coordinates.map((coord) => 
              LatLng(coord[1].toDouble(), coord[0].toDouble())
            ).toList();
            _routeDistance = distance;
            _routeDuration = duration.round();
            _isRouteMode = false; // Rota oluşturulduktan sonra modu kapat
          });
          
          if (mounted) {
            final distanceKm = (distance / 1000).toStringAsFixed(1);
            final durationMin = (duration / 60).round();
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Rota oluşturuldu: ${distanceKm} km, ${durationMin} dk'),
                duration: Duration(seconds: 4),
                backgroundColor: Theme.of(context).colorScheme.primary,
                action: SnackBarAction(
                  label: 'Tamam',
                  textColor: Theme.of(context).colorScheme.onPrimary,
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                ),
              ),
            );
          }
        } else {
          throw Exception('Rota bulunamadı');
        }
      } else {
        // API başarısız olursa basit çizgi çiz
        setState(() {
          _routePoints = [_startPoint!, _endPoint!];
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Rota hesaplanamadı (${response.statusCode}), basit çizgi gösteriliyor'),
              duration: Duration(seconds: 3),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } on TimeoutException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rota hesaplama zaman aşımına uğradı'),
            duration: Duration(seconds: 2),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      // Zaman aşımında basit çizgi göster
      setState(() {
        _routePoints = [_startPoint!, _endPoint!];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rota hesaplanamadı: ${e.toString().length > 50 ? e.toString().substring(0, 50) + '...' : e.toString()}'),
            duration: Duration(seconds: 3),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      // Hata durumunda basit çizgi göster
      setState(() {
        _routePoints = [_startPoint!, _endPoint!];
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _shareLocation() {
    if (_selectedPosition == null) return;

    final locationText =
        'Konum: ${_selectedPosition!.latitude}, ${_selectedPosition!.longitude}';
    Clipboard.setData(ClipboardData(text: locationText));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Konum panoya kopyalandı'),
        duration: Duration(seconds: 2),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  void _showLabelDialog() {
    if (_selectedPosition == null) return;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    showDialog(
      context: context,
      builder: (context) => Theme(
        data: theme,
        child: AlertDialog(
          title: Text('Konum Etiketi', style: textTheme.headlineMedium),
          content: TextField(
            controller: _labelController,
            decoration: InputDecoration(
              hintText: 'Bu konum için bir etiket girin',
              hintStyle: textTheme.bodyMedium,
            ),
            style: textTheme.bodyLarge,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('İptal', style: textTheme.titleMedium),
            ),
            TextButton(
              onPressed: () {
                setState(() =>
                    _selectedLocationLabel = _labelController.text.trim());
                _labelController.clear();
                Navigator.pop(context);
              },
              child: Text('Kaydet', style: textTheme.titleMedium),
            ),
          ],
        ),
      ),
    );
  }

  void _setZoomLevel(double level) {
    setState(() {
      _zoomLevel = level;
    });
    final center =
        _selectedPosition ?? _currentPosition ?? const LatLng(41.0082, 28.9784);
    _mapController.move(center, _zoomLevel);
  }

  Widget _buildZoomLevels(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final mediaQuery = MediaQuery.of(context);
    final safeAreaBottom = mediaQuery.padding.bottom;

    return Positioned(
      bottom: 160 + safeAreaBottom, // Location actions ve confirm button için yer bırak
      left: 16,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius:
              BorderRadius.circular(ThemeConstants.borderRadiusMedium),
          boxShadow: [
            BoxShadow(
              color: colorScheme.onSurface.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _MapPageState._zoomLevels.asMap().entries.map((entry) {
            final index = entry.key;
            final level = entry.value;
            final isSelected = (_zoomLevel - level).abs() < 0.5;

            return InkWell(
              onTap: () => _setZoomLevel(level),
              borderRadius: BorderRadius.circular(ThemeConstants.borderRadiusMedium),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? colorScheme.primary.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(ThemeConstants.borderRadiusMedium),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      size: 16,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface.withOpacity(0.5),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _MapPageState._zoomLabels[index],
                      style: textTheme.bodySmall?.copyWith(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurface.withOpacity(0.7),
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLocationActions(BuildContext context) {
    if (_selectedPosition == null) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final mediaQuery = MediaQuery.of(context);
    final safeAreaBottom = mediaQuery.padding.bottom;

    return Positioned(
      bottom: 80 + safeAreaBottom, // Confirm button için yer bırak
      left: 16,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(ThemeConstants.borderRadiusLarge),
          boxShadow: [
            BoxShadow(
              color: colorScheme.onSurface.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton(
              heroTag: 'share_location_fab',
              onPressed: _shareLocation,
              backgroundColor: colorScheme.secondary,
              mini: true,
              child: Icon(Icons.share, color: colorScheme.onSecondary),
            ),
            const SizedBox(width: 4),
            FloatingActionButton(
              heroTag: 'label_location_fab',
              onPressed: _showLabelDialog,
              backgroundColor: colorScheme.secondary,
              mini: true,
              child: Icon(Icons.label, color: colorScheme.onSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmButton(BuildContext context) {
    if (_selectedPosition == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final mediaQuery = MediaQuery.of(context);
    final safeAreaBottom = mediaQuery.padding.bottom;

    return Positioned(
      bottom: 16 + safeAreaBottom,
      left: 16,
      right: 16,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ThemeConstants.borderRadiusXLarge),
          boxShadow: [
            BoxShadow(
              color: colorScheme.onSurface.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(ThemeConstants.borderRadiusXLarge),
            ),
            elevation: 0, // Container shadow kullanıyoruz
          ),
          icon: const Icon(Icons.check),
          label: Text(
              _selectedLocationLabel != null
                  ? "Seç: $_selectedLocationLabel"
                  : "Bu Konumu Seç",
              style: textTheme.labelLarge),
          onPressed: () {
            if (!mounted) return;
            final result = _selectedPosition;
            setState(() {
              _isLoading = false;
            });
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop(result);
            }
          },
        ),
      ),
    );
  }

  Widget _buildRouteInfo(BuildContext context) {
    if (!_isRouteMode || _startPoint == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final mediaQuery = MediaQuery.of(context);
    final safeAreaTop = mediaQuery.padding.top;

    return Positioned(
      top: 80 + safeAreaTop,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(ThemeConstants.borderRadiusMedium),
          boxShadow: [
            BoxShadow(
              color: colorScheme.onSurface.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.route, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Rota Oluşturma',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_startPoint != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Başlangıç: Seçildi',
                    style: textTheme.bodySmall,
                  ),
                ],
              ),
            if (_endPoint != null) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Bitiş: Seçildi',
                    style: textTheme.bodySmall,
                  ),
                ],
              ),
            ],
            if (_endPoint == null && _startPoint != null) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Bitiş: Seçin',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ],
            if (_routePoints.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Rota hesaplandı',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton.icon(
                  onPressed: _clearRoute,
                  icon: Icon(Icons.clear, size: 16),
                  label: Text('Temizle'),
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.error,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _toggleRouteMode,
                  icon: Icon(Icons.close, size: 16),
                  label: Text('Kapat'),
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.onSurface.withOpacity(0.7),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _clearRoute() {
    setState(() {
      _routePoints.clear();
      _startPoint = null;
      _endPoint = null;
      _routeDistance = null;
      _routeDuration = null;
      _isNavigating = false;
      _currentRouteIndex = 0;
    });
    
    _positionStream?.cancel();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Rota temizlendi'),
        duration: Duration(seconds: 1),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildRouteSummary(BuildContext context) {
    if (_routePoints.isEmpty || _routeDistance == null || _routeDuration == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final mediaQuery = MediaQuery.of(context);
    final safeAreaBottom = mediaQuery.padding.bottom;

    final distanceKm = (_routeDistance! / 1000).toStringAsFixed(1);
    final durationMin = (_routeDuration! / 60).round();

    return Positioned(
      bottom: 16 + safeAreaBottom,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(ThemeConstants.borderRadiusMedium),
          boxShadow: [
            BoxShadow(
              color: colorScheme.onSurface.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.route,
                color: colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Rota Bilgileri',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.straighten, size: 16, color: colorScheme.onSurface.withOpacity(0.7)),
                      const SizedBox(width: 4),
                      Text(
                        '${distanceKm} km',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.access_time, size: 16, color: colorScheme.onSurface.withOpacity(0.7)),
                      const SizedBox(width: 4),
                      Text(
                        '${durationMin} dk',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!_isNavigating) ...[
              ElevatedButton.icon(
                onPressed: _startNavigation,
                icon: Icon(Icons.play_arrow, size: 18),
                label: Text('Başla'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            IconButton(
              onPressed: _clearRoute,
              icon: Icon(Icons.close, color: colorScheme.onSurface.withOpacity(0.7)),
              tooltip: 'Rota temizle',
            ),
          ],
        ),
      ),
    );
  }

  void _startNavigation() {
    if (_routePoints.isEmpty) return;

    setState(() {
      _isNavigating = true;
      _currentRouteIndex = 0;
    });

    _startLocationTracking();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigasyon başladı! Rotayı takip edin.'),
        duration: Duration(seconds: 3),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  void _stopNavigation() {
    setState(() {
      _isNavigating = false;
      _currentRouteIndex = 0;
    });

    _positionStream?.cancel();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigasyon durduruldu'),
        duration: Duration(seconds: 2),
        backgroundColor: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  void _startLocationTracking() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.medium, // Reduced for better performance
        distanceFilter: 25, // Increased to reduce frequency
        timeLimit: const Duration(seconds: 20), // Add timeout
      ),
    ).listen(
      (Position position) {
        if (!_isNavigating || _routePoints.isEmpty) return;

        final currentLocation = LatLng(position.latitude, position.longitude);
        _updateNavigationProgress(currentLocation);
      },
      onError: (error) {
        // debugPrint('Location tracking error: $error');
        // Continue navigation even if location tracking fails
      },
    );
  }

  void _updateNavigationProgress(LatLng currentLocation) {
    if (_routePoints.isEmpty) return;

    // En yakın rota noktasını bul
    double minDistance = double.infinity;
    int nearestIndex = 0;

    for (int i = _currentRouteIndex; i < _routePoints.length; i++) {
      final distance = _calculateDistance(currentLocation, _routePoints[i]);
      if (distance < minDistance) {
        minDistance = distance;
        nearestIndex = i;
      }
    }

    // Eğer kullanıcı rota üzerinde ilerliyorsa
    if (minDistance < 50) { // 50 metre tolerans
      setState(() {
        _currentRouteIndex = nearestIndex;
      });

      // Map'i kullanıcının konumuna odakla
      _mapController.move(currentLocation, 16.0);

      // Hedefe yaklaştıysa navigasyonu bitir
      if (nearestIndex >= _routePoints.length - 5) {
        _stopNavigation();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hedefe ulaştınız!'),
            duration: Duration(seconds: 3),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    }
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Meter, point1, point2);
  }

  Widget _buildNavigationUI(BuildContext context) {
    if (!_isNavigating || _routePoints.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final mediaQuery = MediaQuery.of(context);
    final safeAreaTop = mediaQuery.padding.top;

    final progress = _currentRouteIndex / _routePoints.length;
    final remainingDistance = _calculateRemainingDistance();
    final remainingTime = _calculateRemainingTime();

    return Positioned(
      top: 16 + safeAreaTop,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(ThemeConstants.borderRadiusMedium),
          boxShadow: [
            BoxShadow(
              color: colorScheme.onSurface.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.navigation,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Navigasyon Aktif',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      Text(
                        'Kalan: ${(remainingDistance / 1000).toStringAsFixed(1)} km, ${(remainingTime / 60).round()} dk',
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _stopNavigation,
                  icon: Icon(Icons.stop, color: colorScheme.error),
                  tooltip: 'Navigasyonu durdur',
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: colorScheme.onSurface.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
            const SizedBox(height: 8),
            Text(
              'İlerleme: ${(progress * 100).toStringAsFixed(0)}%',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateRemainingDistance() {
    if (_routePoints.isEmpty || _currentRouteIndex >= _routePoints.length - 1) {
      return 0;
    }

    double totalDistance = 0;
    for (int i = _currentRouteIndex; i < _routePoints.length - 1; i++) {
      totalDistance += _calculateDistance(_routePoints[i], _routePoints[i + 1]);
    }
    return totalDistance;
  }

  double _calculateRemainingTime() {
    final remainingDistance = _calculateRemainingDistance();
    if (remainingDistance == 0 || _routeDistance == null || _routeDuration == null) {
      return 0;
    }

    // Ortalama hız hesapla (km/h)
    final avgSpeed = (_routeDistance! / 1000) / (_routeDuration! / 3600);
    // Kalan süre hesapla (saniye)
    return (remainingDistance / 1000) / avgSpeed * 3600;
  }
}
