import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../core/errors/failures.dart';
import '../repositories/notes_repository.dart';
import 'usecase.dart';

class DeleteNoteParams {
  final String id;

  DeleteNoteParams(this.id);
}

@injectable
class DeleteNoteUseCase implements UseCase<void, DeleteNoteParams> {
  final NotesRepository repository;

  DeleteNoteUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteNoteParams params) async {
    return await repository.deleteNote(params.id);
  }
}
