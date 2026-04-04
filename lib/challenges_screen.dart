import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'homepage.dart';
import 'emotion_board_screen.dart';
import 'profile_screen.dart';
import 'recovery_tips_screen.dart';
import 'services/gemini_challenges_service.dart';
import 'services/mood_log_service.dart';

const _pageBackground = Color(0xFFEDE9FE);
const _kNeoRadius = 22.0;

const _accentCoral = Color(0xFFEA580C);
const _accentPurple = Color(0xFF7C3AED);
const _cardGradientStart = Color(0xFFFFF7ED);
const _cardGradientEnd = Color(0xFFFFFBF5);
const _cardDoneGradientStart = Color(0xFFFFEDD5);
const _cardDoneGradientEnd = Color(0xFFFDE68A);
const _emojiWell = Color(0xFFFED7AA);
const _progressTrack = Color(0xFFFFEDD5);
const _checkMint = Color(0xFF5EEAD4);

List<BoxShadow> _challengesNeoShadows() => [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.28),
        offset: const Offset(4, 4),
        blurRadius: 0,
        spreadRadius: 0,
      ),
    ];

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  late List<_ChallengeItem> _challenges = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadChallenges();
  }

  Future<void> _loadChallenges() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final moodLog = await MoodLogService().getTodayMoodLog();
      if (moodLog == null) {
        // No mood log for today, use default challenges
        setState(() {
          _challenges = _getDefaultChallenges();
          _isLoading = false;
        });
        return;
      }

      final mood = moodLog['mood'] as String? ?? '';
      final sleepHours = moodLog['sleep_hours'] as String? ?? '';
      final goals = (moodLog['goals'] as List<dynamic>? ?? [])
          .map((g) => g.toString())
          .toList();

      final personalizedChallenges = await GeminiChallengesService().getTodayChallengesWithStatus(
        mood: mood,
        sleepHours: sleepHours,
        goals: goals,
      );

      setState(() {
        _challenges = personalizedChallenges
            .map((c) => _ChallengeItem(
                  title: c.title,
                  emoji: c.icon,
                  isDone: c.isDone,
                ))
            .toList();
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _errorMessage = 'Failed to load challenges: $error';
        _challenges = _getDefaultChallenges();
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!)),
        );
      }
    }
  }

  List<_ChallengeItem> _getDefaultChallenges() {
    return [
      _ChallengeItem(
        title: 'Review 2 chapters\nfor the exam',
        emoji: '📚',
        isDone: false,
      ),
      _ChallengeItem(
        title: 'Drink 2L water',
        emoji: '💧',
        isDone: false,
      ),
      _ChallengeItem(
        title: 'Take a 5 min break',
        emoji: '☕',
        isDone: false,
      ),
      _ChallengeItem(
        title: 'Go for a short walk',
        emoji: '🚶',
        isDone: false,
      ),
    ];
  }

  void _toggleChallenge(int index) async {
    HapticFeedback.lightImpact();
    setState(() {
      _challenges[index] = _challenges[index].copyWith(
        isDone: !_challenges[index].isDone,
      );
    });

    // Persist completion status
    final challenge = _challenges[index];
    try {
      await GeminiChallengesService().updateChallengeCompletion(
        title: challenge.title,
        completed: challenge.isDone,
      );
    } catch (error) {
      // Silently fail if update fails
    }
  }

  void _goTo(BuildContext context, Widget screen) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => screen),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _challenges.where((c) => c.isDone).length;
    final progress = _challenges.isEmpty ? 0.0 : completedCount / _challenges.length;

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
              'Challenges',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
                letterSpacing: -0.5,
                height: 1.1,
              ),
            ),
            Text(
              'Tasks from your check-in',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Colors.black.withValues(alpha: 0.38),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF0D9488),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    _ChallengesHeroBanner(completed: completedCount, total: _challenges.length),
                    const SizedBox(height: 20),
                    _ProgressSection(
                      progress: progress,
                      completed: completedCount,
                      total: _challenges.length,
                    ),
                    const SizedBox(height: 28),
                    Padding(
                      padding: const EdgeInsets.only(left: 2, bottom: 12),
                      child: Text(
                        'Your tasks',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.black.withValues(alpha: 0.88),
                          letterSpacing: -0.6,
                        ),
                      ),
                    ),
                    ..._challenges.asMap().entries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _ChallengeCard(
                              item: entry.value,
                              index: entry.key + 1,
                              onToggle: () => _toggleChallenge(entry.key),
                            ),
                          ),
                        ),
                    const SizedBox(height: 80),
                  ],
                ),
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
              icon: const Icon(Icons.home_outlined,
                  color: Color(0xFF115E59), size: 28),
              onPressed: () => _goTo(context, const HomePage()),
            ),
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline_rounded,
                  color: Color(0xFF115E59), size: 28),
              onPressed: () => _goTo(context, const EmotionBoardScreen()),
            ),
            IconButton(
              icon: const Icon(Icons.lightbulb_outline_rounded,
                  color: Color(0xFF115E59), size: 28),
              onPressed: () => _goTo(context, const RecoveryTipsScreen()),
            ),
            IconButton(
              icon: const Icon(Icons.person_outline_rounded,
                  color: Color(0xFF115E59), size: 28),
              onPressed: () => _goTo(context, const ProfileScreen()),
            ),
          ],
        ),
      ),
    );
  }
}

