import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'mood_log_screen.dart';
import 'services/focus_timer_service.dart';
import 'mood_summary_screen.dart';
import 'emotion_board_screen.dart';
import 'challenges_screen.dart';
import 'calendar_screen.dart';
import 'focus_timer_screen.dart';
import 'recovery_tips_screen.dart';
import 'services/mood_log_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'music_recommendation_screen.dart';
import 'widgets/app_main_bottom_nav.dart';
import 'widgets/mini_player.dart';
import 'breathing_exercise_screen.dart';
import 'notification_inbox_screen.dart';
import 'services/reminder_service.dart';
import 'services/social_notification_service.dart';
import 'notification_payload_handler.dart' show tryFlushPendingEmotionPostOpen;

const double _kHomeNeoCardRadius = 22;

/// Slightly left of [Alignment.centerRight] so suggestion images sit clear of the card edge.
const Alignment _kSuggestionImageAlignment = Alignment(0.58, 0.0);

const int _kSuggestionTextFlex = 3;
const int _kSuggestionImageFlex = 2;
const double _kSuggestionImageMaxSide = 120;

List<BoxShadow> _homeNeoCardShadows() => [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.28),
        offset: const Offset(4, 4),
        blurRadius: 0,
        spreadRadius: 0,
      ),
    ];

