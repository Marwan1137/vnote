import 'package:dartz/dartz.dart';
import '../../errors/failures.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  /// Sign in with email and password
  Future<Either<Failure, User>> signInWithEmailAndPassword(
    String email,
    String password,
  );

  /// Sign up with email and password
  Future<Either<Failure, User>> signUpWithEmailAndPassword(
    String email,
    String password,
  );

  /// Sign out current user
  Future<Either<Failure, void>> signOut();

  /// Send password reset email
  Future<Either<Failure, void>> sendPasswordResetEmail(String email);

  /// Reset password with OTP
  Future<Either<Failure, void>> resetPasswordWithOTP(
    String email,
    String otp,
    String newPassword,
  );

  /// Send email verification
  Future<Either<Failure, void>> sendEmailVerification();

  /// Check if email is verified
  Future<Either<Failure, bool>> checkEmailVerification();

  /// Get current authenticated user
  Future<Either<Failure, User?>> getCurrentUser();

  /// Check if email is already registered
  Future<Either<Failure, bool>> isEmailRegistered(String email);

  /// Reload user (to check verification status)
  Future<Either<Failure, User>> reloadUser();

  /// Update password (requires current password for reauthentication)
  Future<Either<Failure, void>> updatePassword(
    String currentPassword,
    String newPassword,
  );
}
