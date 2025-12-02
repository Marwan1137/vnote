import 'package:hive/hive.dart';
import '../../domain/entities/note.dart';
part 'note_model.g.dart';

@HiveType(typeId: 0)
class NoteModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String content;

  @HiveField(3)
  final String? summary;

  @HiveField(4)
  final List<String> tags;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final DateTime updatedAt;

  @HiveField(7)
  final String? transcriptionId;

  @HiveField(8)
  final String? audioPath;

  @HiveField(9)
  final String language;

  @HiveField(10)
  final bool isFavorite;

  @HiveField(11)
  final int wordCount;

  const NoteModel({
    required this.id,
    required this.title,
    required this.content,
    this.summary,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
    this.transcriptionId,
    this.audioPath,
    this.language = 'en',
    this.isFavorite = false,
    this.wordCount = 0,
  });

  factory NoteModel.fromEntity(Note note) {
    return NoteModel(
      id: note.id,
      title: note.title,
      content: note.content,
      summary: note.summary,
      tags: note.tags,
      createdAt: note.createdAt,
      updatedAt: note.updatedAt,
      transcriptionId: note.transcriptionId,
      audioPath: note.audioPath,
      language: note.language,
      isFavorite: note.isFavorite,
      wordCount: note.wordCount,
    );
  }

  /// Convert from Model to Entity
  Note toEntity() {
    return Note(
      id: id,
      title: title,
      content: content,
      summary: summary,
      tags: tags,
      createdAt: createdAt,
      updatedAt: updatedAt,
      transcriptionId: transcriptionId,
      audioPath: audioPath,
      language: language,
      isFavorite: isFavorite,
      wordCount: wordCount,
    );
  }

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      summary: json['summary'] as String?,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      transcriptionId: json['transcriptionId'] as String?,
      audioPath: json['audioPath'] as String?,
      language: json['language'] as String? ?? 'en',
      isFavorite: json['isFavorite'] as bool? ?? false,
      wordCount: json['wordCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'summary': summary,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'transcriptionId': transcriptionId,
      'audioPath': audioPath,
      'language': language,
      'isFavorite': isFavorite,
      'wordCount': wordCount,
    };
  }

  NoteModel copyWith({
    String? id,
    String? title,
    String? content,
    String? summary,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? transcriptionId,
    String? audioPath,
    String? language,
    bool? isFavorite,
    int? wordCount,
  }) {
    return NoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      summary: summary ?? this.summary,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      transcriptionId: transcriptionId ?? this.transcriptionId,
      audioPath: audioPath ?? this.audioPath,
      language: language ?? this.language,
      isFavorite: isFavorite ?? this.isFavorite,
      wordCount: wordCount ?? this.wordCount,
    );
  }
}
