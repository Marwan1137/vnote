enum PasswordStrength { weak, medium, strong }

class PasswordValidator {
  // Password constraints
  static const int minLength = 8;
  static const String uppercasePattern = r'[A-Z]';
  static const String lowercasePattern = r'[a-z]';
  static const String numberPattern = r'[0-9]';
  static const String specialCharPattern = r'[!@#$%^&*(),.?":{}|<>]';

  /// Validates password against all constraints
  static PasswordValidationResult validate(String password) {
    final errors = <String>[];
    final requirements = <String, bool>{};

    // Check length
    if (password.length < minLength) {
      errors.add('Password must be at least $minLength characters');
      requirements['At least $minLength characters'] = false;
    } else {
      requirements['At least $minLength characters'] = true;
    }

    // Check uppercase
    if (!RegExp(uppercasePattern).hasMatch(password)) {
      errors.add('Password must contain at least one uppercase letter');
      requirements['One uppercase letter'] = false;
    } else {
      requirements['One uppercase letter'] = true;
    }

    // Check lowercase
    if (!RegExp(lowercasePattern).hasMatch(password)) {
      errors.add('Password must contain at least one lowercase letter');
      requirements['One lowercase letter'] = false;
    } else {
      requirements['One lowercase letter'] = true;
    }

    // Check number
    if (!RegExp(numberPattern).hasMatch(password)) {
      errors.add('Password must contain at least one number');
      requirements['One number'] = false;
    } else {
      requirements['One number'] = true;
    }

    // Check special character
    if (!RegExp(specialCharPattern).hasMatch(password)) {
      errors.add(
        'Password must contain at least one special character (!@#\$%^&*)',
      );
      requirements['One special character'] = false;
    } else {
      requirements['One special character'] = true;
    }

    final isValid = errors.isEmpty;
    final strength = calculateStrength(password);

    return PasswordValidationResult(
      isValid: isValid,
      errors: errors,
      requirements: requirements,
      strength: strength,
    );
  }

  /// Calculates password strength
  static PasswordStrength calculateStrength(String password) {
    if (password.isEmpty) {
      return PasswordStrength.weak;
    }

    int score = 0;

    // Length score
    if (password.length >= minLength) score += 1;
    if (password.length >= 12) score += 1;

    // Character variety score
    if (RegExp(uppercasePattern).hasMatch(password)) score += 1;
    if (RegExp(lowercasePattern).hasMatch(password)) score += 1;
    if (RegExp(numberPattern).hasMatch(password)) score += 1;
    if (RegExp(specialCharPattern).hasMatch(password)) score += 1;

    // Determine strength
    if (score <= 2) {
      return PasswordStrength.weak;
    } else if (score <= 4) {
      return PasswordStrength.medium;
    } else {
      return PasswordStrength.strong;
    }
  }

  /// Validates password match (for confirm password)
  static bool passwordsMatch(String password, String confirmPassword) {
    return password == confirmPassword;
  }
}

class PasswordValidationResult {
  final bool isValid;
  final List<String> errors;
  final Map<String, bool> requirements;
  final PasswordStrength strength;

  PasswordValidationResult({
    required this.isValid,
    required this.errors,
    required this.requirements,
    required this.strength,
  });
}
