import '../../domain/entities/payment.dart';
import '../models/payment_model.dart';

abstract class PaymentsLocalDataSource {
  Future<List<PaymentModel>> getAllPayments();
  Future<PaymentModel?> getPaymentById(String id);
  Future<PaymentModel> createPayment(PaymentModel payment);
  Future<PaymentModel> updatePayment(PaymentModel payment);
  Future<void> deletePayment(String id);
  Future<List<PaymentModel>> getPaymentsByMonth(int year, int month);
  Future<List<PaymentModel>> getPaymentsByType(PaymentType type);
}
