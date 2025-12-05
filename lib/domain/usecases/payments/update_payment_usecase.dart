import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:vnote/core/errors/failures.dart';
import 'package:vnote/domain/entities/payment.dart';
import 'package:vnote/domain/repositories/payments_repository.dart';
import '../usecase.dart';

@injectable
class UpdatePaymentUseCase implements UseCase<Payment, Payment> {
  final PaymentsRepository repository;

  UpdatePaymentUseCase(this.repository);

  @override
  Future<Either<Failure, Payment>> call(Payment params) async {
    return await repository.updatePayment(params);
  }
}
