import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../core/errors/failures.dart';
import '../repositories/audio_repository.dart';
import 'usecase.dart';

@injectable
class StartRecordingUseCase implements UseCase<String, NoParams> {
  final AudioRepository repository;

  StartRecordingUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(NoParams params) async {
    return await repository.startRecording();
  }
}