BoxDecoration _suggestionSlideDecoration(Color background) {
  return BoxDecoration(
    color: background,
    borderRadius: BorderRadius.circular(_kHomeNeoCardRadius),
    border: Border.all(color: Colors.black, width: 2),
    boxShadow: _homeNeoCardShadows(),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late PageController _pageController;
  late Timer _autoScrollTimer;
  int _currentPage = 0;

  static const int _totalSessions = 4;
  int _completedSessions = 0;
  final FocusTimerService _focusTimerService = FocusTimerService();

  String? _currentMood;
  String? _currentMoodImage;

  String _sleepHoursDisplay(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '—';
    }
    if (value.trim() == '7h') {
      return '7 h';
    }
    return value;
  }

  String _sleepQualityText(String? value) {
    final display = _sleepHoursDisplay(value);
    if (display == '—') {
      return 'Log sleep';
    }
    if (display.contains('<')) {
      return 'Poor Sleep';
    }
    if (display.contains('4')) {
      return 'Okay Sleep';
    }
    if (display.contains('7')) {
      return 'Good Sleep';
    }
    return 'Sleep Logged';
  }

  Future<void> _loadFocusSessions() async {
    try {
      final summary = await _focusTimerService.getSummaryForDate(DateTime.now());
      if (!mounted) return;
      setState(() {
        _completedSessions = summary.sessionCount.clamp(0, _totalSessions);
      });
    } catch (e) {
      debugPrint('Failed to load focus sessions: $e');
    }
  }

  Future<void> _loadTodayMood() async {
    try {
      final existing = await MoodLogService().getTodayMoodLog();
      if (!mounted) return;
      if (existing != null) {
        setState(() {
          _currentMood = existing['mood'] as String?;
          _currentMoodImage = existing['mood_image'] as String?;
        });
      }
    } catch (e) {
      debugPrint('Failed to load today mood: $e');
    }
  }

  /// Re-schedule local notifications with latest mood text and calendar events.
  Future<void> _syncReminderSchedules() async {
    try {
      if (Supabase.instance.client.auth.currentUser == null) {
        return;
      }
      await ReminderService.instance.ensureInitialized();
      await ReminderService.instance.applySchedulesFromPreferences();
    } catch (e) {
      debugPrint('Reminder sync: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadFocusSessions();
    _loadTodayMood();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncReminderSchedules();
      SocialNotificationService.instance.start();
      tryFlushPendingEmotionPostOpen();
    });
    _pageController = PageController();
    _pageController.addListener(() {
      setState(() {
        double? page = _pageController.page;
        if (page != null) {
          _currentPage = page.round();
        }
      });
    });
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        int nextPage = (_currentPage + 1);
        _pageController.animateToPage(
          nextPage,
          duration: Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        ).then((_) {
          // When reaching page 4 (duplicate), jump back to 0 without animation
          if (nextPage == 4) {
            Future.delayed(Duration(milliseconds: 100), () {
              if (_pageController.hasClients) {
                _pageController.jumpToPage(0);
                _currentPage = 0;
              }
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _autoScrollTimer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _openMoodLog() async {
    try {
      final existing = await MoodLogService().getTodayMoodLog();
      if (!mounted) return;

      if (existing != null) {
        await Navigator.push(
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
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MoodLogScreen()),
        );
      }
      // Reload mood after returning
      _loadTodayMood();
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load mood log. Try again.')),
      );
    }
  }

  /// Compact top bar — light pastel header (calendar + notifications on the right).
  Widget _buildHomeHeader() {
    const headerBg = Color(0xFFE3F2FD);
    const headerInk = Color(0xFF0A1E3A);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: headerBg,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 8, 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Welcome',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: headerInk,
                  letterSpacing: -0.5,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.calendar_month_outlined, color: headerInk, size: 28),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CalendarScreen()),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_rounded, color: headerInk, size: 28),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationInboxScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _homeSectionTitle(String title, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: Color(0xFF4C1D95),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Colors.black.withValues(alpha: 0.42),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSuggestionsHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Suggestions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E1B4B),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Quick picks from this app',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Colors.black.withValues(alpha: 0.42),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _suggestionCardTitle(Color color) => TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: color,
        height: 1.12,
      );

  TextStyle _suggestionCardBody(Color color, {double alpha = 0.9}) =>
      TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: color.withValues(alpha: alpha),
        height: 1.28,
      );

  /// Image column for suggestion slides: width-capped so 120px art does not clip in a narrow flex slot.
  /// [nudgeRight] shifts the art east (same [width]/[height]) to clear tight copy e.g. "tracks".
  Widget _suggestionSlideImageCell(
    String assetPath, {
    double maxSide = _kSuggestionImageMaxSide,
    double nudgeRight = 0,
  }) {
    return Expanded(
      flex: _kSuggestionImageFlex,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final side = math.min(
            maxSide,
            math.max(48.0, constraints.maxWidth - 10),
          );
          Widget img = Image.asset(
            assetPath,
            width: side,
            height: side,
            fit: BoxFit.contain,
          );
          if (nudgeRight != 0) {
            img = Transform.translate(
              offset: Offset(nudgeRight, 0),
              child: img,
            );
          }
          return Align(
            alignment: _kSuggestionImageAlignment,
            child: img,
          );
        },
      ),
    );
  }

  /// First and last slides in the infinite PageView — opens [BreathingExerciseScreen].
  Widget _homeSuggestionBreathingSlide({double imageSize = _kSuggestionImageMaxSide}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                BreathingExerciseScreen(mood: _currentMood),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(left: 4, right: 4),
        decoration: _suggestionSlideDecoration(const Color(0xFFD1FAE5)),
        padding: const EdgeInsets.fromLTRB(18, 10, 14, 10),
        child: Row(
          children: [
            Expanded(
              flex: _kSuggestionTextFlex,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Breathing Exercise',
                    style: _suggestionCardTitle(const Color.fromARGB(255, 2, 74, 54)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Try out guided breathing matched to your mood.',
                    style: _suggestionCardBody(
                      const Color.fromARGB(255, 38, 113, 89),
                      alpha: 0.9,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            _suggestionSlideImageCell('assets/Breathing.png', maxSide: imageSize),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showHomeMusic =
        _currentMood != null && _currentMoodImage != null;
    final showHomeBreathing = _currentMood != null &&
        (_currentMood == 'anxious' ||
            _currentMood == 'sad' ||
            _currentMood == 'tired' ||
            _currentMood == 'calm');

    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      body: Column(
        children: [
          _buildHomeHeader(),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GestureDetector(
                    onTap: _openMoodLog,
                    child: _HomeExamCard(
                      stripColor: const Color(0xFF7C3AED),
                      stripEmoji: '📝',
                      stripLabel: 'How Are You Feeling Today?',
                      cardColor: const Color(0xFFF5F0FF),
                      child: Row(
                        children: [
                          Image.asset('assets/ChatIcon.png', width: 44, height: 44, fit: BoxFit.contain),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Log your mood',
                                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.black87),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Tap to check in for today',
                                  style: TextStyle(fontSize: 13, color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF7C3AED), size: 18),
                        ],
                      ),
                    ),
                  ),

              const SizedBox(height: 28),

              _buildSuggestionsHeader(),

              // Suggestions Slider
              SizedBox(
                height: 170,
                child: PageView(
                  controller: _pageController,
                  padEnds: true,
                  pageSnapping: true,
                  physics: ClampingScrollPhysics(),
                  clipBehavior: Clip.none,
                  children: [
                    _homeSuggestionBreathingSlide(),
                    // Recovery Tips — Gemini-powered screen (bottom nav lightbulb)
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                RecoveryTipsScreen(
                                  mood: _currentMood,
                                  moodImage: _currentMoodImage,
                                ),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(left: 4, right: 4),
                        decoration: _suggestionSlideDecoration(
                            const Color(0xFFF3E8FF)),
                        padding: const EdgeInsets.fromLTRB(18, 10, 14, 10),
                        child: Row(
                          children: [
                            Expanded(
                              flex: _kSuggestionTextFlex,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Recovery Tips',
                                    style: _suggestionCardTitle(
                                        const Color(0xFF6B21A8)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'AI based recovery tips tailored to how your mood',
                                    style: _suggestionCardBody(
                                      const Color.fromARGB(255, 89, 61, 137),
                                      alpha: 0.88,
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            _suggestionSlideImageCell('assets/Motivation.png'),
                          ],
                        ),
                      ),
                    ),
                    // Mood log + sleep — feeds Progress & music
                    GestureDetector(
                      onTap: _openMoodLog,
                      child: Container(
                        margin: const EdgeInsets.only(left: 4, right: 4),
                        decoration: _suggestionSlideDecoration(
                            const Color(0xFFE0E7FF)),
                        padding: const EdgeInsets.fromLTRB(18, 10, 14, 10),
                        child: Row(
                          children: [
                            Expanded(
                              flex: _kSuggestionTextFlex,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Mood log',
                                    style: _suggestionCardTitle(
                                        const Color.fromARGB(255, 42, 39, 124)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Log mood, sleep, goals and get personalized challenges, recovery tips, music tracks.',
                                    style: _suggestionCardBody(
                                      const Color.fromARGB(255, 66, 61, 117),
                                      alpha: 0.88,
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            _suggestionSlideImageCell(
                              'assets/Onboarding7.png',
                              nudgeRight: 14,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Focus Timer — Tools section
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FocusTimerScreen(),
                          ),
                        ).then((_) => _loadFocusSessions());
                      },
                      child: Container(
                        margin: const EdgeInsets.only(left: 4, right: 4),
                        decoration: _suggestionSlideDecoration(
                            const Color(0xFFFFEDD5)),
                        padding: const EdgeInsets.fromLTRB(18, 10, 14, 10),
                        child: Row(
                          children: [
                            Expanded(
                              flex: _kSuggestionTextFlex,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Focus Timer',
                                    style: _suggestionCardTitle(
                                        const Color(0xFFC2410C)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Try Pomodoro-style focus \n timer while you study.',
                                    style: _suggestionCardBody(
                                      const Color(0xFFEA580C),
                                      alpha: 0.88,
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            _suggestionSlideImageCell('assets/FocusTimer.png'),
                          ],
                        ),
                      ),
                    ),
                    _homeSuggestionBreathingSlide(),
                  ],
                ),
              ),
              
              // Listen to page changes for infinite loop
              Listener(
                onPointerDown: (_) {
                  // Pause auto-scroll when user touches
                  _autoScrollTimer.cancel();
                },
                onPointerUp: (_) {
                  // Resume auto-scroll when user releases
                  _startAutoScroll();
                },
                child: SizedBox.shrink(),
              ),

              if (showHomeMusic || showHomeBreathing)
                const SizedBox(height: 28),
              if (showHomeMusic) ...[
                _homeSectionTitle('Mood Music'),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MusicRecommendationScreen(
                          mood: _currentMood!,
                          moodImage: _currentMoodImage!,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius:
                          BorderRadius.circular(_kHomeNeoCardRadius),
                      border: Border.all(color: Colors.black, width: 2),
                      boxShadow: _homeNeoCardShadows(),
                    ),
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(_kHomeNeoCardRadius),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -20,
                            top: -20,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF3B82F6)
                                    .withValues(alpha: 0.12),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 30,
                            bottom: -30,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF2563EB)
                                    .withValues(alpha: 0.08),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 54,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFFDBEAFE),
                                    border: Border.all(
                                      color: const Color(0xFF2563EB)
                                          .withValues(alpha: 0.35),
                                      width: 2,
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Image.asset(
                                        _currentMoodImage!,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFBFDBFE),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                            color: const Color(0xFF2563EB)
                                                .withValues(alpha: 0.22),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.headphones_rounded,
                                              color: Color(0xFF1D4ED8),
                                              size: 12,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'MOOD MUSIC',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF1D4ED8),
                                                letterSpacing: 0.8,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Music For You',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.black87,
                                          height: 1.1,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Curated for your ${_currentMood!} mood',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black54,
                                          height: 1.25,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFBFDBFE),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.black.withValues(
                                          alpha: 0.12),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: Color(0xFF1D4ED8),
                                    size: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],

              if (showHomeBreathing) ...[
                if (showHomeMusic) const SizedBox(height: 28),
                _homeSectionTitle('Breathing Exercise '),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            BreathingExerciseScreen(mood: _currentMood),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius:
                          BorderRadius.circular(_kHomeNeoCardRadius),
                      border: Border.all(color: Colors.black, width: 2),
                      boxShadow: _homeNeoCardShadows(),
                    ),
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(_kHomeNeoCardRadius),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -18,
                            top: -18,
                            child: Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF0D9488)
                                    .withValues(alpha: 0.1),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 54,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFFCCFBF1),
                                    border: Border.all(
                                      color: const Color(0xFF0F766E)
                                          .withValues(alpha: 0.4),
                                      width: 2,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Image.asset(
                                      'assets/BreathIcon.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF99F6E4)
                                              .withValues(alpha: 0.65),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                            color: const Color(0xFF0F766E)
                                                .withValues(alpha: 0.22),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.spa_outlined,
                                              color: Color(0xFF0F766E),
                                              size: 12,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Breathing Exercise',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF115E59),
                                                letterSpacing: 0.8,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Breathing Exercise',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.black87,
                                          height: 1.1,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        _currentMood == 'anxious'
                                            ? 'Try 4-7-8 to calm your mind'
                                            : _currentMood == 'tired'
                                                ? 'Try box breathing for focus and energy'
                                                : 'A breathing session can help',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black54,
                                          height: 1.25,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFCCFBF1),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.black.withValues(
                                          alpha: 0.12),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: Color(0xFF0F766E),
                                    size: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 28),

              _homeSectionTitle('Boards'),

              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const EmotionBoardScreen()),
                  );
                },
                child: _HomeExamCard(
                  stripColor: const Color(0xFFF97316),
                  stripEmoji: '💬',
                  stripLabel: 'COMMUNITY',
                  cardColor: const Color(0xFFFFF7ED),
                  child: Row(
                    children: [
                      Image.asset('assets/PieChartIcon.png', width: 44, height: 44, fit: BoxFit.contain),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Emotion Board',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.black87),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Share and connect with peers',
                              style: TextStyle(fontSize: 13, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFF97316), size: 18),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              _homeSectionTitle(
                'Progress',
                subtitle: 'Focus sessions and sleep from today',
              ),

              // Progress Cards Grid (neo chrome + distinct pastels)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Focus sessions card
                    Expanded(
                      child: Container(
                        height: 200,
                        decoration: _suggestionSlideDecoration(
                            const Color(0xFFF0FDFA)),
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Focus sessions',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w800,
                                      height: 1.2,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.timer_outlined,
                                  size: 26,
                                  color: Color(0xFF0F766E),
                                ),
                              ],
                            ),
                            Text(
                              '$_completedSessions/$_totalSessions',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                letterSpacing: -0.5,
                              ),
                            ),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const FocusTimerScreen()),
                                  ).then((_) => _loadFocusSessions());
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF5EEAD4),
                                  foregroundColor: Colors.black,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: const BorderSide(
                                        color: Colors.black, width: 2),
                                  ),
                                ),
                                child: const Text(
                                  'Start',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Sleep — tap opens mood log / summary
                    Expanded(
                      child: GestureDetector(
                        onTap: _openMoodLog,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          height: 200,
                          decoration: _suggestionSlideDecoration(
                              const Color(0xFFEEF2FF)),
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Sleep',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w800,
                                        height: 1.2,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(
                                    Icons.bedtime_outlined,
                                    size: 26,
                                    color: Color(0xFF4F46E5),
                                  ),
                                ],
                              ),
                              FutureBuilder<Map<String, dynamic>?>(
                                future: MoodLogService().getTodayMoodLog(),
                                builder: (context, snapshot) {
                                  final sleepHours =
                                      snapshot.data?['sleep_hours']
                                          as String?;
                                  final displayHours =
                                      _sleepHoursDisplay(sleepHours);
                                  final displayQuality =
                                      _sleepQualityText(sleepHours);

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        displayHours,
                                        style: const TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        displayQuality,
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: Colors.black54,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              Text(
                                'Tap to log',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black.withValues(alpha: 0.38),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              _homeSectionTitle('Tools'),

              // Tools Cards Grid — row 1
              Row(
                children: [
                  // Focus Timer Card
                  Expanded(
                    child: _ToolCard(
                      gradientColors: const [Color(0xFFEDE9FE), Color(0xFFF5F0FF)],
                      iconWidget: const Icon(Icons.timer_outlined,
                          size: 30, color: Color(0xFF7C3AED)),
                      iconBg: const Color(0xFFDDD6FE),
                      label: 'Focus Timer',
                      sublabel: 'Pomodoro blocks',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const FocusTimerScreen()),
                      ).then((_) => _loadFocusSessions()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Challenges Card
                  Expanded(
                    child: _ToolCard(
                      gradientColors: const [Color(0xFFFFF7ED), Color(0xFFFFFBF5)],
                      iconWidget: const Icon(Icons.assignment_outlined,
                          size: 30, color: Color(0xFFEA580C)),
                      iconBg: const Color(0xFFFFEDD5),
                      label: 'Challenges',
                      sublabel: 'Daily goals',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ChallengesScreen()),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          AppMainBottomNav(
            current: AppMainNavTab.home,
            tipsMood: _currentMood,
            tipsMoodImage: _currentMoodImage,
          ),
        ],
      ),
    );
  }
}

/// Strip header card matching [RecoveryTipsScreen] `_TipCard` styling.
class _HomeExamCard extends StatelessWidget {
  final Color stripColor;
  final String stripEmoji;
  final String stripLabel;
  final Color cardColor;
  final Widget child;

  const _HomeExamCard({
    required this.stripColor,
    required this.stripEmoji,
    required this.stripLabel,
    required this.cardColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(_kHomeNeoCardRadius),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: _homeNeoCardShadows(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                Text(
                  stripLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.9,
                  ),
                ),
                const Spacer(),
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

// ─── Tool card ──────────────────────────────────────────────────────────────

class _ToolCard extends StatelessWidget {
  final List<Color> gradientColors;
  final Widget iconWidget;
  final Color iconBg;
  final String label;
  final String sublabel;
  final VoidCallback onTap;

  const _ToolCard({
    required this.gradientColors,
    required this.iconWidget,
    required this.iconBg,
    required this.label,
    required this.sublabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black, width: 1.5),
                    ),
                    child: Center(child: iconWidget),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    sublabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
