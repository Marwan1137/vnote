class AuthException implements Exception {
  final String message;

  const AuthException(this.message);

  @override
  String toString() => message;
}

class EmailAlreadyRegisteredException extends AuthException {
  const EmailAlreadyRegisteredException()
    : super(
        'Email already registered. If you can\'t remember your password, reset it.',
      );
}

class InvalidEmailException extends AuthException {
  const InvalidEmailException([String? suggestion])
    : super(
        suggestion != null
            ? 'Invalid email format. Did you mean $suggestion?'
            : 'Invalid email format. Please check your email address.',
      );
}

class WeakPasswordException extends AuthException {
  const WeakPasswordException()
    : super('Password is too weak. Please ensure it meets all requirements.');
}

class UserNotFoundException extends AuthException {
  const UserNotFoundException()
    : super('No account found with this email address.');
}

class WrongPasswordException extends AuthException {
  const WrongPasswordException()
    : super('Incorrect password. Please try again.');
}

class EmailNotVerifiedException extends AuthException {
  const EmailNotVerifiedException()
    : super(
        'Please verify your email address before signing in. Check your inbox for the verification email.',
      );
}

class InvalidOTPException extends AuthException {
  const InvalidOTPException()
    : super('Invalid OTP code. Please check and try again.');
}

class OTPExpiredException extends AuthException {
  const OTPExpiredException()
    : super('OTP code has expired. Please request a new one.');
}

class NetworkException extends AuthException {
  const NetworkException()
    : super('Network error. Please check your internet connection.');
}

class TooManyRequestsException extends AuthException {
  const TooManyRequestsException()
    : super('Too many requests. Please wait a moment before trying again.');
}
