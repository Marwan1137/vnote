import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../core/errors/failures.dart';
import '../entities/recording.dart';
import '../repositories/audio_repository.dart';
import 'usecase.dart';

class StopRecordingParams {
  final String audioPath;

  StopRecordingParams(this.audioPath);
}

@injectable
class StopRecordingUseCase implements UseCase<Recording, StopRecordingParams> {
  final AudioRepository repository;

  StopRecordingUseCase(this.repository);

  @override
  Future<Either<Failure, Recording>> call(StopRecordingParams params) async {
    return await repository.stopRecording(params.audioPath);
  }
}
