import 'package:flutter/material.dart';

class EventFormFields extends StatelessWidget {
  final TextEditingController titleCtrl;
  final TextEditingController descCtrl;
  final TextEditingController? locCtrl;
  final String? Function(String?)? titleValidator;
  final String? Function(String?)? descValidator;
  final String? Function(String?)? locValidator;
  final bool locationReadOnly;
  final VoidCallback? onTapLocation;
  final VoidCallback? onClearLocation;
  final bool showLocationField;

  const EventFormFields({
    super.key,
    required this.titleCtrl,
    required this.descCtrl,
    this.locCtrl,
    this.titleValidator,
    this.descValidator,
    this.locValidator,
    this.locationReadOnly = false,
    this.onTapLocation,
    this.onClearLocation,
    this.showLocationField = true,
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
        if (showLocationField) ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: locCtrl,
            readOnly: locationReadOnly,
            onTap: locationReadOnly ? onTapLocation : null,
            decoration: InputDecoration(
              labelText: 'Location',
              border: const OutlineInputBorder(),
              suffixIcon: locationReadOnly
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Haritadan seç',
                          icon: const Icon(Icons.map_outlined),
                          onPressed: onTapLocation,
                        ),
                        IconButton(
                          tooltip: 'Temizle',
                          icon: const Icon(Icons.clear),
                          onPressed: onClearLocation,
                        ),
                      ],
                    )
                  : null,
            ),
            validator: locValidator ??
                (v) => v == null || v.trim().isEmpty
                    ? 'Location is required'
                    : null,
          ),
        ],
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
