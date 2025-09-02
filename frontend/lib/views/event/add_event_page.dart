import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  List<String> _selectedGroups = [];

  late EventService _service;

  final List<Map<String, String>> _groups = [
    {'id': '1', 'name': 'The Renegades', 'description': 'Motorcycle Crew'},
    {'id': '2', 'name': 'The Iron Riders', 'description': 'Road Warriors'},
    {'id': '3', 'name': 'The Asphalt Angels', 'description': 'Speed Benners'},
  ];

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
    if (date != null) {
      setState(() => _start = date);
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      setState(() => _time = time);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select date';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return 'Select time';
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _toggleGroupSelection(String groupId) {
    setState(() {
      if (_selectedGroups.contains(groupId)) {
        _selectedGroups.remove(groupId);
      } else {
        _selectedGroups.add(groupId);
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_start == null || _time == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Date and time are required')),
      );
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
                              const Icon(Icons.calendar_today, size: 20),
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
                              const Icon(Icons.access_time, size: 20),
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
                  const Text('Upload Cover Image',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.grey[50],
                      side: BorderSide(color: Colors.grey[300]!),
                      minimumSize: const Size(double.infinity, 100),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.cloud_upload, size: 32, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Tap to upload image',
                            style: TextStyle(color: Colors.grey)),
                      ],
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
                        onChanged: (value) =>
                            setState(() => _isPublic = value!),
                      ),
                      const Text('Public'),
                      const SizedBox(width: 16),
                      Radio(
                        value: false,
                        groupValue: _isPublic,
                        onChanged: (value) =>
                            setState(() => _isPublic = value!),
                      ),
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
                        onChanged: (value) =>
                            setState(() => _noGuestLimit = value!),
                      ),
                      const Text('No Limit'),
                    ],
                  ),
                  if (!_noGuestLimit) ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _guestLimitCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter guest limit',
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Invite Friends/Groups',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextFormField(
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      hintText: 'Search friends or groups',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () {},
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._groups.map((group) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.grey,
                          child: Icon(Icons.group, color: Colors.white),
                        ),
                        title: Text(group['name']!),
                        subtitle: Text(group['description']!),
                        trailing: Checkbox(
                          value: _selectedGroups.contains(group['id']),
                          onChanged: (_) => _toggleGroupSelection(group['id']!),
                        ),
                        onTap: () => _toggleGroupSelection(group['id']!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: _selectedGroups.contains(group['id'])
                                ? Theme.of(context).primaryColor
                                : Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
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
                    borderRadius: BorderRadius.circular(8),
                  ),
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
