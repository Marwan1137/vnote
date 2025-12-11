import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../core/errors/failures.dart';
import '../../../domain/entities/event.dart';
import '../../../domain/repositories/events_repository.dart';
import '../usecase.dart';

class GetEventsByDateParams {
  final DateTime date;

  GetEventsByDateParams(this.date);
}

@injectable
class GetEventsByDateUseCase
    implements UseCase<List<Event>, GetEventsByDateParams> {
  final EventsRepository repository;

  GetEventsByDateUseCase(this.repository);

  @override
  Future<Either<Failure, List<Event>>> call(
    GetEventsByDateParams params,
  ) async {
    return await repository.getEventsByDate(params.date);
  }
}
