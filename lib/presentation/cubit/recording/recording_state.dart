import 'package:equatable/equatable.dart';
import '../../../domain/entities/recording.dart';
import '../../../domain/entities/processed_note.dart';

abstract class RecordingState extends Equatable {
  const RecordingState();

  @override
  List<Object?> get props => [];
}

class RecordingInitial extends RecordingState {}

class RecordingPermissionRequested extends RecordingState {}

class RecordingPermissionDenied extends RecordingState {
  final String message;

  const RecordingPermissionDenied(this.message);

  @override
  List<Object?> get props => [message];
}

class RecordingReady extends RecordingState {}

class RecordingInProgress extends RecordingState {
  final Duration duration;

  const RecordingInProgress(this.duration);

  @override
  List<Object?> get props => [duration];
}

class RecordingStopped extends RecordingState {
  final Recording recording;

  const RecordingStopped(this.recording);

  @override
  List<Object?> get props => [recording];
}

class RecordingTranscribing extends RecordingState {
  final Recording recording;

  const RecordingTranscribing(this.recording);

  @override
  List<Object?> get props => [recording];
}

class RecordingProcessing extends RecordingState {
  final Recording recording;
  final String transcription;

  const RecordingProcessing(this.recording, this.transcription);

  @override
  List<Object?> get props => [recording, transcription];
}

class RecordingFormatSelection extends RecordingState {
  final Recording recording;
  final String transcription;
  final ProcessedNote processedNote;

  const RecordingFormatSelection(
    this.recording,
    this.transcription,
    this.processedNote,
  );

  @override
  List<Object?> get props => [recording, transcription, processedNote];
}

class RecordingProcessed extends RecordingState {
  final Recording recording;
  final ProcessedNote processedNote;

  const RecordingProcessed(this.recording, this.processedNote);

  @override
  List<Object?> get props => [recording, processedNote];
}

class RecordingError extends RecordingState {
  final String message;

  const RecordingError(this.message);

  @override
  List<Object?> get props => [message];
}
