import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:vnote/core/errors/failures.dart';
import 'package:vnote/domain/entities/payment.dart';
import 'package:vnote/domain/repositories/payments_repository.dart';
import '../usecase.dart';

class GetPaymentsByMonthParams {
  final int year;
  final int month;

  GetPaymentsByMonthParams(this.year, this.month);
}

@injectable
class GetPaymentsByMonthUseCase
    implements UseCase<List<Payment>, GetPaymentsByMonthParams> {
  final PaymentsRepository repository;

  GetPaymentsByMonthUseCase(this.repository);

  @override
  Future<Either<Failure, List<Payment>>> call(
    GetPaymentsByMonthParams params,
  ) async {
    return await repository.getPaymentsByMonth(params.year, params.month);
  }
}
