import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:vnote/core/errors/failures.dart';
import 'package:vnote/domain/entities/payment.dart';
import 'package:vnote/domain/repositories/payments_repository.dart';
import '../usecase.dart';

@injectable
class CreatePaymentUseCase implements UseCase<Payment, Payment> {
  final PaymentsRepository repository;

  CreatePaymentUseCase(this.repository);

  @override
  Future<Either<Failure, Payment>> call(Payment params) async {
    return await repository.createPayment(params);
  }
}
