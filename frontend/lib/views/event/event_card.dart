import 'package:flutter/material.dart';
import 'event_helpers.dart';
import '../../core/theme/color_schemes.dart';

class EventCard extends StatelessWidget {
  final Map<String, dynamic> event;
  final String currentUsername;
  final Future<void> Function(int) onJoin;
  final Future<void> Function(int) onLeave;

  const EventCard({
    super.key,
    required this.event,
    required this.currentUsername,
    required this.onJoin,
    required this.onLeave,
  });

  @override
  Widget build(BuildContext context) {
    final isJoined = event['is_joined'] as bool? ?? false;
    final participantCount = event['participants_count'] ?? 0;
    final guestLimit = event['guest_limit'] ?? '-';
    final organizerUsername = (event['organizer'] as Map?)?['username'] ?? '';
    final canJoin = !isJoined &&
        organizerUsername != currentUsername &&
        (guestLimit == '-' || participantCount < guestLimit);

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Chip(
                  label: Text(
                    event['is_public'] == true ? 'Public' : 'Private',
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor:
                      event['is_public'] == true ? Colors.green : Colors.red,
                ),
                const Spacer(),
                if (isJoined || canJoin)
                  TextButton(
                    onPressed: isJoined
                        ? () => onLeave(event['id'])
                        : () => onJoin(event['id']),
                    child: Text(isJoined ? 'Leave' : 'Join'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              event['title']?.toString() ?? 'Başlıksız Etkinlik',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if ((event['description']?.toString() ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(event['description'].toString(),
                    style: const TextStyle(fontSize: 14)),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(formatDate(event['start_time']),
                    style: const TextStyle(fontSize: 14, color: Colors.grey)),
              ],
            ),
            if ((event['location']?.toString() ?? '').isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(event['location'].toString(),
                      style: const TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
            const SizedBox(height: 12),
            Text('Katılımcılar: $participantCount / $guestLimit',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
