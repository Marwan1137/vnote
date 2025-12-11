import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:vnote/core/constants/app_colors.dart';
import 'package:vnote/core/constants/app_typography.dart';
import 'package:vnote/core/utils/page_transitions.dart';
import 'package:vnote/domain/entities/event.dart';
import 'package:vnote/presentation/cubit/events/events_cubit.dart';
import 'package:vnote/presentation/cubit/events/events_state.dart';
import 'package:vnote/presentation/screens/events/add_event_screen.dart';
import 'package:vnote/presentation/widgets/app_bar_actions.dart';

class EventDetailScreen extends StatelessWidget {
  final Event event;

  const EventDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EventsCubit, EventsState>(
      builder: (context, state) {
        // Get the updated event from state if available
        Event currentEvent = event;
        if (state is EventsLoaded) {
          final updatedEvent = state.events.firstWhere(
            (e) => e.id == event.id,
            orElse: () => event,
          );
          currentEvent = updatedEvent;
        }

        return SafeArea(
          top: false,
          bottom: false,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Event Details'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    final cubit = context.read<EventsCubit>();
                    Navigator.push(
                      context,
                      SlidePageRoute(
                        page: BlocProvider.value(
                          value: cubit,
                          child: AddEventScreen(event: currentEvent),
                        ),
                      ),
                    ).then((result) {
                      if (result == true && context.mounted) {
                        // Reload events to get updated data
                        cubit.loadEvents();
                      }
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _showDeleteDialog(context, currentEvent),
                ),
                const AppBarActions(),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentEvent.title,
                    style: AppTypography.h3.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildDetailRow(
                    context,
                    Icons.access_time,
                    'Date & Time',
                    '${DateFormat('MMM d, y').format(currentEvent.dateTime)} at ${DateFormat('h:mm a').format(currentEvent.dateTime)}',
                  ),
                  if (currentEvent.location != null)
                    _buildDetailRow(
                      context,
                      Icons.location_on,
                      'Location',
                      currentEvent.location!,
                    ),
                  if (currentEvent.attendeesCount != null)
                    _buildDetailRow(
                      context,
                      Icons.people,
                      'Attendees',
                      '${currentEvent.attendeesCount} ${currentEvent.attendeesCount == 1 ? 'attendee' : 'attendees'}',
                    ),
                  _buildDetailRow(
                    context,
                    Icons.info_outline,
                    'Status',
                    currentEvent.status == EventStatus.upcoming
                        ? 'Upcoming'
                        : currentEvent.status == EventStatus.completed
                        ? 'Completed'
                        : 'Cancelled',
                  ),
                  if (currentEvent.isRecurring)
                    _buildDetailRow(
                      context,
                      Icons.repeat,
                      'Recurring',
                      currentEvent.recurringFrequency ?? 'Recurring',
                    ),
                  if (currentEvent.description != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Description',
                      style: AppTypography.h5.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentEvent.description!,
                      style: AppTypography.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: 32),
                  if (currentEvent.status == EventStatus.upcoming)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _markCompleted(context, currentEvent),
                            icon: const Icon(Icons.check),
                            label: const Text('Mark as Completed'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _markCancelled(context, currentEvent),
                            icon: const Icon(Icons.cancel),
                            label: const Text('Mark as Cancelled'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.gray),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.gray,
                  ),
                ),
                const SizedBox(height: 4),
                Text(value, style: AppTypography.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _markCompleted(BuildContext context, Event currentEvent) {
    final cubit = context.read<EventsCubit>();
    cubit.markCompleted(currentEvent.id);
    Navigator.pop(context);
  }

  void _markCancelled(BuildContext context, Event currentEvent) {
    final cubit = context.read<EventsCubit>();
    cubit.markCancelled(currentEvent.id);
    Navigator.pop(context);
  }

  void _showDeleteDialog(BuildContext context, Event currentEvent) {
    // Capture cubit reference before showing dialog
    final cubit = context.read<EventsCubit>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this event?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              cubit.deleteEvent(currentEvent.id);
              Navigator.pop(dialogContext); // Close dialog
              Navigator.pop(context); // Close detail screen
            },
            child: Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
