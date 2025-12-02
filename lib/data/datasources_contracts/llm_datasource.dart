import '../../domain/entities/processed_note.dart';

/// Abstract interface for LLM data sources
/// This allows swapping between different LLM providers (Gemini, OpenAI, etc.)
abstract class LLMDataSource {
  /// Process a transcription and generate structured note data
  /// Returns a ProcessedNote with title, bullet points, tags, and summary
  Future<ProcessedNote> processTranscription(String transcription);
}
