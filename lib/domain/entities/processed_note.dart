import 'package:equatable/equatable.dart';

class ProcessedNote extends Equatable {
  final String title;
  final String content;
  final List<String> bulletPoints;
  final List<String> tags;
  final String? summary;

  const ProcessedNote({
    required this.title,
    required this.content,
    required this.bulletPoints,
    required this.tags,
    this.summary,
  });

  @override
  List<Object?> get props => [title, content, bulletPoints, tags, summary];
}

