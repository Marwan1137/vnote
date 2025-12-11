import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../domain/usecases/usecase.dart';
import '../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

class ResetPasswordParams {
  final String email;
  final String otp;
  final String newPassword;

  ResetPasswordParams({
    required this.email,
    required this.otp,
    required this.newPassword,
  });
}

@injectable
class ResetPasswordUseCase implements UseCase<void, ResetPasswordParams> {
  final AuthRepository repository;

  ResetPasswordUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(ResetPasswordParams params) async {
    return await repository.resetPasswordWithOTP(
      params.email,
      params.otp,
      params.newPassword,
    );
  }
}
