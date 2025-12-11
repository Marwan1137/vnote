import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../core/errors/failures.dart';
import '../../../domain/entities/event.dart';
import '../../../domain/repositories/events_repository.dart';
import '../usecase.dart';

class MarkEventCancelledParams {
  final String id;

  MarkEventCancelledParams(this.id);
}

@injectable
class MarkEventCancelledUseCase
    implements UseCase<Event, MarkEventCancelledParams> {
  final EventsRepository repository;

  MarkEventCancelledUseCase(this.repository);

  @override
  Future<Either<Failure, Event>> call(MarkEventCancelledParams params) async {
    return await repository.markEventCancelled(params.id);
  }
}
