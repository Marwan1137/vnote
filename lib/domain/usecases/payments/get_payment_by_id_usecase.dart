import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../core/errors/failures.dart';
import '../../../domain/entities/payment.dart';
import '../../../domain/repositories/payments_repository.dart';
import '../usecase.dart';

class GetPaymentByIdParams {
  final String id;

  GetPaymentByIdParams(this.id);
}

@injectable
class GetPaymentByIdUseCase implements UseCase<Payment, GetPaymentByIdParams> {
  final PaymentsRepository repository;

  GetPaymentByIdUseCase(this.repository);

  @override
  Future<Either<Failure, Payment>> call(GetPaymentByIdParams params) async {
    return await repository.getPaymentById(params.id);
  }
}
