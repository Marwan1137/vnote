import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../domain/usecases/usecase.dart';
import '../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

class IsEmailRegisteredParams {
  final String email;

  IsEmailRegisteredParams({required this.email});
}

@injectable
class IsEmailRegisteredUseCase
    implements UseCase<bool, IsEmailRegisteredParams> {
  final AuthRepository repository;

  IsEmailRegisteredUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(IsEmailRegisteredParams params) async {
    return await repository.isEmailRegistered(params.email);
  }
}
