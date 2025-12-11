// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:firebase_auth/firebase_auth.dart' as _i59;
import 'package:get_it/get_it.dart' as _i174;
import 'package:hive/hive.dart' as _i979;
import 'package:injectable/injectable.dart' as _i526;

import '../../data/auth/datasources/auth_remote_datasource.dart' as _i691;
import '../../data/auth/datasources/auth_remote_datasource_impl.dart' as _i364;
import '../../data/auth/repositories/auth_repository_impl.dart' as _i388;
import '../../data/datasource_impl/audio_local_datasource_impl.dart' as _i171;
import '../../data/datasource_impl/event_llm_datasource_impl.dart' as _i929;
import '../../data/datasource_impl/events_local_datasource_impl.dart' as _i828;
import '../../data/datasource_impl/llm_datasource_impl.dart' as _i934;
import '../../data/datasource_impl/notes_local_datasource_impl.dart' as _i698;
import '../../data/datasource_impl/payment_llm_datasource_impl.dart' as _i815;
import '../../data/datasource_impl/payments_local_datasource_impl.dart' as _i99;
import '../../data/datasource_impl/transcription_datasource_impl.dart' as _i231;
import '../../data/datasources_contracts/audio_local_datasource.dart' as _i625;
import '../../data/datasources_contracts/event_llm_datasource.dart' as _i323;
import '../../data/datasources_contracts/events_local_datasource.dart' as _i147;
import '../../data/datasources_contracts/llm_datasource.dart' as _i801;
import '../../data/datasources_contracts/notes_local_datasource.dart' as _i929;
import '../../data/datasources_contracts/payment_llm_datasource.dart' as _i892;
import '../../data/datasources_contracts/payments_local_datasource.dart'
    as _i465;
import '../../data/datasources_contracts/transcription_datasource.dart'
    as _i217;
import '../../data/models/event_model.dart' as _i270;
import '../../data/models/note_model.dart' as _i1073;
import '../../data/models/payment_model.dart' as _i293;
import '../../data/repositories/audio_repository_impl.dart' as _i425;
import '../../data/repositories/events_repository_impl.dart' as _i669;
import '../../data/repositories/notes_repository_impl.dart' as _i252;
import '../../data/repositories/payments_repository_impl.dart' as _i156;
import '../../domain/repositories/audio_repository.dart' as _i276;
import '../../domain/repositories/events_repository.dart' as _i126;
import '../../domain/repositories/notes_repository.dart' as _i415;
import '../../domain/repositories/payments_repository.dart' as _i1037;
import '../../domain/usecases/check_microphone_permission_usecase.dart'
    as _i636;
import '../../domain/usecases/create_note_usecase.dart' as _i783;
import '../../domain/usecases/delete_note_usecase.dart' as _i732;
import '../../domain/usecases/events/create_event_usecase.dart' as _i603;
import '../../domain/usecases/events/delete_event_usecase.dart' as _i813;
import '../../domain/usecases/events/get_all_events_usecase.dart' as _i56;
import '../../domain/usecases/events/get_event_by_id_usecase.dart' as _i363;
import '../../domain/usecases/events/get_events_by_date_usecase.dart' as _i428;
import '../../domain/usecases/events/get_events_by_month_usecase.dart' as _i723;
import '../../domain/usecases/events/get_upcoming_events_usecase.dart' as _i889;
import '../../domain/usecases/events/mark_event_cancelled_usecase.dart'
    as _i906;
import '../../domain/usecases/events/mark_event_completed_usecase.dart'
    as _i261;
import '../../domain/usecases/events/process_event_transcription_usecase.dart'
    as _i456;
