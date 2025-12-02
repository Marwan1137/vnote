import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:vnote/domain/entities/note.dart';
import 'package:vnote/domain/repositories/notes_repository.dart';
import 'notes_state.dart';

@injectable
class NotesCubit extends Cubit<NotesState> {
  final NotesRepository repository;

  NotesCubit(this.repository) : super(NotesInitial());

  // Load all notes
  Future<void> loadNotes() async {
    emit(NotesLoading());

    final result = await repository.getAllNotes();

    result.fold((failure) => emit(NotesError(failure.message)), (notes) {
      if (notes.isEmpty) {
        emit(NotesEmpty());
      } else {
        emit(NotesLoaded(notes: notes, filteredNotes: notes));
      }
    });
  }

  // Search notes
  Future<void> searchNotes(String query) async {
    final currentState = state;
    if (currentState is! NotesLoaded) return;

    if (query.isEmpty) {
      _applyFilter(currentState.filter);
      return;
    }

    final result = await repository.searchNotes(query);

    result.fold((failure) => emit(NotesError(failure.message)), (
      searchResults,
    ) {
      emit(
        currentState.copyWith(filteredNotes: searchResults, searchQuery: query),
      );
    });
  }

  // Apply filter (All, Recent, Favorites)
  void applyFilter(NotesFilter filter) {
    final currentState = state;
    if (currentState is! NotesLoaded) return;

    _applyFilter(filter);
  }

  void _applyFilter(NotesFilter filter) {
    final currentState = state;
    if (currentState is! NotesLoaded) return;

    List<Note> filtered;

    switch (filter) {
      case NotesFilter.all:
        filtered = currentState.notes;
        break;
      case NotesFilter.recent:
        final now = DateTime.now();
        filtered = currentState.notes.where((note) {
          final difference = now.difference(note.createdAt).inDays;
          return difference <= 7;
        }).toList();
        break;
      case NotesFilter.favorites:
        filtered = currentState.notes.where((note) => note.isFavorite).toList();
        break;
    }

    emit(
      currentState.copyWith(
        filteredNotes: filtered,
        filter: filter,
        searchQuery: null,
      ),
    );
  }

  // Delete note
  Future<void> deleteNote(String id) async {
    final currentState = state;
    if (currentState is! NotesLoaded) return;

    final result = await repository.deleteNote(id);

    result.fold(
      (failure) => emit(NotesError(failure.message)),
      (_) => loadNotes(),
    );
  }

  // Toggle favorite
  Future<void> toggleFavorite(Note note) async {
    final updatedNote = note.copyWith(
      isFavorite: !note.isFavorite,
      updatedAt: DateTime.now(),
    );

    final result = await repository.updateNote(updatedNote);

    result.fold(
      (failure) => emit(NotesError(failure.message)),
      (_) => loadNotes(),
    );
  }

  // Refresh notes
  Future<void> refreshNotes() async {
    await loadNotes();
  }

  // Create note
  Future<void> createNote(Note note) async {
    final result = await repository.createNote(note);

    result.fold(
      (failure) => emit(NotesError(failure.message)),
      (_) => loadNotes(),
    );
  }

  // Update note
  Future<void> updateNote(Note note) async {
    final result = await repository.updateNote(note);

    result.fold(
      (failure) => emit(NotesError(failure.message)),
      (_) => loadNotes(),
    );
  }
}
