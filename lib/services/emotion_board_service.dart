import 'package:supabase_flutter/supabase_flutter.dart';

class EmotionBoardService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchPosts({String? moodFilter}) async {
    // Use embedded count so like_count always reflects actual rows in emotion_likes,
    // regardless of who is logged in or RLS on emotion_posts.
    final response = await _supabase
        .from('emotion_posts')
        .select('*, emotion_likes(count)')
        .order('created_at', ascending: false);

    final posts = response.map((item) {
      final post = Map<String, dynamic>.from(item);
      final likesData = post['emotion_likes'] as List?;
      post['like_count'] = (likesData != null && likesData.isNotEmpty)
          ? (likesData[0]['count'] as int? ?? 0)
          : 0;
      post.remove('emotion_likes');
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
    final response = await _supabase.from('emotion_posts').insert({
      'user_id': user.id,
      'display_name': displayName,
      'is_anonymous': isAnonymous,
      'text': text,
      'mood_type': moodType,
      'mood_image': moodImage,
      'like_count': 0,
      'reply_count': 0,
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
    final response = await _supabase.from('emotion_replies').insert({
      'post_id': postId,
      'user_id': user.id,
      'display_name': displayName,
      'text': text,
    }).select().single();

    return Map<String, dynamic>.from(response);
  }

  Future<void> updateReplyCount({
    required String postId,
    required int replyCount,
  }) async {
    await _supabase.from('emotion_posts').update({'reply_count': replyCount}).eq('id', postId);
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
