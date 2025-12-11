import 'package:equatable/equatable.dart';
import '../../../domain/entities/event.dart';

abstract class EventsState extends Equatable {
  const EventsState();

  @override
  List<Object?> get props => [];
}

class EventsInitial extends EventsState {}

class EventsLoading extends EventsState {}

class EventsLoaded extends EventsState {
  final List<Event> events;
  final List<Event> filteredEvents;
  final EventFilter filter;
  final DateTime? selectedDate;
  final int? selectedYear;
  final int? selectedMonth;

  const EventsLoaded({
    required this.events,
    required this.filteredEvents,
    this.filter = EventFilter.all,
    this.selectedDate,
    this.selectedYear,
    this.selectedMonth,
  });

  @override
  List<Object?> get props => [
    events,
    filteredEvents,
    filter,
    selectedDate,
    selectedYear,
    selectedMonth,
  ];

  EventsLoaded copyWith({
    List<Event>? events,
    List<Event>? filteredEvents,
    EventFilter? filter,
    DateTime? selectedDate,
    int? selectedYear,
    int? selectedMonth,
  }) {
    return EventsLoaded(
      events: events ?? this.events,
      filteredEvents: filteredEvents ?? this.filteredEvents,
      filter: filter ?? this.filter,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedYear: selectedYear ?? this.selectedYear,
      selectedMonth: selectedMonth ?? this.selectedMonth,
    );
  }
}

class EventsEmpty extends EventsState {}

class EventsError extends EventsState {
  final String message;

  const EventsError(this.message);

  @override
  List<Object?> get props => [message];
}

enum EventFilter { all, upcoming }
