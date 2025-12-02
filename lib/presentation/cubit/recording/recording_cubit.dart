import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../domain/entities/note.dart';
import '../../../domain/entities/processed_note.dart';
import '../../../domain/entities/recording.dart';
import '../../../domain/usecases/check_microphone_permission_usecase.dart';
import '../../../domain/usecases/create_note_usecase.dart';
import '../../../domain/usecases/open_app_settings_usecase.dart';
import '../../../domain/usecases/process_transcription_usecase.dart';
import '../../../domain/usecases/request_microphone_permission_usecase.dart';
import '../../../domain/usecases/start_recording_usecase.dart';
import '../../../domain/usecases/stop_recording_usecase.dart';
import '../../../domain/usecases/transcribe_audio_params.dart';
import '../../../domain/usecases/transcribe_audio_usecase.dart';
import '../../../domain/usecases/usecase.dart';
import 'recording_state.dart';

@injectable
class RecordingCubit extends Cubit<RecordingState> {
  final CheckMicrophonePermissionUseCase checkMicrophonePermissionUseCase;
  final RequestMicrophonePermissionUseCase requestMicrophonePermissionUseCase;
  final StartRecordingUseCase startRecordingUseCase;
  final StopRecordingUseCase stopRecordingUseCase;
  final TranscribeAudioUseCase transcribeAudioUseCase;
  final ProcessTranscriptionUseCase processTranscriptionUseCase;
  final CreateNoteUseCase createNoteUseCase;
  final OpenAppSettingsUseCase openAppSettingsUseCase;
  Timer? _durationTimer;
  DateTime? _recordingStartTime;
  String? _currentRecordingPath;

  RecordingCubit(
    this.checkMicrophonePermissionUseCase,
    this.requestMicrophonePermissionUseCase,
    this.startRecordingUseCase,
    this.stopRecordingUseCase,
    this.transcribeAudioUseCase,
    this.processTranscriptionUseCase,
    this.createNoteUseCase,
    this.openAppSettingsUseCase,
  ) : super(RecordingInitial());

  Future<void> checkPermission() async {
    final result = await checkMicrophonePermissionUseCase(const NoParams());
    result.fold((failure) => emit(RecordingPermissionDenied(failure.message)), (
      hasPermission,
    ) {
      if (hasPermission) {
        emit(RecordingReady());
      } else {
        emit(RecordingPermissionDenied('Microphone permission is required'));
      }
    });
  }

  Future<void> requestPermission() async {
    emit(RecordingPermissionRequested());
    final result = await requestMicrophonePermissionUseCase(const NoParams());
    result.fold((failure) => emit(RecordingPermissionDenied(failure.message)), (
      granted,
    ) {
      if (granted) {
        emit(RecordingReady());
      } else {
        emit(RecordingPermissionDenied('Microphone permission denied'));
      }
    });
  }

