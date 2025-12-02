import 'package:injectable/injectable.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../core/errors/exceptions.dart';
import '../datasources_contracts/google_speech_service.dart';
import 'google_speech_service_impl.dart';
import '../datasources_contracts/transcription_datasource.dart';

@LazySingleton(as: TranscriptionDataSource)
class TranscriptionDataSourceImpl implements TranscriptionDataSource {
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  final GoogleSpeechService _googleSpeechService = GoogleSpeechServiceImpl();
  bool _isInitialized = false;

  @override
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      await _googleSpeechService.initialize();

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

      final transcription = await _googleSpeechService.transcribeAudio(
        audioPath,
        languageCode: languageCode,
        alternativeLanguageCodes:
            alternativeLanguageCodes ??
            [
              'en-US',
              'ar-EG',
              'fr-FR',
              'es-ES',
              'de-DE',
              'it-IT',
              'pt-BR',
              'ru-RU',
              'ja-JP',
              'zh-CN',
              'ko-KR',
              'hi-IN',
            ],
        sampleRateHertz: 44100,
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
