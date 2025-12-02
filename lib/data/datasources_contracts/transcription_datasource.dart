import 'package:speech_to_text/speech_to_text.dart' as stt;

abstract class TranscriptionDataSource {
  Future<String> transcribeAudio(
    String audioPath, {
    String? languageCode,
    List<String>? alternativeLanguageCodes,
  });
  Future<bool> initialize();
  Future<List<stt.LocaleName>> getAvailableLanguages();
}
