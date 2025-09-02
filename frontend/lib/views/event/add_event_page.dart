import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:motoapp_frontend/services/event/event_service.dart';
import 'package:motoapp_frontend/services/auth/auth_service.dart';

class AddEventPage extends StatefulWidget {
  final int? groupId;

  const AddEventPage({super.key, this.groupId});

  @override
  State<AddEventPage> createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locCtrl = TextEditingController();
  final _guestLimitCtrl = TextEditingController();
  DateTime? _start;
  TimeOfDay? _time;
  bool _submitting = false;
  bool _isPublic = true;
  bool _noGuestLimit = true;
  File? _coverImageFile;

  late EventService _service;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authService = Provider.of<AuthService>(context, listen: false);
    _service = EventService(authService: authService);
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) setState(() => _start = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) setState(() => _time = time);
  }

  Future<void> _pickCoverImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _coverImageFile = File(pickedFile.path));
    }
  }

  String _formatDate(DateTime? date) =>
      date == null ? 'Select date' : '${date.day}/${date.month}/${date.year}';

  String _formatTime(TimeOfDay? time) => time == null
      ? 'Select time'
      : '${time.hour}:${time.minute.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_start == null || _time == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Date and time are required')));
      return;
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
        guestLimit: _noGuestLimit ? null : int.tryParse(_guestLimitCtrl.text),
        // coverImageFile: ...  <-- bunu kaldır
        coverImageUrl: null, // veya kullanıcıdan aldığın URL
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
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
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Event Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Event name is required'
                    : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Date',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: _pickDate,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.grey[50],
                            side: BorderSide(color: Colors.grey[300]!),
                            minimumSize: const Size(double.infinity, 48),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_formatDate(_start)),
                              const Icon(Icons.calendar_today, size: 20)
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Time',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: _pickTime,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.grey[50],
                            side: BorderSide(color: Colors.grey[300]!),
                            minimumSize: const Size(double.infinity, 48),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_formatTime(_time)),
                              const Icon(Icons.access_time, size: 20)
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locCtrl,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Cover Image',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickCoverImage,
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[50],
                        image: _coverImageFile != null
                            ? DecorationImage(
                                image: FileImage(_coverImageFile!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _coverImageFile == null
                          ? const Center(
                              child: Icon(Icons.cloud_upload,
                                  size: 40, color: Colors.grey))
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Privacy',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Radio(
                          value: true,
                          groupValue: _isPublic,
                          onChanged: (v) => setState(() => _isPublic = v!)),
                      const Text('Public'),
                      const SizedBox(width: 16),
                      Radio(
                          value: false,
                          groupValue: _isPublic,
                          onChanged: (v) => setState(() => _isPublic = v!)),
                      const Text('Private'),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 48),
                    child: Text(
                      _isPublic
                          ? 'Anyone can see the event'
                          : 'Only invited guests can see the event',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Guest Limit',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Checkbox(
                          value: _noGuestLimit,
                          onChanged: (v) => setState(() => _noGuestLimit = v!)),
                      const Text('No Limit'),
                    ],
                  ),
                  if (!_noGuestLimit)
                    TextFormField(
                      controller: _guestLimitCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter guest limit',
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: _submitting
                    ? const CircularProgressIndicator(color: Colors.white)
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
