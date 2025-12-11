// ignore_for_file: deprecated_member_use

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:injectable/injectable.dart';
import '../../../core/auth/entities/user.dart';
import '../../../core/auth/exceptions/auth_exceptions.dart' as auth_exceptions;
import '../../../core/errors/exceptions.dart';
import 'auth_remote_datasource.dart';

@LazySingleton(as: AuthRemoteDataSource)
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final firebase_auth.FirebaseAuth _firebaseAuth;

  AuthRemoteDataSourceImpl(this._firebaseAuth);

  User _mapFirebaseUser(firebase_auth.UserCredential? credential) {
    if (credential?.user == null) {
      throw ServerException('User is null');
    }
    final firebaseUser = credential!.user!;
    return User(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName,
      isEmailVerified: firebaseUser.emailVerified,
      createdAt: firebaseUser.metadata.creationTime,
    );
  }

  User _mapFirebaseUserFromAuth(firebase_auth.User? firebaseUser) {
    if (firebaseUser == null) {
      throw ServerException('User is null');
    }
    return User(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName,
      isEmailVerified: firebaseUser.emailVerified,
      createdAt: firebaseUser.metadata.creationTime,
    );
  }

  @override
  Future<User> signInWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return _mapFirebaseUser(credential);
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw const auth_exceptions.UserNotFoundException();
      } else if (e.code == 'wrong-password') {
        throw const auth_exceptions.WrongPasswordException();
      } else if (e.code == 'invalid-email') {
        throw const auth_exceptions.InvalidEmailException();
      } else if (e.code == 'user-disabled') {
        throw const auth_exceptions.AuthException(
          'This account has been disabled.',
        );
      } else if (e.code == 'too-many-requests') {
        throw const auth_exceptions.TooManyRequestsException();
      } else if (e.code == 'network-request-failed') {
        throw const auth_exceptions.NetworkException();
      } else {
        throw auth_exceptions.AuthException(
          e.message ?? 'Sign in failed. Please try again.',
        );
      }
    } catch (e) {
      if (e is auth_exceptions.AuthException) rethrow;
      throw ServerException('Sign in failed: $e');
    }
  }

  @override
  Future<User> signUpWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return _mapFirebaseUser(credential);
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw const auth_exceptions.EmailAlreadyRegisteredException();
      } else if (e.code == 'invalid-email') {
        throw const auth_exceptions.InvalidEmailException();
      } else if (e.code == 'weak-password') {
        throw const auth_exceptions.WeakPasswordException();
      } else if (e.code == 'network-request-failed') {
        throw const auth_exceptions.NetworkException();
      } else if (e.code == 'internal-error') {
        throw auth_exceptions.AuthException(
          'Unable to create account. Please check your internet connection and try again. If the problem persists, there may be a configuration issue.',
        );
      } else {
        throw auth_exceptions.AuthException(
          e.message ?? 'Sign up failed. Please try again.',
        );
      }
    } catch (e) {
      if (e is auth_exceptions.AuthException) {
        rethrow;
      }
      throw ServerException('Sign up failed: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw ServerException('Sign out failed: $e');
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      // Send password reset email with link
      await _firebaseAuth.sendPasswordResetEmail(
        email: email.trim(),
        actionCodeSettings: firebase_auth.ActionCodeSettings(
          url: 'https://voya-cb3ce.firebaseapp.com',
          handleCodeInApp: true, // Handle the link in the app
          androidPackageName: 'com.example.vnote',
          iOSBundleId: 'com.example.vnote',
        ),
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw const auth_exceptions.UserNotFoundException();
      } else if (e.code == 'invalid-email') {
        throw const auth_exceptions.InvalidEmailException();
      } else if (e.code == 'network-request-failed') {
        throw const auth_exceptions.NetworkException();
      } else if (e.code == 'too-many-requests') {
        throw const auth_exceptions.TooManyRequestsException();
      } else {
        throw auth_exceptions.AuthException(
          e.message ?? 'Failed to send password reset email.',
        );
      }
    } catch (e) {
      if (e is auth_exceptions.AuthException) rethrow;
      throw ServerException('Failed to send password reset email: $e');
    }
  }

  @override
  Future<bool> verifyOTP(String email, String otp) async {
    // OTP verification is no longer used - password reset uses action codes from email links
    // This method is kept for backward compatibility but always returns false
    // The actual password reset is handled via the email link action code
    return false;
  }

  @override
  Future<void> resetPasswordWithOTP(
    String email,
    String otp,
    String newPassword,
  ) async {
    try {
      // The 'otp' parameter contains the action code from the email link
      // Verify the action code and reset password
      await _firebaseAuth.confirmPasswordReset(
        code: otp,
        newPassword: newPassword,
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'expired-action-code') {
        throw const auth_exceptions.OTPExpiredException();
      } else if (e.code == 'invalid-action-code') {
        throw const auth_exceptions.InvalidOTPException();
      } else if (e.code == 'weak-password') {
        throw const auth_exceptions.WeakPasswordException();
      } else if (e.code == 'user-not-found') {
        throw const auth_exceptions.UserNotFoundException();
      } else {
        throw auth_exceptions.AuthException(
          e.message ?? 'Failed to reset password.',
        );
      }
    } catch (e) {
      if (e is auth_exceptions.AuthException) rethrow;
      throw ServerException('Failed to reset password: $e');
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw const auth_exceptions.AuthException(
          'No user is currently signed in.',
        );
      }
      await user.sendEmailVerification();
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'too-many-requests') {
        throw const auth_exceptions.TooManyRequestsException();
      } else {
        throw auth_exceptions.AuthException(
          e.message ?? 'Failed to send verification email.',
        );
      }
    } catch (e) {
      if (e is auth_exceptions.AuthException) rethrow;
      throw ServerException('Failed to send verification email: $e');
    }
  }

  @override
  Future<bool> checkEmailVerification() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return false;
      }
      await user.reload();
      return user.emailVerified;
    } catch (e) {
      throw ServerException('Failed to check email verification: $e');
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return null;
      }
      return _mapFirebaseUserFromAuth(user);
    } catch (e) {
      throw ServerException('Failed to get current user: $e');
    }
  }

  @override
  Future<bool> isEmailRegistered(String email) async {
    try {
      final methods = await _firebaseAuth.fetchSignInMethodsForEmail(
        email.trim(),
      );
      return methods.isNotEmpty;
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'invalid-email') {
        throw const auth_exceptions.InvalidEmailException();
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<User> reloadUser() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw const auth_exceptions.AuthException(
          'No user is currently signed in.',
        );
      }
      await user.reload();
      return _mapFirebaseUserFromAuth(user);
    } catch (e) {
      if (e is auth_exceptions.AuthException) rethrow;
      throw ServerException('Failed to reload user: $e');
    }
  }
}
