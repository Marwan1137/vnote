# Authentication Repository Implementation

## File Overview

**File Path:** `lib/data/auth/repositories/auth_repository_impl.dart`

**Purpose:** This file implements the `AuthRepository` interface, serving as the repository layer in Clean Architecture. It acts as an intermediary between the domain layer (use cases) and the data source layer (Firebase Auth implementation). The repository is responsible for:

1. **Error Translation:** Converting data source exceptions into domain failures using the `Either` type from the `dartz` package.
2. **Business Logic Enforcement:** Adding domain-specific rules (e.g., checking email verification before allowing sign-in).
3. **Abstraction:** Providing a clean interface that hides implementation details from the domain layer.

**Role in Architecture:** This is part of the **Data Layer** in Clean Architecture, specifically the Repository pattern. It sits between Use Cases (Domain Layer) and Data Sources (also Data Layer), providing a single source of truth for authentication operations.

## Architecture Context

```
┌─────────────────────────────────────┐
│   Presentation Layer               │
│   - AuthCubit (uses Use Cases)     │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│   Domain Layer                       │
│   - SignInUseCase                   │
│   - SignUpUseCase                    │
│   (depends on AuthRepository)       │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│   Data Layer (Repository)            │
│   - AuthRepositoryImpl               │ ← This file
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│   Data Layer (Data Source)           │
│   - AuthRemoteDataSourceImpl         │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│   External Service                   │
│   - Firebase Authentication           │
└─────────────────────────────────────┘
```

## Dependencies

### External Packages
- **`dartz`** (`^0.10.1`): Functional programming library providing the `Either<L, R>` type for error handling.
  - `Left<L>`: Represents a failure/error
  - `Right<R>`: Represents success/value

### Internal Dependencies
- **`AuthRepository`**: Abstract interface defining the repository contract.
- **`AuthRemoteDataSource`**: Data source interface for Firebase Auth operations.
- **`User`** (`core/auth/entities/user.dart`): Domain entity representing an authenticated user.
- **`Failures`** (`core/errors/failures.dart`): Domain failure types (AuthFailure, NetworkFailure, ServerFailure).
- **`auth_exceptions`** (`core/auth/exceptions/auth_exceptions.dart`): Custom exception classes.
- **`exceptions.dart`** (`core/errors/exceptions.dart`): Base exception classes.

## The Either Pattern

### What is Either?

`Either<L, R>` is a functional programming construct that represents a value that can be one of two types:
- **Left (L):** Typically represents an error or failure
- **Right (R):** Typically represents success or a value

### Why Use Either?

1. **Explicit Error Handling:** Forces developers to handle both success and failure cases.
2. **Type Safety:** The compiler ensures errors aren't ignored.
3. **Functional Style:** Aligns with functional programming principles.
4. **No Exceptions:** Errors are values, not thrown exceptions, making code more predictable.

### Example Usage

```dart
final result = await authRepository.signInWithEmailAndPassword(email, password);

result.fold(
  (failure) => print('Error: ${failure.message}'),  // Handle Left (failure)
  (user) => print('Success: ${user.email}'),       // Handle Right (success)
);
```

## Detailed Code Walkthrough

### Class Declaration and Constructor

```dart
@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl(this.remoteDataSource);
```

**Why `@LazySingleton`?**
- Ensures only one instance exists throughout the app lifecycle.
- Lazy initialization means it's only created when first needed.
- Registered as `AuthRepository` interface, allowing dependency on abstraction.

**Why inject `AuthRemoteDataSource`?**
- **Dependency Inversion:** Depends on interface, not concrete implementation.
- **Testability:** Can inject mock data source in tests.
- **Flexibility:** Can swap Firebase implementation for another auth provider without changing this code.

### Sign In Implementation

```dart
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
```

**Key Design Decisions:**

1. **Email Verification Check:**
   ```dart
   if (!user.isEmailVerified) {
     return Left(AuthFailure('Email not verified'));
   }
   ```
   - **Why here?** This is a business rule: users must verify their email before signing in.
   - **Why not in data source?** The data source should only handle Firebase operations. Business rules belong in the repository.
   - **Why return Left?** Even though Firebase returned a user, from the domain's perspective, this is a failure because the user can't proceed.

