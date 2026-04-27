import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../notification_payload_handler.dart';
import 'reminder_service.dart';

/// Listens for new [social_notifications] rows via Realtime and shows a local banner.
/// Rows are created by DB triggers when someone likes/replies to your Emotion board post.
/// Apply `supabase/migrations/20260427120000_social_notifications.sql` and enable Realtime for the table.
class SocialNotificationService {
  SocialNotificationService._();
  static final SocialNotificationService instance = SocialNotificationService._();

  RealtimeChannel? _channel;
  StreamSubscription<AuthState>? _authSub;

  void start() {
    _authSub ??= Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.session != null) {
        unawaited(_attachRealtime());
        tryFlushPendingEmotionPostOpen();
      } else {
        _detachRealtime();
      }
    });
    unawaited(_attachRealtime());
  }

  void _detachRealtime() {
    final c = _channel;
    _channel = null;
    // ignore: discarded_futures
    c?.unsubscribe();
  }

  Future<void> _attachRealtime() async {
    _detachRealtime();
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return;
    }
    final ch = Supabase.instance.client.channel('social_notifications_${user.id}');
    ch.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'social_notifications',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'recipient_id',
        value: user.id,
      ),
      callback: (payload) {
        unawaited(_onInsert(payload));
      },
    );
    try {
      await ch.subscribe();
      _channel = ch;
    } catch (e) {
      debugPrint('social Realtime subscribe: $e');
    }
  }

  String _actorLabel(Map<String, dynamic> row) {
    final n = row['actor_name'] as String?;
    if (n != null && n.trim().isNotEmpty) {
      return n.trim();
    }
    return 'Someone';
  }

  Future<void> _onInsert(PostgresChangePayload payload) async {
    final row = payload.newRecord;
    final type = row['type'] as String?;
    final preview = row['preview_text'] as String?;
    final idStr = row['id']?.toString();
    final notifId = _stableIntId(idStr);
    final who = _actorLabel(row);
    final postId = row['post_id']?.toString() ?? '';

    final String title;
    final String body;
    switch (type) {
      case 'like':
        title = 'New like from $who';
        body = '$who liked your Emotion board post.';
        break;
      case 'reply':
        title = 'New reply from $who';
        body = (preview != null && preview.isNotEmpty)
            ? '$who: $preview'
            : '$who replied to your post.';
        break;
      default:
        title = 'Emotion board';
        body = 'You have a new notification.';
    }

    if (postId.isEmpty) {
      return;
    }
    try {
      await ReminderService.instance.showSocialInteractionNotification(
        title: title,
        body: body,
        postId: postId,
        notificationId: notifId,
      );
    } catch (e) {
      debugPrint('social notification: show failed $e');
    }
  }

  int _stableIntId(String? uuid) {
    if (uuid == null || uuid.isEmpty) {
      return DateTime.now().millisecondsSinceEpoch.remainder(2000000000);
    }
    return uuid.hashCode.abs() % 2000000000;
  }

  Future<List<Map<String, dynamic>>> fetchNotifications() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return [];
    }
    final response = await Supabase.instance.client
        .from('social_notifications')
        .select()
        .eq('recipient_id', user.id)
        .order('created_at', ascending: false)
        .limit(100);
    return (response as List<dynamic>)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<void> markAsRead(String notificationId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return;
    }
    await Supabase.instance.client.from('social_notifications').update({
      'read_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', notificationId).eq('recipient_id', user.id);
  }
}
