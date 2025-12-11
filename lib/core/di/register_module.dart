import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import 'package:injectable/injectable.dart';
import '../../core/theme/theme_provider.dart';
import '../../data/models/event_model.dart';
import '../../data/models/note_model.dart';
import '../../data/models/payment_model.dart';

@module
abstract class RegisterModule {
  @Named('notesBox')
  @lazySingleton
  Box<NoteModel> get notesBox => Hive.box<NoteModel>('notes_box');

  @Named('paymentsBox')
  @lazySingleton
  Box<PaymentModel> get paymentsBox => Hive.box<PaymentModel>('payments_box');

  @Named('eventsBox')
  @lazySingleton
  Box<EventModel> get eventsBox => Hive.box<EventModel>('events_box');

  @lazySingleton
  FirebaseAuth get firebaseAuth => FirebaseAuth.instance;

  @lazySingleton
  ThemeProvider get themeProvider => ThemeProvider();
}
