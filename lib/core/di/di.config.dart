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

import '../../data/datasource_impl/audio_local_datasource_impl.dart' as _i171;
import '../../data/datasource_impl/llm_datasource_impl.dart' as _i934;
import '../../data/datasource_impl/notes_local_datasource_impl.dart' as _i698;
import '../../data/datasource_impl/transcription_datasource_impl.dart' as _i231;
import '../../data/datasources/payment_llm_datasource.dart' as _i434;
import '../../data/datasources/payment_llm_datasource_impl.dart' as _i939;
import '../../data/datasources/payments_local_datasource.dart' as _i1064;
import '../../data/datasources/payments_local_datasource_impl.dart' as _i693;
import '../../data/datasources_contracts/audio_local_datasource.dart' as _i625;
import '../../data/datasources_contracts/llm_datasource.dart' as _i801;
import '../../data/datasources_contracts/notes_local_datasource.dart' as _i929;
import '../../data/datasources_contracts/transcription_datasource.dart'
    as _i217;
import '../../data/models/note_model.dart' as _i1073;
import '../../data/models/payment_model.dart' as _i293;
import '../../data/repositories/audio_repository_impl.dart' as _i425;
import '../../data/repositories/notes_repository_impl.dart' as _i252;
import '../../data/repositories/payments_repository_impl.dart' as _i156;
import '../../domain/repositories/audio_repository.dart' as _i276;
import '../../domain/repositories/notes_repository.dart' as _i415;
import '../../domain/repositories/payments_repository.dart' as _i1037;
import '../../domain/usecases/check_microphone_permission_usecase.dart'
    as _i636;
import '../../domain/usecases/create_note_usecase.dart' as _i783;
import '../../domain/usecases/delete_note_usecase.dart' as _i732;
import '../../domain/usecases/get_all_notes_usecase.dart' as _i520;
import '../../domain/usecases/get_favorite_notes_usecase.dart' as _i120;
import '../../domain/usecases/get_note_by_id_usecase.dart' as _i219;
import '../../domain/usecases/open_app_settings_usecase.dart' as _i314;
import '../../domain/usecases/payments/create_payment_usecase.dart' as _i489;
import '../../domain/usecases/payments/delete_payment_usecase.dart' as _i137;
import '../../domain/usecases/payments/get_all_payments_usecase.dart' as _i309;
import '../../domain/usecases/payments/get_payment_by_id_usecase.dart' as _i798;
import '../../domain/usecases/payments/get_payments_by_month_usecase.dart'
    as _i326;
import '../../domain/usecases/payments/get_payments_by_type_usecase.dart'
    as _i310;
import '../../domain/usecases/payments/mark_payment_paid_usecase.dart' as _i251;
import '../../domain/usecases/payments/process_payment_transcription_usecase.dart'
    as _i483;
import '../../domain/usecases/payments/update_payment_usecase.dart' as _i281;
import '../../domain/usecases/process_transcription_usecase.dart' as _i755;
import '../../domain/usecases/request_microphone_permission_usecase.dart'
    as _i685;
