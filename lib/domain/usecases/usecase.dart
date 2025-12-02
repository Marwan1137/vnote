import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';

/// Base UseCase interface
/// T: Return type
/// Params: Parameters type
abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

/// No parameters class for UseCases that don't need parameters
class NoParams {
  const NoParams();
}
