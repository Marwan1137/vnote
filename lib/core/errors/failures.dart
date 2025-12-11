import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

// General failures
class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error occurred']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache error occurred']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network connection failed']);
}

// Storage failures
class StorageFailure extends Failure {
  const StorageFailure([super.message = 'Storage operation failed']);
}

class DatabaseFailure extends Failure {
  const DatabaseFailure([super.message = 'Database operation failed']);
}

// Audio failures
class RecordingFailure extends Failure {
  const RecordingFailure([super.message = 'Recording failed']);
}

class AudioPermissionFailure extends Failure {
  const AudioPermissionFailure([
    super.message = 'Microphone permission denied',
  ]);
}

class AudioProcessingFailure extends Failure {
  const AudioProcessingFailure([super.message = 'Audio processing failed']);
}

// AI processing failures
class TranscriptionFailure extends Failure {
  const TranscriptionFailure([super.message = 'Transcription failed']);
}

class LLMProcessingFailure extends Failure {
  const LLMProcessingFailure([super.message = 'AI processing failed']);
}

class ModelNotFoundFailure extends Failure {
  const ModelNotFoundFailure([super.message = 'AI model not found']);
}

class GeminiAPIFailure extends Failure {
  const GeminiAPIFailure([super.message = 'Gemini API error']);
}

// Note failures
class NoteNotFoundFailure extends Failure {
  const NoteNotFoundFailure([super.message = 'Note not found']);
}

class NoteSaveFailure extends Failure {
  const NoteSaveFailure([super.message = 'Failed to save note']);
}

class NoteDeleteFailure extends Failure {
  const NoteDeleteFailure([super.message = 'Failed to delete note']);
}

// Export failures
class ExportFailure extends Failure {
  const ExportFailure([super.message = 'Export failed']);
}

class FilePermissionFailure extends Failure {
  const FilePermissionFailure([super.message = 'File permission denied']);
}

// Validation failures
class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Validation failed']);
}

class InvalidInputFailure extends Failure {
  const InvalidInputFailure([super.message = 'Invalid input provided']);
}

// Authentication failures
class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication failed']);
}
