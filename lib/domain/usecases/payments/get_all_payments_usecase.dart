import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../core/errors/failures.dart';
import '../../../domain/entities/payment.dart';
import '../../../domain/repositories/payments_repository.dart';
import '../usecase.dart';

@injectable
class GetAllPaymentsUseCase implements UseCase<List<Payment>, NoParams> {
  final PaymentsRepository repository;

  GetAllPaymentsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Payment>>> call(NoParams params) async {
    return await repository.getAllPayments();
  }
}
