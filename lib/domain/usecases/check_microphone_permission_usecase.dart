import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../core/errors/failures.dart';
import '../repositories/audio_repository.dart';
import 'usecase.dart';

@injectable
class CheckMicrophonePermissionUseCase implements UseCase<bool, NoParams> {
  final AudioRepository repository;

  CheckMicrophonePermissionUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(NoParams params) async {
    return await repository.checkMicrophonePermission();
  }
}
