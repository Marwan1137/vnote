import '../../domain/entities/processed_payment.dart';

abstract class PaymentLLMDataSource {
  Future<List<ProcessedPayment>> processPaymentTranscription(
    String transcription,
  );
}
