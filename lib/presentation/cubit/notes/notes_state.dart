import 'package:equatable/equatable.dart';
import 'package:vnote/domain/entities/note.dart';

abstract class NotesState extends Equatable {
  const NotesState();

  @override
  List<Object?> get props => [];
}

// Initial State
class NotesInitial extends NotesState {}

// Loading State
class NotesLoading extends NotesState {}

// Loaded State
class NotesLoaded extends NotesState {
  final List<Note> notes;
  final List<Note> filteredNotes;
  final String? searchQuery;
  final NotesFilter filter;

  const NotesLoaded({
    required this.notes,
    required this.filteredNotes,
    this.searchQuery,
    this.filter = NotesFilter.all,
  });

  @override
  List<Object?> get props => [notes, filteredNotes, searchQuery, filter];

  NotesLoaded copyWith({
    List<Note>? notes,
    List<Note>? filteredNotes,
    String? searchQuery,
    NotesFilter? filter,
  }) {
    return NotesLoaded(
      notes: notes ?? this.notes,
      filteredNotes: filteredNotes ?? this.filteredNotes,
      searchQuery: searchQuery ?? this.searchQuery,
      filter: filter ?? this.filter,
    );
  }
}

// Empty State
class NotesEmpty extends NotesState {}

// Error State
class NotesError extends NotesState {
  final String message;

  const NotesError(this.message);

  @override
  List<Object?> get props => [message];
}

// Filter Enum
enum NotesFilter { all, recent, favorites }
