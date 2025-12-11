import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../core/errors/failures.dart';
import '../../../domain/entities/event.dart';
import '../../../domain/repositories/events_repository.dart';
import '../usecase.dart';

class MarkEventCompletedParams {
  final String id;

  MarkEventCompletedParams(this.id);
}

@injectable
class MarkEventCompletedUseCase
    implements UseCase<Event, MarkEventCompletedParams> {
  final EventsRepository repository;

  MarkEventCompletedUseCase(this.repository);

  @override
  Future<Either<Failure, Event>> call(MarkEventCompletedParams params) async {
    return await repository.markEventCompleted(params.id);
  }
}
