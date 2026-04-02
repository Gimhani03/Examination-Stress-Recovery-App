import 'package:flutter/material.dart';
import 'homepage.dart';
import 'emotion_board_screen.dart';
import 'profile_screen.dart';
import 'breathing_exercise_screen.dart';
import 'services/gemini_tips_service.dart';
import 'services/mood_log_service.dart';

const double _kRtNeoRadius = 22;

List<BoxShadow> _rtNeoShadows() => [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.28),
        offset: const Offset(4, 4),
        blurRadius: 0,
        spreadRadius: 0,
      ),
    ];

class RecoveryTipsScreen extends StatefulWidget {
  final String? mood;
  /// Optional asset path when the parent already knows today’s mood (e.g. summary).
  final String? moodImage;

  const RecoveryTipsScreen({super.key, this.mood, this.moodImage});

  @override
  State<RecoveryTipsScreen> createState() => _RecoveryTipsScreenState();
}

class _RecoveryTipsScreenState extends State<RecoveryTipsScreen>
    with SingleTickerProviderStateMixin {
  final GeminiTipsService _tipsService = GeminiTipsService();
  final MoodLogService _moodService = MoodLogService();
  late Future<RecoveryTips> _tipsFuture;
  late String _mood;
  String _moodImage = 'assets/CalmIcon.png';
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _mood = 'calm';
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _tipsFuture = _loadMoodAndTips();
    _animController.forward();
  }

  @override
  void didUpdateWidget(covariant RecoveryTipsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_explicitMoodFromWidget(oldWidget.mood) !=
            _explicitMoodFromWidget(widget.mood) ||
        _trimOrNull(oldWidget.moodImage) != _trimOrNull(widget.moodImage)) {
      _tipsFuture = _loadMoodAndTips();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  String? _trimOrNull(String? s) {
    final t = s?.trim();
    if (t == null || t.isEmpty) return null;
    return t;
  }

  /// Non-null when the parent passed a mood; used for ordering vs DB and [didUpdateWidget].
  String? _explicitMoodFromWidget(String? mood) {
    final t = _trimOrNull(mood);
    if (t == null) return null;
    return _normalizeMood(t);
  }

  Future<RecoveryTips> _loadMoodAndTips() async {
    final todayLog = await _moodService.getTodayMoodLog();
    final loggedMood = todayLog?['mood'] as String?;
    final loggedImage = todayLog?['mood_image'] as String?;
    // Prefer explicit navigation args over DB so the header matches right after logging
    // even if read-after-write lags, and so Summary/Home can drive mood without a second fetch winning.
    final explicit = _explicitMoodFromWidget(widget.mood);
    final newMood = _normalizeMood(explicit ?? loggedMood);
    final fromWidget = _trimOrNull(widget.moodImage);
    final newImage = (fromWidget != null)
        ? fromWidget
        : ((loggedImage != null && loggedImage.isNotEmpty)
            ? loggedImage
            : _moodImageFor(newMood));

    _mood = newMood;
    _moodImage = newImage;
    if (mounted) {
      setState(() {});
    }

    return _tipsService.getTips(mood: _mood);
  }

  String _normalizeMood(String? mood) {
    final trimmed = mood?.trim();
    if (trimmed == null || trimmed.isEmpty) return 'calm';
    return trimmed.toLowerCase();
  }

  /// Returns the asset path that matches the mood log screen assets.
  String _moodImageFor(String mood) {
    switch (mood.toLowerCase()) {
      case 'anxious':
        return 'assets/AnxiousIcon.png';
      case 'tired':
        return 'assets/TiredIcon.png';
      case 'sad':
        return 'assets/SadIcon.png';
      default:
        return 'assets/CalmIcon.png';
    }
  }

  /// Capitalises the first letter for display (calm → Calm).
  String _moodLabel(String mood) {
    if (mood.isEmpty) return mood;
    return mood[0].toUpperCase() + mood.substring(1);
  }

  void _goTo(BuildContext context, Widget screen) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => screen),
      (route) => false,
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDE9FE),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: FutureBuilder<RecoveryTips>(
              future: _tipsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoading();
                }
                if (snapshot.hasError) {
                  return _buildError(snapshot.error);
                }
                final tips = snapshot.data!;
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
                    child: Column(
                      children: [
                        _buildRelaxationCard(tips),
                        const SizedBox(height: 16),
                        _buildRecoveryTipCard(tips),
                        const SizedBox(height: 16),
                        _buildMotivationCard(tips),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFF5F0FF),
            Color(0xFFEEF2FF),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        _goTo(context, const HomePage());
                      }
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black, width: 2),
                        boxShadow: _rtNeoShadows(),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.black87,
                        size: 18,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.menu_book_rounded,
                          color: Color(0xFF7C3AED).withValues(alpha: 0.85),
                          size: 22),
                      const SizedBox(width: 10),
                      Icon(Icons.psychology_rounded,
                          color: Color(0xFF0D9488).withValues(alpha: 0.85),
                          size: 22),
                      const SizedBox(width: 10),
                      Icon(Icons.auto_awesome_rounded,
                          color: Color(0xFFEA580C).withValues(alpha: 0.75),
                          size: 22),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recovery tips',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                            height: 1.1,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Personalised for your ${_moodLabel(_mood)} mood',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black.withValues(alpha: 0.48),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black, width: 2),
                      boxShadow: _rtNeoShadows(),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          _moodImage,
                          width: 28,
                          height: 28,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _moodLabel(_mood),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Loading ──────────────────────────────────────────────────────────────

  Widget _buildLoading() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 108,
              height: 108,
              decoration: BoxDecoration(
                color: const Color(0xFFCCFBF1),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.black, width: 2),
                boxShadow: _rtNeoShadows(),
              ),
              child: const Center(
                child: Text('🧘', style: TextStyle(fontSize: 48)),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Finding your\nperfect tips...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: const SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  minHeight: 8,
                  backgroundColor: Color(0xFFEDE4FF),
                  color: Color(0xFF0D9488),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Personalising just for you',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black.withValues(alpha: 0.42),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Error ────────────────────────────────────────────────────────────────

  Widget _buildError(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(_kRtNeoRadius),
                border: Border.all(color: Colors.black, width: 2),
                boxShadow: _rtNeoShadows(),
              ),
              child: Column(
                children: [
                  const Text('😵', style: TextStyle(fontSize: 56)),
                  const SizedBox(height: 14),
                  const Text(
                    'Oops! Something went wrong',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "We couldn't load your tips. No worries — just try again!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            GestureDetector(
              onTap: () {
                setState(() {
                  _tipsFuture = _tipsService.getTips(mood: _mood);
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF5EEAD4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black, width: 2),
                  boxShadow: _rtNeoShadows(),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, color: Colors.black87, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Try again',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Tip Cards ────────────────────────────────────────────────────────────

  Widget _buildRelaxationCard(RecoveryTips tips) {
    return _TipCard(
      stripColor: const Color(0xFF7C3AED),
      stripEmoji: '🧘',
      stripLabel: 'RELAXATION EXERCISE',
      cardColor: const Color(0xFFFAF5FF),
      borderColor: Colors.black,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tips.relaxationTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tips.relaxationInstruction,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 80,
                height: 80,
                child: Image.asset(
                  'assets/Meditation.png',
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
          if (tips.isBreathingExercise) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BreathingExerciseScreen(
                      mood: _mood,
                      breathingType: tips.breathingType,
                    ),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF5EEAD4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black, width: 2),
                  boxShadow: _rtNeoShadows(),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.air_rounded, color: Colors.black87, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Start breathing exercise',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecoveryTipCard(RecoveryTips tips) {
    return _TipCard(
      stripColor: const Color(0xFFF97316),
      stripEmoji: '💡',
      stripLabel: 'RECOVERY TIP',
      cardColor: const Color(0xFFFFFBF5),
      borderColor: Colors.black,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 66,
            height: 66,
            child: Image.asset('assets/RecoveryTip.png', fit: BoxFit.contain),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.1),
                  width: 1.5,
                ),
              ),
              child: Text(
                '"${tips.recoveryTip}"',
                style: const TextStyle(
                  fontSize: 13.5,
                  color: Colors.black87,
                  height: 1.6,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationCard(RecoveryTips tips) {
    return _TipCard(
      stripColor: const Color(0xFF1D4ED8),
      stripEmoji: '🌟',
      stripLabel: 'DAILY MOTIVATION',
      cardColor: const Color(0xFFEFF6FF),
      borderColor: Colors.black,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFBFDBFE).withValues(alpha: 0.6),
                  width: 1.5,
                ),
              ),
              child: Text(
                '"${tips.motivation}"',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.6,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 72,
            height: 72,
            child: Image.asset('assets/Motivation.png', fit: BoxFit.contain),
          ),
        ],
      ),
    );
  }

  // ─── Bottom Nav ───────────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    return Container(
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
          _navItem(
            Icons.home_outlined,
            false,
            () => _goTo(context, const HomePage()),
          ),
          _navItem(
            Icons.chat_bubble_outline_rounded,
            false,
            () => _goTo(context, const EmotionBoardScreen()),
          ),
          _navItem(Icons.lightbulb_rounded, true, () {}),
          _navItem(
            Icons.person_outline_rounded,
            false,
            () => _goTo(context, const ProfileScreen()),
          ),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, bool isActive, VoidCallback onTap) {
    return IconButton(
      icon: Icon(
        icon,
        color: isActive
            ? const Color(0xFF7C3AED)
            : const Color(0xFF115E59),
        size: 28,
      ),
      onPressed: onTap,
    );
  }
}

// ─── Reusable Card Widget ─────────────────────────────────────────────────────

class _TipCard extends StatelessWidget {
  final Color stripColor;
  final String stripEmoji;
  final String stripLabel;
  final Color cardColor;
  final Color borderColor;
  final Widget child;

  const _TipCard({
    required this.stripColor,
    required this.stripEmoji,
    required this.stripLabel,
    required this.cardColor,
    required this.borderColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(_kRtNeoRadius),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: _rtNeoShadows(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dark strip — same idea as [HomePage] `_HomeExamCard` header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              color: stripColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Text(stripEmoji, style: const TextStyle(fontSize: 17)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    stripLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.9,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ...List.generate(
                  3,
                  (i) => Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 1.0 - i * 0.3),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
}