import '../../domain/usecases/search_notes_usecase.dart' as _i661;
import '../../domain/usecases/start_recording_usecase.dart' as _i719;
import '../../domain/usecases/stop_recording_usecase.dart' as _i949;
import '../../domain/usecases/transcribe_audio_usecase.dart' as _i820;
import '../../domain/usecases/update_note_usecase.dart' as _i1050;
import '../../presentation/cubit/notes/notes_cubit.dart' as _i1073;
import '../../presentation/cubit/payments/payments_cubit.dart' as _i72;
import '../../presentation/cubit/recording/recording_cubit.dart' as _i198;
import '../services/onboarding_service.dart' as _i854;
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
    gh.lazySingleton<_i854.OnboardingService>(() => _i854.OnboardingService());
    gh.lazySingleton<_i434.PaymentLLMDataSource>(
        () => _i939.PaymentLLMDataSourceImpl());
    gh.lazySingleton<_i217.TranscriptionDataSource>(
        () => _i231.TranscriptionDataSourceImpl());
    gh.lazySingleton<_i979.Box<_i293.PaymentModel>>(
      () => registerModule.paymentsBox,
      instanceName: 'paymentsBox',
    );
    gh.lazySingleton<_i625.AudioLocalDataSource>(
        () => _i171.AudioLocalDataSourceImpl());
    gh.lazySingleton<_i1064.PaymentsLocalDataSource>(() =>
        _i693.PaymentsLocalDataSourceImpl(
            gh<_i979.Box<_i293.PaymentModel>>(instanceName: 'paymentsBox')));
    gh.lazySingleton<_i1037.PaymentsRepository>(() =>
        _i156.PaymentsRepositoryImpl(gh<_i1064.PaymentsLocalDataSource>()));
    gh.lazySingleton<_i801.LLMDataSource>(() => _i934.LLMDataSourceImpl());
    gh.lazySingleton<_i979.Box<_i1073.NoteModel>>(
      () => registerModule.notesBox,
      instanceName: 'notesBox',
    );
    gh.lazySingleton<_i276.AudioRepository>(() => _i425.AudioRepositoryImpl(
          gh<_i625.AudioLocalDataSource>(),
          gh<_i217.TranscriptionDataSource>(),
          gh<_i801.LLMDataSource>(),
        ));
    gh.factory<_i483.ProcessPaymentTranscriptionUseCase>(() =>
        _i483.ProcessPaymentTranscriptionUseCase(
            gh<_i434.PaymentLLMDataSource>()));
    gh.factory<_i309.GetAllPaymentsUseCase>(
        () => _i309.GetAllPaymentsUseCase(gh<_i1037.PaymentsRepository>()));
    gh.factory<_i310.GetPaymentsByTypeUseCase>(
        () => _i310.GetPaymentsByTypeUseCase(gh<_i1037.PaymentsRepository>()));
    gh.factory<_i798.GetPaymentByIdUseCase>(
        () => _i798.GetPaymentByIdUseCase(gh<_i1037.PaymentsRepository>()));
    gh.factory<_i326.GetPaymentsByMonthUseCase>(
        () => _i326.GetPaymentsByMonthUseCase(gh<_i1037.PaymentsRepository>()));
    gh.factory<_i137.DeletePaymentUseCase>(
        () => _i137.DeletePaymentUseCase(gh<_i1037.PaymentsRepository>()));
    gh.factory<_i251.MarkPaymentPaidUseCase>(
        () => _i251.MarkPaymentPaidUseCase(gh<_i1037.PaymentsRepository>()));
    gh.factory<_i281.UpdatePaymentUseCase>(
        () => _i281.UpdatePaymentUseCase(gh<_i1037.PaymentsRepository>()));
    gh.factory<_i489.CreatePaymentUseCase>(
        () => _i489.CreatePaymentUseCase(gh<_i1037.PaymentsRepository>()));
    gh.lazySingleton<_i929.NotesLocalDataSource>(() =>
        _i698.NotesLocalDataSourceImpl(
            gh<_i979.Box<_i1073.NoteModel>>(instanceName: 'notesBox')));
    gh.lazySingleton<_i415.NotesRepository>(
        () => _i252.NotesRepositoryImpl(gh<_i929.NotesLocalDataSource>()));
    gh.factory<_i783.CreateNoteUseCase>(
        () => _i783.CreateNoteUseCase(gh<_i415.NotesRepository>()));
    gh.factory<_i219.GetNoteByIdUseCase>(
        () => _i219.GetNoteByIdUseCase(gh<_i415.NotesRepository>()));
    gh.factory<_i732.DeleteNoteUseCase>(
        () => _i732.DeleteNoteUseCase(gh<_i415.NotesRepository>()));
    gh.factory<_i120.GetFavoriteNotesUseCase>(
        () => _i120.GetFavoriteNotesUseCase(gh<_i415.NotesRepository>()));
    gh.factory<_i661.SearchNotesUseCase>(
        () => _i661.SearchNotesUseCase(gh<_i415.NotesRepository>()));
    gh.factory<_i1050.UpdateNoteUseCase>(
        () => _i1050.UpdateNoteUseCase(gh<_i415.NotesRepository>()));
    gh.factory<_i520.GetAllNotesUseCase>(
        () => _i520.GetAllNotesUseCase(gh<_i415.NotesRepository>()));
    gh.factory<_i72.PaymentsCubit>(() => _i72.PaymentsCubit(
          gh<_i309.GetAllPaymentsUseCase>(),
          gh<_i326.GetPaymentsByMonthUseCase>(),
          gh<_i310.GetPaymentsByTypeUseCase>(),
          gh<_i489.CreatePaymentUseCase>(),
          gh<_i281.UpdatePaymentUseCase>(),
          gh<_i137.DeletePaymentUseCase>(),
          gh<_i251.MarkPaymentPaidUseCase>(),
          gh<_i483.ProcessPaymentTranscriptionUseCase>(),
        ));
    gh.factory<_i949.StopRecordingUseCase>(
        () => _i949.StopRecordingUseCase(gh<_i276.AudioRepository>()));
    gh.factory<_i314.OpenAppSettingsUseCase>(
        () => _i314.OpenAppSettingsUseCase(gh<_i276.AudioRepository>()));
    gh.factory<_i755.ProcessTranscriptionUseCase>(
        () => _i755.ProcessTranscriptionUseCase(gh<_i276.AudioRepository>()));
    gh.factory<_i719.StartRecordingUseCase>(
        () => _i719.StartRecordingUseCase(gh<_i276.AudioRepository>()));
    gh.factory<_i820.TranscribeAudioUseCase>(
        () => _i820.TranscribeAudioUseCase(gh<_i276.AudioRepository>()));
    gh.factory<_i685.RequestMicrophonePermissionUseCase>(() =>
        _i685.RequestMicrophonePermissionUseCase(gh<_i276.AudioRepository>()));
    gh.factory<_i636.CheckMicrophonePermissionUseCase>(() =>
        _i636.CheckMicrophonePermissionUseCase(gh<_i276.AudioRepository>()));
    gh.factory<_i1073.NotesCubit>(() => _i1073.NotesCubit(
          gh<_i520.GetAllNotesUseCase>(),
          gh<_i661.SearchNotesUseCase>(),
          gh<_i783.CreateNoteUseCase>(),
          gh<_i1050.UpdateNoteUseCase>(),
          gh<_i732.DeleteNoteUseCase>(),
        ));
    gh.factory<_i198.RecordingCubit>(() => _i198.RecordingCubit(
          gh<_i636.CheckMicrophonePermissionUseCase>(),
          gh<_i685.RequestMicrophonePermissionUseCase>(),
          gh<_i719.StartRecordingUseCase>(),
          gh<_i949.StopRecordingUseCase>(),
          gh<_i820.TranscribeAudioUseCase>(),
          gh<_i755.ProcessTranscriptionUseCase>(),
          gh<_i783.CreateNoteUseCase>(),
          gh<_i314.OpenAppSettingsUseCase>(),
        ));
    return this;
  }
}

class _$RegisterModule extends _i291.RegisterModule {}
