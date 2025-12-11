import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:vnote/domain/usecases/usecase.dart';
import '../../../core/auth/usecases/check_email_verification_usecase.dart';
import '../../../core/auth/usecases/get_current_user_usecase.dart';
import '../../../core/auth/usecases/is_email_registered_usecase.dart';
import '../../../core/auth/usecases/reload_user_usecase.dart';
import '../../../core/auth/usecases/reset_password_usecase.dart';
import '../../../core/auth/usecases/send_email_verification_usecase.dart';
import '../../../core/auth/usecases/send_password_reset_usecase.dart';
import '../../../core/auth/usecases/sign_in_usecase.dart';
import '../../../core/auth/usecases/sign_out_usecase.dart';
import '../../../core/auth/usecases/sign_up_usecase.dart';
import '../../../core/auth/usecases/update_password_usecase.dart';
import '../../../core/errors/failures.dart';
import '../../../core/utils/user_friendly_errors.dart';
import 'auth_state.dart';

@injectable
class AuthCubit extends Cubit<AuthState> {
  final SignInUseCase signInUseCase;
  final SignUpUseCase signUpUseCase;
  final SignOutUseCase signOutUseCase;
  final SendPasswordResetUseCase sendPasswordResetUseCase;
  final ResetPasswordUseCase resetPasswordUseCase;
  final SendEmailVerificationUseCase sendEmailVerificationUseCase;
  final CheckEmailVerificationUseCase checkEmailVerificationUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final IsEmailRegisteredUseCase isEmailRegisteredUseCase;
  final ReloadUserUseCase reloadUserUseCase;
  final UpdatePasswordUseCase updatePasswordUseCase;

  AuthCubit(
    this.signInUseCase,
    this.signUpUseCase,
    this.signOutUseCase,
    this.sendPasswordResetUseCase,
    this.resetPasswordUseCase,
    this.sendEmailVerificationUseCase,
    this.checkEmailVerificationUseCase,
    this.getCurrentUserUseCase,
    this.isEmailRegisteredUseCase,
    this.reloadUserUseCase,
    this.updatePasswordUseCase,
  ) : super(AuthInitial()) {
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    if (isClosed) return;
    emit(AuthLoading());
    final result = await getCurrentUserUseCase(const NoParams());

    if (isClosed) return;

    result.fold(
      (failure) {
        if (!isClosed) {
          emit(AuthUnauthenticated());
        }
      },
      (user) {
        if (isClosed) return;

        if (user == null) {
          emit(AuthUnauthenticated());
        } else if (!user.isEmailVerified) {
          emit(AuthEmailNotVerified(user));
        } else {
          emit(AuthAuthenticated(user));
        }
      },
    );
  }

  Future<void> signIn(String email, String password) async {
    if (isClosed) return;
    emit(AuthLoading());
    final result = await signInUseCase(
      SignInParams(email: email, password: password),
    );

    if (isClosed) return;

    result.fold(
      (failure) {
        if (isClosed) return;

        if (failure is AuthFailure &&
            failure.message.contains('not verified')) {
          // Get user to show email not verified state
          _checkAuthState();
        } else {
          emit(
            AuthError(
              UserFriendlyErrors.getUserFriendlyMessage(
                failure,
                context: 'auth',
              ),
            ),
          );
        }
      },
      (user) {
        if (isClosed) return;

        if (!user.isEmailVerified) {
          emit(AuthEmailNotVerified(user));
        } else {
          emit(AuthAuthenticated(user));
        }
      },
    );
  }

  Future<void> signUp(String email, String password) async {
    if (isClosed) return;

    emit(AuthLoading());
    try {
      final result = await signUpUseCase(
        SignUpParams(email: email, password: password),
      );

      if (isClosed) {
        return;
      }

      result.fold(
        (failure) {
          if (isClosed) return;

          emit(
            AuthError(
              UserFriendlyErrors.getUserFriendlyMessage(
                failure,
                context: 'auth',
              ),
            ),
          );
        },
        (user) {
          if (isClosed) return;

          // After sign up, email is not verified yet
          emit(AuthEmailNotVerified(user));
        },
      );
    } catch (e) {
      if (isClosed) return;

      emit(
        AuthError(UserFriendlyErrors.getGenericErrorMessage(context: 'auth')),
      );
    }
  }

  Future<void> signOut() async {
    if (isClosed) return;
    emit(AuthLoading());
    final result = await signOutUseCase(const NoParams());

    if (isClosed) return;

    result.fold(
      (failure) {
        if (!isClosed) {
          emit(
            AuthError(
              UserFriendlyErrors.getUserFriendlyMessage(
                failure,
                context: 'auth',
              ),
            ),
          );
        }
      },
      (_) {
        if (!isClosed) {
          emit(AuthUnauthenticated());
        }
      },
    );
  }

