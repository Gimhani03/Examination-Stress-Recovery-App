import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
      emailRedirectTo: null, // Disable email redirect for mobile app
    );
    return response;
  }

  /// Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response;
  }

  /// Sends a password recovery email (Supabase **Reset password** flow).
  ///
  /// For in-app OTP entry, edit the **Reset password** template in the Supabase
  /// dashboard (Authentication → Email Templates) and include `{{ .Token }}`
  /// (numeric one-time code; length can vary by project, often 6 or 8 digits).
  ///
  /// Optional [redirectTo] is only relevant if your template still relies on link-based
  /// recovery; allow-list the URL under Authentication → URL Configuration.
  Future<void> sendPasswordResetEmail(
    String email, {
    String? redirectTo,
  }) async {
    await _supabase.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: redirectTo,
    );
  }

  /// Verifies the recovery OTP from email. Opens a short-lived recovery session for
  /// [completePasswordRecovery].
  Future<void> verifyPasswordRecoveryOtp({
    required String email,
    required String otp,
  }) async {
    final trimmedEmail = email.trim();
    final code = otp.trim().replaceAll(RegExp(r'\s+'), '');
    final res = await _supabase.auth.verifyOTP(
      email: trimmedEmail,
      token: code,
      type: OtpType.recovery,
    );
    if (res.user == null) {
      throw Exception('Invalid or expired code. Request a new code and try again.');
    }
  }

  /// Sets a new password after [verifyPasswordRecoveryOtp], then signs out.
  Future<void> completePasswordRecovery(String newPassword) async {
    if (currentUser == null) {
      throw Exception('Session expired. Verify your code again.');
    }
    try {
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
    } catch (e) {
      await _supabase.auth.signOut();
      rethrow;
    }
    await _supabase.auth.signOut();
  }

  /// Verifies OTP and updates password in one call (legacy combined flow).
  Future<void> resetPasswordWithEmailOtp({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    await verifyPasswordRecoveryOtp(email: email, otp: otp);
    await completePasswordRecovery(newPassword);
  }

  /// Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Get current user
  User? get currentUser => _supabase.auth.currentUser;

  /// Check if user is signed in
  bool get isSignedIn => currentUser != null;

  /// Patches Auth `user_metadata` via Supabase **`updateUser`**, which **merges** server-side:
  /// omitting keys does **not** delete existing values — unset fields by sending **`null`**
  /// ([Supabase / GoTrue](https://github.com/supabase/gotrue-js/issues/411#issuecomment)).
  ///
  /// [removeKeys] are written as **`null`** in the payload so the server removes those keys.
  /// [patch] entries with **`null`** values do the same for that key.
  ///
  /// Pass [mergeFromUser] after a prior `updateUser` when `currentUser` may be stale briefly.
  Future<UserResponse> mergeUserMetadata(
    Map<String, dynamic> patch, {
    Set<String> removeKeys = const {},
    User? mergeFromUser,
  }) async {
    final user = mergeFromUser ?? currentUser;
    if (user == null) {
      throw Exception('Not signed in');
    }
    final meta = Map<String, dynamic>.from(user.userMetadata ?? {});
    for (final key in removeKeys) {
      meta[key] = null;
    }
    for (final e in patch.entries) {
      meta[e.key] = e.value;
    }
    return _supabase.auth.updateUser(UserAttributes(data: meta));
  }

  /// Updates the signed-in user's display name (`full_name` in user metadata).
  ///
  /// See [mergeFromUser] on [mergeUserMetadata].
  Future<UserResponse> updateFullName(
    String fullName, {
    User? mergeFromUser,
  }) async {
    return mergeUserMetadata(
      {'full_name': fullName.trim()},
      mergeFromUser: mergeFromUser,
    );
  }
}
