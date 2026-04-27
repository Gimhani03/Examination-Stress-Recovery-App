import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_navigator.dart';
import 'emotion_post_open_screen.dart';

const String kSocialPostPayloadPrefix = 'social_post:';

String? _pendingPostId;

/// Returns the emotion-board post id when [payload] is `social_post:<id>`, else null.
String? parseSocialPostNotificationPayload(String? payload) {
  final p = payload?.trim() ?? '';
  if (p.isEmpty) return null;
  if (!p.startsWith(kSocialPostPayloadPrefix)) return null;
  final id = p.substring(kSocialPostPayloadPrefix.length);
  if (id.isEmpty) return null;
  return id;
}

/// Called from [ReminderService] when the user taps a local notification.
void handleLocalNotificationResponse(NotificationResponse response) {
  final id = parseSocialPostNotificationPayload(response.payload);
  if (id != null) {
    openEmotionPostById(id);
  }
}

/// Opens the replies screen for a post. Uses [appNavigatorKey]; if the navigator
/// is not ready yet, stores a pending id for [tryFlushPendingEmotionPostOpen].
void openEmotionPostById(String postId) {
  if (postId.isEmpty) {
    return;
  }
  if (Supabase.instance.client.auth.currentUser == null) {
    if (kDebugMode) {
      debugPrint('notification: waiting for sign-in, queue post $postId');
    }
    _pendingPostId = postId;
    return;
  }
  final nav = appNavigatorKey.currentState;
  if (nav == null) {
    if (kDebugMode) {
      debugPrint('notification: navigator not ready, queue post $postId');
    }
    _pendingPostId = postId;
    return;
  }
  _pendingPostId = null;
  nav.push(
    MaterialPageRoute<void>(
      builder: (_) => EmotionPostOpenScreen(postId: postId),
    ),
  );
}

/// Call after the first frame on Home (or when the nav tree is mounted) so a
/// tap that arrived before the [Navigator] existed can still open the post.
void tryFlushPendingEmotionPostOpen() {
  final id = _pendingPostId;
  if (id == null) {
    return;
  }
  if (appNavigatorKey.currentState == null) {
    return;
  }
  _pendingPostId = null;
  openEmotionPostById(id);
}
