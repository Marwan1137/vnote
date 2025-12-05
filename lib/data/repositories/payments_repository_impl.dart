import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/payment.dart';
import '../../domain/repositories/payments_repository.dart';
import '../datasources/payments_local_datasource.dart';
import '../models/payment_model.dart';

@LazySingleton(as: PaymentsRepository)
class PaymentsRepositoryImpl implements PaymentsRepository {
  final PaymentsLocalDataSource localDataSource;

  PaymentsRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, List<Payment>>> getAllPayments() async {
    try {
      final models = await localDataSource.getAllPayments();
      final payments = models.map((model) => model.toEntity()).toList();
      return Right(payments);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Payment>> getPaymentById(String id) async {
    try {
      final model = await localDataSource.getPaymentById(id);
      if (model == null) {
        return Left(CacheFailure('Payment not found'));
      }
      return Right(model.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Payment>> createPayment(Payment payment) async {
    try {
      final model = PaymentModel.fromEntity(payment);
      final created = await localDataSource.createPayment(model);
      return Right(created.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Payment>> updatePayment(Payment payment) async {
    try {
      final model = PaymentModel.fromEntity(payment);
      final updated = await localDataSource.updatePayment(model);
      return Right(updated.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deletePayment(String id) async {
    try {
      await localDataSource.deletePayment(id);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Payment>>> getPaymentsByMonth(
    int year,
    int month,
  ) async {
    try {
      final models = await localDataSource.getPaymentsByMonth(year, month);
      final payments = models.map((model) => model.toEntity()).toList();
      return Right(payments);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Payment>>> getPaymentsByType(
    PaymentType type,
  ) async {
    try {
      final models = await localDataSource.getPaymentsByType(type);
      final payments = models.map((model) => model.toEntity()).toList();
      return Right(payments);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Payment>> markPaymentPaid(String id) async {
    try {
      final model = await localDataSource.getPaymentById(id);
      if (model == null) {
        return Left(CacheFailure('Payment not found'));
      }

      final updatedModel = model.copyWith(
        status: 3, // PaymentStatus.paid
        paymentDate: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final updated = await localDataSource.updatePayment(updatedModel);
      return Right(updated.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Unexpected error: $e'));
    }
  }
}
