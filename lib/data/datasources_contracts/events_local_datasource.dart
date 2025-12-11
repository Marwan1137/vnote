import '../models/event_model.dart';

abstract class EventsLocalDataSource {
  Future<List<EventModel>> getAllEvents(String userId);
  Future<EventModel?> getEventById(String id, String userId);
  Future<List<EventModel>> getEventsByDate(DateTime date, String userId);
  Future<List<EventModel>> getEventsByMonth(int year, int month, String userId);
  Future<List<EventModel>> getUpcomingEvents(String userId);
  Future<EventModel> createEvent(EventModel event);
  Future<EventModel> updateEvent(EventModel event);
  Future<void> deleteEvent(String id, String userId);
}
