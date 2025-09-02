import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:motoapp_frontend/services/event/event_service.dart';
import 'package:motoapp_frontend/services/auth/auth_service.dart';
import '../../widgets/events/event_privacy_guest.dart';
import '../../widgets/events/event_form_fields.dart';
import '../../widgets/events/event_date_time_picker.dart';
import '../../widgets/events/event_cover_image_picker.dart';

class AddEventPage extends StatefulWidget {
  final int? groupId;
  const AddEventPage({super.key, this.groupId});

  @override
  State<AddEventPage> createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  final _formKey = GlobalKey<FormState>();
  late EventService _service;

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locCtrl = TextEditingController();
  final _guestLimitCtrl = TextEditingController();

  DateTime? _start;
  TimeOfDay? _time;
  bool _isPublic = true;
  bool _noGuestLimit = true;
  File? _coverImageFile;
  bool _submitting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authService = Provider.of<AuthService>(context, listen: false);
    _service = EventService(authService: authService);
  }

  Future<String> uploadImageAndGetUrl(File file) async {
    // TODO: Burada resmi Supabase veya başka bir sunucuya yükle
    // ve URL döndür. Örnek placeholder:
    final uploadedUrl =
        'https://your-storage.com/path/to/${file.path.split('/').last}';
    return uploadedUrl;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    if (_start == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a start date')),
      );
      return;
    }

    if (_time == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a start time')),
      );
      return;
    }

    int? guestLimit;
    if (!_noGuestLimit) {
      guestLimit = int.tryParse(_guestLimitCtrl.text);
      if (guestLimit == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Guest limit must be a number')),
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
        location: _locCtrl.text.trim(),
        startTime: eventDateTime,
        endTime: null,
        isPublic: _isPublic,
        guestLimit: _noGuestLimit ? null : guestLimit,
        coverImageUrl: _coverImageFile != null
            ? await uploadImageAndGetUrl(_coverImageFile!)
            : null,
      );

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
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
                locCtrl: _locCtrl,
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
                onPick: (file) => setState(() => _coverImageFile = file),
              ),
              const SizedBox(height: 16),
              EventPrivacyGuest(
                isPublic: _isPublic,
                noGuestLimit: _noGuestLimit,
                guestLimitCtrl: _guestLimitCtrl,
                onPrivacyChanged: (val) => setState(() => _isPublic = val),
                onGuestLimitChanged: (val) =>
                    setState(() => _noGuestLimit = val),
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
