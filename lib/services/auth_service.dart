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

  /// Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Get current user
  User? get currentUser => _supabase.auth.currentUser;

  /// Check if user is signed in
  bool get isSignedIn => currentUser != null;

  /// Merges [patch] into existing `user_metadata`. Keys in [removeKeys] are removed.
  /// Null values in [patch] remove that key.
  Future<UserResponse> mergeUserMetadata(
    Map<String, dynamic> patch, {
    Set<String> removeKeys = const {},
  }) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('Not signed in');
    }
    final meta = Map<String, dynamic>.from(user.userMetadata ?? {});
    for (final key in removeKeys) {
      meta.remove(key);
    }
    for (final e in patch.entries) {
      if (e.value == null) {
        meta.remove(e.key);
      } else {
        meta[e.key] = e.value;
      }
    }
    return _supabase.auth.updateUser(UserAttributes(data: meta));
  }

  /// Updates the signed-in user's display name (`full_name` in user metadata).
  Future<UserResponse> updateFullName(String fullName) async {
    return mergeUserMetadata({'full_name': fullName.trim()});
  }
}
