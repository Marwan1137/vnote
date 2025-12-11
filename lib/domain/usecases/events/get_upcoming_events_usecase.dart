import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../core/errors/failures.dart';
import '../../../domain/entities/event.dart';
import '../../../domain/repositories/events_repository.dart';
import '../usecase.dart';

@injectable
class GetUpcomingEventsUseCase implements UseCase<List<Event>, NoParams> {
  final EventsRepository repository;

  GetUpcomingEventsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Event>>> call(NoParams params) async {
    return await repository.getUpcomingEvents();
  }
}
