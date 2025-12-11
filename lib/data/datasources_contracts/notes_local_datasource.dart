import '../models/note_model.dart';

abstract class NotesLocalDataSource {
  Future<List<NoteModel>> getAllNotes(String userId);
  Future<NoteModel> getNoteById(String id, String userId);
  Future<NoteModel> createNote(NoteModel note);
  Future<NoteModel> updateNote(NoteModel note);
  Future<void> deleteNote(String id, String userId);
  Future<List<NoteModel>> searchNotes(String query, String userId);
  Future<List<NoteModel>> getFavoriteNotes(String userId);
}
