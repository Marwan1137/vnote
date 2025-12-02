class TranscribeAudioParams {
  final String audioPath;
  final String? languageCode;
  final List<String>? alternativeLanguageCodes;

  TranscribeAudioParams({
    required this.audioPath,
    this.languageCode,
    this.alternativeLanguageCodes,
  });
}
