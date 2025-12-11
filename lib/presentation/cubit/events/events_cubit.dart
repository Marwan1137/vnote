import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/user_friendly_errors.dart';
import '../../../domain/entities/event.dart';
import '../../../domain/usecases/events/create_event_usecase.dart';
import '../../../domain/usecases/events/delete_event_usecase.dart';
import '../../../domain/usecases/events/get_all_events_usecase.dart';
import '../../../domain/usecases/events/get_events_by_date_usecase.dart';
import '../../../domain/usecases/events/get_events_by_month_usecase.dart';
import '../../../domain/usecases/events/get_upcoming_events_usecase.dart';
import '../../../domain/usecases/events/mark_event_cancelled_usecase.dart';
import '../../../domain/usecases/events/mark_event_completed_usecase.dart';
import '../../../domain/usecases/events/process_event_transcription_usecase.dart';
import '../../../domain/usecases/events/update_event_usecase.dart';
import '../../../domain/usecases/usecase.dart';
import 'events_state.dart';

@injectable
class EventsCubit extends Cubit<EventsState> {
  final GetAllEventsUseCase getAllEventsUseCase;
  final GetEventsByMonthUseCase getEventsByMonthUseCase;
  final GetEventsByDateUseCase getEventsByDateUseCase;
  final GetUpcomingEventsUseCase getUpcomingEventsUseCase;
  final CreateEventUseCase createEventUseCase;
  final UpdateEventUseCase updateEventUseCase;
  final DeleteEventUseCase deleteEventUseCase;
  final MarkEventCompletedUseCase markEventCompletedUseCase;
  final MarkEventCancelledUseCase markEventCancelledUseCase;
  final ProcessEventTranscriptionUseCase processEventTranscriptionUseCase;
  final AuthService authService;

  EventsCubit(
    this.getAllEventsUseCase,
    this.getEventsByMonthUseCase,
    this.getEventsByDateUseCase,
    this.getUpcomingEventsUseCase,
    this.createEventUseCase,
    this.updateEventUseCase,
    this.deleteEventUseCase,
    this.markEventCompletedUseCase,
    this.markEventCancelledUseCase,
    this.processEventTranscriptionUseCase,
    this.authService,
  ) : super(EventsInitial());

  Future<void> loadEvents() async {
    emit(EventsLoading());

    final result = await getAllEventsUseCase(const NoParams());

    result.fold(
      (failure) {
        emit(
          EventsError(
            UserFriendlyErrors.getUserFriendlyMessage(
              failure,
              context: 'events',
            ),
          ),
        );
      },
      (events) {
        if (events.isEmpty) {
          emit(EventsEmpty());
        } else {
          emit(EventsLoaded(events: events, filteredEvents: events));
        }
      },
    );
  }

  Future<void> loadEventsByMonth(int year, int month) async {
    final currentState = state;
    if (currentState is EventsLoaded) {
      // If we already have events loaded, preserve them for calendar markers
      // Only filter events for the selected month in the list view
      final eventsForMonth = currentState.events.where((event) {
        return event.dateTime.year == year && event.dateTime.month == month;
      }).toList();

      emit(
        currentState.copyWith(
          filteredEvents: List<Event>.from(eventsForMonth),
          selectedYear: year,
          selectedMonth: month,
        ),
      );
    } else {
      // If no events are loaded, first load ALL events to ensure calendar markers work
      // Then filter by month for the list view
      emit(EventsLoading());

      final allEventsResult = await getAllEventsUseCase(const NoParams());

      allEventsResult.fold(
        (failure) {
          emit(
            EventsError(
              UserFriendlyErrors.getUserFriendlyMessage(
                failure,
                context: 'events',
              ),
            ),
          );
        },
        (allEvents) {
          // Filter events for the selected month
          final eventsForMonth = allEvents.where((event) {
            return event.dateTime.year == year && event.dateTime.month == month;
          }).toList();

          if (allEvents.isEmpty) {
            emit(EventsEmpty());
          } else {
            // Keep all events in state.events for calendar markers
            // Only filter filteredEvents for the list view
            emit(
              EventsLoaded(
                events: allEvents,
                filteredEvents: List<Event>.from(eventsForMonth),
                selectedYear: year,
                selectedMonth: month,
              ),
            );
          }
        },
      );
    }
  }

