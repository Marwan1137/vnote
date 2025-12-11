import 'package:hive/hive.dart';
import 'package:injectable/injectable.dart';
import '../../core/errors/exceptions.dart';
import '../models/event_model.dart';
import '../datasources_contracts/events_local_datasource.dart';

@LazySingleton(as: EventsLocalDataSource)
class EventsLocalDataSourceImpl implements EventsLocalDataSource {
  @factoryMethod
  EventsLocalDataSourceImpl(@Named('eventsBox') this.eventsBox);

  final Box<EventModel> eventsBox;

  @override
  Future<List<EventModel>> getAllEvents() async {
    try {
      return eventsBox.values.toList()
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    } catch (e) {
      throw CacheException('Failed to get all events: $e');
    }
  }

  @override
  Future<EventModel?> getEventById(String id) async {
    try {
      return eventsBox.get(id);
    } catch (e) {
      throw CacheException('Failed to get event by id: $e');
    }
  }

  @override
  Future<List<EventModel>> getEventsByDate(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      return eventsBox.values.where((event) {
        return event.dateTime.isAfter(
              startOfDay.subtract(const Duration(milliseconds: 1)),
            ) &&
            event.dateTime.isBefore(endOfDay);
      }).toList()..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    } catch (e) {
      throw CacheException('Failed to get events by date: $e');
    }
  }

  @override
  Future<List<EventModel>> getEventsByMonth(int year, int month) async {
    try {
      return eventsBox.values.where((event) {
        return event.dateTime.year == year && event.dateTime.month == month;
      }).toList()..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    } catch (e) {
      throw CacheException('Failed to get events by month: $e');
    }
  }

  @override
  Future<List<EventModel>> getUpcomingEvents() async {
    try {
      final now = DateTime.now();
      return eventsBox.values
          .where((event) => event.dateTime.isAfter(now) && event.status == 0)
          .toList()
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    } catch (e) {
      throw CacheException('Failed to get upcoming events: $e');
    }
  }

  @override
  Future<EventModel> createEvent(EventModel event) async {
    try {
      await eventsBox.put(event.id, event);
      return event;
    } catch (e) {
      throw CacheException('Failed to create event: $e');
    }
  }

  @override
  Future<EventModel> updateEvent(EventModel event) async {
    try {
      await eventsBox.put(event.id, event);
      return event;
    } catch (e) {
      throw CacheException('Failed to update event: $e');
    }
  }

  @override
  Future<void> deleteEvent(String id) async {
    try {
      await eventsBox.delete(id);
    } catch (e) {
      throw CacheException('Failed to delete event: $e');
    }
  }
}
