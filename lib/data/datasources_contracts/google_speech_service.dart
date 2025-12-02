abstract class GoogleSpeechService {
  Future<void> initialize();
  Future<String> transcribeAudio(
    String audioPath, {
    String? languageCode,
    List<String>? alternativeLanguageCodes,
    int sampleRateHertz = 44100,
  });
  void dispose();
}