  Future<void> startRecording() async {
    // Check permission first
    final permissionResult = await checkMicrophonePermissionUseCase(
      const NoParams(),
    );
    bool hasPermission = false;
    permissionResult.fold(
      (failure) => null,
      (granted) => hasPermission = granted,
    );

    if (!hasPermission) {
      await requestPermission();
      final checkAgain = await checkMicrophonePermissionUseCase(
        const NoParams(),
      );
      checkAgain.fold((failure) => null, (granted) => hasPermission = granted);
      if (!hasPermission) {
        emit(
          RecordingPermissionDenied(
            'Microphone permission is required to record',
          ),
        );
        return;
      }
    }

    final result = await startRecordingUseCase(const NoParams());
    result.fold((failure) => emit(RecordingError(failure.message)), (path) {
      _currentRecordingPath = path;
      _recordingStartTime = DateTime.now();
      emit(RecordingInProgress(Duration.zero));
      _startDurationTimer();
    });
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_recordingStartTime != null) {
        final duration = DateTime.now().difference(_recordingStartTime!);
        emit(RecordingInProgress(duration));
      }
    });
  }

  Future<void> stopRecording() async {
    _durationTimer?.cancel();
    _durationTimer = null;

    if (_currentRecordingPath == null) {
      emit(const RecordingError('No active recording'));
      return;
    }

    final result = await stopRecordingUseCase(
      StopRecordingParams(_currentRecordingPath!),
    );
    result.fold((failure) => emit(RecordingError(failure.message)), (
      recording,
    ) {
      _currentRecordingPath = null;
      _recordingStartTime = null;
      emit(RecordingStopped(recording));
      _processRecording(recording);
    });
  }

  Future<void> cancelRecording() async {
    _durationTimer?.cancel();
    _durationTimer = null;
    _recordingStartTime = null;

    if (_currentRecordingPath != null) {
      // Cancel and delete the recording
      await startRecordingUseCase(const NoParams()); // This will handle cleanup
      _currentRecordingPath = null;
    }

    emit(RecordingInitial());
  }

  Future<void> _processRecording(recording) async {
    emit(RecordingTranscribing(recording));

    // Transcribe audio
    final transcriptionResult = await transcribeAudioUseCase(
      TranscribeAudioParams(audioPath: recording.audioPath),
    );

    transcriptionResult.fold(
      (failure) {
        // If transcription fails, create a basic note
        _createBasicNote(recording, null);
      },
      (transcription) async {
        if (transcription.isEmpty) {
          _createBasicNote(recording, null);
          return;
        }

        emit(RecordingProcessing(recording, transcription));

        // Process with AI
        final processingResult = await processTranscriptionUseCase(
          ProcessTranscriptionParams(transcription),
        );

        processingResult.fold(
          (failure) {
            // If AI processing fails, create a fallback ProcessedNote
            // Still show format selection screen so user can choose format

            final fallbackNote = ProcessedNote(
              title: _extractTitleFromTranscription(transcription),
              content: transcription,
              bulletPoints: [],
              tags: _extractSimpleTags(transcription),
              summary: null,
            );

            // Show format selection screen even if AI processing fails
            emit(
              RecordingFormatSelection(recording, transcription, fallbackNote),
            );
          },
          (processedNote) {
            // Show format selection screen with AI-processed note

            emit(
              RecordingFormatSelection(recording, transcription, processedNote),
            );
          },
        );
      },
    );
  }

  Future<void> _createBasicNote(recording, String? transcription) async {
    final now = DateTime.now();
    final note = Note(
      id: recording.id,
      title: 'Voice Note',
      content: transcription ?? 'Recording completed',
      audioPath: recording.audioPath,
      createdAt: recording.createdAt,
      updatedAt: now,
      wordCount: transcription?.split(RegExp(r'\s+')).length ?? 0,
    );

    final result = await createNoteUseCase(CreateNoteParams(note));
    result.fold(
      (failure) => emit(RecordingError(failure.message)),
      (_) => emit(RecordingProcessed(recording, _createBasicProcessedNote())),
    );
  }

  ProcessedNote _createBasicProcessedNote() {
    return const ProcessedNote(
      title: 'Voice Note',
      content: 'Recording completed',
      bulletPoints: [],
      tags: [],
    );
  }

  String _extractTitleFromTranscription(String transcription) {
    if (transcription.isEmpty) return 'Voice Note';

    // Clean up the transcription
    final cleaned = transcription.trim();

    // Try to extract first sentence
    final sentences = cleaned.split(RegExp(r'[.!?\n]'));
    if (sentences.isNotEmpty) {
      final firstSentence = sentences.first.trim();
      if (firstSentence.isNotEmpty) {
        // Limit to 50 characters for title
        if (firstSentence.length > 50) {
          return '${firstSentence.substring(0, 47)}...';
        }
        return firstSentence;
      }
    }

    // If no sentences, use first 50 characters
    if (cleaned.length > 50) {
      return '${cleaned.substring(0, 47)}...';
    }

    return cleaned;
  }

  List<String> _extractSimpleTags(String text) {
    if (text.isEmpty) return [];

    // Simple keyword extraction (fallback)
    // Remove punctuation and convert to lowercase
    final cleaned = text.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), ' ');
    final words = cleaned
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();

    final commonWords = {
      'the',
      'a',
      'an',
      'and',
      'or',
      'but',
      'in',
      'on',
      'at',
      'to',
      'for',
      'of',
      'with',
      'by',
      'is',
      'are',
      'was',
      'were',
      'be',
      'been',
      'have',
      'has',
      'had',
      'do',
      'does',
      'did',
      'will',
      'would',
      'could',
      'should',
      'i',
      'you',
      'he',
      'she',
      'it',
      'we',
      'they',
      'this',
      'that',
      'these',
      'those',
      'what',
      'which',
      'who',
      'when',
      'where',
      'why',
      'how',
      'can',
      'may',
      'might',
      'must',
      'shall',
      'about',
      'into',
      'through',
      'during',
      'before',
      'after',
      'above',
      'below',
      'up',
      'down',
      'out',
      'off',
      'over',
      'under',
      'again',
      'further',
      'then',
      'once',
    };

    // Extract meaningful keywords (longer words, not common words)
    final keywords = words
        .where((word) => word.length > 3 && !commonWords.contains(word))
        .toSet() // Remove duplicates
        .take(5)
        .toList();

    // If we don't have enough keywords, add some generic tags based on content
    if (keywords.length < 3) {
      final lowerText = text.toLowerCase();
      if (lowerText.contains('meeting') || lowerText.contains('call')) {
        keywords.add('meeting');
      }
      if (lowerText.contains('todo') || lowerText.contains('task')) {
        keywords.add('todo');
      }
      if (lowerText.contains('idea') || lowerText.contains('think')) {
        keywords.add('idea');
      }
      if (lowerText.contains('work') || lowerText.contains('project')) {
        keywords.add('work');
      }
      if (lowerText.contains('personal') || lowerText.contains('home')) {
        keywords.add('personal');
      }
    }

    return keywords.take(5).toList();
  }

  /// Create note with selected format (full text or bullet points)
  Future<void> createNoteWithFormat({
    required Recording recording,
    required String transcription,
    required ProcessedNote processedNote,
    required bool useBulletPoints,
  }) async {
    final now = DateTime.now();

    // Choose content format based on user selection
    final content = useBulletPoints
        ? (processedNote.bulletPoints.isEmpty
              ? transcription
              : processedNote.bulletPoints
                    .map((point) => '• $point')
                    .join('\n'))
        : transcription; // Full text

    final note = Note(
      id: recording.id,
      title: processedNote.title,
      content: content,
      summary: processedNote.summary,
      tags: processedNote.tags,
      audioPath: recording.audioPath,
      createdAt: recording.createdAt,
      updatedAt: now,
      wordCount: content.split(RegExp(r'\s+')).length,
    );

    final result = await createNoteUseCase(CreateNoteParams(note));
    result.fold(
      (failure) => emit(RecordingError(failure.message)),
      (_) => emit(RecordingProcessed(recording, processedNote)),
    );
  }

  Future<void> openAppSettings() async {
    final result = await openAppSettingsUseCase(const NoParams());
    result.fold((failure) => emit(RecordingError(failure.message)), (_) {
      // After opening settings, check permission again when user returns
      // This will be handled by checking permission when screen is resumed
    });
  }

  @override
  Future<void> close() {
    _durationTimer?.cancel();
    return super.close();
  }
}
