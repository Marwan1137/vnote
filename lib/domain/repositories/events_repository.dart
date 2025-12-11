import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/event.dart';
import '../entities/processed_event.dart';

abstract class EventsRepository {
  Future<Either<Failure, List<Event>>> getAllEvents();
  Future<Either<Failure, Event>> getEventById(String id);
  Future<Either<Failure, List<Event>>> getEventsByDate(DateTime date);
  Future<Either<Failure, List<Event>>> getEventsByMonth(int year, int month);
  Future<Either<Failure, List<Event>>> getUpcomingEvents();
  Future<Either<Failure, Event>> createEvent(Event event);
  Future<Either<Failure, Event>> updateEvent(Event event);
  Future<Either<Failure, void>> deleteEvent(String id);
  Future<Either<Failure, Event>> markEventCompleted(String id);
  Future<Either<Failure, Event>> markEventCancelled(String id);
  Future<Either<Failure, List<ProcessedEvent>>> processEventTranscription(
    String transcription,
  );
}
