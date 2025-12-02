import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../core/errors/failures.dart';
import '../entities/note.dart';
import '../repositories/notes_repository.dart';
import 'usecase.dart';

class SearchNotesParams {
  final String query;

  SearchNotesParams(this.query);
}

@injectable
class SearchNotesUseCase implements UseCase<List<Note>, SearchNotesParams> {
  final NotesRepository repository;

  SearchNotesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Note>>> call(SearchNotesParams params) async {
    return await repository.searchNotes(params.query);
  }
}