  Future<void> loadEventsByDate(DateTime date) async {
    final currentState = state;
    if (currentState is EventsLoaded) {
      // If we already have events loaded, just filter them by date
      // This preserves all events for the calendar markers
      final eventsForDate = currentState.events.where((event) {
        return event.dateTime.year == date.year &&
            event.dateTime.month == date.month &&
            event.dateTime.day == date.day;
      }).toList();

      emit(
        currentState.copyWith(
          filteredEvents: List<Event>.from(eventsForDate),
          selectedDate: date,
        ),
      );
    } else {
      // If no events are loaded, first load ALL events to ensure calendar markers work
      // Then filter by date for the list view
      emit(EventsLoading());

      final allEventsResult = await getAllEventsUseCase(const NoParams());

      allEventsResult.fold(
        (failure) {
          emit(
            EventsError(
              UserFriendlyErrors.getUserFriendlyMessage(
                failure,
                context: 'events',
              ),
            ),
          );
        },
        (allEvents) {
          // Filter events for the selected date
          final eventsForDate = allEvents.where((event) {
            return event.dateTime.year == date.year &&
                event.dateTime.month == date.month &&
                event.dateTime.day == date.day;
          }).toList();

          if (allEvents.isEmpty) {
            emit(EventsEmpty());
          } else {
            // Keep all events in state.events for calendar markers
            // Only filter filteredEvents for the list view
            emit(
              EventsLoaded(
                events: allEvents,
                filteredEvents: List<Event>.from(eventsForDate),
                selectedDate: date,
              ),
            );
          }
        },
      );
    }
  }

  Future<void> loadUpcomingEvents() async {
    emit(EventsLoading());

    // Load all events first to ensure calendar markers work for all events
    final allEventsResult = await getAllEventsUseCase(const NoParams());

    allEventsResult.fold(
      (failure) {
        emit(
          EventsError(
            UserFriendlyErrors.getUserFriendlyMessage(
              failure,
              context: 'events',
            ),
          ),
        );
      },
      (allEvents) {
        if (allEvents.isEmpty) {
          emit(EventsEmpty());
        } else {
          // Filter for upcoming events from all events
          final now = DateTime.now();
          final upcomingEvents = allEvents
              .where(
                (e) =>
                    e.status == EventStatus.upcoming && e.dateTime.isAfter(now),
              )
              .toList();

          // Keep all events in state.events for calendar markers
          // Only filter filteredEvents for the list view
          emit(
            EventsLoaded(
              events: allEvents,
              filteredEvents: upcomingEvents,
              filter: EventFilter.upcoming,
            ),
          );
        }
      },
    );
  }

