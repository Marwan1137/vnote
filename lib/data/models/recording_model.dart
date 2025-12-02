import '../../domain/entities/recording.dart';

class RecordingModel extends Recording {
  const RecordingModel({
    required super.id,
    required super.audioPath,
    required super.createdAt,
    super.duration,
    super.transcription,
    super.language,
  });

  factory RecordingModel.fromEntity(Recording recording) {
    return RecordingModel(
      id: recording.id,
      audioPath: recording.audioPath,
      createdAt: recording.createdAt,
      duration: recording.duration,
      transcription: recording.transcription,
      language: recording.language,
    );
  }

  Recording toEntity() {
    return Recording(
      id: id,
      audioPath: audioPath,
      createdAt: createdAt,
      duration: duration,
      transcription: transcription,
      language: language,
    );
  }
}

