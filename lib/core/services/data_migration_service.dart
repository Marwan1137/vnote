import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:injectable/injectable.dart';
import '../di/di.dart';
import '../services/auth_service.dart';
import '../../data/models/event_model.dart';
import '../../data/models/note_model.dart';
import '../../data/models/payment_model.dart';

@lazySingleton
class DataMigrationService {
  final AuthService authService;

  DataMigrationService(this.authService);

  /// Migrate existing data to include userId
  /// This should be called once when a user signs in for the first time
  Future<void> migrateExistingData() async {
    try {
      final userId = await authService.getCurrentUserId();
      if (userId.isEmpty) {
        // No user logged in, skip migration
        return;
      }

      // Get boxes using @Named
      final notesBox = getIt<Box<NoteModel>>(instanceName: 'notesBox');
      final paymentsBox = getIt<Box<PaymentModel>>(instanceName: 'paymentsBox');
      final eventsBox = getIt<Box<EventModel>>(instanceName: 'eventsBox');

      // Migrate notes
      await _migrateNotes(notesBox, userId);

      // Migrate payments
      await _migratePayments(paymentsBox, userId);

      // Migrate events
      await _migrateEvents(eventsBox, userId);
    } catch (e) {
      // Log error but don't throw - migration is not critical
      debugPrint('Data migration error: $e');
    }
  }

  Future<void> _migrateNotes(Box<NoteModel> notesBox, String userId) async {
    final notesToMigrate = <String, NoteModel>{};

    for (var key in notesBox.keys) {
      final note = notesBox.get(key);
      if (note != null && note.userId.isEmpty) {
        notesToMigrate[key] = note.copyWith(userId: userId);
      }
    }

    // Update all notes in batch
    for (var entry in notesToMigrate.entries) {
      await notesBox.put(entry.key, entry.value);
    }
  }

  Future<void> _migratePayments(
    Box<PaymentModel> paymentsBox,
    String userId,
  ) async {
    final paymentsToMigrate = <String, PaymentModel>{};

    for (var key in paymentsBox.keys) {
      final payment = paymentsBox.get(key);
      if (payment != null && payment.userId.isEmpty) {
        paymentsToMigrate[key] = payment.copyWith(userId: userId);
      }
    }

    // Update all payments in batch
    for (var entry in paymentsToMigrate.entries) {
      await paymentsBox.put(entry.key, entry.value);
    }
  }

  Future<void> _migrateEvents(Box<EventModel> eventsBox, String userId) async {
    final eventsToMigrate = <String, EventModel>{};

    for (var key in eventsBox.keys) {
      final event = eventsBox.get(key);
      if (event != null && event.userId.isEmpty) {
        eventsToMigrate[key] = event.copyWith(userId: userId);
      }
    }

    // Update all events in batch
    for (var entry in eventsToMigrate.entries) {
      await eventsBox.put(entry.key, entry.value);
    }
  }
}
