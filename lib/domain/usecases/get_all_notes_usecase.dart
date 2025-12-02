import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../core/errors/failures.dart';
import '../entities/note.dart';
import '../repositories/notes_repository.dart';
import 'usecase.dart';

@injectable
class GetAllNotesUseCase implements UseCase<List<Note>, NoParams> {
  final NotesRepository repository;

  GetAllNotesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Note>>> call(NoParams params) async {
    return await repository.getAllNotes();
  }
}
