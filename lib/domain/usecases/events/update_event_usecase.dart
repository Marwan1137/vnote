import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../core/errors/failures.dart';
import '../../../domain/entities/event.dart';
import '../../../domain/repositories/events_repository.dart';
import '../usecase.dart';

@injectable
class UpdateEventUseCase implements UseCase<Event, Event> {
  final EventsRepository repository;

  UpdateEventUseCase(this.repository);

  @override
  Future<Either<Failure, Event>> call(Event params) async {
    return await repository.updateEvent(params);
  }
}
