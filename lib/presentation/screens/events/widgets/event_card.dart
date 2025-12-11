import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vnote/core/constants/app_colors.dart';
import 'package:vnote/core/constants/app_typography.dart';
import 'package:vnote/domain/entities/event.dart';

class EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;

  const EventCard({super.key, required this.event, required this.onTap});

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final tomorrow = today.add(const Duration(days: 1));

    if (eventDate.isAtSameMomentAs(today)) {
      return 'Today, ${DateFormat('MMM d').format(dateTime)} at ${DateFormat('h:mm a').format(dateTime)}';
    } else if (eventDate.isAtSameMomentAs(tomorrow)) {
      return 'Tomorrow, ${DateFormat('MMM d').format(dateTime)} at ${DateFormat('h:mm a').format(dateTime)}';
    } else {
      return '${DateFormat('MMM d, y').format(dateTime)} at ${DateFormat('h:mm a').format(dateTime)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: event.color, width: 2),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title,
                style: AppTypography.h4.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: AppColors.gray),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _formatDateTime(event.dateTime),
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.gray,
                      ),
                    ),
                  ),
                ],
              ),
              if (event.location != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: AppColors.gray),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event.location!,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.gray,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (event.attendeesCount != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.people, size: 16, color: AppColors.gray),
                    const SizedBox(width: 4),
                    Text(
                      '${event.attendeesCount} ${event.attendeesCount == 1 ? 'attendee' : 'attendees'}',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.gray,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
