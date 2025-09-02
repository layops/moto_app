import 'package:flutter/material.dart';

class EventDateTimePicker extends StatelessWidget {
  final DateTime? start;
  final TimeOfDay? time;
  final void Function(DateTime) onPickDate;
  final void Function(TimeOfDay) onPickTime;

  const EventDateTimePicker({
    super.key,
    required this.start,
    required this.time,
    required this.onPickDate,
    required this.onPickTime,
  });

  String _formatDate(DateTime? date) =>
      date == null ? 'Select date' : '${date.day}/${date.month}/${date.year}';

  String _formatTime(TimeOfDay? time) => time == null
      ? 'Select time'
      : '${time.hour}:${time.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Date', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) onPickDate(date);
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.grey[50],
                  side: BorderSide(color: Colors.grey[300]!),
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatDate(start)),
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
              const Text('Time', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () async {
                  final pickedTime = await showTimePicker(
                      context: context, initialTime: TimeOfDay.now());
                  if (pickedTime != null) onPickTime(pickedTime);
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.grey[50],
                  side: BorderSide(color: Colors.grey[300]!),
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatTime(time)),
                    const Icon(Icons.access_time, size: 20)
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
