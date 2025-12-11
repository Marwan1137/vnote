import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../domain/usecases/usecase.dart';
import '../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

@injectable
class SendEmailVerificationUseCase implements UseCase<void, NoParams> {
  final AuthRepository repository;

  SendEmailVerificationUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    return await repository.sendEmailVerification();
  }
}
