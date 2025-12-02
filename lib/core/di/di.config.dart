// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:hive/hive.dart' as _i979;
import 'package:injectable/injectable.dart' as _i526;

import '../../data/datasources/audio_local_datasource.dart' as _i521;
import '../../data/datasources/notes_local_datasource.dart' as _i983;
import '../../data/datasources/ollama_datasource.dart' as _i209;
import '../../data/datasources/transcription_datasource.dart' as _i307;
import '../../data/models/note_model.dart' as _i1073;
import '../../data/repositories/audio_repository_impl.dart' as _i425;
import '../../data/repositories/notes_repository_impl.dart' as _i252;
import '../../domain/repositories/audio_repository.dart' as _i276;
import '../../domain/repositories/notes_repository.dart' as _i415;
import '../../presentation/cubit/notes/notes_cubit.dart' as _i1073;
import '../../presentation/cubit/recording/recording_cubit.dart' as _i198;
import 'register_module.dart' as _i291;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    final registerModule = _$RegisterModule();
    gh.lazySingleton<_i979.Box<_i1073.NoteModel>>(
        () => registerModule.notesBox);
    gh.lazySingleton<_i209.OllamaDataSource>(
        () => _i209.OllamaDataSourceImpl());
    gh.lazySingleton<_i307.TranscriptionDataSource>(
        () => _i307.TranscriptionDataSourceImpl());
    gh.lazySingleton<_i521.AudioLocalDataSource>(
        () => _i521.AudioLocalDataSourceImpl());
    gh.lazySingleton<_i276.AudioRepository>(() => _i425.AudioRepositoryImpl(
          gh<_i521.AudioLocalDataSource>(),
          gh<_i307.TranscriptionDataSource>(),
          gh<_i209.OllamaDataSource>(),
        ));
    gh.lazySingleton<_i983.NotesLocalDataSource>(() =>
        _i983.NotesLocalDataSourceImpl(gh<_i979.Box<_i1073.NoteModel>>()));
    gh.lazySingleton<_i415.NotesRepository>(
        () => _i252.NotesRepositoryImpl(gh<_i983.NotesLocalDataSource>()));
    gh.factory<_i1073.NotesCubit>(
        () => _i1073.NotesCubit(gh<_i415.NotesRepository>()));
    gh.factory<_i198.RecordingCubit>(() => _i198.RecordingCubit(
          gh<_i276.AudioRepository>(),
          gh<_i415.NotesRepository>(),
        ));
    return this;
  }
}

class _$RegisterModule extends _i291.RegisterModule {}
