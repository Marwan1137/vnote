import 'package:equatable/equatable.dart';

class Recording extends Equatable {
  final String id;
  final String audioPath;
  final DateTime createdAt;
  final Duration? duration;
  final String? transcription;
  final String? language;

  const Recording({
    required this.id,
    required this.audioPath,
    required this.createdAt,
    this.duration,
    this.transcription,
    this.language,
  });

  @override
  List<Object?> get props => [
        id,
        audioPath,
        createdAt,
        duration,
        transcription,
        language,
      ];
}

