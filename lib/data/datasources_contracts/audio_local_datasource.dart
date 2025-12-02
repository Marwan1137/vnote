abstract class AudioLocalDataSource {
  Future<String> startRecording();
  Future<String> stopRecording();
  Future<bool> checkPermission();
  Future<bool> requestPermission();
  Future<void> cancelRecording();
  Future<bool> openAppSettings();
}
