class EmailValidator {
  // Standard email regex pattern
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  // Common email domain typos
  static final Map<String, String> _commonTypos = {
    'gmial.com': 'gmail.com',
    'gmail.co': 'gmail.com',
    'gmail.cm': 'gmail.com',
    'gmail.con': 'gmail.com',
    'gmai.com': 'gmail.com',
    'gmal.com': 'gmail.com',
    'gmil.com': 'gmail.com',
    'yahoo.co': 'yahoo.com',
    'yaho.com': 'yahoo.com',
    'yahoo.con': 'yahoo.com',
    'outlok.com': 'outlook.com',
    'outlook.co': 'outlook.com',
    'outlook.con': 'outlook.com',
    'hotmai.com': 'hotmail.com',
    'hotmail.co': 'hotmail.com',
    'hotmail.con': 'hotmail.com',
  };

  /// Validates email format
  static bool isValidFormat(String email) {
    return _emailRegex.hasMatch(email.trim());
  }

  /// Detects common email typos and suggests corrections
  static String? detectTypo(String email) {
    final trimmed = email.trim().toLowerCase();
    final parts = trimmed.split('@');

    if (parts.length != 2) {
      return null;
    }

    final domain = parts[1];
    final correctedDomain = _commonTypos[domain];

    if (correctedDomain != null) {
      return '${parts[0]}@$correctedDomain';
    }

    return null;
  }

  /// Validates email and returns error message if invalid
  static String? validate(String email) {
    if (email.trim().isEmpty) {
      return 'Email is required';
    }

    if (!isValidFormat(email)) {
      final suggestion = detectTypo(email);
      if (suggestion != null) {
        return 'Invalid email format. Did you mean $suggestion?';
      }
      return 'Invalid email format. Please check your email address.';
    }

    return null;
  }

  /// Validates email and returns suggestion if typo detected
  static EmailValidationResult validateWithSuggestion(String email) {
    final error = validate(email);
    final suggestion = detectTypo(email);

    return EmailValidationResult(
      isValid: error == null,
      error: error,
      suggestion: suggestion,
    );
  }
}

class EmailValidationResult {
  final bool isValid;
  final String? error;
  final String? suggestion;

  EmailValidationResult({required this.isValid, this.error, this.suggestion});
}
