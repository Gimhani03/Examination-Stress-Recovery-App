import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'homepage.dart';
import 'emotion_board_screen.dart';
import 'recovery_tips_screen.dart';
import 'login_screen.dart';
import 'services/auth_service.dart';
import 'mood_log_screen.dart';
import 'mood_summary_screen.dart';
import 'services/mood_log_service.dart';
import 'services/profile_stats_service.dart';
import 'edit_profile_screen.dart';

const _pageBackground = Color(0xFFEDE9FE);
const _kNeoRadius = 22.0;
const _tealNav = Color(0xFF115E59);
const _cardCreamA = Color(0xFFFFF7ED);
const _cardCreamB = Color(0xFFFFFBF5);
const _mint = Color(0xFF5EEAD4);
const _accentPurple = Color(0xFF7C3AED);
const _accentTeal = Color(0xFF0D9488);
const _accentCoral = Color(0xFFEA580C);

List<BoxShadow> _profileNeoShadows() => [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.28),
        offset: const Offset(4, 4),
        blurRadius: 0,
        spreadRadius: 0,
      ),
    ];

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _goTo(BuildContext context, Widget screen) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => screen),
      (route) => false,
    );
  }

  Future<void> _handleCheckIn(BuildContext context) async {
    try {
      final existing = await MoodLogService().getTodayMoodLog();
      if (!context.mounted) return;

      if (existing != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MoodSummaryScreen(
              mood: (existing['mood'] as String?) ?? '',
              moodImage: (existing['mood_image'] as String?) ?? '',
              sleepHours: (existing['sleep_hours'] as String?) ?? '',
              goals: (existing['goals'] as List<dynamic>? ?? [])
                  .map((goal) => goal.toString())
                  .toList(),
            ),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MoodLogScreen()),
        );
      }
    } on AuthException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load mood log. Try again.')),
      );
    }
  }

  String _formatFocusTime(int totalSeconds) {
    if (totalSeconds <= 0) {
      return '0h';
    }

    final hours = totalSeconds ~/ 3600;
    if (hours > 0) {
      return '${hours}h';
    }

    final minutes = (totalSeconds % 3600) ~/ 60;
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final authStream = Supabase.instance.client.auth.onAuthStateChange;

    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        backgroundColor: _pageBackground,
        elevation: 0,
        leadingWidth: 56,
        leading: Center(
          child: PhysicalModel(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            elevation: 4,
            shadowColor: Colors.black38,
            child: GestureDetector(
              onTap: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  _goTo(context, const HomePage());
                }
              },
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 18),
              ),
            ),
          ),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Profile',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
                letterSpacing: -0.5,
                height: 1.1,
              ),
            ),
            Text(
              'You and your progress',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Colors.black.withValues(alpha: 0.38),
                letterSpacing: 0.15,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(12),
                  child: Ink(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black, width: 2),
                      boxShadow: _profileNeoShadows(),
                    ),
                    child: const SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(Icons.settings_outlined, color: Colors.black87, size: 22),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<AuthState>(
          stream: authStream,
          builder: (context, snapshot) {
            final user =
                snapshot.data?.session?.user ?? authService.currentUser;
            final isSignedIn = user != null;
            final metaName = user?.userMetadata?['full_name'];
            final metaNameString = metaName is String
                ? metaName.trim()
                : metaName?.toString().trim();
            final displayName = (metaNameString?.isNotEmpty == true)
                ? metaNameString!
                : (user?.email?.split('@').first ?? 'Guest');
            final email = user?.email ?? 'Sign in to see your details';
            final initials = displayName.isNotEmpty
                ? displayName.characters.first.toUpperCase()
                : 'G';
            final createdAt = user?.createdAt ?? '';
            final memberSince = createdAt.isNotEmpty
                ? 'Member since ${DateTime.tryParse(createdAt)?.year ?? ''}'
                : 'Welcome to your space';
            final rawAvatar = user?.userMetadata?['avatar_url'];
            final String? avatarUrl = rawAvatar is String && rawAvatar.trim().isNotEmpty
                ? rawAvatar.trim()
                : null;
            final statsFuture = isSignedIn
                ? ProfileStatsService().getStats()
                : null;

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 88),
              children: [
                if (isSignedIn)
                  _ProfileHeader(
                    displayName: displayName,
                    email: email,
                    badgeText: memberSince,
                    initials: initials,
                    avatarUrl: avatarUrl,
                  )
                else
                  _LoggedOutCard(
                    onLogin: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                  ),
                const SizedBox(height: 20),
                if (isSignedIn)
                  FutureBuilder<ProfileStats>(
                    future: statsFuture,
                    builder: (context, snapshot) {
                      final stats = snapshot.data;
                      if (snapshot.connectionState != ConnectionState.done) {
                        return _StatsRow(
                          moodLogsValue: '—',
                          focusTimeValue: '—',
                          goalsValue: '—',
                        );
                      }

                      return _StatsRow(
                        moodLogsValue: (stats?.moodLogsCount ?? 0).toString(),
                        focusTimeValue: _formatFocusTime(
                          stats?.totalFocusSeconds ?? 0,
                        ),
                        goalsValue: (stats?.goalsCount ?? 0).toString(),
                      );
                    },
                  )
                else
                  _StatsRow(
                    moodLogsValue: '0',
                    focusTimeValue: '0h',
                    goalsValue: '0',
                  ),
                const SizedBox(height: 20),
                _QuickActions(
                  onCheckIn: () => _handleCheckIn(context),
                ),
                const SizedBox(height: 20),
                _SectionTitle(title: 'Account'),
                const SizedBox(height: 8),
                _SettingsCard(
                  children: [
                    _SettingsTile(
                      icon: Icons.person_outline,
                      title: 'Edit profile',
                      subtitle: 'Update your details',
                      onTap: isSignedIn
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => const EditProfileScreen(),
                                ),
                              );
                            }
                          : null,
                    ),
                    const _SettingsTile(
                      icon: Icons.notifications_none,
                      title: 'Notifications',
                      subtitle: 'Reminder preferences',
                    ),
                    const _SettingsTile(
                      icon: Icons.lock_outline,
                      title: 'Privacy & security',
                      subtitle: 'Manage your data',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _SectionTitle(title: 'Support'),
                const SizedBox(height: 8),
                _SettingsCard(
                  children: const [
                    _SettingsTile(
                      icon: Icons.help_outline,
                      title: 'Help center',
                      subtitle: 'FAQs and guides',
                    ),
                    _SettingsTile(
                      icon: Icons.info_outline,
                      title: 'About',
                      subtitle: 'App version and info',
                    ),
                  ],
                ),
                if (isSignedIn) ...[
                  const SizedBox(height: 24),
                  _SignOutButton(
                    onSignOut: () async {
                      await authService.signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: Container(
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.home_outlined, color: _tealNav, size: 28),
              onPressed: () => _goTo(context, const HomePage()),
            ),
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline_rounded, color: _tealNav, size: 28),
              onPressed: () => _goTo(context, const EmotionBoardScreen()),
            ),
            IconButton(
              icon: const Icon(Icons.lightbulb_outline_rounded, color: _tealNav, size: 28),
              onPressed: () => _goTo(context, const RecoveryTipsScreen()),
            ),
            IconButton(
              icon: const Icon(Icons.person_outline_rounded, color: _tealNav, size: 28),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.displayName,
    required this.email,
    required this.badgeText,
    required this.initials,
    this.avatarUrl,
  });

  final String displayName;
  final String email;
  final String badgeText;
  final String initials;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_cardCreamA, _cardCreamB],
        ),
        borderRadius: BorderRadius.circular(_kNeoRadius),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: _profileNeoShadows(),
      ),
      child: Row(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _mint,
              border: Border.all(color: Colors.black, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  offset: const Offset(2, 2),
                  blurRadius: 0,
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: avatarUrl != null && avatarUrl!.isNotEmpty
                ? Image.network(
                    avatarUrl!,
                    fit: BoxFit.cover,
                    width: 76,
                    height: 76,
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                          height: 1,
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                        height: 1,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withValues(alpha: 0.48),
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoggedOutCard extends StatelessWidget {
  const _LoggedOutCard({required this.onLogin});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_kNeoRadius),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: _profileNeoShadows(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'You’re not signed in',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Log in for your stats, streaks, and personalized insights.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black.withValues(alpha: 0.52),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: _profileNeoShadows(),
            ),
            child: Material(
              color: _mint,
              borderRadius: BorderRadius.circular(14),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onLogin,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: const Text(
                    'Log in',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.moodLogsValue,
    required this.focusTimeValue,
    required this.goalsValue,
  });

  final String moodLogsValue;
  final String focusTimeValue;
  final String goalsValue;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Mood logs',
            value: moodLogsValue,
            icon: Icons.favorite_outline,
            color: _accentPurple,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            title: 'Focus time',
            value: focusTimeValue,
            icon: Icons.timer_outlined,
            color: _accentTeal,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            title: 'Goals',
            value: goalsValue,
            icon: Icons.emoji_events_outlined,
            color: _accentCoral,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: _profileNeoShadows(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.black, width: 1.5),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.black.withValues(alpha: 0.45),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onCheckIn});

  final VoidCallback onCheckIn;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 14, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_cardCreamA, _cardCreamB],
        ),
        borderRadius: BorderRadius.circular(_kNeoRadius),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: _profileNeoShadows(),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Today’s check-in',
                  style: TextStyle(
                    fontSize: 17,
                    color: Colors.black87,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Log mood and keep your streak going.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withValues(alpha: 0.48),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: _profileNeoShadows(),
            ),
            child: Material(
              color: _mint,
              borderRadius: BorderRadius.circular(14),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onCheckIn,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: const Text(
                    'Check in',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w900,
        color: Colors.black87,
        letterSpacing: -0.3,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_kNeoRadius),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: _profileNeoShadows(),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Container(height: 2, color: Colors.black),
          ],
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _cardCreamA,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: Icon(icon, color: _accentPurple, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black.withValues(alpha: 0.45),
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.black.withValues(alpha: 0.35), size: 26),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignOutButton extends StatelessWidget {
  const _SignOutButton({required this.onSignOut});

  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_kNeoRadius),
        boxShadow: _profileNeoShadows(),
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_kNeoRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onSignOut,
          borderRadius: BorderRadius.circular(_kNeoRadius),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_kNeoRadius),
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout_rounded, color: Colors.red.shade700, size: 22),
                const SizedBox(width: 10),
                Text(
                  'Sign out',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.red.shade700,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