import '../../domain/usecases/events/update_event_usecase.dart' as _i829;
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
import '../../presentation/auth/cubit/auth_cubit.dart' as _i1063;
import '../../presentation/cubit/events/events_cubit.dart' as _i761;
import '../../presentation/cubit/notes/notes_cubit.dart' as _i1073;
import '../../presentation/cubit/payments/payments_cubit.dart' as _i72;
import '../../presentation/cubit/recording/recording_cubit.dart' as _i198;
import '../auth/repositories/auth_repository.dart' as _i964;
import '../auth/usecases/check_email_verification_usecase.dart' as _i339;
import '../auth/usecases/get_current_user_usecase.dart' as _i936;
import '../auth/usecases/is_email_registered_usecase.dart' as _i382;
import '../auth/usecases/reload_user_usecase.dart' as _i207;
import '../auth/usecases/reset_password_usecase.dart' as _i388;
import '../auth/usecases/send_email_verification_usecase.dart' as _i352;
import '../auth/usecases/send_password_reset_usecase.dart' as _i880;
import '../auth/usecases/sign_in_usecase.dart' as _i136;
import '../auth/usecases/sign_out_usecase.dart' as _i185;
import '../auth/usecases/sign_up_usecase.dart' as _i819;
import '../auth/usecases/verify_otp_usecase.dart' as _i896;
import '../services/auth_service.dart' as _i745;
import '../services/data_migration_service.dart' as _i223;
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
    gh.lazySingleton<_i59.FirebaseAuth>(() => registerModule.firebaseAuth);
    gh.lazySingleton<_i854.OnboardingService>(() => _i854.OnboardingService());
    gh.lazySingleton<_i979.Box<_i270.EventModel>>(
      () => registerModule.eventsBox,
      instanceName: 'eventsBox',
    );
    gh.lazySingleton<_i217.TranscriptionDataSource>(
        () => _i231.TranscriptionDataSourceImpl());
    gh.lazySingleton<_i979.Box<_i293.PaymentModel>>(
      () => registerModule.paymentsBox,
      instanceName: 'paymentsBox',
    );
    gh.lazySingleton<_i625.AudioLocalDataSource>(
        () => _i171.AudioLocalDataSourceImpl());
    gh.lazySingleton<_i465.PaymentsLocalDataSource>(() =>
        _i99.PaymentsLocalDataSourceImpl(
            gh<_i979.Box<_i293.PaymentModel>>(instanceName: 'paymentsBox')));
    gh.lazySingleton<_i147.EventsLocalDataSource>(() =>
        _i828.EventsLocalDataSourceImpl(
            gh<_i979.Box<_i270.EventModel>>(instanceName: 'eventsBox')));
    gh.lazySingleton<_i801.LLMDataSource>(() => _i934.LLMDataSourceImpl());
    gh.lazySingleton<_i892.PaymentLLMDataSource>(
        () => _i815.PaymentLLMDataSourceImpl());
    gh.lazySingleton<_i979.Box<_i1073.NoteModel>>(
      () => registerModule.notesBox,
      instanceName: 'notesBox',
    );
    gh.lazySingleton<_i323.EventLLMDataSource>(
        () => _i929.EventLLMDataSourceImpl());
    gh.factory<_i456.ProcessEventTranscriptionUseCase>(() =>
        _i456.ProcessEventTranscriptionUseCase(gh<_i323.EventLLMDataSource>()));
    gh.lazySingleton<_i276.AudioRepository>(() => _i425.AudioRepositoryImpl(
          gh<_i625.AudioLocalDataSource>(),
          gh<_i217.TranscriptionDataSource>(),
          gh<_i801.LLMDataSource>(),
        ));
    gh.lazySingleton<_i691.AuthRemoteDataSource>(
        () => _i364.AuthRemoteDataSourceImpl(gh<_i59.FirebaseAuth>()));
    gh.lazySingleton<_i964.AuthRepository>(
        () => _i388.AuthRepositoryImpl(gh<_i691.AuthRemoteDataSource>()));
    gh.lazySingleton<_i929.NotesLocalDataSource>(() =>
        _i698.NotesLocalDataSourceImpl(
            gh<_i979.Box<_i1073.NoteModel>>(instanceName: 'notesBox')));
    gh.factory<_i483.ProcessPaymentTranscriptionUseCase>(() =>
        _i483.ProcessPaymentTranscriptionUseCase(
            gh<_i892.PaymentLLMDataSource>()));
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
    gh.factory<_i382.IsEmailRegisteredUseCase>(
        () => _i382.IsEmailRegisteredUseCase(gh<_i964.AuthRepository>()));
    gh.factory<_i388.ResetPasswordUseCase>(
        () => _i388.ResetPasswordUseCase(gh<_i964.AuthRepository>()));
    gh.factory<_i880.SendPasswordResetUseCase>(
        () => _i880.SendPasswordResetUseCase(gh<_i964.AuthRepository>()));
    gh.factory<_i136.SignInUseCase>(
        () => _i136.SignInUseCase(gh<_i964.AuthRepository>()));
    gh.factory<_i339.CheckEmailVerificationUseCase>(
        () => _i339.CheckEmailVerificationUseCase(gh<_i964.AuthRepository>()));
    gh.factory<_i819.SignUpUseCase>(
        () => _i819.SignUpUseCase(gh<_i964.AuthRepository>()));
    gh.factory<_i352.SendEmailVerificationUseCase>(
        () => _i352.SendEmailVerificationUseCase(gh<_i964.AuthRepository>()));
    gh.factory<_i936.GetCurrentUserUseCase>(
        () => _i936.GetCurrentUserUseCase(gh<_i964.AuthRepository>()));
    gh.factory<_i207.ReloadUserUseCase>(
        () => _i207.ReloadUserUseCase(gh<_i964.AuthRepository>()));
    gh.factory<_i896.VerifyOTPUseCase>(
        () => _i896.VerifyOTPUseCase(gh<_i964.AuthRepository>()));
    gh.factory<_i185.SignOutUseCase>(
        () => _i185.SignOutUseCase(gh<_i964.AuthRepository>()));
    gh.lazySingleton<_i745.AuthService>(
        () => _i745.AuthService(gh<_i936.GetCurrentUserUseCase>()));
    gh.lazySingleton<_i1037.PaymentsRepository>(
        () => _i156.PaymentsRepositoryImpl(
              gh<_i465.PaymentsLocalDataSource>(),
              gh<_i745.AuthService>(),
            ));
    gh.lazySingleton<_i223.DataMigrationService>(
        () => _i223.DataMigrationService(gh<_i745.AuthService>()));
    gh.lazySingleton<_i415.NotesRepository>(() => _i252.NotesRepositoryImpl(
          gh<_i929.NotesLocalDataSource>(),
          gh<_i745.AuthService>(),
        ));
    gh.factory<_i1063.AuthCubit>(() => _i1063.AuthCubit(
          gh<_i136.SignInUseCase>(),
          gh<_i819.SignUpUseCase>(),
          gh<_i185.SignOutUseCase>(),
          gh<_i880.SendPasswordResetUseCase>(),
          gh<_i896.VerifyOTPUseCase>(),
          gh<_i388.ResetPasswordUseCase>(),
          gh<_i352.SendEmailVerificationUseCase>(),
          gh<_i339.CheckEmailVerificationUseCase>(),
          gh<_i936.GetCurrentUserUseCase>(),
          gh<_i382.IsEmailRegisteredUseCase>(),
          gh<_i207.ReloadUserUseCase>(),
        ));
    gh.lazySingleton<_i126.EventsRepository>(() => _i669.EventsRepositoryImpl(
          gh<_i147.EventsLocalDataSource>(),
          gh<_i745.AuthService>(),
        ));
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
    gh.factory<_i198.RecordingCubit>(() => _i198.RecordingCubit(
          gh<_i636.CheckMicrophonePermissionUseCase>(),
          gh<_i685.RequestMicrophonePermissionUseCase>(),
          gh<_i719.StartRecordingUseCase>(),
          gh<_i949.StopRecordingUseCase>(),
          gh<_i820.TranscribeAudioUseCase>(),
          gh<_i755.ProcessTranscriptionUseCase>(),
          gh<_i783.CreateNoteUseCase>(),
          gh<_i314.OpenAppSettingsUseCase>(),
          gh<_i745.AuthService>(),
        ));
    gh.factory<_i72.PaymentsCubit>(() => _i72.PaymentsCubit(
          gh<_i309.GetAllPaymentsUseCase>(),
          gh<_i326.GetPaymentsByMonthUseCase>(),
          gh<_i310.GetPaymentsByTypeUseCase>(),
          gh<_i489.CreatePaymentUseCase>(),
          gh<_i281.UpdatePaymentUseCase>(),
          gh<_i137.DeletePaymentUseCase>(),
          gh<_i251.MarkPaymentPaidUseCase>(),
          gh<_i483.ProcessPaymentTranscriptionUseCase>(),
          gh<_i745.AuthService>(),
        ));
    gh.factory<_i889.GetUpcomingEventsUseCase>(
        () => _i889.GetUpcomingEventsUseCase(gh<_i126.EventsRepository>()));
    gh.factory<_i906.MarkEventCancelledUseCase>(
        () => _i906.MarkEventCancelledUseCase(gh<_i126.EventsRepository>()));
    gh.factory<_i829.UpdateEventUseCase>(
        () => _i829.UpdateEventUseCase(gh<_i126.EventsRepository>()));
    gh.factory<_i363.GetEventByIdUseCase>(
        () => _i363.GetEventByIdUseCase(gh<_i126.EventsRepository>()));
    gh.factory<_i723.GetEventsByMonthUseCase>(
        () => _i723.GetEventsByMonthUseCase(gh<_i126.EventsRepository>()));
    gh.factory<_i261.MarkEventCompletedUseCase>(
        () => _i261.MarkEventCompletedUseCase(gh<_i126.EventsRepository>()));
    gh.factory<_i428.GetEventsByDateUseCase>(
        () => _i428.GetEventsByDateUseCase(gh<_i126.EventsRepository>()));
    gh.factory<_i56.GetAllEventsUseCase>(
        () => _i56.GetAllEventsUseCase(gh<_i126.EventsRepository>()));
    gh.factory<_i813.DeleteEventUseCase>(
        () => _i813.DeleteEventUseCase(gh<_i126.EventsRepository>()));
    gh.factory<_i603.CreateEventUseCase>(
        () => _i603.CreateEventUseCase(gh<_i126.EventsRepository>()));
    gh.factory<_i1073.NotesCubit>(() => _i1073.NotesCubit(
          gh<_i520.GetAllNotesUseCase>(),
          gh<_i661.SearchNotesUseCase>(),
          gh<_i783.CreateNoteUseCase>(),
          gh<_i1050.UpdateNoteUseCase>(),
          gh<_i732.DeleteNoteUseCase>(),
        ));
    gh.factory<_i761.EventsCubit>(() => _i761.EventsCubit(
          gh<_i56.GetAllEventsUseCase>(),
          gh<_i723.GetEventsByMonthUseCase>(),
          gh<_i428.GetEventsByDateUseCase>(),
          gh<_i889.GetUpcomingEventsUseCase>(),
          gh<_i603.CreateEventUseCase>(),
          gh<_i829.UpdateEventUseCase>(),
          gh<_i813.DeleteEventUseCase>(),
          gh<_i261.MarkEventCompletedUseCase>(),
          gh<_i906.MarkEventCancelledUseCase>(),
          gh<_i456.ProcessEventTranscriptionUseCase>(),
          gh<_i745.AuthService>(),
        ));
    return this;
  }
}

class _$RegisterModule extends _i291.RegisterModule {}
