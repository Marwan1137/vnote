# Firebase Authentication Remote Data Source Implementation

## File Overview

**File Path:** `lib/data/auth/datasources/auth_remote_datasource_impl.dart`

**Purpose:** This file implements the `AuthRemoteDataSource` interface, providing a concrete implementation that interacts directly with Firebase Authentication. It serves as the data layer component that handles all authentication operations including sign in, sign up, password management, email verification, and user management.

**Role in Architecture:** This is part of the **Data Layer** in Clean Architecture. It acts as the boundary between the application's domain logic and Firebase's authentication service. It translates Firebase-specific exceptions into domain-specific exceptions, ensuring the upper layers remain decoupled from Firebase implementation details.

## Architecture Context

```
┌─────────────────────────────────────┐
│   Presentation Layer (Cubits)       │
│   - AuthCubit                       │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│   Domain Layer (Use Cases)          │
│   - SignInUseCase                   │
│   - SignUpUseCase                    │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│   Data Layer (Repository)           │
│   - AuthRepositoryImpl              │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│   Data Layer (Data Source)          │
│   - AuthRemoteDataSourceImpl        │ ← This file
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│   External Service                  │
│   - Firebase Authentication         │
└─────────────────────────────────────┘
```

## Dependencies

### External Packages
- **`firebase_auth`** (`^5.3.1`): Firebase Authentication SDK for Flutter. Provides the `FirebaseAuth` instance and all authentication methods.

### Internal Dependencies
- **`AuthRemoteDataSource`**: Abstract interface defining the contract this class implements.
- **`User`** (`core/auth/entities/user.dart`): Domain entity representing an authenticated user.
- **`auth_exceptions`** (`core/auth/exceptions/auth_exceptions.dart`): Custom exception classes for authentication errors.
- **`exceptions.dart`** (`core/errors/exceptions.dart`): Base exception classes like `ServerException`.

## Detailed Code Walkthrough

### Class Declaration and Constructor

```dart
@LazySingleton(as: AuthRemoteDataSource)
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final firebase_auth.FirebaseAuth _firebaseAuth;

  AuthRemoteDataSourceImpl(this._firebaseAuth);
```

**Why `@LazySingleton`?**
- The `@LazySingleton` annotation from the `injectable` package ensures this class is created only once and only when first needed (lazy initialization).
- This is important because Firebase Auth is a singleton service, and we want to reuse the same instance throughout the app lifecycle.
- The `as: AuthRemoteDataSource` parameter tells the dependency injection system to register this implementation under the abstract interface, allowing other parts of the app to depend on the interface rather than the concrete implementation.

**Why inject `FirebaseAuth`?**
- Dependency injection makes the class testable. In tests, we can inject a mock `FirebaseAuth` instance.
- It follows the Dependency Inversion Principle - the class depends on an abstraction (FirebaseAuth interface) rather than creating it directly.
- The `FirebaseAuth` instance is registered in `register_module.dart` as a lazy singleton, ensuring consistency across the app.

### User Mapping Methods

#### `_mapFirebaseUser` Method

```dart
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
```

**Purpose:** Converts a Firebase `UserCredential` object (returned from sign-in/sign-up operations) into our domain `User` entity.

**Why this mapping is necessary:**
- **Abstraction:** Our domain layer shouldn't know about Firebase's `UserCredential` or `User` types. This mapping creates a clean boundary.
- **Data Transformation:** Firebase's user object contains more information than we need. This method extracts only the relevant fields.
- **Null Safety:** The method handles potential null values from Firebase, providing defaults (empty string for email) when necessary.

