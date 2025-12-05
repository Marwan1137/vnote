import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/payment.dart';

abstract class PaymentsRepository {
  Future<Either<Failure, List<Payment>>> getAllPayments();
  Future<Either<Failure, Payment>> getPaymentById(String id);
  Future<Either<Failure, Payment>> createPayment(Payment payment);
  Future<Either<Failure, Payment>> updatePayment(Payment payment);
  Future<Either<Failure, void>> deletePayment(String id);
  Future<Either<Failure, List<Payment>>> getPaymentsByMonth(
    int year,
    int month,
  );
  Future<Either<Failure, List<Payment>>> getPaymentsByType(PaymentType type);
  Future<Either<Failure, Payment>> markPaymentPaid(String id);
}
