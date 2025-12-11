import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../core/errors/failures.dart';
import '../../../domain/entities/event.dart';
import '../../../domain/repositories/events_repository.dart';
import '../usecase.dart';

class GetEventsByMonthParams {
  final int year;
  final int month;

  GetEventsByMonthParams(this.year, this.month);
}

@injectable
class GetEventsByMonthUseCase
    implements UseCase<List<Event>, GetEventsByMonthParams> {
  final EventsRepository repository;

  GetEventsByMonthUseCase(this.repository);

  @override
  Future<Either<Failure, List<Event>>> call(
    GetEventsByMonthParams params,
  ) async {
    return await repository.getEventsByMonth(params.year, params.month);
  }
}
