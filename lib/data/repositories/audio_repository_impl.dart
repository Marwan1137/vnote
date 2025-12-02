import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/processed_note.dart';
import '../../domain/entities/recording.dart';
import '../../domain/repositories/audio_repository.dart';
import '../datasources/audio_local_datasource.dart';
import '../datasources/ollama_datasource.dart';
import '../datasources/transcription_datasource.dart';

@LazySingleton(as: AudioRepository)
class AudioRepositoryImpl implements AudioRepository {
  final AudioLocalDataSource audioDataSource;
  final TranscriptionDataSource transcriptionDataSource;
  final OllamaDataSource ollamaDataSource;

  AudioRepositoryImpl(
    this.audioDataSource,
    this.transcriptionDataSource,
    this.ollamaDataSource,
  );

  @override
  Future<Either<Failure, String>> startRecording() async {
    try {
      final path = await audioDataSource.startRecording();
      return Right(path);
    } on AudioPermissionException catch (e) {
      return Left(AudioPermissionFailure(e.message));
    } on RecordingException catch (e) {
      return Left(RecordingFailure(e.message));
    } catch (e) {
      return Left(RecordingFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Recording>> stopRecording(String audioPath) async {
    try {
      final path = await audioDataSource.stopRecording();
      final recording = Recording(
        id: const Uuid().v4(),
        audioPath: path,
        createdAt: DateTime.now(),
      );
      return Right(recording);
    } on RecordingException catch (e) {
      return Left(RecordingFailure(e.message));
    } catch (e) {
      return Left(RecordingFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> transcribeAudio(
    String audioPath, {
    String? languageCode,
    List<String>? alternativeLanguageCodes,
  }) async {
    try {
      // Initialize transcription service
      await transcriptionDataSource.initialize();

      // Transcribe the audio file
      // If languageCode is null, Google will auto-detect the language
      // alternativeLanguageCodes helps with better detection across multiple languages
      final transcription = await transcriptionDataSource.transcribeAudio(
        audioPath,
        languageCode: languageCode,
        alternativeLanguageCodes: alternativeLanguageCodes,
      );

      if (transcription.isEmpty) {
        return Left(
          TranscriptionFailure('Transcription returned empty result'),
        );
      }

      return Right(transcription);
    } on TranscriptionException catch (e) {
      return Left(TranscriptionFailure(e.message));
    } catch (e) {
      return Left(TranscriptionFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, ProcessedNote>> processTranscription(
    String transcription,
  ) async {
    try {
      final processedNote = await ollamaDataSource.processTranscription(
        transcription,
      );
      return Right(processedNote);
    } on LLMProcessingException catch (e) {
      return Left(LLMProcessingFailure(e.message));
    } on OllamaConnectionException catch (e) {
      return Left(OllamaConnectionFailure(e.message));
    } catch (e) {
      return Left(LLMProcessingFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> checkMicrophonePermission() async {
    try {
      final hasPermission = await audioDataSource.checkPermission();
      return Right(hasPermission);
    } catch (e) {
      return Left(AudioPermissionFailure('Failed to check permission: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> requestMicrophonePermission() async {
    try {
      final granted = await audioDataSource.requestPermission();
      return Right(granted);
    } on AudioPermissionException catch (e) {
      return Left(AudioPermissionFailure(e.message));
    } catch (e) {
      return Left(AudioPermissionFailure('Failed to request permission: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> openAppSettings() async {
    try {
      final opened = await audioDataSource.openAppSettings();
      return Right(opened);
    } catch (e) {
      return Left(AudioPermissionFailure('Failed to open settings: $e'));
    }
  }
}
