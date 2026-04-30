import 'package:flutter/material.dart';
import 'package:flutter_application_1/chat_screen.dart';
import 'package:flutter_application_1/homepage.dart';
import 'package:flutter_application_1/profile_screen.dart';
import 'package:flutter_application_1/recovery_tips_screen.dart';

/// Primary shell tabs — matches [HomePage] bar (purple active, grey inactive).
enum AppMainNavTab { home, chat, tips, profile }

/// Shared 4-tab bottom bar used on home, chat, tips, profile, and tool screens.
class AppMainBottomNav extends StatelessWidget {
  const AppMainBottomNav({
    super.key,
    this.current,
    this.tipsMood,
    this.tipsMoodImage,
  });

  /// Highlighted tab; null = no highlight (e.g. calendar, challenges).
  final AppMainNavTab? current;
  final String? tipsMood;
  final String? tipsMoodImage;

  static const Color _activePurple = Color(0xFF7C3AED);

  Color _iconColor(AppMainNavTab tab) {
    if (current == null) {
      return Colors.grey[400]!;
    }
    return current == tab ? _activePurple : Colors.grey[400]!;
  }

  void _go(BuildContext context, AppMainNavTab tab) {
    if (current == tab || !context.mounted) return;

    switch (tab) {
      case AppMainNavTab.home:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute<void>(builder: (_) => const HomePage()),
          (_) => false,
        );
        break;
      case AppMainNavTab.chat:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute<void>(builder: (_) => const ChatScreen()),
          (_) => false,
        );
        break;
      case AppMainNavTab.tips:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute<void>(
            builder: (_) => RecoveryTipsScreen(
              mood: tipsMood,
              moodImage: tipsMoodImage,
            ),
          ),
          (_) => false,
        );
        break;
      case AppMainNavTab.profile:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
          (_) => false,
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 14,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: Icon(
              Icons.home_rounded,
              color: _iconColor(AppMainNavTab.home),
              size: 28,
            ),
            onPressed: () => _go(context, AppMainNavTab.home),
          ),
          IconButton(
            icon: Icon(
              Icons.chat_bubble_outline_rounded,
              color: _iconColor(AppMainNavTab.chat),
              size: 28,
            ),
            onPressed: () => _go(context, AppMainNavTab.chat),
          ),
          IconButton(
            icon: Icon(
              Icons.lightbulb_rounded,
              color: _iconColor(AppMainNavTab.tips),
              size: 28,
            ),
            onPressed: () => _go(context, AppMainNavTab.tips),
          ),
          IconButton(
            icon: Icon(
              Icons.person_outline_rounded,
              color: _iconColor(AppMainNavTab.profile),
              size: 28,
            ),
            onPressed: () => _go(context, AppMainNavTab.profile),
          ),
        ],
      ),
    );
  }
}