2. **Exception to Failure Mapping:**
   - Each exception type is caught and converted to a corresponding `Failure` type.
   - **`AuthException` → `AuthFailure`:** Authentication-related errors.
   - **`NetworkException` → `NetworkFailure`:** Network connectivity issues.
   - **`ServerException` → `ServerFailure`:** Unexpected server errors.

3. **Why Different Failure Types?**
   - **`AuthFailure`:** User can fix (wrong password, unverified email).
   - **`NetworkFailure`:** User needs to check internet connection.
   - **`ServerFailure`:** System issue, user should retry or contact support.
   - This allows the UI to show different messages or actions based on failure type.

4. **Catch-All Handler:**
   ```dart
   catch (e) {
     return Left(ServerFailure('Unexpected error: $e'));
   }
   ```
   - Catches any unexpected exceptions.
   - Converts to `ServerFailure` as a safe default.
   - Includes error details for debugging.

### Sign Up Implementation

```dart
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
```

**Key Design Decisions:**

1. **Verification Email in Sign-Up:**
   ```dart
   try {
     await remoteDataSource.sendEmailVerification();
   } catch (e) {
     // Don't fail sign-up if verification email fails
   }
   ```
   - **Why send automatically?** Better UX - user doesn't need to remember to verify.
   - **Why not fail if it fails?** The account was created successfully. The user can request verification email again later.
   - **Why nested try-catch?** We want to isolate verification email errors from sign-up errors. If verification fails, we still want to return the user.

2. **Error Message Strategy:**
   - Specific exceptions (like `WeakPasswordException`) get specific messages.
   - Generic `AuthException` uses the exception's message.
   - Catch-all provides a user-friendly message about checking internet connection.

3. **Why `AuthFailure` for ServerException in sign-up?**
   - From user's perspective, sign-up failure is an auth issue, not a generic server issue.
   - More actionable error message for the user.

### Sign Out Implementation

```dart
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
```

**Why return `void` in Right?**
- Sign out doesn't return a value, just indicates success.
- `Right(null)` or `const Right(null)` represents successful completion.
- The `void` type parameter makes it clear no value is expected.

**Why simple error handling?**
- Sign out rarely fails.
- If it does, it's almost always a server issue.
- No user-specific errors to handle.

### Password Reset Email

```dart
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
```

**Why handle `UserNotFoundException`?**
- Even though Firebase might not reveal if an email exists (for security), our data source might throw this.
- We provide a clear message to the user.
- Note: Firebase typically sends the email anyway to prevent email enumeration attacks.

### Password Reset with OTP

```dart
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
```

**Error Handling for OTP:**
- **`InvalidOTPException`:** User entered wrong code - can retry.
- **`OTPExpiredException`:** Code expired - user must request new one.
- **`WeakPasswordException`:** New password doesn't meet requirements.
- Each gets a specific, actionable error message.

### Email Verification

#### Send Email Verification

```dart
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
```

**Simple Implementation:**
- Just forwards the request to data source.
- Maps exceptions to failures.
- No additional business logic needed.

#### Check Email Verification

```dart
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
```

**Why return `bool`?**
- The method returns whether email is verified or not.
- `Right(true)` = verified, `Right(false)` = not verified.
- This allows the calling code to check status without exceptions.

### Get Current User

```dart
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
```

**Why nullable `User?`?**
- `Right(null)` = no user signed in (valid state).
- `Right(user)` = user is signed in.
- `Left(failure)` = error occurred while checking.

**Use Case:**
- UI can check if user is authenticated.
- If `Right(null)`, show sign-in screen.
- If `Right(user)`, show authenticated content.

### Check if Email is Registered

```dart
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
```

**Why handle `InvalidEmailException`?**
- If email format is invalid, we shouldn't proceed with the check.
- We return an `AuthFailure` with the exception's message.
- This provides immediate feedback to the user.

### Reload User

```dart
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
```

**Why non-nullable `User`?**
- This method is specifically for reloading an existing user.
- If there's no user, the data source throws an exception.
- We return `User` (not `User?`) because success means we have a user.

### Update Password

