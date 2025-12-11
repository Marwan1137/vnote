// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:vnote/core/constants/app_colors.dart';
import 'package:vnote/core/constants/app_typography.dart';
import 'package:vnote/core/di/di.dart';
import 'package:vnote/domain/entities/event.dart' as event_entity;
import 'package:vnote/presentation/cubit/events/events_cubit.dart';
import 'package:vnote/presentation/cubit/events/events_state.dart';
import 'package:vnote/presentation/cubit/recording/recording_cubit.dart';
import 'package:vnote/presentation/screens/events/event_detail_screen.dart';
import 'package:vnote/presentation/screens/events/widgets/event_card.dart';
import 'package:vnote/presentation/screens/events/widgets/events_calendar.dart';
import 'package:vnote/presentation/screens/events/widgets/filter_tabs.dart';
import 'package:vnote/presentation/screens/recording/recording_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  bool _hasLoaded = false;
  bool _justCreatedEvents = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoaded) {
      _hasLoaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<EventsCubit>().loadEvents();
        }
      });
    }
  }

  void _onFilterChanged(EventFilter filter) {
    context.read<EventsCubit>().applyFilter(filter);
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
      context.read<EventsCubit>().loadEventsByDate(selectedDay);
    }
  }

  void _onPageChanged(DateTime focusedDay) {
    setState(() {
      _focusedDay = focusedDay;
    });
    context.read<EventsCubit>().loadEventsByMonth(
      focusedDay.year,
      focusedDay.month,
    );
  }

  void _onStartVoiceRecording() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => getIt<RecordingCubit>(),
          child: const RecordingScreen(mode: RecordingMode.event),
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    if (result != null && result is String) {
      final cubit = context.read<EventsCubit>();

      // Mark that we just created events to prevent automatic reload
      _justCreatedEvents = true;

      await cubit.processTranscription(result);

      // Reset flag immediately after state is updated
      if (mounted) {
        _justCreatedEvents = false;
      }
    }
  }

  int _getUpcomingEventsCount(List<event_entity.Event> events) {
    final now = DateTime.now();
    return events
        .where(
          (e) =>
              e.status == event_entity.EventStatus.upcoming &&
              e.dateTime.isAfter(now),
        )
        .length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Events',
              style: AppTypography.h3.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: AppTypography.bold,
              ),
            ),
            BlocBuilder<EventsCubit, EventsState>(
              builder: (context, state) {
                if (state is EventsLoaded) {
                  final count = _getUpcomingEventsCount(state.events);
                  return Text(
                    '$count upcoming ${count == 1 ? 'event' : 'events'}',
                    style: AppTypography.bodySmall.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
      body: BlocConsumer<EventsCubit, EventsState>(
        listener: (context, state) {
          if (state is EventsLoaded) {
            if (_justCreatedEvents && state.events.isNotEmpty) {
              return;
            }
          }
        },
        builder: (context, state) {
          if (state is EventsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is EventsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: AppTypography.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<EventsCubit>().loadEvents(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is EventsEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event, size: 64, color: AppColors.gray),
                  const SizedBox(height: 16),
                  Text('No events yet', style: AppTypography.h4),
                  const SizedBox(height: 8),
                  Text(
                    'Add your first event to get started',
                    style: AppTypography.bodyMedium,
                  ),
                ],
              ),
            );
          }

          if (state is EventsLoaded) {
            return Column(
              children: [
                EventsCalendar(
                  focusedDay: _focusedDay,
                  selectedDay: _selectedDay,
                  events: state.events,
                  onDaySelected: _onDaySelected,
                  onPageChanged: _onPageChanged,
                ),
                FilterTabs(
                  currentFilter: state.filter,
                  onFilterChanged: _onFilterChanged,
                ),
                Expanded(
                  child: state.filteredEvents.isEmpty
                      ? Center(
                          child: Text(
                            'No events found',
                            style: AppTypography.bodyLarge,
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: state.filteredEvents.length,
                          itemBuilder: (context, index) {
                            final event = state.filteredEvents[index];
                            return EventCard(
                              event: event,
                              onTap: () {
                                final cubit = context.read<EventsCubit>();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BlocProvider.value(
                                      value: cubit,
                                      child: EventDetailScreen(event: event),
                                    ),
                                  ),
                                ).then((_) {
                                  if (mounted) {
                                    cubit.loadEvents();
                                  }
                                });
                              },
                            );
                          },
                        ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onStartVoiceRecording,
        backgroundColor: AppColors.purple,
        heroTag: 'mic_fab_events',
        child: const Icon(Icons.mic, color: Colors.white),
      ),
    );
  }
}
