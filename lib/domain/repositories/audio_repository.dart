import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/recording.dart';
import '../entities/processed_note.dart';

abstract class AudioRepository {
  Future<Either<Failure, String>> startRecording();
  Future<Either<Failure, Recording>> stopRecording(String audioPath);
  Future<Either<Failure, String>> transcribeAudio(
    String audioPath, {
    String? languageCode,
    List<String>? alternativeLanguageCodes,
  });
  Future<Either<Failure, ProcessedNote>> processTranscription(
    String transcription,
  );
  Future<Either<Failure, bool>> checkMicrophonePermission();
  Future<Either<Failure, bool>> requestMicrophonePermission();
  Future<Either<Failure, bool>> openAppSettings();
}
