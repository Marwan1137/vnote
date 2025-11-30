class AppDurations {
  // ==================== ANIMATION DURATIONS ====================

  static const Duration instant = Duration(milliseconds: 0);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 800);

  // Specific Animations
  static const Duration splash = Duration(seconds: 2);
  static const Duration pageTransition = Duration(milliseconds: 300);
  static const Duration fabAnimation = Duration(milliseconds: 200);
  static const Duration ripple = Duration(milliseconds: 400);
  static const Duration shimmer = Duration(milliseconds: 1500);

  // Recording Animations
  static const Duration recordingPulse = Duration(milliseconds: 1000);
  static const Duration waveformUpdate = Duration(milliseconds: 50);

  // ==================== DEBOUNCE DURATIONS ====================

  static const Duration searchDebounce = Duration(milliseconds: 500);
  static const Duration inputDebounce = Duration(milliseconds: 300);

  // ==================== TIMEOUT DURATIONS ====================

  static const Duration shortTimeout = Duration(seconds: 10);
  static const Duration mediumTimeout = Duration(seconds: 30);
  static const Duration longTimeout = Duration(seconds: 60);

  static const Duration apiTimeout = Duration(seconds: 120);
  static const Duration transcriptionTimeout = Duration(minutes: 5);
  static const Duration llmTimeout = Duration(minutes: 3);
}
