import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import '../../core/errors/exceptions.dart';
import '../../domain/entities/processed_note.dart';

abstract class OllamaDataSource {
  Future<ProcessedNote> processTranscription(String transcription);
}

@LazySingleton(as: OllamaDataSource)
class OllamaDataSourceImpl implements OllamaDataSource {
  // Ollama URL configuration
  // For iOS Simulator: use 'http://localhost:11434'
  // For Physical iOS Device: use your Mac's IP address, e.g., 'http://192.168.1.xxx:11434'
  // To find your Mac's IP: run 'ifconfig | grep "inet " | grep -v 127.0.0.1' in Terminal
  // Your Mac's IP: 192.168.1.168
  final String baseUrl = 'http://192.168.1.168:11434';

  // Model to use - make sure you've downloaded it: 'ollama pull llama3.2'
  final String model = 'llama3.2';

  @override
  Future<ProcessedNote> processTranscription(String transcription) async {
    try {
      final prompt = _buildPrompt(transcription);

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/generate'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'model': model,
              'prompt': prompt,
              'stream': false,
            }),
          )
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () {
              throw LLMProcessingException('Request timeout');
            },
          );

      if (response.statusCode != 200) {
        throw LLMProcessingException(
          'Ollama API error: ${response.statusCode}',
        );
      }

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      final generatedText = jsonResponse['response'] as String? ?? '';

      return _parseResponse(generatedText, transcription);
    } catch (e) {
      if (e is LLMProcessingException) rethrow;
      if (e is OllamaConnectionException) rethrow;

      // Provide helpful error messages
      final errorMessage = e.toString();
      if (errorMessage.contains('Connection refused') ||
          errorMessage.contains('Failed host lookup')) {
        throw OllamaConnectionException(
          'Cannot connect to Ollama at $baseUrl. '
          'Make sure Ollama is running and accessible. '
          'For physical devices, use your Mac\'s IP address instead of localhost.',
        );
      }

      throw LLMProcessingException('Failed to process transcription: $e');
    }
  }

  String _buildPrompt(String transcription) {
    // Detect primary language from transcription
    final detectedLanguage = _detectLanguage(transcription);
    final languageInstruction = detectedLanguage == 'en'
        ? 'The transcription is in ENGLISH. You MUST respond in ENGLISH for ALL fields (title, bulletPoints, tags, summary). Do NOT use Arabic or any other language.'
        : detectedLanguage == 'ar'
        ? 'The transcription is in ARABIC. You MUST respond in ARABIC for ALL fields (title, bulletPoints, tags, summary).'
        : 'The transcription appears to be in ${detectedLanguage.toUpperCase()}. You MUST respond in the EXACT SAME LANGUAGE as the transcription for ALL fields.';

    return '''
You are an intelligent note-taking assistant. Analyze the following voice transcription and create a well-structured note.

${'=' * 80}
ABSOLUTE LANGUAGE REQUIREMENT - READ THIS CAREFULLY:
$languageInstruction

CRITICAL RULES:
1. FIRST, identify the language of the transcription below
2. THEN, use that EXACT SAME language for ALL your responses
3. If transcription is English → ALL responses MUST be in English
4. If transcription is Arabic → ALL responses MUST be in Arabic
5. DO NOT mix languages - use only one language throughout
6. DO NOT translate - keep the same language as the transcription
${'=' * 80}

IMPORTANT: You MUST generate bullet points. The bulletPoints array must contain at least 3 items, even for short transcriptions.

Requirements:
1. Title: Create a concise, descriptive title (3-7 words) that captures the main topic. Make it specific and meaningful, not generic like "Voice Note". MUST be in the exact same language as the transcription.

2. Bullet Points: Extract 3-7 key points from the transcription. This is REQUIRED - you must always provide bullet points. Break down the transcription into main ideas, actions, or topics discussed. Each point should be clear and concise. If the transcription is short, extract the main points from it. MUST be in the exact same language as the transcription.

3. Hashtags: Generate 3-7 relevant hashtags based on:
   - Main topics discussed
   - Categories (e.g., work, personal, ideas, meeting, todo)
   - Context (e.g., urgent, important, reminder)
   MUST be in the exact same language as the transcription.

4. Summary: Write a brief 1-2 sentence summary that captures the essence of the note. MUST be in the exact same language as the transcription.

Transcription to analyze:
$transcription

Respond ONLY with valid JSON in this exact format (do not use markdown code blocks):
{
  "title": "Specific descriptive title here",
  "bulletPoints": ["First key point", "Second key point", "Third key point"],
  "tags": ["hashtag1", "hashtag2", "hashtag3"],
  "summary": "Brief summary sentence here"
}

FINAL REMINDER: 
- The bulletPoints array MUST contain at least 3 items
- Do not return an empty bulletPoints array
- ALL fields (title, bulletPoints, tags, summary) MUST be in the EXACT SAME LANGUAGE as the transcription above
- Match the language exactly - if transcription is English, use English; if Arabic, use Arabic
- Only respond with the JSON object, no additional text, explanations, or markdown formatting
''';
  }

  /// Detect the primary language of the text
  String _detectLanguage(String text) {
    if (text.isEmpty) return 'en';

    // Check for Arabic characters
    final arabicChars = RegExp(
      r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]',
    );
    final arabicMatches = arabicChars.allMatches(text).length;
    final totalChars = text
        .replaceAll(RegExp(r'[\s\p{P}]', unicode: true), '')
        .length;

    // If more than 40% Arabic characters, consider it Arabic
    if (totalChars > 0 && (arabicMatches / totalChars) > 0.4) {
      return 'ar';
    }

    // Check for common English words/patterns
    final englishPattern = RegExp(
      r'\b(the|and|or|but|in|on|at|to|for|of|with|by|is|are|was|were|a|an|this|that|you|I|we|they|he|she|it)\b',
      caseSensitive: false,
    );
    final englishMatches = englishPattern.allMatches(text).length;

    // If significant English words found, likely English
    if (englishMatches > 2) {
      return 'en';
    }

    // Default to English if unclear
    return 'en';
  }

  ProcessedNote _parseResponse(String response, String originalTranscription) {
    try {
      // Try to extract JSON from response
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch == null) {
        throw const FormatException('No JSON found in response');
      }

      final jsonString = jsonMatch.group(0)!;
      final json = jsonDecode(jsonString) as Map<String, dynamic>;

      final title = json['title'] as String? ?? 'Untitled Note';

      // Parse bullet points - handle different possible field names
      var bulletPoints = <String>[];
      if (json.containsKey('bulletPoints')) {
        final bp = json['bulletPoints'];
        if (bp is List) {
          bulletPoints = bp
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList();
        }
      } else if (json.containsKey('bullet_points')) {
        final bp = json['bullet_points'];
        if (bp is List) {
          bulletPoints = bp
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList();
        }
      }

      // If no bullet points were generated, create them from the transcription
      if (bulletPoints.isEmpty) {
        bulletPoints = _generateBulletPointsFromTranscription(
          originalTranscription,
        );
      }

      final tags =
          (json['tags'] as List<dynamic>?)
              ?.map((e) => e.toString().toLowerCase().trim())
              .where((e) => e.isNotEmpty)
              .toList() ??
          [];
      final summary = json['summary'] as String?;

      // Create content from bullet points
      final content = bulletPoints.isEmpty
          ? originalTranscription
          : bulletPoints.map((point) => '• $point').join('\n');

      return ProcessedNote(
        title: title,
        content: content,
        bulletPoints: bulletPoints,
        tags: tags,
        summary: summary,
      );
    } catch (e) {
      // Fallback: create a simple note from transcription
      return ProcessedNote(
        title: _extractTitle(originalTranscription),
        content: originalTranscription,
        bulletPoints: [],
        tags: _extractSimpleTags(originalTranscription),
        summary: null,
      );
    }
  }

  String _extractTitle(String text) {
    final sentences = text.split(RegExp(r'[.!?]'));
    if (sentences.isNotEmpty) {
      final firstSentence = sentences.first.trim();
      if (firstSentence.length > 50) {
        return '${firstSentence.substring(0, 47)}...';
      }
      return firstSentence;
    }
    return 'Voice Note';
  }

  /// Generate bullet points from transcription when Ollama doesn't provide them
  List<String> _generateBulletPointsFromTranscription(String transcription) {
    if (transcription.isEmpty) return [];

    // Split by sentences (Arabic and English punctuation)
    final sentences = transcription
        .split(RegExp(r'[.!?。！？\n]+'))
        .map((s) => s.trim())
        .where(
          (s) => s.isNotEmpty && s.length > 10,
        ) // Filter out very short sentences
        .toList();

    if (sentences.isEmpty) {
      // If no sentences, try splitting by commas or other separators
      final parts = transcription
          .split(RegExp(r'[،,;؛\n]+'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty && s.length > 10)
          .toList();

      if (parts.length >= 3) {
        return parts.take(7).toList();
      } else if (parts.isNotEmpty) {
        // If transcription is short, create meaningful points
        return [transcription];
      }
    }

    // Take 3-7 sentences as bullet points
    if (sentences.length >= 3) {
      return sentences.take(7).toList();
    } else if (sentences.isNotEmpty) {
      // For shorter transcriptions, split the content into logical parts
      final words = transcription.split(RegExp(r'\s+'));
      if (words.length > 20) {
        // Split into 3-5 roughly equal parts
        final chunkSize = (words.length / 3).ceil();
        final points = <String>[];
        for (int i = 0; i < words.length; i += chunkSize) {
          final chunk = words.skip(i).take(chunkSize).join(' ');
          if (chunk.trim().isNotEmpty) {
            points.add(chunk.trim());
          }
          if (points.length >= 5) break;
        }
        return points;
      }
      return sentences;
    }

    return [transcription];
  }

  List<String> _extractSimpleTags(String text) {
    // Simple keyword extraction (fallback)
    final words = text.toLowerCase().split(RegExp(r'\s+'));
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
    };

    final keywords = words
        .where((word) => word.length > 3 && !commonWords.contains(word))
        .take(5)
        .toList();

    return keywords;
  }
}
