import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../core/errors/failures.dart';
import '../../../domain/repositories/payments_repository.dart';
import '../usecase.dart';

class DeletePaymentParams {
  final String id;

  DeletePaymentParams(this.id);
}

@injectable
class DeletePaymentUseCase implements UseCase<void, DeletePaymentParams> {
  final PaymentsRepository repository;

  DeletePaymentUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeletePaymentParams params) async {
    return await repository.deletePayment(params.id);
  }
}
