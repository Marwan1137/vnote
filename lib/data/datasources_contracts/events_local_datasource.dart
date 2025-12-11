import '../models/event_model.dart';

abstract class EventsLocalDataSource {
  Future<List<EventModel>> getAllEvents();
  Future<EventModel?> getEventById(String id);
  Future<List<EventModel>> getEventsByDate(DateTime date);
  Future<List<EventModel>> getEventsByMonth(int year, int month);
  Future<List<EventModel>> getUpcomingEvents();
  Future<EventModel> createEvent(EventModel event);
  Future<EventModel> updateEvent(EventModel event);
  Future<void> deleteEvent(String id);
}
