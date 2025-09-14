part of map_page;

extension MapLocationShare on _MapPageState {
  /// Konum paylaşımı dialog'unu göster
  void _showLocationShareDialog() {
    showDialog(
      context: context,
      builder: (context) => _LocationShareDialog(
        currentPosition: _currentPosition,
        selectedPosition: _selectedPosition,
        onShare: _shareLocation,
      ),
    );
  }

  /// Konum paylaş
  Future<void> _shareLocation({
    required LatLng position,
    required String message,
    required List<int> userIds,
    bool isRealTime = false,
  }) async {
    try {
      // TODO: Backend API'ye konum paylaşımı gönder
      // await _locationService.shareLocation(
      //   position: position,
      //   message: message,
      //   userIds: userIds,
      //   isRealTime: isRealTime,
      // );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Konum paylaşıldı!'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Konum paylaşılamadı: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  /// Gerçek zamanlı konum paylaşımını başlat/durdur
  void _toggleRealTimeLocationSharing() {
    setState(() {
      _isSharingLocation = !_isSharingLocation;
    });

    if (_isSharingLocation) {
      _startRealTimeLocationSharing();
    } else {
      _stopRealTimeLocationSharing();
    }
  }

  /// Gerçek zamanlı konum paylaşımını başlat
  void _startRealTimeLocationSharing() {
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_currentPosition != null) {
        _updateLocationShare(_currentPosition!);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Gerçek zamanlı konum paylaşımı başlatıldı'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  /// Gerçek zamanlı konum paylaşımını durdur
  void _stopRealTimeLocationSharing() {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Gerçek zamanlı konum paylaşımı durduruldu'),
        backgroundColor: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  /// Konum paylaşımını güncelle
  Future<void> _updateLocationShare(LatLng position) async {
    // TODO: Backend API'ye konum güncellemesi gönder
    print('Konum güncellendi: ${position.latitude}, ${position.longitude}');
  }

  /// Aktif konum paylaşımlarını yükle
  Future<void> _loadActiveLocationShares() async {
    try {
      // TODO: Backend API'den aktif konum paylaşımlarını getir
      // final shares = await _locationService.getActiveLocationShares();
      // setState(() {
      //   _activeLocationShares = shares;
      // });
    } catch (e) {
      print('Aktif konum paylaşımları yüklenemedi: $e');
    }
  }

  /// Kullanıcı gruplarını yükle
  Future<void> _loadUserGroups() async {
    try {
      // TODO: Backend API'den kullanıcı gruplarını getir
      // final groups = await ServiceLocator.group.getUserGroups();
      // setState(() {
      //   _userGroups = groups;
      // });
    } catch (e) {
      print('Kullanıcı grupları yüklenemedi: $e');
    }
  }

  /// Konum paylaşımı butonunu oluştur
  Widget _buildLocationShareButton() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Positioned(
      bottom: 100,
      right: 16,
      child: Column(
        children: [
          // Gerçek zamanlı konum paylaşımı butonu
          FloatingActionButton(
            heroTag: 'realtime_location',
            mini: true,
            backgroundColor: _isSharingLocation 
                ? colorScheme.error 
                : colorScheme.primary,
            onPressed: _toggleRealTimeLocationSharing,
            child: Icon(
              _isSharingLocation ? Icons.location_off : Icons.location_on,
              color: colorScheme.onPrimary,
            ),
          ),
          const SizedBox(height: 8),
          
          // Konum paylaşımı butonu
          FloatingActionButton(
            heroTag: 'share_location',
            mini: true,
            backgroundColor: colorScheme.secondary,
            onPressed: _showLocationShareDialog,
            child: Icon(
              Icons.share_location,
              color: colorScheme.onSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Grup üyelerinin konumlarını göster
  Widget _buildGroupMembersLocations() {
    if (!_showGroupMembers || _groupMembersLocations.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Positioned(
      top: 100,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Grup Üyeleri',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _showGroupMembers = false;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...(_groupMembersLocations.map((location) => 
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: colorScheme.primary,
                  child: Text(
                    location.userName.substring(0, 1).toUpperCase(),
                    style: TextStyle(color: colorScheme.onPrimary),
                  ),
                ),
                title: Text(location.userName),
                subtitle: Text(
                  'Son güncelleme: ${_formatTime(location.updatedAt)}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.navigation),
                  onPressed: () {
                    _mapController.move(location.position, 15.0);
                  },
                ),
              ),
            ).toList()),
          ],
        ),
      ),
    );
  }
}

/// Konum paylaşımı modeli
// LocationShare class'ı map_page.dart'da tanımlı

/// Konum paylaşımı dialog'u
class _LocationShareDialog extends StatefulWidget {
  final LatLng? currentPosition;
  final LatLng? selectedPosition;
  final Function({
    required LatLng position,
    required String message,
    required List<int> userIds,
    bool isRealTime,
  }) onShare;

  const _LocationShareDialog({
    required this.currentPosition,
    required this.selectedPosition,
    required this.onShare,
  });

  @override
  State<_LocationShareDialog> createState() => _LocationShareDialogState();
}

class _LocationShareDialogState extends State<_LocationShareDialog> {
  final TextEditingController _messageController = TextEditingController();
  final List<int> _selectedUserIds = [];
  bool _isRealTime = false;
  LatLng? _selectedPosition;

  @override
  void initState() {
    super.initState();
    _selectedPosition = widget.selectedPosition ?? widget.currentPosition;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: const Text('Konum Paylaş'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Konum seçimi
            if (widget.currentPosition != null && widget.selectedPosition != null)
              Card(
                child: ListTile(
                  title: const Text('Mevcut Konum'),
                  subtitle: Text(
                    '${widget.currentPosition!.latitude.toStringAsFixed(4)}, '
                    '${widget.currentPosition!.longitude.toStringAsFixed(4)}',
                  ),
                  leading: const Icon(Icons.my_location),
                  selected: _selectedPosition == widget.currentPosition,
                  onTap: () {
                    setState(() {
                      _selectedPosition = widget.currentPosition;
                    });
                  },
                ),
              ),
            
            if (widget.selectedPosition != null)
              Card(
                child: ListTile(
                  title: const Text('Seçilen Konum'),
                  subtitle: Text(
                    '${widget.selectedPosition!.latitude.toStringAsFixed(4)}, '
                    '${widget.selectedPosition!.longitude.toStringAsFixed(4)}',
                  ),
                  leading: const Icon(Icons.location_on),
                  selected: _selectedPosition == widget.selectedPosition,
                  onTap: () {
                    setState(() {
                      _selectedPosition = widget.selectedPosition;
                    });
                  },
                ),
              ),

            const SizedBox(height: 16),

            // Mesaj
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Mesaj (opsiyonel)',
                hintText: 'Konum hakkında not...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 16),

            // Gerçek zamanlı paylaşım
            SwitchListTile(
              title: const Text('Gerçek zamanlı paylaşım'),
              subtitle: const Text('Konumunuz otomatik olarak güncellenecek'),
              value: _isRealTime,
              onChanged: (value) {
                setState(() {
                  _isRealTime = value;
                });
              },
            ),

            const SizedBox(height: 16),

            // Kullanıcı seçimi (TODO: Backend'den kullanıcı listesi)
            const Text(
              'Paylaşılacak kullanıcılar:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Kullanıcı seçimi özelliği yakında eklenecek',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _selectedPosition != null ? _shareLocation : null,
          child: const Text('Paylaş'),
        ),
      ],
    );
  }

  void _shareLocation() {
    if (_selectedPosition == null) return;

    widget.onShare(
      position: _selectedPosition!,
      message: _messageController.text.trim(),
      userIds: _selectedUserIds,
      isRealTime: _isRealTime,
    );

    Navigator.pop(context);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
