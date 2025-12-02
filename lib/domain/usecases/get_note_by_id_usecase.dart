import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../core/errors/failures.dart';
import '../entities/note.dart';
import '../repositories/notes_repository.dart';
import 'usecase.dart';

class GetNoteByIdParams {
  final String id;

  GetNoteByIdParams(this.id);
}

@injectable
class GetNoteByIdUseCase implements UseCase<Note, GetNoteByIdParams> {
  final NotesRepository repository;

  GetNoteByIdUseCase(this.repository);

  @override
  Future<Either<Failure, Note>> call(GetNoteByIdParams params) async {
    return await repository.getNoteById(params.id);
  }
}
