import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../core/services/auth_service.dart';
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
        emit(EventsError(failure.message));
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
    emit(EventsLoading());

    final result = await getEventsByMonthUseCase(
      GetEventsByMonthParams(year, month),
    );

    result.fold(
      (failure) {
        emit(EventsError(failure.message));
      },
      (events) {
        final currentState = state;
        if (currentState is EventsLoaded) {
          emit(
            currentState.copyWith(
              events: List<Event>.from(events),
              filteredEvents: List<Event>.from(events),
              selectedYear: year,
              selectedMonth: month,
            ),
          );
        } else {
          emit(
            EventsLoaded(
              events: List<Event>.from(events),
              filteredEvents: List<Event>.from(events),
              selectedYear: year,
              selectedMonth: month,
            ),
          );
        }
      },
    );
  }

  Future<void> loadEventsByDate(DateTime date) async {
    emit(EventsLoading());

    final result = await getEventsByDateUseCase(GetEventsByDateParams(date));

    result.fold(
      (failure) {
        emit(EventsError(failure.message));
      },
      (events) {
        final currentState = state;
        if (currentState is EventsLoaded) {
          emit(
            currentState.copyWith(
              events: List<Event>.from(events),
              filteredEvents: List<Event>.from(events),
              selectedDate: date,
            ),
          );
        } else {
          emit(
            EventsLoaded(
              events: List<Event>.from(events),
              filteredEvents: List<Event>.from(events),
              selectedDate: date,
            ),
          );
        }
      },
    );
  }

  Future<void> loadUpcomingEvents() async {
    emit(EventsLoading());

    final result = await getUpcomingEventsUseCase(const NoParams());

    result.fold(
      (failure) {
        emit(EventsError(failure.message));
      },
      (events) {
        if (events.isEmpty) {
          emit(EventsEmpty());
        } else {
          emit(
            EventsLoaded(
              events: events,
              filteredEvents: events,
              filter: EventFilter.upcoming,
            ),
          );
        }
      },
    );
  }

  void applyFilter(EventFilter filter) {
    final currentState = state;
    if (currentState is! EventsLoaded) return;

    List<Event> filtered;
    if (filter == EventFilter.all) {
      filtered = currentState.events;
    } else {
      // Filter for upcoming events (status is upcoming and dateTime is in the future)
      final now = DateTime.now();
      filtered = currentState.events
          .where(
            (e) => e.status == EventStatus.upcoming && e.dateTime.isAfter(now),
          )
          .toList();
    }

    emit(currentState.copyWith(filteredEvents: filtered, filter: filter));
  }

  Future<void> createEvent(Event event) async {
    final result = await createEventUseCase(event);

    result.fold((failure) => emit(EventsError(failure.message)), (
      createdEvent,
    ) {
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
    });
  }

  Future<void> updateEvent(Event event) async {
    final updatedEvent = event.copyWith(updatedAt: DateTime.now());
    final result = await updateEventUseCase(updatedEvent);

    result.fold((failure) => emit(EventsError(failure.message)), (updated) {
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
    });
  }

  Future<void> deleteEvent(String id) async {
    final result = await deleteEventUseCase(DeleteEventParams(id));

    result.fold((failure) => emit(EventsError(failure.message)), (_) {
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
    });
  }

  Future<void> markCompleted(String id) async {
    final result = await markEventCompletedUseCase(
      MarkEventCompletedParams(id),
    );

    result.fold((failure) => emit(EventsError(failure.message)), (updated) {
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
    });
  }

  Future<void> markCancelled(String id) async {
    final result = await markEventCancelledUseCase(
      MarkEventCancelledParams(id),
    );

    result.fold((failure) => emit(EventsError(failure.message)), (updated) {
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
    });
  }

  Future<void> processTranscription(String transcription) async {
    final result = await processEventTranscriptionUseCase(
      ProcessEventTranscriptionParams(transcription),
    );

    result.fold(
      (failure) {
        emit(EventsError(failure.message));
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
                emit(EventsError(failure.message));
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
