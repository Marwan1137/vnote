class ServerException implements Exception {
  final String message;
  ServerException([this.message = 'Server error occurred']);

  @override
  String toString() => message;
}

class CacheException implements Exception {
  final String message;
  CacheException([this.message = 'Cache error occurred']);

  @override
  String toString() => message;
}

class NetworkException implements Exception {
  final String message;
  NetworkException([this.message = 'Network connection failed']);

  @override
  String toString() => message;
}

class StorageException implements Exception {
  final String message;
  StorageException([this.message = 'Storage operation failed']);

  @override
  String toString() => message;
}

class DatabaseException implements Exception {
  final String message;
  DatabaseException([this.message = 'Database operation failed']);

  @override
  String toString() => message;
}

class RecordingException implements Exception {
  final String message;
  RecordingException([this.message = 'Recording failed']);

  @override
  String toString() => message;
}

class AudioPermissionException implements Exception {
  final String message;
  AudioPermissionException([this.message = 'Microphone permission denied']);

  @override
  String toString() => message;
}

class TranscriptionException implements Exception {
  final String message;
  TranscriptionException([this.message = 'Transcription failed']);

  @override
  String toString() => message;
}

class LLMProcessingException implements Exception {
  final String message;
  LLMProcessingException([this.message = 'AI processing failed']);

  @override
  String toString() => message;
}

class ModelNotFoundException implements Exception {
  final String message;
  ModelNotFoundException([this.message = 'AI model not found']);

  @override
  String toString() => message;
}

class GeminiAPIException implements Exception {
  final String message;
  GeminiAPIException([this.message = 'Gemini API error']);

  @override
  String toString() => message;
}

class NoteNotFoundException implements Exception {
  final String message;
  NoteNotFoundException([this.message = 'Note not found']);

  @override
  String toString() => message;
}

class ExportException implements Exception {
  final String message;
  ExportException([this.message = 'Export failed']);

  @override
  String toString() => message;
}

class ValidationException implements Exception {
  final String message;
  ValidationException([this.message = 'Validation failed']);

  @override
  String toString() => message;
}
