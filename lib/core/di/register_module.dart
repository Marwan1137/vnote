import 'package:hive/hive.dart';
import 'package:injectable/injectable.dart';
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
}