**Key Design Decisions:**
1. **`email ?? ''`**: If email is null (shouldn't happen with email/password auth, but defensive programming), we use an empty string. This prevents null reference errors in the domain layer.
2. **`metadata.creationTime`**: We extract the account creation time, which is useful for displaying "Member since" information in the UI.
3. **Throwing `ServerException`**: If the credential is null, this indicates a server-side issue, not a user error, so we throw a server exception rather than an auth exception.

#### `_mapFirebaseUserFromAuth` Method

```dart
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
```

**Purpose:** Similar to `_mapFirebaseUser`, but works directly with a `firebase_auth.User` object instead of `UserCredential`.

**Why two mapping methods?**
- Firebase returns different types in different scenarios:
  - `UserCredential` is returned from sign-in/sign-up operations
  - `User` is returned when getting the current user or reloading user data
- Having separate methods makes the code clearer and avoids unnecessary null checks or type casting.

### Sign In Implementation

```dart
@override
Future<User> signInWithEmailAndPassword(String email, String password) async {
  try {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return _mapFirebaseUser(credential);
  } on firebase_auth.FirebaseAuthException catch (e) {
    // Error handling...
  } catch (e) {
    // Fallback error handling...
  }
}
```

**Why `email.trim()`?**
- Users often accidentally include leading/trailing spaces when typing their email.
- Trimming prevents authentication failures due to whitespace, improving user experience.
- We don't trim the password because passwords can legitimately start or end with spaces (though uncommon).

**Error Handling Strategy:**
The method uses a comprehensive error handling approach:

1. **Specific Firebase Exceptions First:** Catches `FirebaseAuthException` to handle Firebase-specific error codes.
2. **Error Code Mapping:** Maps Firebase error codes to domain-specific exceptions:
   - `user-not-found` → `UserNotFoundException`
   - `wrong-password` → `WrongPasswordException`
   - `invalid-email` → `InvalidEmailException`
   - `user-disabled` → Generic `AuthException` with descriptive message
   - `too-many-requests` → `TooManyRequestsException`
   - `network-request-failed` → `NetworkException`
3. **Fallback:** If the error code doesn't match known patterns, it uses the Firebase error message or a generic message.
4. **Re-throwing Domain Exceptions:** If the error is already a domain exception (from the catch block), it re-throws it to maintain the exception type.
5. **Server Exception for Unknown Errors:** Any other exception becomes a `ServerException`, indicating an unexpected server-side issue.

**Why this error handling approach?**
- **User-Friendly Messages:** Domain exceptions provide clear, user-friendly error messages that can be displayed directly in the UI.
- **Separation of Concerns:** The data layer translates technical Firebase errors into business-logic errors that the domain layer understands.
- **Maintainability:** If Firebase changes error codes, we only need to update this one file.

### Sign Up Implementation

```dart
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
```

**Key Differences from Sign In:**
- **`email-already-in-use`**: This error is specific to sign-up. It indicates the email is already registered.
- **`weak-password`**: Firebase validates password strength. This error occurs when the password doesn't meet Firebase's requirements (minimum 6 characters by default).
- **`internal-error`**: This is a catch-all for Firebase internal issues. The message is more detailed to help users understand it might be a configuration problem.

**Why the detailed `internal-error` message?**
- Internal errors are often caused by misconfiguration (missing Firebase setup, network issues, etc.).
- Providing a detailed message helps users understand they should check their connection or contact support if the issue persists.

### Sign Out Implementation

```dart
@override
Future<void> signOut() async {
  try {
    await _firebaseAuth.signOut();
  } catch (e) {
    throw ServerException('Sign out failed: $e');
  }
}
```

**Why is this so simple?**
- Sign out is a straightforward operation that rarely fails.
- If it does fail, it's almost always a server-side issue, so we throw a `ServerException`.
- There are no user-specific error cases (like wrong password) for sign out.

### Password Reset Email

```dart
@override
Future<void> sendPasswordResetEmail(String email) async {
  try {
    await _firebaseAuth.sendPasswordResetEmail(
      email: email.trim(),
      actionCodeSettings: firebase_auth.ActionCodeSettings(
        url: 'https://voya-cb3ce.firebaseapp.com',
        handleCodeInApp: true,
        androidPackageName: 'com.example.vnote',
        iOSBundleId: 'com.example.vnote',
      ),
    );
  } on firebase_auth.FirebaseAuthException catch (e) {
    // Error handling...
  }
}
```

**What is `ActionCodeSettings`?**
- This configuration tells Firebase how to handle the password reset link.
- **`url`**: The URL to redirect to after the user clicks the reset link (if opening in a browser).
- **`handleCodeInApp: true`**: Tells Firebase to try opening the link in the app if possible (deep linking).
- **`androidPackageName` and `iOSBundleId`**: These enable deep linking on mobile platforms. When the user clicks the reset link in their email, it can open directly in the app instead of a browser.

**Why deep linking?**
- Better user experience: Users stay in the app instead of switching to a browser.
- Seamless flow: The app can automatically extract the OTP code from the deep link URL.
- Security: The app can verify the OTP code securely.

**Error Handling:**
- Similar to sign-in, but with specific error codes for password reset:
  - `user-not-found`: The email isn't registered (we still send the email to prevent email enumeration attacks, but Firebase handles this).
  - `too-many-requests`: Prevents abuse of the password reset feature.

### Password Reset with OTP

```dart
@override
Future<void> resetPasswordWithOTP(
  String email,
  String otp,
  String newPassword,
  ) async {
  try {
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
```

**How OTP works:**
- When `sendPasswordResetEmail` is called, Firebase sends an email with a reset link.
- The link contains an action code (OTP) as a URL parameter.
- When the user clicks the link (or the app extracts the code from a deep link), the code is passed to `confirmPasswordReset`.
- Firebase validates the code and resets the password if valid.

**Error Codes:**
- **`expired-action-code`**: Password reset links expire after a certain time (default: 1 hour). This prevents old links from being used.
- **`invalid-action-code`**: The code is malformed or doesn't match any pending reset request.
- **`weak-password`**: The new password doesn't meet Firebase's requirements.

**Why check `user-not-found` here?**
- Although the user should exist (they requested the reset), edge cases might occur (account deleted between request and reset).
- This provides a clear error message if such a scenario occurs.

### Email Verification

#### Send Email Verification

```dart
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
```

**Why check for `currentUser`?**
- Email verification can only be sent for the currently authenticated user.
- If no user is signed in, there's no one to verify, so we throw an exception immediately.
- This prevents unnecessary API calls and provides immediate feedback.

**Why `too-many-requests`?**
- Firebase limits how frequently verification emails can be sent to prevent spam.
- This protects both the user's inbox and Firebase's email service from abuse.

#### Check Email Verification

```dart
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
```

**Why call `user.reload()`?**
- Firebase caches user data locally for performance.
- After a user verifies their email (by clicking the link), the local cache might still show `emailVerified: false`.
- `reload()` fetches the latest user data from Firebase servers, ensuring we get the updated verification status.
- This is crucial for the app to recognize when verification is complete.

**Why return `false` instead of throwing when user is null?**
- This method is often called to check verification status, not necessarily requiring an authenticated user.
- Returning `false` is a valid response meaning "not verified" (because there's no user to verify).
- Throwing an exception would be too aggressive for a status check.

### Get Current User

```dart
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
```

**Why return `User?` (nullable)?**
- When no user is signed in, `currentUser` is `null`, which is a valid state.
- Returning `null` allows the calling code to handle the unauthenticated state gracefully.
- This is different from methods like `signIn`, where a null user would indicate an error.

**Why use `_mapFirebaseUserFromAuth`?**
- `currentUser` returns a `firebase_auth.User` directly, not a `UserCredential`.
- We use the appropriate mapping method for the type we receive.

### Check if Email is Registered

```dart
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
```

**What is `fetchSignInMethodsForEmail`?**
- This Firebase method returns a list of sign-in methods available for an email address.
- For example, if an email is registered with password auth, it returns `['password']`.
- If the email isn't registered, it returns an empty list.

**Why return `false` on errors (except invalid email)?**
- If there's a network error or other issue, we can't definitively say the email is registered.
- Returning `false` (not registered) is safer than returning `true` (which might allow sign-up attempts that will fail).
- However, for `invalid-email`, we throw an exception because the input itself is invalid, not because of a server issue.

**Use Case:**
- This method is useful for sign-up flows to check if an email is already taken before the user fills out the entire form.
- It can also be used to show "Email already registered" hints in the UI.

### Reload User

```dart
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
```

**Why this method exists:**
- After operations like email verification, the user's data in Firebase might have changed.
- `reload()` fetches the latest data from Firebase servers.
- This ensures the app has the most up-to-date user information.

**Why throw exception if user is null?**
- Unlike `getCurrentUser()`, this method is specifically for reloading an existing user's data.
- If there's no user, there's nothing to reload, so it's an error condition.

### Update Password

```dart
@override
Future<void> updatePassword(
  String currentPassword,
  String newPassword,
) async {
  try {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const auth_exceptions.AuthException(
        'No user is currently signed in.',
      );
    }

    if (user.email == null) {
      throw const auth_exceptions.AuthException(
        'User email is not available.',
      );
    }

    // Reauthenticate user with current password
    final credential = firebase_auth.EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);

    // Update password
    await user.updatePassword(newPassword);
  } on firebase_auth.FirebaseAuthException catch (e) {
    if (e.code == 'wrong-password') {
      throw const auth_exceptions.WrongPasswordException();
    } else if (e.code == 'weak-password') {
      throw const auth_exceptions.WeakPasswordException();
    } else if (e.code == 'requires-recent-login') {
      throw const auth_exceptions.AuthException(
        'Please sign out and sign in again before changing your password.',
      );
    } else {
      throw auth_exceptions.AuthException(
        e.message ?? 'Failed to update password.',
      );
    }
  } catch (e) {
    if (e is auth_exceptions.AuthException) rethrow;
    throw ServerException('Failed to update password: $e');
  }
}
```

**Why reauthentication is required:**
- Firebase requires users to reauthenticate before changing sensitive information like passwords.
- This is a security measure to prevent unauthorized password changes (e.g., if someone gains temporary access to the device).
- The reauthentication must happen within a certain time window (usually the last hour of activity).

**The Two-Step Process:**
1. **Reauthenticate:** Verify the user knows their current password by creating credentials and calling `reauthenticateWithCredential`.
2. **Update Password:** After successful reauthentication, call `updatePassword` with the new password.

**Why check for email?**
- Email is required to create email/password credentials for reauthentication.
- If the user somehow doesn't have an email (shouldn't happen with email/password auth), we can't proceed.

**Error Code: `requires-recent-login`:**
- This occurs when the user hasn't authenticated recently enough.
- Firebase requires recent authentication (within the last hour by default) for sensitive operations.
- The error message guides the user to sign out and sign in again to refresh their authentication status.

## Error Handling Strategy

### Exception Hierarchy

```
Exception (Dart base)
├── ServerException (core/errors/exceptions.dart)
│   └── Unexpected server errors, network issues
└── AuthException (core/auth/exceptions/auth_exceptions.dart)
    ├── EmailAlreadyRegisteredException
    ├── InvalidEmailException
    ├── WeakPasswordException
    ├── UserNotFoundException
    ├── WrongPasswordException
    ├── EmailNotVerifiedException
    ├── InvalidOTPException
    ├── OTPExpiredException
    ├── NetworkException
    └── TooManyRequestsException
```

### Error Mapping Philosophy

1. **Firebase-Specific → Domain-Specific:** All Firebase error codes are mapped to domain exceptions that the business logic understands.
2. **User-Friendly Messages:** Domain exceptions contain messages that can be displayed directly to users.
3. **Preserve Exception Types:** If an error is already a domain exception, it's re-thrown to maintain type information.
4. **Fallback to ServerException:** Unknown errors become `ServerException`, indicating unexpected server-side issues.

### Why This Approach?

- **Testability:** Domain exceptions can be easily tested and mocked.
- **Maintainability:** If Firebase changes, only this file needs updates.
- **User Experience:** Clear, actionable error messages improve UX.
- **Separation of Concerns:** Upper layers don't need to know about Firebase error codes.

## Configuration Requirements

### Firebase Setup

1. **Firebase Project:** A Firebase project must be created at [Firebase Console](https://console.firebase.google.com/).
2. **Authentication Enabled:** Email/Password authentication must be enabled in Firebase Console.
3. **Platform Configuration:**
   - **Android:** `google-services.json` file in `android/app/`
   - **iOS:** `GoogleService-Info.plist` in `ios/Runner/`
   - **Web:** Firebase config in `firebase_options.dart`
4. **Dependencies:** `firebase_core` and `firebase_auth` packages in `pubspec.yaml`.

### Deep Linking Setup (for Password Reset)

1. **Android:** Configure intent filters in `AndroidManifest.xml` to handle password reset links.
2. **iOS:** Configure URL schemes in `Info.plist` to handle password reset links.
3. **Firebase Console:** Enable email action handlers in Authentication settings.

## Testing Considerations

### What Should Be Tested

1. **Successful Operations:**
   - Sign in with valid credentials returns a `User` entity.
   - Sign up creates a new user and returns a `User` entity.
   - Sign out completes without errors.
   - Password reset email is sent successfully.
   - Email verification is sent and checked correctly.

2. **Error Handling:**
   - Each Firebase error code maps to the correct domain exception.
   - Unknown errors become `ServerException`.
   - Null users are handled appropriately.

3. **User Mapping:**
   - `UserCredential` maps correctly to `User` entity.
   - `firebase_auth.User` maps correctly to `User` entity.
   - Null values are handled with defaults.

4. **Edge Cases:**
   - Email with whitespace is trimmed.
   - Null users return appropriate values or exceptions.
   - Network errors are caught and mapped correctly.

### How to Test

```dart
// Example test structure
test('signInWithEmailAndPassword maps Firebase errors correctly', () async {
  // Arrange: Mock FirebaseAuth to throw specific error
  when(mockFirebaseAuth.signInWithEmailAndPassword(...))
    .thenThrow(FirebaseAuthException(code: 'user-not-found'));
  
  // Act & Assert
  expect(
    () => datasource.signInWithEmailAndPassword('test@test.com', 'password'),
    throwsA(isA<UserNotFoundException>()),
  );
});
```

## Future Improvements

1. **Social Authentication:** Add support for Google Sign-In, Apple Sign-In, etc.
2. **Phone Authentication:** Implement phone number verification for password reset.
3. **Multi-Factor Authentication (MFA):** Add 2FA support for enhanced security.
4. **Account Linking:** Allow users to link multiple authentication methods to one account.
5. **Rate Limiting:** Implement client-side rate limiting to prevent abuse before hitting Firebase limits.
6. **Caching:** Cache user data locally to reduce Firebase API calls.
7. **Offline Support:** Handle offline scenarios gracefully with cached user data.

## Summary

This implementation serves as a robust bridge between Firebase Authentication and the application's domain layer. It provides:

- **Clean Abstraction:** Upper layers don't need to know about Firebase.
- **Comprehensive Error Handling:** All Firebase errors are mapped to meaningful domain exceptions.
- **Security:** Implements reauthentication for sensitive operations.
- **User Experience:** Handles edge cases (whitespace, null values) gracefully.
- **Maintainability:** Centralized Firebase interaction makes updates easier.

The code follows Clean Architecture principles, ensuring the app remains testable, maintainable, and scalable.
