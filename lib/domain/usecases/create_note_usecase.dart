import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../core/errors/failures.dart';
import '../entities/note.dart';
import '../repositories/notes_repository.dart';
import 'usecase.dart';

class CreateNoteParams {
  final Note note;

  CreateNoteParams(this.note);
}

@injectable
class CreateNoteUseCase implements UseCase<Note, CreateNoteParams> {
  final NotesRepository repository;

  CreateNoteUseCase(this.repository);

  @override
  Future<Either<Failure, Note>> call(CreateNoteParams params) async {
    return await repository.createNote(params.note);
  }
}
