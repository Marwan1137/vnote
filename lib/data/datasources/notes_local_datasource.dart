import 'package:hive/hive.dart';
import 'package:injectable/injectable.dart';
import '../../core/errors/exceptions.dart';
import '../models/note_model.dart';

abstract class NotesLocalDataSource {
  Future<List<NoteModel>> getAllNotes();
  Future<NoteModel> getNoteById(String id);
  Future<NoteModel> createNote(NoteModel note);
  Future<NoteModel> updateNote(NoteModel note);
  Future<void> deleteNote(String id);
  Future<List<NoteModel>> searchNotes(String query);
  Future<List<NoteModel>> getFavoriteNotes();
}

@LazySingleton(as: NotesLocalDataSource)
class NotesLocalDataSourceImpl implements NotesLocalDataSource {
  final Box<NoteModel> notesBox;

  NotesLocalDataSourceImpl(this.notesBox);

  @override
  Future<List<NoteModel>> getAllNotes() async {
    try {
      final notes = notesBox.values.toList();
      notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return notes;
    } catch (e) {
      throw DatabaseException('Failed to get all notes: $e');
    }
  }

  @override
  Future<NoteModel> getNoteById(String id) async {
    try {
      final note = notesBox.get(id);
      if (note == null) {
        throw NoteNotFoundException('Note with id $id not found');
      }
      return note;
    } catch (e) {
      if (e is NoteNotFoundException) rethrow;
      throw DatabaseException('Failed to get note: $e');
    }
  }

  @override
  Future<NoteModel> createNote(NoteModel note) async {
    try {
      await notesBox.put(note.id, note);
      return note;
    } catch (e) {
      throw DatabaseException('Failed to create note: $e');
    }
  }

  @override
  Future<NoteModel> updateNote(NoteModel note) async {
    try {
      if (!notesBox.containsKey(note.id)) {
        throw NoteNotFoundException('Note with id ${note.id} not found');
      }
      await notesBox.put(note.id, note);
      return note;
    } catch (e) {
      if (e is NoteNotFoundException) rethrow;
      throw DatabaseException('Failed to update note: $e');
    }
  }

  @override
  Future<void> deleteNote(String id) async {
    try {
      if (!notesBox.containsKey(id)) {
        throw NoteNotFoundException('Note with id $id not found');
      }
      await notesBox.delete(id);
    } catch (e) {
      if (e is NoteNotFoundException) rethrow;
      throw DatabaseException('Failed to delete note: $e');
    }
  }

  @override
  Future<List<NoteModel>> searchNotes(String query) async {
    try {
      final allNotes = await getAllNotes();
      final lowercaseQuery = query.toLowerCase();

      return allNotes.where((note) {
        final titleMatch = note.title.toLowerCase().contains(lowercaseQuery);
        final contentMatch = note.content.toLowerCase().contains(
          lowercaseQuery,
        );
        final tagsMatch = note.tags.any(
          (tag) => tag.toLowerCase().contains(lowercaseQuery),
        );
        return titleMatch || contentMatch || tagsMatch;
      }).toList();
    } catch (e) {
      throw DatabaseException('Failed to search notes: $e');
    }
  }

  @override
  Future<List<NoteModel>> getFavoriteNotes() async {
    try {
      final allNotes = await getAllNotes();
      return allNotes.where((note) => note.isFavorite).toList();
    } catch (e) {
      throw DatabaseException('Failed to get favorite notes: $e');
    }
  }
}
