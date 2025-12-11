import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../domain/usecases/usecase.dart';
import '../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

class UpdatePasswordParams {
  final String currentPassword;
  final String newPassword;

  UpdatePasswordParams({
    required this.currentPassword,
    required this.newPassword,
  });
}

@injectable
class UpdatePasswordUseCase implements UseCase<void, UpdatePasswordParams> {
  final AuthRepository repository;

  UpdatePasswordUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdatePasswordParams params) async {
    return await repository.updatePassword(
      params.currentPassword,
      params.newPassword,
    );
  }
}
