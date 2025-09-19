import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:motoapp_frontend/services/service_locator.dart';
import 'package:motoapp_frontend/services/event/event_service.dart';
import '../../widgets/events/event_privacy_guest.dart';
import '../../widgets/events/event_form_fields.dart';
import '../../widgets/events/event_date_time_picker.dart';
import '../../widgets/events/event_cover_image_picker.dart';
import '../map/map_page.dart'; // Harita sayfasını import ettik

class AddEventPage extends StatefulWidget {
  final int? groupId;
  const AddEventPage({super.key, this.groupId});

  @override
  State<AddEventPage> createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  final _formKey = GlobalKey<FormState>();
  late final EventService _service;

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locCtrl = TextEditingController();
  final _guestLimitCtrl = TextEditingController();

  DateTime? _start;
  TimeOfDay? _time;
  bool _isPublic = true;
  bool _noGuestLimit = true;
  bool _requiresApproval = false;
  File? _coverImageFile;
  bool _submitting = false;
  LatLng? _selectedLatLng; // Seçilen konum
  String? _selectedAddress; // Kullanıcıya gösterilecek adres adı

  @override
  void initState() {
    super.initState();
    _service = ServiceLocator.event;
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MapPage(allowSelection: true),
      ),
    );
    if (result != null && result is LatLng) {
      setState(() {
        _selectedLatLng = result;
        _selectedAddress = null;
      });
      await _reverseGeocode(result);
    }
  }

  Future<void> _reverseGeocode(LatLng position) async {
    final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=${position.latitude}&lon=${position.longitude}&format=json');
    try {
      final response = await http.get(uri, headers: {
        'User-Agent': 'motoapp-front/1.0 (reverse-geocode)'
      });
      if (!mounted) return;
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final String displayName = data['display_name']?.toString() ?? 'Seçilen konum';
        setState(() {
          _selectedAddress = displayName;
        });
      } else {
        setState(() {
          _selectedAddress = 'Seçilen konum';
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _selectedAddress = 'Seçilen konum';
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      ServiceLocator.messenger.showSnackBar(
        const SnackBar(content: Text('Lütfen gerekli alanları doldurun')),
      );
      return;
    }

    if (_start == null) {
      ServiceLocator.messenger.showSnackBar(
        const SnackBar(content: Text('Lütfen başlangıç tarihi seçin')),
      );
      return;
    }

    if (_time == null) {
      ServiceLocator.messenger.showSnackBar(
        const SnackBar(content: Text('Lütfen başlangıç saati seçin')),
      );
      return;
    }

    if (_selectedLatLng == null) {
      ServiceLocator.messenger.showSnackBar(
        const SnackBar(content: Text('Lütfen konumu haritadan seçin')),
      );
      return;
    }

    int? guestLimit;
    if (!_noGuestLimit) {
      guestLimit = int.tryParse(_guestLimitCtrl.text);
      if (guestLimit == null) {
        ServiceLocator.messenger.showSnackBar(
          const SnackBar(content: Text('Konuk sınırı bir sayı olmalıdır')),
        );
        return;
      }
    }

    final eventDateTime = DateTime(
      _start!.year,
      _start!.month,
      _start!.day,
      _time!.hour,
      _time!.minute,
    );

    setState(() => _submitting = true);
    try {
      await _service.createEvent(
        groupId: widget.groupId,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        location: "${_selectedLatLng!.latitude}, ${_selectedLatLng!.longitude}",
        startTime: eventDateTime,
        endTime: null,
        isPublic: _isPublic,
        guestLimit: _noGuestLimit ? null : guestLimit,
        requiresApproval: _requiresApproval,
        coverImageFile: _coverImageFile,
      );

      if (mounted) {
        ServiceLocator.messenger.showSnackBar(
          SnackBar(
            content: const Text('Etkinlik başarıyla oluşturuldu!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        ServiceLocator.navigator.pop(true);
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        if (errorMessage.contains('Failed to create event:')) {
          errorMessage =
              errorMessage.replaceFirst('Failed to create event:', '');
        }

        ServiceLocator.messenger.showSnackBar(
          SnackBar(
            content: Text('Hata: $errorMessage'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locCtrl.dispose();
    _guestLimitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Event'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              EventFormFields(
                titleCtrl: _titleCtrl,
                descCtrl: _descCtrl,
                showLocationField: false,
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.place, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Etkinlik Konumu',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on_outlined,
                                color: Colors.redAccent),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _selectedAddress ??
                                    'Konum seçilmedi. Haritadan seçin.',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickLocation,
                              icon: const Icon(Icons.map_outlined),
                              label: const Text('Haritadan Seç'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _selectedLatLng == null
                                  ? null
                                  : () {
                                      setState(() {
                                        _selectedLatLng = null;
                                        _selectedAddress = null;
                                        _locCtrl.text = '';
                                      });
                                    },
                              icon: const Icon(Icons.clear),
                              label: const Text('Temizle'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              EventDateTimePicker(
                start: _start,
                time: _time,
                onPickDate: (date) => setState(() => _start = date),
                onPickTime: (time) => setState(() => _time = time),
              ),
              const SizedBox(height: 16),
              EventCoverImagePicker(
                coverImageFile: _coverImageFile,
                onPick: (file) => setState(() {
                  _coverImageFile = file;
                }),
              ),
              const SizedBox(height: 16),
              EventPrivacyGuest(
                isPublic: _isPublic,
                noGuestLimit: _noGuestLimit,
                requiresApproval: _requiresApproval,
                guestLimitCtrl: _guestLimitCtrl,
                onPrivacyChanged: (val) => setState(() => _isPublic = val),
                onGuestLimitChanged: (val) =>
                    setState(() => _noGuestLimit = val),
                onApprovalChanged: (val) => setState(() => _requiresApproval = val),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Create Event',
                        style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
