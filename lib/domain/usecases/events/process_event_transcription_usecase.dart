import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../core/errors/failures.dart';
import '../../../data/datasources_contracts/event_llm_datasource.dart';
import '../../../domain/entities/processed_event.dart';
import '../usecase.dart';

class ProcessEventTranscriptionParams {
  final String transcription;

  ProcessEventTranscriptionParams(this.transcription);
}

@injectable
class ProcessEventTranscriptionUseCase
    implements UseCase<List<ProcessedEvent>, ProcessEventTranscriptionParams> {
  final EventLLMDataSource eventLLMDataSource;

  ProcessEventTranscriptionUseCase(this.eventLLMDataSource);

  @override
  Future<Either<Failure, List<ProcessedEvent>>> call(
    ProcessEventTranscriptionParams params,
  ) async {
    try {
      final processedEvents = await eventLLMDataSource
          .processEventTranscription(params.transcription);
      return Right(processedEvents);
    } catch (e) {
      return Left(LLMProcessingFailure(e.toString()));
    }
  }
}