  Future<void> sendPasswordResetEmail(String email) async {
    if (isClosed) return;
    emit(AuthLoading());
    final result = await sendPasswordResetUseCase(
      SendPasswordResetParams(email: email),
    );

    if (isClosed) return;

    result.fold(
      (failure) {
        if (!isClosed) {
          emit(
            AuthError(
              UserFriendlyErrors.getUserFriendlyMessage(
                failure,
                context: 'auth',
              ),
            ),
          );
        }
      },
      (_) {
        // Password reset email sent successfully
        // Emit AuthUnauthenticated to signal success and navigate to OTP screen
        if (!isClosed) {
          emit(AuthUnauthenticated());
        }
      },
    );
  }

  Future<void> resetPassword(
    String email,
    String otp,
    String newPassword,
  ) async {
    emit(AuthLoading());
    final result = await resetPasswordUseCase(
      ResetPasswordParams(email: email, otp: otp, newPassword: newPassword),
    );
    result.fold(
      (failure) => emit(
        AuthError(
          UserFriendlyErrors.getUserFriendlyMessage(failure, context: 'auth'),
        ),
      ),
      (_) {
        // After password reset, user needs to sign in again
        emit(AuthUnauthenticated());
      },
    );
  }

  Future<void> sendEmailVerification() async {
    if (isClosed) return;
    final result = await sendEmailVerificationUseCase(const NoParams());

    if (isClosed) return;

    result.fold(
      (failure) {
        if (!isClosed) {
          emit(
            AuthError(
              UserFriendlyErrors.getUserFriendlyMessage(
                failure,
                context: 'auth',
              ),
            ),
          );
        }
      },
      (_) {
        // Don't change state, UI will handle success message
      },
    );
  }

  Future<void> checkEmailVerification() async {
    if (isClosed) {
      return;
    }

    try {
      final result = await checkEmailVerificationUseCase(const NoParams());

      if (isClosed) {
        return;
      }

      result.fold(
        (failure) {
          if (!isClosed) {
            emit(
              AuthError(
                UserFriendlyErrors.getUserFriendlyMessage(
                  failure,
                  context: 'auth',
                ),
              ),
            );
          }
        },
        (isVerified) async {
          if (isClosed) {
            return;
          }

          if (isVerified) {
            // Reload user to get updated verification status
            final userResult = await reloadUserUseCase(const NoParams());

            if (isClosed) {
              return;
            }

            userResult.fold(
              (failure) {
                if (!isClosed) {
                  emit(
                    AuthError(
                      UserFriendlyErrors.getUserFriendlyMessage(
                        failure,
                        context: 'auth',
                      ),
                    ),
                  );
                }
              },
              (user) {
                if (!isClosed) {
                  emit(AuthAuthenticated(user));
                }
              },
            );
          } else {
            // Get current user to maintain state
            final userResult = await getCurrentUserUseCase(const NoParams());

            if (isClosed) {
              return;
            }

            userResult.fold(
              (failure) {
                if (!isClosed) {
                  emit(AuthUnauthenticated());
                }
              },
              (user) {
                if (!isClosed) {
                  if (user != null) {
                    emit(AuthEmailNotVerified(user));
                  } else {
                    emit(AuthUnauthenticated());
                  }
                }
              },
            );
          }
        },
      );
    } catch (e) {
      if (!isClosed) {
        emit(
          AuthError(UserFriendlyErrors.getGenericErrorMessage(context: 'auth')),
        );
      }
    }
  }

  Future<bool> isEmailRegistered(String email) async {
    final result = await isEmailRegisteredUseCase(
      IsEmailRegisteredParams(email: email),
    );
    return result.fold((failure) {
      emit(
        AuthError(
          UserFriendlyErrors.getUserFriendlyMessage(failure, context: 'auth'),
        ),
      );
      return false;
    }, (isRegistered) => isRegistered);
  }

  Future<void> reloadAuthState() async {
    await _checkAuthState();
  }

  Future<void> updatePassword(
    String currentPassword,
    String newPassword,
  ) async {
    if (isClosed) return;
    emit(AuthLoading());
    final result = await updatePasswordUseCase(
      UpdatePasswordParams(
        currentPassword: currentPassword,
        newPassword: newPassword,
      ),
    );

    if (isClosed) return;

    result.fold(
      (failure) {
        if (!isClosed) {
          emit(
            AuthError(
              UserFriendlyErrors.getUserFriendlyMessage(
                failure,
                context: 'auth',
              ),
            ),
          );
        }
      },
      (_) {
        // Password updated successfully, reload user to get updated state
        if (!isClosed) {
          _checkAuthState();
        }
      },
    );
  }
}
