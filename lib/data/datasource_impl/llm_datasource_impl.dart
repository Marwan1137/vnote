import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:injectable/injectable.dart';
import '../../core/config/app_config.dart';
import '../../core/errors/exceptions.dart';
import '../../domain/entities/processed_note.dart';
import '../datasources_contracts/llm_datasource.dart';

@LazySingleton(as: LLMDataSource)
class LLMDataSourceImpl implements LLMDataSource {
  late final GenerativeModel _model;
  static const List<String> _fallbackModels = [
    'gemini-2.5-flash',
    'gemini-2.0-flash',
    'gemini-2.5-flash-lite',
    'gemini-2.0-flash-lite',
    'gemini-2.5-pro',
  ];

  LLMDataSourceImpl() {
    try {
      _model = GenerativeModel(
        model: AppConfig.geminiModel,
        apiKey: AppConfig.geminiApiKey,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<ProcessedNote> processTranscription(String transcription) async {
    try {
      final prompt = _buildPrompt(transcription);

      final generationConfig = GenerationConfig(
        temperature: 0.3,
        topK: 40,
        topP: 0.95,
      );

      GenerateContentResponse response;
      try {
        response = await _model
            .generateContent([
              Content.text(prompt),
            ], generationConfig: generationConfig)
            .timeout(
              const Duration(seconds: 60),
              onTimeout: () {
                throw LLMProcessingException('Request timeout');
              },
            );
      } on GenerativeAIException catch (e) {
        if (e.message.contains('not found') ||
            e.message.contains('not supported') ||
            e.message.contains('quota') ||
            e.message.contains('Quota exceeded')) {
          return _tryWithFallbackModels(
            prompt,
            transcription,
            generationConfig,
          );
        }
        rethrow;
      }

      final generatedText = response.text ?? '';

      if (generatedText.isEmpty) {
        throw LLMProcessingException('Gemini API returned empty response');
      }

      return _parseResponse(generatedText, transcription);
    } on GenerativeAIException catch (e) {
      throw LLMProcessingException('Gemini API error: ${e.message}');
    } catch (e) {
      if (e is LLMProcessingException) {
        rethrow;
      }

      final errorMessage = e.toString();
      if (errorMessage.contains('API key') ||
          errorMessage.contains('authentication')) {
        throw LLMProcessingException(
          'Invalid Gemini API key. Please check your configuration.',
        );
      }

      throw LLMProcessingException('Failed to process transcription: $e');
    }
  }

  String _buildPrompt(String transcription) {
    final detectedLanguage = _detectLanguage(transcription);
    final languageInstruction = detectedLanguage == 'en'
        ? 'The transcription is in ENGLISH. You MUST respond in ENGLISH for ALL fields (title, bulletPoints, tags, summary). Do NOT use Arabic, German, or any other language.'
        : detectedLanguage == 'ar'
        ? 'The transcription is in ARABIC. You MUST respond in ARABIC for ALL fields (title, bulletPoints, tags, summary).'
        : detectedLanguage == 'de'
        ? 'The transcription is in GERMAN. You MUST respond in GERMAN for ALL fields (title, bulletPoints, tags, summary). Use German language for all responses.'
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
5. If transcription is German → ALL responses MUST be in German
6. DO NOT mix languages - use only one language throughout
7. DO NOT translate - keep the same language as the transcription
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

CRITICAL: You MUST respond with ONLY valid JSON. Do NOT include markdown code blocks, explanations, or any other text.

Respond with this EXACT JSON structure:
{
  "title": "Specific descriptive title here",
  "bulletPoints": ["First key point", "Second key point", "Third key point"],
  "tags": ["hashtag1", "hashtag2", "hashtag3"],
  "summary": "Brief summary sentence here"
}

ABSOLUTE REQUIREMENTS:
1. The bulletPoints array MUST contain at least 3 items - this is MANDATORY
2. Do NOT return an empty bulletPoints array under any circumstances
3. ALL fields (title, bulletPoints, tags, summary) MUST be in the EXACT SAME LANGUAGE as the transcription
4. Start your response with { and end with } - no markdown, no code blocks, no explanations
5. Ensure the JSON is valid and parseable

Example of correct response format:
{"title":"Meeting Notes","bulletPoints":["Discuss project timeline","Review budget constraints","Assign team responsibilities"],"tags":["meeting","work","project"],"summary":"Team meeting to discuss project progress and next steps"}
''';
  }

  String _detectLanguage(String text) {
    if (text.isEmpty) return 'en';

    final arabicChars = RegExp(
      r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]',
    );
    final arabicMatches = arabicChars.allMatches(text).length;
    final totalChars = text
        .replaceAll(RegExp(r'[\s\p{P}]', unicode: true), '')
        .length;

    if (totalChars > 0 && (arabicMatches / totalChars) > 0.4) {
      return 'ar';
    }

    final germanPattern = RegExp(
      r'\b(der|die|das|und|oder|aber|in|auf|mit|von|zu|für|ist|sind|war|waren|ein|eine|einer|dies|dass|du|ich|wir|sie|er|sie|es|haben|hat|wird|kann|muss|soll)\b',
      caseSensitive: false,
    );
    final germanMatches = germanPattern.allMatches(text).length;

    if (germanMatches > 2) {
      return 'de';
    }

    final englishPattern = RegExp(
      r'\b(the|and|or|but|in|on|at|to|for|of|with|by|is|are|was|were|a|an|this|that|you|I|we|they|he|she|it)\b',
      caseSensitive: false,
    );
    final englishMatches = englishPattern.allMatches(text).length;

    if (englishMatches > 2) {
      return 'en';
    }

    return 'en';
  }

  ProcessedNote _parseResponse(String response, String originalTranscription) {
    try {
      String cleanedResponse = response.trim();

      cleanedResponse = cleanedResponse.replaceAll(
        RegExp(r'```(?:json)?\s*\n?([\s\S]*?)\n?```', multiLine: true),
        r'$1',
      );

      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(cleanedResponse);
      if (jsonMatch == null) {
        throw const FormatException('No JSON found in response');
      }

      final jsonString = jsonMatch.group(0)!;

      final json = jsonDecode(jsonString) as Map<String, dynamic>;

      final title = json['title'] as String? ?? 'Untitled Note';

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

  List<String> _generateBulletPointsFromTranscription(String transcription) {
    if (transcription.isEmpty) return [];

    final sentences = transcription
        .split(RegExp(r'[.!?。！？\n]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && s.length > 10)
        .toList();

    if (sentences.isEmpty) {
      final parts = transcription
          .split(RegExp(r'[،,;؛\n]+'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty && s.length > 10)
          .toList();

      if (parts.length >= 3) {
        return parts.take(7).toList();
      } else if (parts.isNotEmpty) {
        return [transcription];
      }
    }

    if (sentences.length >= 3) {
      return sentences.take(7).toList();
    } else if (sentences.isNotEmpty) {
      final words = transcription.split(RegExp(r'\s+'));
      if (words.length > 20) {
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

  Future<ProcessedNote> _tryWithFallbackModels(
    String prompt,
    String transcription,
    GenerationConfig generationConfig,
  ) async {
    for (final modelName in _fallbackModels) {
      if (modelName == AppConfig.geminiModel) {
        continue;
      }

      try {
        final fallbackModel = GenerativeModel(
          model: modelName,
          apiKey: AppConfig.geminiApiKey,
        );

        final response = await fallbackModel
            .generateContent([
              Content.text(prompt),
            ], generationConfig: generationConfig)
            .timeout(const Duration(seconds: 60));

        final generatedText = response.text ?? '';
        if (generatedText.isNotEmpty) {
          return _parseResponse(generatedText, transcription);
        }
      } on GenerativeAIException catch (e) {
        if (e.message.contains('quota') ||
            e.message.contains('Quota exceeded')) {
          continue;
        }
        continue;
      } catch (e) {
        continue;
      }
    }

    throw LLMProcessingException(
      'All Gemini models failed due to quota limits or availability. '
      'Please check your API key quota at https://ai.dev/usage?tab=rate-limit. '
      'You may need to enable billing or wait for quota reset.',
    );
  }
}
