import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../domain/usecases/usecase.dart';
import '../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

class SendPasswordResetParams {
  final String email;

  SendPasswordResetParams({required this.email});
}

@injectable
class SendPasswordResetUseCase
    implements UseCase<void, SendPasswordResetParams> {
  final AuthRepository repository;

  SendPasswordResetUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(SendPasswordResetParams params) async {
    return await repository.sendPasswordResetEmail(params.email);
  }
}
