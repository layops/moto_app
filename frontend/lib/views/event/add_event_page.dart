import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:motoapp_frontend/services/event/event_service.dart';
import 'package:motoapp_frontend/services/auth/auth_service.dart';

class AddEventPage extends StatefulWidget {
  final int groupId;

  const AddEventPage({super.key, required this.groupId});

  @override
  State<AddEventPage> createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locCtrl = TextEditingController();
  DateTime? _start;
  DateTime? _end;
  bool _submitting = false;

  late EventService _service;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authService = Provider.of<AuthService>(context, listen: false);
    _service = EventService(authService: authService);
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 12, minute: 0),
    );
    if (time == null) return;

    final dt =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isStart)
        _start = dt;
      else
        _end = dt;
    });
  }

  String _displayDate(DateTime? dt) {
    if (dt == null) return 'Seçilmedi';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_start == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Başlangıç zamanı gerekli.')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      await _service.createEvent(
        groupId: widget.groupId,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        location: _locCtrl.text.trim(),
        startTime: _start!,
        endTime: _end,
      );

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: ${e.toString()}')),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yeni Etkinlik Oluştur')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration:
                    const InputDecoration(labelText: 'Etkinlik Başlığı'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Başlık gerekli' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Açıklama'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locCtrl,
                decoration:
                    const InputDecoration(labelText: 'Konum (opsiyonel)'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: Text('Başlangıç: ${_displayDate(_start)}')),
                  TextButton(
                      onPressed: () => _pickDateTime(isStart: true),
                      child: const Text('Seç')),
                ],
              ),
              Row(
                children: [
                  Expanded(child: Text('Bitiş: ${_displayDate(_end)}')),
                  TextButton(
                      onPressed: () => _pickDateTime(isStart: false),
                      child: const Text('Seç')),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const CircularProgressIndicator()
                    : const Text('Oluştur'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
