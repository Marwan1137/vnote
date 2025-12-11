import 'package:hive/hive.dart';
import 'package:injectable/injectable.dart';
import '../../core/errors/exceptions.dart';
import '../../domain/entities/payment.dart';
import '../models/payment_model.dart';
import '../datasources_contracts/payments_local_datasource.dart';

@LazySingleton(as: PaymentsLocalDataSource)
class PaymentsLocalDataSourceImpl implements PaymentsLocalDataSource {
  @factoryMethod
  PaymentsLocalDataSourceImpl(@Named('paymentsBox') this.paymentsBox);

  final Box<PaymentModel> paymentsBox;

  @override
  Future<List<PaymentModel>> getAllPayments() async {
    try {
      return paymentsBox.values.toList()
        ..sort((a, b) => b.dueDate.compareTo(a.dueDate));
    } catch (e) {
      throw CacheException('Failed to get all payments: $e');
    }
  }

  @override
  Future<PaymentModel?> getPaymentById(String id) async {
    try {
      return paymentsBox.get(id);
    } catch (e) {
      throw CacheException('Failed to get payment by id: $e');
    }
  }

  @override
  Future<PaymentModel> createPayment(PaymentModel payment) async {
    try {
      await paymentsBox.put(payment.id, payment);
      return payment;
    } catch (e) {
      throw CacheException('Failed to create payment: $e');
    }
  }

  @override
  Future<PaymentModel> updatePayment(PaymentModel payment) async {
    try {
      await paymentsBox.put(payment.id, payment);
      return payment;
    } catch (e) {
      throw CacheException('Failed to update payment: $e');
    }
  }

  @override
  Future<void> deletePayment(String id) async {
    try {
      await paymentsBox.delete(id);
    } catch (e) {
      throw CacheException('Failed to delete payment: $e');
    }
  }

  @override
  Future<List<PaymentModel>> getPaymentsByMonth(int year, int month) async {
    try {
      return paymentsBox.values.where((payment) {
        return payment.dueDate.year == year && payment.dueDate.month == month;
      }).toList()..sort((a, b) => b.dueDate.compareTo(a.dueDate));
    } catch (e) {
      throw CacheException('Failed to get payments by month: $e');
    }
  }

  @override
  Future<List<PaymentModel>> getPaymentsByType(PaymentType type) async {
    try {
      final typeValue = type == PaymentType.toPay ? 0 : 1;
      return paymentsBox.values
          .where((payment) => payment.type == typeValue)
          .toList()
        ..sort((a, b) => b.dueDate.compareTo(a.dueDate));
    } catch (e) {
      throw CacheException('Failed to get payments by type: $e');
    }
  }
}