```dart
@override
Future<Either<Failure, void>> updatePassword(
  String currentPassword,
  String newPassword,
) async {
  try {
    await remoteDataSource.updatePassword(currentPassword, newPassword);
    return const Right(null);
  } on auth_exceptions.WrongPasswordException {
    return Left(AuthFailure('Current password is incorrect.'));
  } on auth_exceptions.WeakPasswordException {
    return Left(
      AuthFailure(
        'Password is too weak. Please ensure it meets all requirements.',
      ),
    );
  } on auth_exceptions.AuthException catch (e) {
    return Left(AuthFailure(e.message));
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message));
  } catch (e) {
    return Left(ServerFailure('Unexpected error: $e'));
  }
}
```

**Error Messages:**
- **`WrongPasswordException`:** Clear message that current password is wrong.
- **`WeakPasswordException`:** Guides user to meet password requirements.
- Other errors use exception messages or generic server failure.

## Error Handling Strategy

### Exception to Failure Mapping

| Exception Type | Failure Type | Reason |
|----------------|--------------|--------|
| `AuthException` | `AuthFailure` | User-actionable authentication errors |
| `NetworkException` | `NetworkFailure` | Connectivity issues |
| `ServerException` | `ServerFailure` | Unexpected server errors |
| Unknown Exception | `ServerFailure` | Safe fallback for unexpected errors |

### Why This Mapping?

1. **Domain Consistency:** All domain layer code works with `Failure` types, not exceptions.
2. **Type Safety:** `Either` forces error handling at compile time.
3. **User Experience:** Different failure types can trigger different UI responses.
4. **Testability:** Failures are easier to test than exceptions.

### Failure Types Explained

- **`AuthFailure`:** Errors the user can fix (wrong password, unverified email).
- **`NetworkFailure`:** Network connectivity issues - user should check connection.
- **`ServerFailure`:** System errors - user should retry or contact support.

## Repository Pattern Benefits

### 1. Single Source of Truth
- All authentication operations go through this repository.
- Consistent error handling across the app.
- Easy to add caching, logging, or analytics.

### 2. Abstraction
- Domain layer doesn't know about Firebase.
- Can swap Firebase for another provider without changing domain code.
- Easier to test with mocks.

### 3. Business Logic Centralization
- Email verification check in sign-in.
- Automatic verification email in sign-up.
- All business rules in one place.

### 4. Error Translation
- Converts technical exceptions to domain failures.
- Provides user-friendly error messages.
- Maintains type safety with `Either`.

## Testing Considerations

### What Should Be Tested

1. **Success Cases:**
   - Each method returns `Right` with correct value when data source succeeds.
   - Business logic (email verification check) is enforced.

2. **Error Mapping:**
   - Each exception type maps to correct failure type.
   - Error messages are preserved or enhanced appropriately.

3. **Edge Cases:**
   - Null values are handled correctly.
   - Unexpected exceptions become `ServerFailure`.

### Example Test Structure

```dart
test('signInWithEmailAndPassword returns AuthFailure when email not verified', () async {
  // Arrange
  final mockDataSource = MockAuthRemoteDataSource();
  final repository = AuthRepositoryImpl(mockDataSource);
  final unverifiedUser = User(/* ... */ isEmailVerified: false);
  
  when(mockDataSource.signInWithEmailAndPassword(any, any))
    .thenAnswer((_) async => unverifiedUser);
  
  // Act
  final result = await repository.signInWithEmailAndPassword('test@test.com', 'password');
  
  // Assert
  expect(result.isLeft(), true);
  result.fold(
    (failure) => expect(failure, isA<AuthFailure>()),
    (user) => fail('Should have returned failure'),
  );
});
```

## Future Improvements

1. **Caching:** Cache current user to reduce API calls.
2. **Retry Logic:** Automatic retry for network failures.
3. **Analytics:** Log authentication events for analytics.
4. **Rate Limiting:** Client-side rate limiting to prevent abuse.
5. **Offline Support:** Handle offline scenarios with cached data.
6. **Token Refresh:** Automatic token refresh before expiration.
7. **Session Management:** Track and manage multiple sessions.

## Summary

The `AuthRepositoryImpl` serves as a crucial layer in Clean Architecture:

- **Translates** technical exceptions to domain failures.
- **Enforces** business rules (email verification).
- **Abstracts** Firebase implementation from domain layer.
- **Provides** type-safe error handling with `Either`.
- **Centralizes** authentication logic in one place.

This implementation ensures the app remains maintainable, testable, and follows Clean Architecture principles while providing a clean API for the domain layer to use.
