import '../../domain/entities/processed_event.dart';

abstract class EventLLMDataSource {
  Future<List<ProcessedEvent>> processEventTranscription(String transcription);
}
