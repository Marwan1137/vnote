import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../core/errors/failures.dart';
import '../../../domain/repositories/events_repository.dart';
import '../usecase.dart';

class DeleteEventParams {
  final String id;

  DeleteEventParams(this.id);
}

@injectable
class DeleteEventUseCase implements UseCase<void, DeleteEventParams> {
  final EventsRepository repository;

  DeleteEventUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteEventParams params) async {
    return await repository.deleteEvent(params.id);
  }
}
