import 'package:flutter/material.dart';
import 'package:motoapp_frontend/core/theme/theme_constants.dart';
import '../../services/rides/rides_service.dart';
import '../map/pages/map_page_new.dart';
import 'package:latlong2/latlong.dart';

/// Yolculuk oluşturma sayfası
class CreateRidePage extends StatefulWidget {
  const CreateRidePage({super.key});

  @override
  State<CreateRidePage> createState() => _CreateRidePageState();
}

class _CreateRidePageState extends State<CreateRidePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _startLocationController = TextEditingController();
  final _endLocationController = TextEditingController();
  final _maxParticipantsController = TextEditingController();
  
  final RidesService _ridesService = RidesService();
  
  String _rideType = 'casual';
  String _privacyLevel = 'public';
  DateTime _startTime = DateTime.now().add(const Duration(hours: 1));
  LatLng? _startCoordinates;
  LatLng? _endCoordinates;
  String? _routePolyline;
  List<dynamic> _waypoints = [];
  double? _distanceKm;
  int? _estimatedDurationMinutes;
  
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _startLocationController.dispose();
    _endLocationController.dispose();
    _maxParticipantsController.dispose();
    super.dispose();
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
          'Yeni Yolculuk',
          style: textTheme.headlineSmall?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createRide,
            child: Text(
              'Oluştur',
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBasicInfoSection(),
                    const SizedBox(height: 24),
                    _buildRouteSection(),
                    const SizedBox(height: 24),
                    _buildSettingsSection(),
                    const SizedBox(height: 24),
                    _buildDateTimeSection(),
                    const SizedBox(height: 32),
                    _buildCreateButton(),
                  ],
                ),
              ),
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
            'Yolculuk oluşturuluyor...',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Temel Bilgiler',
          style: textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        
        // Title
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            labelText: 'Yolculuk Başlığı',
            hintText: 'Örn: İstanbul - Ankara Turu',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ThemeConstants.borderRadiusMedium),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Başlık gerekli';
            }
            return null;
          },
        ),
        
        const SizedBox(height: 16),
        
        // Description
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
            labelText: 'Açıklama',
            hintText: 'Yolculuk hakkında detaylar...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ThemeConstants.borderRadiusMedium),
            ),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildRouteSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rota',
          style: textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        
        // Start Location
        TextFormField(
          controller: _startLocationController,
          decoration: InputDecoration(
            labelText: 'Başlangıç Noktası',
            hintText: 'Başlangıç konumu',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ThemeConstants.borderRadiusMedium),
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.map),
              onPressed: () => _selectLocation(true),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Başlangıç noktası gerekli';
            }
            return null;
          },
        ),
        
        const SizedBox(height: 16),
        
        // End Location
        TextFormField(
          controller: _endLocationController,
          decoration: InputDecoration(
            labelText: 'Bitiş Noktası',
            hintText: 'Bitiş konumu',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ThemeConstants.borderRadiusMedium),
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.map),
              onPressed: () => _selectLocation(false),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Bitiş noktası gerekli';
            }
            return null;
          },
        ),
        
        const SizedBox(height: 16),
        
        // Route Info
        if (_distanceKm != null || _estimatedDurationMinutes != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(ThemeConstants.borderRadiusMedium),
            ),
            child: Row(
              children: [
                if (_distanceKm != null) ...[
                  Icon(Icons.straighten, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text('${_distanceKm!.toStringAsFixed(1)} km'),
                  const SizedBox(width: 16),
                ],
                if (_estimatedDurationMinutes != null) ...[
                  Icon(Icons.access_time, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text('${_estimatedDurationMinutes} dakika'),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSettingsSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ayarlar',
          style: textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        
        // Ride Type
        DropdownButtonFormField<String>(
          value: _rideType,
          decoration: InputDecoration(
            labelText: 'Yolculuk Türü',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ThemeConstants.borderRadiusMedium),
            ),
          ),
          items: const [
            DropdownMenuItem(value: 'casual', child: Text('Günlük Sürüş')),
            DropdownMenuItem(value: 'touring', child: Text('Tur Sürüşü')),
            DropdownMenuItem(value: 'group', child: Text('Grup Sürüşü')),
            DropdownMenuItem(value: 'track', child: Text('Pist Sürüşü')),
            DropdownMenuItem(value: 'adventure', child: Text('Macera Sürüşü')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => _rideType = value);
            }
          },
        ),
        
        const SizedBox(height: 16),
        
        // Privacy Level
        DropdownButtonFormField<String>(
          value: _privacyLevel,
          decoration: InputDecoration(
            labelText: 'Gizlilik Seviyesi',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ThemeConstants.borderRadiusMedium),
            ),
          ),
          items: const [
            DropdownMenuItem(value: 'public', child: Text('Herkese Açık')),
            DropdownMenuItem(value: 'friends', child: Text('Sadece Arkadaşlar')),
            DropdownMenuItem(value: 'private', child: Text('Özel')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => _privacyLevel = value);
            }
          },
        ),
        
        const SizedBox(height: 16),
        
        // Max Participants
        TextFormField(
          controller: _maxParticipantsController,
          decoration: InputDecoration(
            labelText: 'Maksimum Katılımcı Sayısı',
            hintText: 'Boş bırakırsanız sınırsız',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ThemeConstants.borderRadiusMedium),
            ),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              final num = int.tryParse(value);
              if (num == null || num < 1) {
                return 'Geçerli bir sayı girin';
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDateTimeSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Zaman',
          style: textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        
        InkWell(
          onTap: _selectDateTime,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outline),
              borderRadius: BorderRadius.circular(ThemeConstants.borderRadiusMedium),
            ),
            child: Row(
              children: [
                Icon(Icons.schedule, color: colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Başlangıç Zamanı',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '${_startTime.day}/${_startTime.month}/${_startTime.year} ${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
                        style: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateButton() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _createRide,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ThemeConstants.borderRadiusLarge),
          ),
          elevation: 0,
        ),
        child: Text(
          'Yolculuk Oluştur',
          style: textTheme.labelLarge?.copyWith(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _selectLocation(bool isStart) async {
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (context) => MapPageNew(
          allowSelection: true,
          showMarker: true,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        if (isStart) {
          _startCoordinates = result;
          _startLocationController.text = '${result.latitude.toStringAsFixed(4)}, ${result.longitude.toStringAsFixed(4)}';
        } else {
          _endCoordinates = result;
          _endLocationController.text = '${result.latitude.toStringAsFixed(4)}, ${result.longitude.toStringAsFixed(4)}';
        }
      });
    }
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_startTime),
      );

      if (time != null) {
        setState(() {
          _startTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _createRide() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final request = CreateRideRequest(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        startLocation: _startLocationController.text.trim(),
        endLocation: _endLocationController.text.trim(),
        startCoordinates: _startCoordinates != null 
            ? [_startCoordinates!.latitude, _startCoordinates!.longitude]
            : null,
        endCoordinates: _endCoordinates != null 
            ? [_endCoordinates!.latitude, _endCoordinates!.longitude]
            : null,
        startTime: _startTime,
        maxParticipants: _maxParticipantsController.text.isNotEmpty 
            ? int.tryParse(_maxParticipantsController.text)
            : null,
        rideType: _rideType,
        privacyLevel: _privacyLevel,
        distanceKm: _distanceKm,
        estimatedDurationMinutes: _estimatedDurationMinutes,
        routePolyline: _routePolyline,
        waypoints: _waypoints,
      );

      await _ridesService.createRide(request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Yolculuk başarıyla oluşturuldu!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        Navigator.pop(context, true);
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
