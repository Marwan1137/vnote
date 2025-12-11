import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../core/services/auth_service.dart';
import '../../domain/entities/payment.dart';
import '../../domain/repositories/payments_repository.dart';
import '../datasources_contracts/payments_local_datasource.dart';
import '../models/payment_model.dart';

@LazySingleton(as: PaymentsRepository)
class PaymentsRepositoryImpl implements PaymentsRepository {
  final PaymentsLocalDataSource localDataSource;
  final AuthService authService;

  PaymentsRepositoryImpl(this.localDataSource, this.authService);

  @override
  Future<Either<Failure, List<Payment>>> getAllPayments() async {
    try {
      final userId = await authService.getCurrentUserId();
      final models = await localDataSource.getAllPayments(userId);
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
      final userId = await authService.getCurrentUserId();
      final model = await localDataSource.getPaymentById(id, userId);
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
      final userId = await authService.getCurrentUserId();
      await localDataSource.deletePayment(id, userId);
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
      final userId = await authService.getCurrentUserId();
      final models = await localDataSource.getPaymentsByMonth(
        year,
        month,
        userId,
      );
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
      final userId = await authService.getCurrentUserId();
      final models = await localDataSource.getPaymentsByType(type, userId);
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
      final userId = await authService.getCurrentUserId();
      final model = await localDataSource.getPaymentById(id, userId);
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
