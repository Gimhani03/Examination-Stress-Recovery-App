import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'emotion_board_screen.dart';
import 'emotion_post_open_screen.dart';
import 'login_screen.dart';
import 'mood_flow_theme.dart';
import 'services/social_notification_service.dart';

/// Likes and replies on your Emotion board posts. System settings live under Profile → Settings.
class NotificationInboxScreen extends StatefulWidget {
  const NotificationInboxScreen({super.key});

  @override
  State<NotificationInboxScreen> createState() => _NotificationInboxScreenState();
}

class _NotificationInboxScreenState extends State<NotificationInboxScreen> {
  final _service = SocialNotificationService.instance;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (Supabase.instance.client.auth.currentUser == null) {
      setState(() {
        _loading = false;
        _items = [];
        _error = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await _service.fetchNotifications();
      if (!mounted) {
        return;
      }
      setState(() {
        _items = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  String _actorName(Map<String, dynamic> row) {
    final n = row['actor_name'] as String?;
    if (n != null && n.trim().isNotEmpty) {
      return n.trim();
    }
    return 'Someone';
  }

  String _titleFor(Map<String, dynamic> row) {
    final t = row['type'] as String? ?? '';
    switch (t) {
      case 'like':
        return 'New like on your post';
      case 'reply':
        return '${_actorName(row)} replied';
      default:
        return 'Notification';
    }
  }

  String _subtitleFor(Map<String, dynamic> row) {
    final t = row['type'] as String? ?? '';
    final who = _actorName(row);
    final preview = row['preview_text'] as String?;
    if (t == 'reply' && preview != null && preview.isNotEmpty) {
      return preview;
    }
    if (t == 'like') {
      return '$who liked your Emotion board post.';
    }
    return 'Open to see activity on your post.';
  }

  String _timeLabel(String? iso) {
    if (iso == null || iso.isEmpty) {
      return '';
    }
    final d = DateTime.tryParse(iso)?.toLocal();
    if (d == null) {
      return '';
    }
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.isNegative) {
      return DateFormat.MMMd().add_jm().format(d);
    }
    if (diff.inSeconds < 45) {
      return 'Just now';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    }
    return DateFormat.MMMd().add_jm().format(d);
  }

  void _popOrHome() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = Supabase.instance.client.auth.currentUser != null;

    return Scaffold(
      backgroundColor: kMoodFlowBg,
      appBar: AppBar(
        backgroundColor: kMoodFlowBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          iconSize: 26,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: _popOrHome,
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
                letterSpacing: -0.5,
                height: 1.1,
              ),
            ),
            Text(
              'Likes & replies on your posts',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Colors.black.withValues(alpha: 0.45),
                height: 1.2,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: kMoodFlowTealAccent,
        onRefresh: _load,
        child: _buildBody(signedIn),
      ),
    );
  }

  Widget _buildBody(bool signedIn) {
    if (!signedIn) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.12),
          _EmptyStateCard(
            icon: Icons.notifications_active_outlined,
            iconBg: const Color(0xFFE8E0FF),
            iconColor: const Color(0xFF5B21B6),
            title: 'Sign in to see activity',
            body:
                'When people like or reply to your Emotion board posts, it all shows up here in one place.',
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: kMoodFlowTealAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Colors.black, width: 2),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
                );
              },
              child: const Text('Sign in', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      );
    }
    if (_loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.28),
          const Center(
            child: Column(
              children: [
                SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    color: kMoodFlowTealAccent,
                    strokeWidth: 3,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Loading your notifications…',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.08),
          _EmptyStateCard(
            icon: Icons.cloud_off_outlined,
            iconBg: const Color(0xFFFFE4E6),
            iconColor: const Color(0xFF9F1239),
            title: 'Could not load notifications',
            body:
                'Check your connection and try again. If you just set up the app, apply the social_notifications migration in Supabase and enable Realtime for that table.',
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: kMoodFlowTealNav,
                side: const BorderSide(color: Colors.black, width: 2),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('Try again', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(height: 16),
          SelectableText(
            _error!,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.black.withValues(alpha: 0.38),
              height: 1.35,
            ),
          ),
        ],
      );
    }
    if (_items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.1),
          _EmptyStateCard(
            icon: Icons.mark_chat_unread_outlined,
            iconBg: const Color(0xFFE3F2FD),
            iconColor: kMoodFlowTealAccent,
            title: "You're all caught up",
            body:
                'No likes or replies yet. Share something on your Emotion board - when others react, you will see it here.',
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: kMoodFlowTealNav,
                side: const BorderSide(color: Colors.black, width: 2),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => const EmotionBoardScreen()),
                );
              },
              icon: const Icon(Icons.edit_note_rounded, size: 22),
              label: const Text('Open Emotion board', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      );
    }
    final unreadCount = _items.where((r) => r['read_at'] == null).length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        if (unreadCount > 0)
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 4, bottom: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE9FE),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.black, width: 1.5),
                  ),
                  child: Text(
                    '$unreadCount new',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF4C1D95),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ...List.generate(_items.length, (i) {
          final row = _items[i];
          return Padding(
            padding: EdgeInsets.only(bottom: i == _items.length - 1 ? 0 : 12),
            child: _NotificationTile(
              row: row,
              title: _titleFor(row),
              subtitle: _subtitleFor(row),
              time: _timeLabel(row['created_at'] as String?),
              onTap: () async {
                final id = row['id']?.toString() ?? '';
                if (id.isNotEmpty) {
                  await _service.markAsRead(id);
                  if (mounted) {
                    setState(() {
                      _items[i] = {...row, 'read_at': DateTime.now().toUtc().toIso8601String()};
                    });
                  }
                }
                final postId = row['post_id']?.toString();
                if (postId != null && postId.isNotEmpty && context.mounted) {
                  await Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => EmotionPostOpenScreen(postId: postId),
                    ),
                  );
                }
              },
            ),
          );
        }),
      ],
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.body,
    this.child,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String body;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kMoodFlowNeoRadius),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: moodFlowNeoShadows(),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: Icon(icon, size: 34, color: iconColor),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
              letterSpacing: -0.4,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: Colors.black.withValues(alpha: 0.52),
              height: 1.45,
            ),
          ),
          if (child != null) ...[
            const SizedBox(height: 22),
            child!,
          ],
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.row,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.onTap,
  });

  final Map<String, dynamic> row;
  final String title;
  final String subtitle;
  final String time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final read = row['read_at'] != null;
    final type = row['type'] as String? ?? '';
    final (IconData icon, Color bg, Color fg) = switch (type) {
      'like' => (
          Icons.favorite_rounded,
          const Color(0xFFFFE4E6),
          const Color(0xFFE11D48),
        ),
      'reply' => (
          Icons.chat_bubble_rounded,
          const Color(0xFFE3F2FD),
          kMoodFlowTealAccent,
        ),
      _ => (
          Icons.notifications_none_rounded,
          const Color(0xFFF3E8FF),
          const Color(0xFF6B21A8),
        ),
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(kMoodFlowNeoRadius),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          decoration: BoxDecoration(
            color: read ? Colors.white : const Color(0xFFF8F5FF),
            borderRadius: BorderRadius.circular(kMoodFlowNeoRadius),
            border: Border.all(
              color: read ? Colors.black.withValues(alpha: 0.85) : const Color(0xFF4C1D95),
              width: read ? 2 : 2.5,
            ),
            boxShadow: moodFlowNeoShadows(),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: Icon(icon, color: fg, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.black.withValues(alpha: read ? 0.52 : 0.88),
                              height: 1.25,
                            ),
                          ),
                        ),
                        if (!read)
                          Padding(
                            padding: const EdgeInsets.only(left: 6, top: 2),
                            child: Container(
                              width: 9,
                              height: 9,
                              decoration: const BoxDecoration(
                                color: Color(0xFF7C3AED),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black.withValues(alpha: read ? 0.42 : 0.55),
                        height: 1.35,
                      ),
                    ),
                    if (time.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.black.withValues(alpha: 0.35),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 4, top: 10),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.black.withValues(alpha: read ? 0.22 : 0.35),
                  size: 26,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