  Future<void> applyFilter(EventFilter filter) async {
    final currentState = state;

    // If filter is upcoming, always load all events first to ensure we have complete data
    // This ensures we show ALL upcoming events from any date, not just currently loaded ones
    if (filter == EventFilter.upcoming) {
      // Always reload all events to ensure we have complete data for filtering
      emit(EventsLoading());

      final result = await getAllEventsUseCase(const NoParams());

      result.fold(
        (failure) {
          emit(
            EventsError(
              UserFriendlyErrors.getUserFriendlyMessage(
                failure,
                context: 'events',
              ),
            ),
          );
        },
        (allEvents) {
          if (allEvents.isEmpty) {
            emit(EventsEmpty());
          } else {
            // Filter for upcoming events from all events
            final now = DateTime.now();
            final filtered = allEvents
                .where(
                  (e) =>
                      e.status == EventStatus.upcoming &&
                      e.dateTime.isAfter(now),
                )
                .toList();

            // Keep all events in state.events for calendar markers
            // Only filter filteredEvents for the list view
            emit(
              EventsLoaded(
                events: allEvents,
                filteredEvents: filtered,
                filter: filter,
              ),
            );
          }
        },
      );
      return;
    }

    // For "all" filter, ensure we have all events loaded
    if (filter == EventFilter.all) {
      if (currentState is! EventsLoaded) {
        await loadEvents();
        return;
      }
      // If we already have events loaded, reload to ensure we have ALL events
      // (not just a subset from date/month filtering)
      emit(EventsLoading());

      final result = await getAllEventsUseCase(const NoParams());

      result.fold(
        (failure) {
          emit(
            EventsError(
              UserFriendlyErrors.getUserFriendlyMessage(
                failure,
                context: 'events',
              ),
            ),
          );
        },
        (allEvents) {
          if (allEvents.isEmpty) {
            emit(EventsEmpty());
          } else {
            emit(
              EventsLoaded(
                events: allEvents,
                filteredEvents: allEvents,
                filter: filter,
              ),
            );
          }
        },
      );
    }
  }

  Future<void> createEvent(Event event) async {
    final result = await createEventUseCase(event);

    result.fold(
      (failure) => emit(
        EventsError(
          UserFriendlyErrors.getUserFriendlyMessage(failure, context: 'events'),
        ),
      ),
      (createdEvent) {
        final currentState = state;
        if (currentState is EventsLoaded) {
          final updatedEvents = [createdEvent, ...currentState.events];
          emit(
            currentState.copyWith(
              events: List<Event>.from(updatedEvents),
              filteredEvents: List<Event>.from(updatedEvents),
            ),
          );
        } else {
          loadEvents();
        }
      },
    );
  }

  Future<void> updateEvent(Event event) async {
    final updatedEvent = event.copyWith(updatedAt: DateTime.now());
    final result = await updateEventUseCase(updatedEvent);

    result.fold(
      (failure) => emit(
        EventsError(
          UserFriendlyErrors.getUserFriendlyMessage(failure, context: 'events'),
        ),
      ),
      (updated) {
        final currentState = state;
        if (currentState is EventsLoaded) {
          final updatedEvents = currentState.events
              .map((e) => e.id == updated.id ? updated : e)
              .toList();
          emit(
            currentState.copyWith(
              events: List<Event>.from(updatedEvents),
              filteredEvents: List<Event>.from(updatedEvents),
            ),
          );
        } else {
          loadEvents();
        }
      },
    );
  }

  Future<void> deleteEvent(String id) async {
    final result = await deleteEventUseCase(DeleteEventParams(id));

    result.fold(
      (failure) => emit(
        EventsError(
          UserFriendlyErrors.getUserFriendlyMessage(failure, context: 'events'),
        ),
      ),
      (_) {
        final currentState = state;
        if (currentState is EventsLoaded) {
          final updatedEvents = currentState.events
              .where((e) => e.id != id)
              .toList();
          if (updatedEvents.isEmpty) {
            emit(EventsEmpty());
          } else {
            emit(
              currentState.copyWith(
                events: updatedEvents,
                filteredEvents: updatedEvents,
              ),
            );
          }
        } else {
          loadEvents();
        }
      },
    );
  }

  Future<void> markCompleted(String id) async {
    final result = await markEventCompletedUseCase(
      MarkEventCompletedParams(id),
    );

    result.fold(
      (failure) => emit(
        EventsError(
          UserFriendlyErrors.getUserFriendlyMessage(failure, context: 'events'),
        ),
      ),
      (updated) {
        final currentState = state;
        if (currentState is EventsLoaded) {
          final updatedEvents = currentState.events
              .map((e) => e.id == updated.id ? updated : e)
              .toList();
          emit(
            currentState.copyWith(
              events: List<Event>.from(updatedEvents),
              filteredEvents: List<Event>.from(updatedEvents),
            ),
          );
        } else {
          loadEvents();
        }
      },
    );
  }

