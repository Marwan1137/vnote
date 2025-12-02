import 'package:injectable/injectable.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../core/errors/exceptions.dart';
import 'google_speech_service.dart';

abstract class TranscriptionDataSource {
  Future<String> transcribeAudio(
    String audioPath, {
    String? languageCode,
    List<String>? alternativeLanguageCodes,
  });
  Future<bool> initialize();
  Future<List<stt.LocaleName>> getAvailableLanguages();
}

@LazySingleton(as: TranscriptionDataSource)
class TranscriptionDataSourceImpl implements TranscriptionDataSource {
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  final GoogleSpeechService _googleSpeechService = GoogleSpeechService();
  bool _isInitialized = false;

  @override
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Initialize Google Speech-to-Text service
      await _googleSpeechService.initialize();

      // Also initialize speech_to_text for language detection (if needed)
      final available = await _speechToText.initialize(
        onError: (error) {
          // Log error but don't throw - we're using Google API for transcription
        },
        onStatus: (status) {
          // Handle status if needed
        },
      );

      _isInitialized = true;
      return available;
    } catch (e) {
      throw TranscriptionException(
        'Failed to initialize speech recognition: $e',
      );
    }
  }

  @override
  Future<String> transcribeAudio(
    String audioPath, {
    String? languageCode,
    List<String>? alternativeLanguageCodes,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      // Use Google Speech-to-Text API for file transcription
      // If no language is specified, Google will auto-detect the language
      // You can also provide alternativeLanguageCodes for better multi-language support
      final transcription = await _googleSpeechService.transcribeAudio(
        audioPath,
        languageCode: languageCode,
        alternativeLanguageCodes:
            alternativeLanguageCodes ??
            [
              // Common languages for better auto-detection
              'en-US', // English
              'ar-EG', // Arabic
              'fr-FR', // French
              'es-ES', // Spanish
              'de-DE', // German
              'it-IT', // Italian
              'pt-BR', // Portuguese
              'ru-RU', // Russian
              'ja-JP', // Japanese
              'zh-CN', // Chinese (Simplified)
              'ko-KR', // Korean
              'hi-IN', // Hindi
            ],
        sampleRateHertz: 44100, // Match the recording sample rate
      );

      if (transcription.isEmpty) {
        throw TranscriptionException('Transcription returned empty result');
      }

      return transcription;
    } catch (e) {
      if (e is TranscriptionException) rethrow;
      throw TranscriptionException('Transcription failed: $e');
    }
  }

  @override
  Future<List<stt.LocaleName>> getAvailableLanguages() async {
    if (!_isInitialized) {
      await initialize();
    }
    return _speechToText.locales();
  }
}
