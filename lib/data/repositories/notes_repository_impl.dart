import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../core/services/auth_service.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/notes_repository.dart';
import '../datasources_contracts/notes_local_datasource.dart';
import '../models/note_model.dart';

@LazySingleton(as: NotesRepository)
class NotesRepositoryImpl implements NotesRepository {
  final NotesLocalDataSource localDataSource;
  final AuthService authService;

  NotesRepositoryImpl(this.localDataSource, this.authService);

  @override
  Future<Either<Failure, List<Note>>> getAllNotes() async {
    try {
      final userId = await authService.getCurrentUserId();
      final notes = await localDataSource.getAllNotes(userId);
      return Right(notes.map((model) => model.toEntity()).toList());
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Note>> getNoteById(String id) async {
    try {
      final userId = await authService.getCurrentUserId();
      final note = await localDataSource.getNoteById(id, userId);
      return Right(note.toEntity());
    } on NoteNotFoundException catch (e) {
      return Left(NoteNotFoundFailure(e.message));
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Note>> createNote(Note note) async {
    try {
      final noteModel = NoteModel.fromEntity(note);
      final createdNote = await localDataSource.createNote(noteModel);
      return Right(createdNote.toEntity());
    } on DatabaseException catch (e) {
      return Left(NoteSaveFailure(e.message));
    } catch (e) {
      return Left(NoteSaveFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Note>> updateNote(Note note) async {
    try {
      final noteModel = NoteModel.fromEntity(note);
      final updatedNote = await localDataSource.updateNote(noteModel);
      return Right(updatedNote.toEntity());
    } on NoteNotFoundException catch (e) {
      return Left(NoteNotFoundFailure(e.message));
    } on DatabaseException catch (e) {
      return Left(NoteSaveFailure(e.message));
    } catch (e) {
      return Left(NoteSaveFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteNote(String id) async {
    try {
      final userId = await authService.getCurrentUserId();
      await localDataSource.deleteNote(id, userId);
      return const Right(null);
    } on NoteNotFoundException catch (e) {
      return Left(NoteNotFoundFailure(e.message));
    } on DatabaseException catch (e) {
      return Left(NoteDeleteFailure(e.message));
    } catch (e) {
      return Left(NoteDeleteFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Note>>> searchNotes(String query) async {
    try {
      final userId = await authService.getCurrentUserId();
      final notes = await localDataSource.searchNotes(query, userId);
      return Right(notes.map((model) => model.toEntity()).toList());
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Note>>> getFavoriteNotes() async {
    try {
      final userId = await authService.getCurrentUserId();
      final notes = await localDataSource.getFavoriteNotes(userId);
      return Right(notes.map((model) => model.toEntity()).toList());
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }
}
