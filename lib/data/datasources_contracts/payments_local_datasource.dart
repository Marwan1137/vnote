import '../../domain/entities/payment.dart';
import '../models/payment_model.dart';

abstract class PaymentsLocalDataSource {
  Future<List<PaymentModel>> getAllPayments(String userId);
  Future<PaymentModel?> getPaymentById(String id, String userId);
  Future<PaymentModel> createPayment(PaymentModel payment);
  Future<PaymentModel> updatePayment(PaymentModel payment);
  Future<void> deletePayment(String id, String userId);
  Future<List<PaymentModel>> getPaymentsByMonth(
    int year,
    int month,
    String userId,
  );
  Future<List<PaymentModel>> getPaymentsByType(PaymentType type, String userId);
}
