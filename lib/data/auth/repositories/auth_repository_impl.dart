import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../core/auth/entities/user.dart';
import '../../../core/auth/exceptions/auth_exceptions.dart' as auth_exceptions;
import '../../../core/auth/repositories/auth_repository.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/errors/failures.dart';
import '../datasources/auth_remote_datasource.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, User>> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final user = await remoteDataSource.signInWithEmailAndPassword(
        email,
        password,
      );

      // Check if email is verified
      if (!user.isEmailVerified) {
        return Left(AuthFailure('Email not verified'));
      }

      return Right(user);
    } on auth_exceptions.EmailNotVerifiedException {
      return Left(AuthFailure('Email not verified'));
    } on auth_exceptions.UserNotFoundException {
      return Left(AuthFailure('No account found with this email address.'));
    } on auth_exceptions.WrongPasswordException {
      return Left(AuthFailure('Incorrect password. Please try again.'));
    } on auth_exceptions.InvalidEmailException catch (e) {
      return Left(AuthFailure(e.message));
    } on auth_exceptions.NetworkException {
      return Left(
        NetworkFailure('Network error. Please check your internet connection.'),
      );
    } on auth_exceptions.AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, User>> signUpWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final user = await remoteDataSource.signUpWithEmailAndPassword(
        email,
        password,
      );

      // Send verification email
      try {
        await remoteDataSource.sendEmailVerification();
      } catch (e) {
        // If email verification fails, still return the user
        // The user can request verification email again later
        // Log the error but don't fail the sign-up
      }

      return Right(user);
    } on auth_exceptions.EmailAlreadyRegisteredException catch (e) {
      return Left(AuthFailure(e.message));
    } on auth_exceptions.InvalidEmailException catch (e) {
      return Left(AuthFailure(e.message));
    } on auth_exceptions.WeakPasswordException {
      return Left(
        AuthFailure(
          'Password is too weak. Please ensure it meets all requirements.',
        ),
      );
    } on auth_exceptions.NetworkException {
      return Left(
        NetworkFailure('Network error. Please check your internet connection.'),
      );
    } on auth_exceptions.AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(AuthFailure('Sign up failed: ${e.message}'));
    } catch (e) {
      return Left(
        AuthFailure(
          'Failed to create account. Please check your internet connection and try again.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await remoteDataSource.signOut();
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail(String email) async {
    try {
      await remoteDataSource.sendPasswordResetEmail(email);
      return const Right(null);
    } on auth_exceptions.UserNotFoundException {
      return Left(AuthFailure('No account found with this email address.'));
    } on auth_exceptions.InvalidEmailException catch (e) {
      return Left(AuthFailure(e.message));
    } on auth_exceptions.NetworkException {
      return Left(
        NetworkFailure('Network error. Please check your internet connection.'),
      );
    } on auth_exceptions.AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> verifyOTP(String email, String otp) async {
    try {
      final isValid = await remoteDataSource.verifyOTP(email, otp);
      return Right(isValid);
    } on auth_exceptions.InvalidOTPException {
      return Left(AuthFailure('Invalid OTP code. Please check and try again.'));
    } on auth_exceptions.OTPExpiredException {
      return Left(
        AuthFailure('OTP code has expired. Please request a new one.'),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> resetPasswordWithOTP(
    String email,
    String otp,
    String newPassword,
  ) async {
    try {
      await remoteDataSource.resetPasswordWithOTP(email, otp, newPassword);
      return const Right(null);
    } on auth_exceptions.InvalidOTPException {
      return Left(AuthFailure('Invalid OTP code. Please check and try again.'));
    } on auth_exceptions.OTPExpiredException {
      return Left(
        AuthFailure('OTP code has expired. Please request a new one.'),
      );
    } on auth_exceptions.WeakPasswordException {
      return Left(
        AuthFailure(
          'Password is too weak. Please ensure it meets all requirements.',
        ),
      );
    } on auth_exceptions.UserNotFoundException {
      return Left(AuthFailure('No account found with this email address.'));
    } on auth_exceptions.AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> sendEmailVerification() async {
    try {
      await remoteDataSource.sendEmailVerification();
      return const Right(null);
    } on auth_exceptions.AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> checkEmailVerification() async {
    try {
      final isVerified = await remoteDataSource.checkEmailVerification();
      return Right(isVerified);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      final user = await remoteDataSource.getCurrentUser();
      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> isEmailRegistered(String email) async {
    try {
      final isRegistered = await remoteDataSource.isEmailRegistered(email);
      return Right(isRegistered);
    } on auth_exceptions.InvalidEmailException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, User>> reloadUser() async {
    try {
      final user = await remoteDataSource.reloadUser();
      return Right(user);
    } on auth_exceptions.AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }
}
