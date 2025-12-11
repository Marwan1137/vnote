import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/event.dart';
import '../../domain/entities/processed_event.dart';
import '../../domain/repositories/events_repository.dart';
import '../datasources_contracts/events_local_datasource.dart';
import '../models/event_model.dart';

@LazySingleton(as: EventsRepository)
class EventsRepositoryImpl implements EventsRepository {
  final EventsLocalDataSource localDataSource;

  EventsRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, List<Event>>> getAllEvents() async {
    try {
      final models = await localDataSource.getAllEvents();
      final events = models.map((model) => model.toEntity()).toList();
      return Right(events);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Event>> getEventById(String id) async {
    try {
      final model = await localDataSource.getEventById(id);
      if (model == null) {
        return Left(CacheFailure('Event not found'));
      }
      return Right(model.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Event>>> getEventsByDate(DateTime date) async {
    try {
      final models = await localDataSource.getEventsByDate(date);
      final events = models.map((model) => model.toEntity()).toList();
      return Right(events);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Event>>> getEventsByMonth(
    int year,
    int month,
  ) async {
    try {
      final models = await localDataSource.getEventsByMonth(year, month);
      final events = models.map((model) => model.toEntity()).toList();
      return Right(events);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Event>>> getUpcomingEvents() async {
    try {
      final models = await localDataSource.getUpcomingEvents();
      final events = models.map((model) => model.toEntity()).toList();
      return Right(events);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Event>> createEvent(Event event) async {
    try {
      final model = EventModel.fromEntity(event);
      final created = await localDataSource.createEvent(model);
      return Right(created.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Event>> updateEvent(Event event) async {
    try {
      final model = EventModel.fromEntity(event);
      final updated = await localDataSource.updateEvent(model);
      return Right(updated.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteEvent(String id) async {
    try {
      await localDataSource.deleteEvent(id);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Event>> markEventCompleted(String id) async {
    try {
      final model = await localDataSource.getEventById(id);
      if (model == null) {
        return Left(CacheFailure('Event not found'));
      }

      final updatedModel = model.copyWith(
        status: 1, // EventStatus.completed
        updatedAt: DateTime.now(),
      );

      final updated = await localDataSource.updateEvent(updatedModel);
      return Right(updated.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Event>> markEventCancelled(String id) async {
    try {
      final model = await localDataSource.getEventById(id);
      if (model == null) {
        return Left(CacheFailure('Event not found'));
      }

      final updatedModel = model.copyWith(
        status: 2, // EventStatus.cancelled
        updatedAt: DateTime.now(),
      );

      final updated = await localDataSource.updateEvent(updatedModel);
      return Right(updated.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<ProcessedEvent>>> processEventTranscription(
    String transcription,
  ) async {
    // This method is not used - LLM processing is done directly in the use case
    // But we need to implement it to satisfy the interface
    throw UnimplementedError('Use ProcessEventTranscriptionUseCase instead');
  }
}
