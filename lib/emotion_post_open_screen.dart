import 'package:flutter/material.dart';

import 'mood_flow_theme.dart';
import 'services/emotion_board_service.dart';
import 'view_replies_screen.dart';

/// Fetches a post by id, then shows [ViewRepliesScreen] (used from notifications / inbox).
class EmotionPostOpenScreen extends StatelessWidget {
  const EmotionPostOpenScreen({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: EmotionBoardService().fetchPostById(postId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: kMoodFlowBg,
            appBar: AppBar(
              backgroundColor: kMoodFlowBg,
              elevation: 0,
              title: const Text(
                'Post',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
              centerTitle: true,
            ),
            body: const Center(
              child: CircularProgressIndicator(color: kMoodFlowTealAccent),
            ),
          );
        }
        final m = snapshot.data;
        if (m == null) {
          return Scaffold(
            backgroundColor: kMoodFlowBg,
            appBar: AppBar(
              backgroundColor: kMoodFlowBg,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.black87),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  "This post is no longer available, or you don't have access.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withValues(alpha: 0.55),
                    height: 1.4,
                  ),
                ),
              ),
            ),
          );
        }
        final name = (m['display_name'] as String?)?.trim().isNotEmpty == true
            ? m['display_name'] as String
            : 'Post';
        final text = (m['text'] as String?) ?? '';
        final anon = m['is_anonymous'] == true;
        final rawPreset = m['author_avatar_preset_id'];
        final rawUrl = m['author_avatar_url'];
        final preset = !anon &&
                rawPreset is String &&
                rawPreset.trim().isNotEmpty
            ? rawPreset.trim()
            : null;
        final url = !anon && rawUrl is String && rawUrl.trim().isNotEmpty
            ? rawUrl.trim()
            : null;
        return ViewRepliesScreen(
          postId: postId,
          postName: name,
          postText: text,
          postAvatarPresetId: preset,
          postAvatarUrl: url,
          initialLikeCount: (m['like_count'] as int?) ?? 0,
          initialReplyCount: (m['reply_count'] as int?) ?? 0,
          moodImageAsset: m['mood_image'] as String?,
          useMintForCard: postId.hashCode.abs() % 2 == 0,
          onReplyAdded: (_) {},
        );
      },
    );
  }
}
