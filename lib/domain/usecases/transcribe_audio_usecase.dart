import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../core/errors/failures.dart';
import '../repositories/audio_repository.dart';
import 'transcribe_audio_params.dart';
import 'usecase.dart';

@injectable
class TranscribeAudioUseCase implements UseCase<String, TranscribeAudioParams> {
  final AudioRepository repository;

  TranscribeAudioUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(TranscribeAudioParams params) async {
    return await repository.transcribeAudio(
      params.audioPath,
      languageCode: params.languageCode,
      alternativeLanguageCodes: params.alternativeLanguageCodes,
    );
  }
}
