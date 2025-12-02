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

import '../../data/datasources_contracts/audio_local_datasource.dart' as _i521;
import '../../data/datasource_impl/audio_local_datasource_impl.dart' as _i346;
import '../../data/datasources_contracts/llm_datasource.dart' as _i1071;
import '../../data/datasource_impl/llm_datasource_impl.dart' as _i810;
import '../../data/datasources_contracts/notes_local_datasource.dart' as _i983;
import '../../data/datasource_impl/notes_local_datasource_impl.dart' as _i122;
import '../../data/datasources_contracts/transcription_datasource.dart'
    as _i307;
import '../../data/datasource_impl/transcription_datasource_impl.dart' as _i838;
import '../../data/models/note_model.dart' as _i1073;
import '../../data/repositories/audio_repository_impl.dart' as _i425;
import '../../data/repositories/notes_repository_impl.dart' as _i252;
import '../../domain/repositories/audio_repository.dart' as _i276;
import '../../domain/repositories/notes_repository.dart' as _i415;
import '../../domain/usecases/check_microphone_permission_usecase.dart'
    as _i636;
import '../../domain/usecases/create_note_usecase.dart' as _i783;
import '../../domain/usecases/delete_note_usecase.dart' as _i732;
import '../../domain/usecases/get_all_notes_usecase.dart' as _i520;
import '../../domain/usecases/get_favorite_notes_usecase.dart' as _i120;
import '../../domain/usecases/get_note_by_id_usecase.dart' as _i219;
import '../../domain/usecases/open_app_settings_usecase.dart' as _i314;
import '../../domain/usecases/process_transcription_usecase.dart' as _i755;
import '../../domain/usecases/request_microphone_permission_usecase.dart'
    as _i685;
import '../../domain/usecases/search_notes_usecase.dart' as _i661;
import '../../domain/usecases/start_recording_usecase.dart' as _i719;
import '../../domain/usecases/stop_recording_usecase.dart' as _i949;
import '../../domain/usecases/transcribe_audio_usecase.dart' as _i820;
import '../../domain/usecases/update_note_usecase.dart' as _i1050;
import '../../presentation/cubit/notes/notes_cubit.dart' as _i1073;
import '../../presentation/cubit/recording/recording_cubit.dart' as _i198;
import 'register_module.dart' as _i291;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    gh.lazySingleton<_i979.Box<_i1073.NoteModel>>(
      () => registerModule.notesBox,
    );
    gh.lazySingleton<_i1071.LLMDataSource>(() => _i810.LLMDataSourceImpl());
    gh.lazySingleton<_i521.AudioLocalDataSource>(
      () => _i346.AudioLocalDataSourceImpl(),
    );
    gh.lazySingleton<_i307.TranscriptionDataSource>(
      () => _i838.TranscriptionDataSourceImpl(),
    );
    gh.lazySingleton<_i276.AudioRepository>(
      () => _i425.AudioRepositoryImpl(
        gh<_i521.AudioLocalDataSource>(),
        gh<_i307.TranscriptionDataSource>(),
        gh<_i1071.LLMDataSource>(),
      ),
    );
    gh.lazySingleton<_i983.NotesLocalDataSource>(
      () => _i122.NotesLocalDataSourceImpl(gh<_i979.Box<_i1073.NoteModel>>()),
    );
    gh.lazySingleton<_i415.NotesRepository>(
      () => _i252.NotesRepositoryImpl(gh<_i983.NotesLocalDataSource>()),
    );
    gh.factory<_i783.CreateNoteUseCase>(
      () => _i783.CreateNoteUseCase(gh<_i415.NotesRepository>()),
    );
    gh.factory<_i219.GetNoteByIdUseCase>(
      () => _i219.GetNoteByIdUseCase(gh<_i415.NotesRepository>()),
    );
    gh.factory<_i732.DeleteNoteUseCase>(
      () => _i732.DeleteNoteUseCase(gh<_i415.NotesRepository>()),
    );
    gh.factory<_i120.GetFavoriteNotesUseCase>(
      () => _i120.GetFavoriteNotesUseCase(gh<_i415.NotesRepository>()),
    );
    gh.factory<_i661.SearchNotesUseCase>(
      () => _i661.SearchNotesUseCase(gh<_i415.NotesRepository>()),
    );
    gh.factory<_i1050.UpdateNoteUseCase>(
      () => _i1050.UpdateNoteUseCase(gh<_i415.NotesRepository>()),
    );
    gh.factory<_i520.GetAllNotesUseCase>(
      () => _i520.GetAllNotesUseCase(gh<_i415.NotesRepository>()),
    );
    gh.factory<_i949.StopRecordingUseCase>(
      () => _i949.StopRecordingUseCase(gh<_i276.AudioRepository>()),
    );
    gh.factory<_i314.OpenAppSettingsUseCase>(
      () => _i314.OpenAppSettingsUseCase(gh<_i276.AudioRepository>()),
    );
    gh.factory<_i755.ProcessTranscriptionUseCase>(
      () => _i755.ProcessTranscriptionUseCase(gh<_i276.AudioRepository>()),
    );
    gh.factory<_i719.StartRecordingUseCase>(
      () => _i719.StartRecordingUseCase(gh<_i276.AudioRepository>()),
    );
    gh.factory<_i685.RequestMicrophonePermissionUseCase>(
      () =>
          _i685.RequestMicrophonePermissionUseCase(gh<_i276.AudioRepository>()),
    );
    gh.factory<_i636.CheckMicrophonePermissionUseCase>(
      () => _i636.CheckMicrophonePermissionUseCase(gh<_i276.AudioRepository>()),
    );
    gh.factory<_i820.TranscribeAudioUseCase>(
      () => _i820.TranscribeAudioUseCase(gh<_i276.AudioRepository>()),
    );
    gh.factory<_i1073.NotesCubit>(
      () => _i1073.NotesCubit(
        gh<_i520.GetAllNotesUseCase>(),
        gh<_i661.SearchNotesUseCase>(),
        gh<_i783.CreateNoteUseCase>(),
        gh<_i1050.UpdateNoteUseCase>(),
        gh<_i732.DeleteNoteUseCase>(),
      ),
    );
    gh.factory<_i198.RecordingCubit>(
      () => _i198.RecordingCubit(
        gh<_i636.CheckMicrophonePermissionUseCase>(),
        gh<_i685.RequestMicrophonePermissionUseCase>(),
        gh<_i719.StartRecordingUseCase>(),
        gh<_i949.StopRecordingUseCase>(),
        gh<_i820.TranscribeAudioUseCase>(),
        gh<_i755.ProcessTranscriptionUseCase>(),
        gh<_i783.CreateNoteUseCase>(),
        gh<_i314.OpenAppSettingsUseCase>(),
      ),
    );
    return this;
  }
}

class _$RegisterModule extends _i291.RegisterModule {}
