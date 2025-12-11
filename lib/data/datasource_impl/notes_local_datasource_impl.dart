import 'package:hive/hive.dart';
import 'package:injectable/injectable.dart';
import '../../core/errors/exceptions.dart';
import '../models/note_model.dart';
import '../datasources_contracts/notes_local_datasource.dart';

@LazySingleton(as: NotesLocalDataSource)
class NotesLocalDataSourceImpl implements NotesLocalDataSource {
  @factoryMethod
  NotesLocalDataSourceImpl(@Named('notesBox') this.notesBox);

  final Box<NoteModel> notesBox;

  @override
  Future<List<NoteModel>> getAllNotes(String userId) async {
    try {
      final notes = notesBox.values
          .where((note) => note.userId == userId)
          .toList();
      notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return notes;
    } catch (e) {
      throw DatabaseException('Failed to get all notes: $e');
    }
  }

  @override
  Future<NoteModel> getNoteById(String id, String userId) async {
    try {
      final note = notesBox.get(id);
      if (note == null || note.userId != userId) {
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
  Future<void> deleteNote(String id, String userId) async {
    try {
      final note = notesBox.get(id);
      if (note == null || note.userId != userId) {
        throw NoteNotFoundException('Note with id $id not found');
      }
      await notesBox.delete(id);
    } catch (e) {
      if (e is NoteNotFoundException) rethrow;
      throw DatabaseException('Failed to delete note: $e');
    }
  }

  @override
  Future<List<NoteModel>> searchNotes(String query, String userId) async {
    try {
      final allNotes = await getAllNotes(userId);
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
  Future<List<NoteModel>> getFavoriteNotes(String userId) async {
    try {
      final allNotes = await getAllNotes(userId);
      return allNotes.where((note) => note.isFavorite).toList();
    } catch (e) {
      throw DatabaseException('Failed to get favorite notes: $e');
    }
  }
}