String _progressEncouragement(double p) {
  if (p >= 1) return 'You crushed it — amazing work.';
  if (p >= 0.75) return 'So close. One more push!';
  if (p >= 0.5) return 'More than halfway there.';
  if (p > 0) return 'Nice momentum — keep going.';
  return 'Small steps still move you forward.';
}

class _ChallengesHeroBanner extends StatelessWidget {
  const _ChallengesHeroBanner({
    required this.completed,
    required this.total,
  });

  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_cardGradientStart, _cardGradientEnd],
        ),
        borderRadius: BorderRadius.circular(_kNeoRadius),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: _challengesNeoShadows(),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _emojiWell,
              shape: BoxShape.circle,
              border: Border.all(
                color: _accentCoral.withValues(alpha: 0.35),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  offset: const Offset(2, 2),
                  blurRadius: 0,
                ),
              ],
            ),
            child: const Center(
              child: Text('🏆', style: TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  total == 0
                      ? 'No challenges yet'
                      : completed == total
                          ? 'All done for today'
                          : 'Today\'s challenges',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                    letterSpacing: -0.4,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  total == 0
                      ? 'Log your mood to get tasks matched to you.'
                      : completed == total
                          ? 'Great work — see you tomorrow.'
                          : 'Matched to your mood log. Tap a row when you\'re done.',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                    color: Colors.black87,
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

class _ProgressSection extends StatelessWidget {
  const _ProgressSection({
    required this.progress,
    required this.completed,
    required this.total,
  });

  final double progress;
  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0 : (progress * 100).round();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_cardGradientStart, _cardGradientEnd],
        ),
        borderRadius: BorderRadius.circular(_kNeoRadius),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: _challengesNeoShadows(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.bolt_rounded, color: _accentCoral, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today\'s progress',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.black.withValues(alpha: 0.88),
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _progressEncouragement(progress),
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        color: Colors.black.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$pct%',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: _accentCoral,
                      height: 1,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$completed of $total',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.black.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            height: 18,
            decoration: BoxDecoration(
              color: _progressTrack,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black, width: 2),
            ),
            clipBehavior: Clip.antiAlias,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 450),
                        curve: Curves.easeOutCubic,
                        height: 18,
                        width: constraints.maxWidth * progress.clamp(0.0, 1.0),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _accentCoral,
                              _accentCoral.withValues(alpha: 0.85),
                              _accentPurple.withValues(alpha: 0.9),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ChallengeItem {
  const _ChallengeItem({
    required this.title,
    required this.emoji,
    required this.isDone,
  });

  final String title;
  final String emoji;
  final bool isDone;

  _ChallengeItem copyWith({
    String? title,
    String? emoji,
    bool? isDone,
  }) {
    return _ChallengeItem(
      title: title ?? this.title,
      emoji: emoji ?? this.emoji,
      isDone: isDone ?? this.isDone,
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({
    required this.item,
    required this.index,
    required this.onToggle,
  });

  final _ChallengeItem item;
  final int index;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(_kNeoRadius),
        onTap: onToggle,
        splashColor: _accentCoral.withValues(alpha: 0.12),
        highlightColor: _accentPurple.withValues(alpha: 0.06),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: item.isDone
                  ? [_cardDoneGradientStart, _cardDoneGradientEnd]
                  : [_cardGradientStart, _cardGradientEnd],
            ),
            borderRadius: BorderRadius.circular(_kNeoRadius),
            border: Border.all(color: Colors.black, width: 2),
            boxShadow: _challengesNeoShadows(),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 58,
                  height: 58,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: 4,
                        top: 4,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: _emojiWell,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _accentCoral.withValues(alpha: 0.35),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                offset: const Offset(2, 2),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              item.emoji,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: -2,
                        left: -2,
                        child: Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: item.isDone
                                ? _checkMint.withValues(alpha: 0.5)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(color: Colors.black, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                offset: const Offset(1, 1),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: Text(
                            '$index',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: item.isDone
                                  ? Colors.black.withValues(alpha: 0.5)
                                  : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.isDone)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _checkMint,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.black, width: 1.5),
                            ),
                            child: const Text(
                              'DONE',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: item.isDone
                              ? Colors.black.withValues(alpha: 0.45)
                              : Colors.black.withValues(alpha: 0.9),
                          height: 1.28,
                          letterSpacing: -0.2,
                          decoration: item.isDone
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    color: item.isDone ? _checkMint : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 2),
                    boxShadow: item.isDone
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              offset: const Offset(2, 2),
                              blurRadius: 0,
                            ),
                          ]
                        : null,
                  ),
                  child: item.isDone
                      ? const Icon(Icons.check_rounded, color: Colors.black87, size: 24)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
