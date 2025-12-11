import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../domain/usecases/usecase.dart';
import '../../../core/errors/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class SignUpParams {
  final String email;
  final String password;

  SignUpParams({required this.email, required this.password});
}

@injectable
class SignUpUseCase implements UseCase<User, SignUpParams> {
  final AuthRepository repository;

  SignUpUseCase(this.repository);

  @override
  Future<Either<Failure, User>> call(SignUpParams params) async {
    return await repository.signUpWithEmailAndPassword(
      params.email,
      params.password,
    );
  }
}