  Future<void> markCancelled(String id) async {
    final result = await markEventCancelledUseCase(
      MarkEventCancelledParams(id),
    );

    result.fold(
      (failure) => emit(
        EventsError(
          UserFriendlyErrors.getUserFriendlyMessage(failure, context: 'events'),
        ),
      ),
      (updated) {
        final currentState = state;
        if (currentState is EventsLoaded) {
          final updatedEvents = currentState.events
              .map((e) => e.id == updated.id ? updated : e)
              .toList();
          emit(
            currentState.copyWith(
              events: List<Event>.from(updatedEvents),
              filteredEvents: List<Event>.from(updatedEvents),
            ),
          );
        } else {
          loadEvents();
        }
      },
    );
  }

  Future<void> processTranscription(String transcription) async {
    final result = await processEventTranscriptionUseCase(
      ProcessEventTranscriptionParams(transcription),
    );

    result.fold(
      (failure) {
        emit(
          EventsError(
            UserFriendlyErrors.getUserFriendlyMessage(
              failure,
              context: 'events',
            ),
          ),
        );
      },
      (processedEvents) async {
        // Create all events simultaneously for better performance
        final now = DateTime.now();
        final userId = await authService.getCurrentUserId();
        final baseTimestamp = now.millisecondsSinceEpoch;
        final eventsToCreate = processedEvents.asMap().entries.map((entry) {
          final index = entry.key;
          final processed = entry.value;
          return Event(
            id: '${baseTimestamp}_$index',
            userId: userId,
            title: processed.title,
            description: null,
            dateTime: processed.dateTime,
            location: processed.location,
            attendeesCount: processed.attendeesCount,
            status: EventStatus.upcoming,
            isRecurring: processed.isRecurring,
            recurringFrequency: processed.recurringFrequency,
            recurringEndDate: null,
            notificationDays: processed.notificationDays,
            createdAt: now,
            updatedAt: now,
          );
        }).toList();

        // Create all events in parallel
        final createResults = await Future.wait(
          eventsToCreate.map((event) => createEventUseCase(event)),
        );

        // Check if all succeeded and update state once
        final currentState = state;

        final createdEvents = <Event>[];
        bool hasError = false;

        for (var i = 0; i < createResults.length; i++) {
          final result = createResults[i];
          result.fold(
            (failure) {
              // If any event creation fails, mark error
              if (!hasError) {
                hasError = true;
                emit(
                  EventsError(
                    UserFriendlyErrors.getUserFriendlyMessage(
                      failure,
                      context: 'events',
                    ),
                  ),
                );
              }
            },
            (event) {
              createdEvents.add(event);
            },
          );
        }

        // If there was an error, don't update state
        if (hasError || createdEvents.length != eventsToCreate.length) {
          await loadEvents();
          return;
        }

        // Update state based on current state
        if (currentState is EventsLoaded) {
          // State is already loaded, add new events to existing list
          final updatedEvents = [...createdEvents, ...currentState.events];

          // Reapply current filter to filteredEvents
          List<Event> filtered;
          if (currentState.filter == EventFilter.all) {
            filtered = updatedEvents;
          } else {
            // Filter for upcoming events
            final now = DateTime.now();
            filtered = updatedEvents
                .where(
                  (e) =>
                      e.status == EventStatus.upcoming &&
                      e.dateTime.isAfter(now),
                )
                .toList();
          }

          emit(
            currentState.copyWith(
              events: List<Event>.from(updatedEvents),
              filteredEvents: List<Event>.from(filtered),
            ),
          );
        } else {
          // State is EventsEmpty or EventsInitial - emit EventsLoaded directly with created events
          emit(
            EventsLoaded(
              events: List<Event>.from(createdEvents),
              filteredEvents: List<Event>.from(createdEvents),
            ),
          );
        }
      },
    );
  }
}
