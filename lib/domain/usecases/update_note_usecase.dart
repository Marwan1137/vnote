import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../core/errors/failures.dart';
import '../entities/note.dart';
import '../repositories/notes_repository.dart';
import 'usecase.dart';

class UpdateNoteParams {
  final Note note;

  UpdateNoteParams(this.note);
}

@injectable
class UpdateNoteUseCase implements UseCase<Note, UpdateNoteParams> {
  final NotesRepository repository;

  UpdateNoteUseCase(this.repository);

  @override
  Future<Either<Failure, Note>> call(UpdateNoteParams params) async {
    return await repository.updateNote(params.note);
  }
}
