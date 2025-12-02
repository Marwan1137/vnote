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
