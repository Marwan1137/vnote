import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../core/errors/failures.dart';
import '../entities/processed_note.dart';
import '../repositories/audio_repository.dart';
import 'usecase.dart';

class ProcessTranscriptionParams {
  final String transcription;

  ProcessTranscriptionParams(this.transcription);
}

@injectable
class ProcessTranscriptionUseCase
    implements UseCase<ProcessedNote, ProcessTranscriptionParams> {
  final AudioRepository repository;

  ProcessTranscriptionUseCase(this.repository);

  @override
  Future<Either<Failure, ProcessedNote>> call(
    ProcessTranscriptionParams params,
  ) async {
    return await repository.processTranscription(params.transcription);
  }
}
