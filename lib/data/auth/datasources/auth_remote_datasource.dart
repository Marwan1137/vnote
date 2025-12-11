import '../../../core/auth/entities/user.dart';

abstract class AuthRemoteDataSource {
  /// Sign in with email and password
  Future<User> signInWithEmailAndPassword(String email, String password);

  /// Sign up with email and password
  Future<User> signUpWithEmailAndPassword(String email, String password);

  /// Sign out current user
  Future<void> signOut();

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email);

  /// Verify OTP code (for password reset)
  Future<bool> verifyOTP(String email, String otp);

  /// Reset password with OTP
  Future<void> resetPasswordWithOTP(
    String email,
    String otp,
    String newPassword,
  );

  /// Send email verification
  Future<void> sendEmailVerification();

  /// Check if email is verified
  Future<bool> checkEmailVerification();

  /// Get current authenticated user
  Future<User?> getCurrentUser();

  /// Check if email is already registered
  Future<bool> isEmailRegistered(String email);

  /// Reload user (to check verification status)
  Future<User> reloadUser();
}
