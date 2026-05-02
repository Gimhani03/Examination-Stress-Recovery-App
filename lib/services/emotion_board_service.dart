import 'package:supabase_flutter/supabase_flutter.dart';

import '../profile_avatar_presets.dart';

class EmotionBoardService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static int _countFromEmbed(Map<String, dynamic> post, String key) {
    final data = post[key] as List?;
    if (data == null || data.isEmpty) {
      return 0;
    }
    final c = data[0]['count'];
    if (c is int) {
      return c;
    }
    if (c is num) {
      return c.toInt();
    }
    return 0;
  }

  /// Applies true counts from related rows, not the denormalized [like_count] / [reply_count] columns.
  static void _applyEmbedCounts(Map<String, dynamic> post) {
    post['like_count'] = _countFromEmbed(post, 'emotion_likes');
    post['reply_count'] = _countFromEmbed(post, 'emotion_replies');
    post.remove('emotion_likes');
    post.remove('emotion_replies');
  }

  Future<List<Map<String, dynamic>>> fetchPosts({String? moodFilter}) async {
    // Embedded counts = source of truth (actual rows in emotion_likes / emotion_replies).
    final response = await _supabase
        .from('emotion_posts')
        .select('*, emotion_likes(count), emotion_replies(count)')
        .order('created_at', ascending: false);

    final posts = (response as List<dynamic>)
        .map((item) {
      final post = Map<String, dynamic>.from(item as Map);
      _applyEmbedCounts(post);
      return post;
    }).toList();

    if (moodFilter == null || moodFilter.isEmpty || moodFilter == 'All') {
      return posts;
    }
    return posts.where((post) => post['mood_type'] == moodFilter).toList();
  }

  /// Returns the set of post IDs that the current user has liked.
  /// Reads only the current user's own rows — always allowed by RLS.
  Future<Set<String>> fetchLikedPostIds() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return {};
    final response = await _supabase
        .from('emotion_likes')
        .select('post_id')
        .eq('user_id', user.id);
    return (response as List)
        .map((row) => row['post_id'] as String)
        .toSet();
  }

  /// One post by id (for deep links / reply screen). Counts match the feed (embedded aggregates).
  Future<Map<String, dynamic>?> fetchPostById(String postId) async {
    if (postId.isEmpty) {
      return null;
    }
    try {
      final r = await _supabase
          .from('emotion_posts')
          .select('*, emotion_likes(count), emotion_replies(count)')
          .eq('id', postId)
          .maybeSingle();
      if (r == null) {
        return null;
      }
      final post = Map<String, dynamic>.from(r);
      _applyEmbedCounts(post);
      return post;
    } on PostgrestException {
      return null;
    }
  }

  Future<Map<String, dynamic>> createPost({
    required String text,
    required String moodType,
    required String moodImage,
    required bool isAnonymous,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('User not signed in');
    }

    final displayName = _resolveDisplayName(user, isAnonymous);
    final avatarCols = _authorAvatarColumnsForInsert(user: user, anonymous: isAnonymous);
    final response = await _supabase.from('emotion_posts').insert({
      'user_id': user.id,
      'display_name': displayName,
      'is_anonymous': isAnonymous,
      'text': text,
      'mood_type': moodType,
      'mood_image': moodImage,
      'like_count': 0,
      'reply_count': 0,
      ...avatarCols,
    }).select().single();

    return Map<String, dynamic>.from(response);
  }

  Future<void> updatePostText({
    required String postId,
    required String text,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('User not signed in');
    }

    await _supabase
        .from('emotion_posts')
        .update({'text': text})
        .eq('id', postId)
        .eq('user_id', user.id);
  }

  Future<void> deletePost({required String postId}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('User not signed in');
    }

    await _supabase.from('emotion_posts').delete().eq('id', postId).eq('user_id', user.id);
  }

  Future<void> likePost({required String postId}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw const AuthException('User not signed in');
    try {
      await _supabase.from('emotion_likes').insert({
        'post_id': postId,
        'user_id': user.id,
      });
    } on PostgrestException catch (e) {
      if (e.code != '23505') rethrow; // ignore duplicate, rethrow anything else
    }
  }

  Future<void> unlikePost({required String postId}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw const AuthException('User not signed in');
    await _supabase
        .from('emotion_likes')
        .delete()
        .eq('post_id', postId)
        .eq('user_id', user.id);
  }

  Future<void> updateLikeCount({
    required String postId,
    required int likeCount,
  }) async {
    await _supabase.from('emotion_posts').update({'like_count': likeCount}).eq('id', postId);
  }

  Future<List<Map<String, dynamic>>> fetchReplies({required String postId}) async {
    final response = await _supabase
        .from('emotion_replies')
        .select()
        .eq('post_id', postId)
        .order('created_at', ascending: true);

    return response.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  Future<Map<String, dynamic>> addReply({
    required String postId,
    required String text,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('User not signed in');
    }

    final displayName = _resolveDisplayName(user, false);
    final avatarCols = _authorAvatarColumnsForInsert(user: user, anonymous: false);
    final response = await _supabase.from('emotion_replies').insert({
      'post_id': postId,
      'user_id': user.id,
      'display_name': displayName,
      'text': text,
      ...avatarCols,
    }).select().single();

    return Map<String, dynamic>.from(response);
  }

  Future<void> updateReplyCount({
    required String postId,
    required int replyCount,
  }) async {
    await _supabase.from('emotion_posts').update({'reply_count': replyCount}).eq('id', postId);
  }

  /// Overwrites avatar snapshot rows for this [user]'s authored content so the emotion board
  /// stays in sync with profile after preset / photo changes.
  ///
  /// Pass [authorAvatarSnapshot] after updating auth metadata so we do not rely on a possibly
  /// stale `user.userMetadata` in the [User] object returned from the SDK.
  ///
  /// Uses the same column shape as `_authorAvatarColumnsForInsert`.
  /// **Anonymous** posts (`is_anonymous = true`) are skipped so we never reveal an avatar link.
  /// Rows with `is_anonymous` NULL (legacy data) are included — treat NULL as non-anonymous
  /// in the filter below; see migration that backfills `false` where appropriate.
  Future<void> syncAuthorAvatarsForUser(
    User user, {
    Map<String, dynamic>? authorAvatarSnapshot,
  }) async {
    final patch = authorAvatarSnapshot ??
        _authorAvatarColumnsForInsert(user: user, anonymous: false);

    await _supabase.from('emotion_posts').update(patch).eq('user_id', user.id).or(
          'is_anonymous.eq.false,is_anonymous.is.null',
        );

    await _supabase.from('emotion_replies').update(patch).eq('user_id', user.id);
  }

  /// Rewrites **non-anonymous** posts' and **all** of this author's replies' `display_name`
  /// to match profile after editing `full_name` in Edit profile.
  ///
  /// Anonymous posts (`is_anonymous = true`) are skipped so labels stay `"Anonymous User"`.
  Future<void> syncAuthorDisplayName({
    required User user,
    required String displayName,
  }) async {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) return;

    await _supabase
        .from('emotion_posts')
        .update({'display_name': trimmed})
        .eq('user_id', user.id)
        .or('is_anonymous.eq.false,is_anonymous.is.null');

    await _supabase.from('emotion_replies').update({'display_name': trimmed}).eq('user_id', user.id);
  }

  static Map<String, dynamic> _authorAvatarColumnsForInsert({
    required User user,
    required bool anonymous,
  }) {
    if (anonymous) {
      return {
        'author_avatar_preset_id': null,
        'author_avatar_url': null,
      };
    }
    final rawPreset = user.userMetadata?[kAvatarPresetIdKey];
    final preset =
        rawPreset is String && rawPreset.trim().isNotEmpty ? rawPreset.trim() : null;
    final rawUrl = user.userMetadata?['avatar_url'];
    final url = rawUrl is String && rawUrl.trim().isNotEmpty ? rawUrl.trim() : null;
    return {
      'author_avatar_preset_id': preset,
      'author_avatar_url': url,
    };
  }

  String _resolveDisplayName(User user, bool isAnonymous) {
    if (isAnonymous) {
      return 'Anonymous User';
    }

    final metaName = user.userMetadata?['full_name'];
    final metaNameString = metaName is String ? metaName.trim() : metaName?.toString().trim();
    if (metaNameString != null && metaNameString.isNotEmpty) {
      return metaNameString;
    }

    final email = user.email ?? 'User';
    return email.split('@').first;
  }
}
