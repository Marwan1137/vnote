import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../domain/usecases/usecase.dart';
import '../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

class VerifyOTPParams {
  final String email;
  final String otp;

  VerifyOTPParams({required this.email, required this.otp});
}

@injectable
class VerifyOTPUseCase implements UseCase<bool, VerifyOTPParams> {
  final AuthRepository repository;

  VerifyOTPUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(VerifyOTPParams params) async {
    return await repository.verifyOTP(params.email, params.otp);
  }
}
