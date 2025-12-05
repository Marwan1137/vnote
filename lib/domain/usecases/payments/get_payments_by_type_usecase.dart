import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:vnote/core/errors/failures.dart';
import 'package:vnote/domain/entities/payment.dart';
import 'package:vnote/domain/repositories/payments_repository.dart';
import '../usecase.dart';

class GetPaymentsByTypeParams {
  final PaymentType type;

  GetPaymentsByTypeParams(this.type);
}

@injectable
class GetPaymentsByTypeUseCase
    implements UseCase<List<Payment>, GetPaymentsByTypeParams> {
  final PaymentsRepository repository;

  GetPaymentsByTypeUseCase(this.repository);

  @override
  Future<Either<Failure, List<Payment>>> call(
    GetPaymentsByTypeParams params,
  ) async {
    return await repository.getPaymentsByType(params.type);
  }
}
