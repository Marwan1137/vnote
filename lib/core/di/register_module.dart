import 'package:hive/hive.dart';
import 'package:injectable/injectable.dart';
import '../../data/models/note_model.dart';

@module
abstract class RegisterModule {
  @lazySingleton
  Box<NoteModel> get notesBox => Hive.box<NoteModel>('notes_box');
}
