import '../errors/failures.dart';

/// Maps technical error messages to user-friendly messages
///
/// This utility ensures that users never see technical details from
/// backend services, APIs, or internal exceptions. All error messages
/// are sanitized and presented in a user-friendly format.
class UserFriendlyErrors {
  /// Returns a user-friendly error message based on the failure type and context
  ///
  /// [failure] - The failure object containing the technical error
  /// [context] - Optional context to provide more specific messages
  ///             ('auth', 'payments', 'notes', 'events', 'recording')
  static String getUserFriendlyMessage(Failure failure, {String? context}) {
    // First, check for specific error patterns in the message
    final message = failure.message.toLowerCase();

    // Handle Firebase error codes
    if (message.contains('wrong-password') ||
        message.contains('invalid-password')) {
      return 'Incorrect password. Please try again.';
    }
    if (message.contains('user-not-found') ||
        message.contains('email not found')) {
      return 'No account found with this email address.';
    }
    if (message.contains('email-already-in-use') ||
        message.contains('email already exists')) {
      return 'An account with this email already exists.';
    }
    if (message.contains('weak-password') ||
        message.contains('password is too weak')) {
      return 'Password is too weak. Please use a stronger password.';
    }
    if (message.contains('invalid-email') ||
        message.contains('invalid email')) {
      return 'Please enter a valid email address.';
    }
    if (message.contains('user-disabled')) {
      return 'This account has been disabled. Please contact support.';
    }
    if (message.contains('too-many-requests')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    if (message.contains('network-request-failed') ||
        message.contains('network error')) {
      return 'Unable to connect. Please check your internet connection and try again.';
    }
    if (message.contains('not verified') ||
        message.contains('email not verified')) {
      return 'Please verify your email address before signing in.';
    }

    // Handle API-specific errors
    if (message.contains('api') &&
        (message.contains('error') || message.contains('failed'))) {
      return _getContextMessage(
        context,
        defaultMessage: 'Unable to process your request. Please try again.',
        recordingMessage: 'Unable to process your recording. Please try again.',
      );
    }
    if (message.contains('gemini') ||
        message.contains('llm') ||
        message.contains('ai')) {
      return 'Unable to process your request. Please try again.';
    }
    if (message.contains('transcription') ||
        message.contains('speech-to-text')) {
      return 'Unable to process your recording. Please try again.';
    }

    // Map by Failure type
    if (failure is NetworkFailure) {
      return 'Unable to connect. Please check your internet connection and try again.';
    }

    if (failure is ServerFailure) {
      return 'Something went wrong. Please try again later.';
    }

    if (failure is AuthFailure) {
      // For auth failures, try to extract more context from the message
      if (message.contains('password')) {
        return 'Incorrect password. Please try again.';
      }
      if (message.contains('email')) {
        return 'Please check your email address and try again.';
      }
      if (message.contains('sign in') || message.contains('signin')) {
        return 'Unable to sign in. Please check your credentials and try again.';
      }
      if (message.contains('sign up') || message.contains('signup')) {
        return 'Unable to create account. Please try again.';
      }
      return 'Authentication failed. Please try again.';
    }

    if (failure is TranscriptionFailure) {
      return 'Unable to process your recording. Please try again.';
    }

    if (failure is LLMProcessingFailure ||
        failure is ModelNotFoundFailure ||
        failure is GeminiAPIFailure) {
      return 'Unable to process your request. Please try again.';
    }

    if (failure is RecordingFailure || failure is AudioProcessingFailure) {
      return 'Unable to record audio. Please try again.';
    }

    if (failure is AudioPermissionFailure) {
      // Permission messages are already user-friendly, return as-is
      return failure.message;
    }

    if (failure is StorageFailure ||
        failure is DatabaseFailure ||
        failure is CacheFailure) {
      return _getContextMessage(
        context,
        defaultMessage: 'Unable to save your data. Please try again.',
        paymentsMessage: 'Unable to save payment. Please try again.',
        notesMessage: 'Unable to save note. Please try again.',
        eventsMessage: 'Unable to save event. Please try again.',
      );
    }

    if (failure is NoteNotFoundFailure) {
      return 'Note not found.';
    }

    if (failure is NoteSaveFailure) {
      return 'Unable to save note. Please try again.';
    }

    if (failure is NoteDeleteFailure) {
      return 'Unable to delete note. Please try again.';
    }

    if (failure is ValidationFailure || failure is InvalidInputFailure) {
      return 'Invalid input. Please check your information and try again.';
    }

    if (failure is ExportFailure) {
      return 'Unable to export. Please try again.';
    }

    if (failure is FilePermissionFailure) {
      return 'Permission denied. Please grant file access and try again.';
    }

    // Generic fallback for unknown errors
    return _getContextMessage(
      context,
      defaultMessage: 'An unexpected error occurred. Please try again.',
      recordingMessage: 'Unable to process your recording. Please try again.',
      paymentsMessage: 'Unable to process payment. Please try again.',
      notesMessage: 'Unable to process note. Please try again.',
      eventsMessage: 'Unable to process event. Please try again.',
    );
  }

  /// Helper method to get context-specific messages
  static String _getContextMessage(
    String? context, {
    required String defaultMessage,
    String? recordingMessage,
    String? paymentsMessage,
    String? notesMessage,
    String? eventsMessage,
  }) {
    switch (context) {
      case 'recording':
        return recordingMessage ?? defaultMessage;
      case 'payments':
        return paymentsMessage ?? defaultMessage;
      case 'notes':
        return notesMessage ?? defaultMessage;
      case 'events':
        return eventsMessage ?? defaultMessage;
      default:
        return defaultMessage;
    }
  }

  /// Returns a user-friendly message for generic exceptions
  /// Used in catch blocks where we catch unknown exceptions
  static String getGenericErrorMessage({String? context}) {
    return _getContextMessage(
      context,
      defaultMessage: 'An unexpected error occurred. Please try again.',
      recordingMessage: 'Unable to process your recording. Please try again.',
      paymentsMessage: 'Unable to process payment. Please try again.',
      notesMessage: 'Unable to process note. Please try again.',
      eventsMessage: 'Unable to process event. Please try again.',
    );
  }
}
