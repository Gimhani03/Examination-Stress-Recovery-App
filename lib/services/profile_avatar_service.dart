import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../profile_avatar_presets.dart';
import 'auth_service.dart';
import 'emotion_board_service.dart';

/// Profile pictures are **preset avatars** (`avatar_preset_id` in auth metadata).
///
/// Optionally, older accounts may still have `avatar_url` / `avatar_storage_path`
/// from a previous photo upload flow; switching to a preset clears those.
///
/// Historic: a public Storage bucket named `avatars` may still exist for legacy files.
class ProfileAvatarService {
  ProfileAvatarService({
    SupabaseClient? client,
    AuthService? authService,
    EmotionBoardService? emotionBoard,
  })  : _client = client ?? Supabase.instance.client,
        _authService = authService ?? AuthService(),
        _emotionBoard = emotionBoard ?? EmotionBoardService();

  final SupabaseClient _client;
  final AuthService _authService;
  final EmotionBoardService _emotionBoard;

  static const String bucketName = 'avatars';

  /// Validates [presetId] against [ProfileAvatarPreset.library], then saves it and clears
  /// any uploaded photo metadata (and deletes the storage object when possible).
  /// Returns the auth response from the metadata update (use [UserResponse.user] when
  /// merging further fields so the client does not resurrect stale avatar keys).
  Future<UserResponse> savePresetAvatar(String presetId) async {
    if (ProfileAvatarPreset.byId(presetId) == null) {
      throw Exception('Unknown avatar');
    }

    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Not signed in');
    }

    await _removeStoredAvatarObjectIfNeeded(user);

    final res = await _authService.mergeUserMetadata(
      {
        kAvatarPresetIdKey: presetId,
        'avatar_url': null,
        'avatar_storage_path': null,
      },
    );
    await _bestEffortSyncEmotionBoardAvatars(
      res,
      authorAvatarSnapshot: {
        'author_avatar_preset_id': presetId,
        'author_avatar_url': null,
      },
    );
    return res;
  }

  Future<void> _bestEffortSyncEmotionBoardAvatars(
    UserResponse res, {
    required Map<String, dynamic> authorAvatarSnapshot,
  }) async {
    final user = res.user ?? _client.auth.currentUser;
    if (user == null) return;
    try {
      await _emotionBoard.syncAuthorAvatarsForUser(
        user,
        authorAvatarSnapshot: authorAvatarSnapshot,
      );
    } on PostgrestException catch (e, stack) {
      debugPrint(
        'EmotionBoard avatar sync failed — check UPDATE RLS on emotion_posts / emotion_replies: '
        '${e.message} (code=${e.code})',
      );
      debugPrint('$stack');
    } catch (e, stack) {
      debugPrint('EmotionBoard avatar sync failed: $e\n$stack');
    }
  }

  Future<void> _removeStoredAvatarObjectIfNeeded(User user) async {
    final path = user.userMetadata?['avatar_storage_path'] as String?;
    if (path == null || path.isEmpty) return;
    try {
      await _client.storage.from(bucketName).remove([path]);
    } catch (_) {
      // Ignore; metadata will still be cleared.
    }
  }

  /// Deletes the Supabase Storage object for an old uploaded profile photo **before**
  /// clearing avatar metadata — call first, while [avatar_storage_path] is still readable.
  Future<void> deleteLegacyUploadedFileIfStored() async {
    final user = _client.auth.currentUser;
    if (user != null) {
      await _removeStoredAvatarObjectIfNeeded(user);
    }
  }

  /// Applies [authorAvatarSnapshot] to emotion-board rows (best-effort).
  Future<void> syncEmotionBoardAfterAuth({
    required UserResponse authResponse,
    required Map<String, dynamic> authorAvatarSnapshot,
  }) async {
    await _bestEffortSyncEmotionBoardAvatars(
      authResponse,
      authorAvatarSnapshot: authorAvatarSnapshot,
    );
  }

  /// Clears preset avatar and removes any uploaded photo metadata.
  Future<UserResponse> removeAvatar() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Not signed in');
    }

    await _removeStoredAvatarObjectIfNeeded(user);

    final res = await _authService.mergeUserMetadata(
      {},
      removeKeys: {
        kAvatarPresetIdKey,
        'avatar_url',
        'avatar_storage_path',
      },
    );
    await _bestEffortSyncEmotionBoardAvatars(
      res,
      authorAvatarSnapshot: {
        'author_avatar_preset_id': null,
        'author_avatar_url': null,
      },
    );
    return res;
  }
}
