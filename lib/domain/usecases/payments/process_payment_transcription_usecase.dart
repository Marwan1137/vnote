import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../core/errors/failures.dart';
import '../../../data/datasources/payment_llm_datasource.dart';
import '../../../domain/entities/processed_payment.dart';
import '../usecase.dart';

class ProcessPaymentTranscriptionParams {
  final String transcription;

  ProcessPaymentTranscriptionParams(this.transcription);
}

@injectable
class ProcessPaymentTranscriptionUseCase
    implements
        UseCase<List<ProcessedPayment>, ProcessPaymentTranscriptionParams> {
  final PaymentLLMDataSource paymentLLMDataSource;

  ProcessPaymentTranscriptionUseCase(this.paymentLLMDataSource);

  @override
  Future<Either<Failure, List<ProcessedPayment>>> call(
    ProcessPaymentTranscriptionParams params,
  ) async {
    try {
      final processedPayments = await paymentLLMDataSource
          .processPaymentTranscription(params.transcription);
      return Right(processedPayments);
    } catch (e) {
      return Left(LLMProcessingFailure(e.toString()));
    }
  }
}
