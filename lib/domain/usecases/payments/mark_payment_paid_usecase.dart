import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:vnote/core/errors/failures.dart';
import 'package:vnote/domain/entities/payment.dart';
import 'package:vnote/domain/repositories/payments_repository.dart';
import '../usecase.dart';

class MarkPaymentPaidParams {
  final String id;

  MarkPaymentPaidParams(this.id);
}

@injectable
class MarkPaymentPaidUseCase
    implements UseCase<Payment, MarkPaymentPaidParams> {
  final PaymentsRepository repository;

  MarkPaymentPaidUseCase(this.repository);

  @override
  Future<Either<Failure, Payment>> call(MarkPaymentPaidParams params) async {
    return await repository.markPaymentPaid(params.id);
  }
}
