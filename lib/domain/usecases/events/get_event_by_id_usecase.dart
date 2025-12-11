import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../core/errors/failures.dart';
import '../../../domain/entities/event.dart';
import '../../../domain/repositories/events_repository.dart';
import '../usecase.dart';

class GetEventByIdParams {
  final String id;

  GetEventByIdParams(this.id);
}

@injectable
class GetEventByIdUseCase implements UseCase<Event, GetEventByIdParams> {
  final EventsRepository repository;

  GetEventByIdUseCase(this.repository);

  @override
  Future<Either<Failure, Event>> call(GetEventByIdParams params) async {
    return await repository.getEventById(params.id);
  }
}
