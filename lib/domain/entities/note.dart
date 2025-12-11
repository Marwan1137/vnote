import 'package:equatable/equatable.dart';

class Note extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String content;
  final String? summary;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? transcriptionId;
  final String? audioPath;
  final String language;
  final bool isFavorite;
  final int wordCount;

  const Note({
    required this.id,
    required this.userId,
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

  // Helper method to get category color based on tags
  String get categoryColor {
    if (tags.isEmpty) return 'blue';
    final firstTag = tags.first.toLowerCase();

    if (firstTag.contains('work') || firstTag.contains('meeting')) {
      return 'blue';
    } else if (firstTag.contains('personal')) {
      return 'green';
    } else if (firstTag.contains('idea')) {
      return 'purple';
    } else if (firstTag.contains('cooking')) {
      return 'orange';
    }
    return 'blue';
  }

  // Helper method to get time ago string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  // Get preview text (first 100 characters)
  String get preview {
    if (content.length <= 100) return content;
    return '${content.substring(0, 100)}...';
  }

  // Copy with method for updates
  Note copyWith({
    String? id,
    String? userId,
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
    return Note(
      id: id ?? this.id,
      userId: userId ?? this.userId,
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

  @override
  List<Object?> get props => [
    id,
    userId,
    title,
    content,
    summary,
    tags,
    createdAt,
    updatedAt,
    transcriptionId,
    audioPath,
    language,
    isFavorite,
    wordCount,
  ];
}
