import 'package:flutter/material.dart';

class EventPrivacyGuest extends StatelessWidget {
  final bool isPublic;
  final bool noGuestLimit;
  final TextEditingController guestLimitCtrl;
  final void Function(bool) onPrivacyChanged;
  final void Function(bool) onGuestLimitChanged;

  const EventPrivacyGuest({
    super.key,
    required this.isPublic,
    required this.noGuestLimit,
    required this.guestLimitCtrl,
    required this.onPrivacyChanged,
    required this.onGuestLimitChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Privacy', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Radio(
                value: true,
                groupValue: isPublic,
                onChanged: (v) => onPrivacyChanged(v!)),
            const Text('Public'),
            const SizedBox(width: 16),
            Radio(
                value: false,
                groupValue: isPublic,
                onChanged: (v) => onPrivacyChanged(v!)),
            const Text('Private'),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 48),
          child: Text(
            isPublic
                ? 'Anyone can see the event'
                : 'Only invited guests can see the event',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Guest Limit',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Checkbox(
                value: noGuestLimit, onChanged: (v) => onGuestLimitChanged(v!)),
            const Text('No Limit'),
          ],
        ),
        if (!noGuestLimit)
          TextFormField(
            controller: guestLimitCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Enter guest limit',
            ),
            validator: (v) {
              if (!noGuestLimit) {
                if (v == null || v.trim().isEmpty) {
                  return 'Guest limit is required';
                }
                if (int.tryParse(v.trim()) == null) {
                  return 'Guest limit must be a number';
                }
              }
              return null;
            },
          ),
      ],
    );
  }
}
