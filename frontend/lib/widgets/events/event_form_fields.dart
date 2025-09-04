import 'package:flutter/material.dart';

class EventFormFields extends StatelessWidget {
  final TextEditingController titleCtrl;
  final TextEditingController descCtrl;
  final TextEditingController locCtrl;
  final String? Function(String?)? titleValidator;
  final String? Function(String?)? descValidator;
  final String? Function(String?)? locValidator;

  const EventFormFields({
    super.key,
    required this.titleCtrl,
    required this.descCtrl,
    required this.locCtrl,
    this.titleValidator,
    this.descValidator,
    this.locValidator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: titleCtrl,
          decoration: const InputDecoration(
            labelText: 'Event Name',
            border: OutlineInputBorder(),
          ),
          validator: titleValidator ??
              (v) => v == null || v.trim().isEmpty
                  ? 'Event name is required'
                  : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: locCtrl,
          decoration: const InputDecoration(
            labelText: 'Location',
            border: OutlineInputBorder(),
          ),
          validator: locValidator ??
              (v) =>
                  v == null || v.trim().isEmpty ? 'Location is required' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: descCtrl,
          decoration: const InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          maxLines: 3,
          validator: descValidator ??
              (v) => v == null || v.trim().isEmpty
                  ? 'Description is required'
                  : null,
        ),
      ],
    );
  }
}
