import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;
import 'homepage.dart';
import 'emotion_board_screen.dart';
import 'profile_screen.dart';
import 'recovery_tips_screen.dart';
import 'mood_flow_theme.dart';
import 'services/focus_timer_service.dart';

class FocusTimerScreen extends StatefulWidget {
  const FocusTimerScreen({super.key});

  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen> {
  static const int _defaultSeconds = 25 * 60;
  static const int _totalSessions = 4;
  late int _remainingSeconds;
  Timer? _timer;
  bool _isRunning = false;
  int _completedSessions = 0;
  String? _summaryError;
  final FocusTimerService _focusTimerService = FocusTimerService();

  @override
  void initState() {
    super.initState();
    _remainingSeconds = _defaultSeconds;
    _loadTodaySummary();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    HapticFeedback.lightImpact();
    if (_isRunning) {
      _timer?.cancel();
      setState(() {
        _isRunning = false;
      });
      return;
    }

    if (_remainingSeconds == 0) {
      setState(() {
        _remainingSeconds = _defaultSeconds;
      });
    }

    _timer?.cancel();
    setState(() {
      _isRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        HapticFeedback.mediumImpact();
        setState(() {
          _remainingSeconds = 0;
          _isRunning = false;
          _completedSessions = _clampSessions(_completedSessions + 1);
        });
        _logCompletedSession();
        return;
      }
      setState(() {
        _remainingSeconds--;
      });
    });
  }

  void _resetTimer() {
    HapticFeedback.lightImpact();
    _timer?.cancel();
    setState(() {
      _remainingSeconds = _defaultSeconds;
      _isRunning = false;
    });
  }

  Future<void> _loadTodaySummary() async {
    try {
      final summary = await _focusTimerService.getSummaryForDate(DateTime.now());
      if (!mounted) {
        return;
      }
      setState(() {
        _completedSessions = _clampSessions(summary.sessionCount);
        _summaryError = null;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _summaryError = 'Failed to load focus sessions.';
      });
    }
  }

  Future<void> _logCompletedSession() async {
    try {
      await _focusTimerService.logSession(
        durationSeconds: _defaultSeconds,
        targetSeconds: _defaultSeconds,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _summaryError = 'Failed to save focus session.';
      });
    }
  }

  int _clampSessions(int value) {
    if (value < 0) {
      return 0;
    }
    if (value > _totalSessions) {
      return _totalSessions;
    }
    return value;
  }

  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  double get _sessionProgress =>
      1.0 - (_remainingSeconds / _defaultSeconds);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kMoodFlowBg,
      appBar: AppBar(
        backgroundColor: kMoodFlowBg,
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
                  moodFlowGoTo(context, const HomePage());
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
              'Focus Timer',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
                letterSpacing: -0.5,
                height: 1.1,
              ),
            ),
            Text(
              'Pomodoro · 25 min blocks',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Colors.black.withValues(alpha: 0.38),
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [kMoodCardCreamA, kMoodCardCreamB],
                  ),
                  borderRadius: BorderRadius.circular(kMoodFlowNeoRadius),
                  border: Border.all(color: Colors.black, width: 2),
                  boxShadow: moodFlowNeoShadows(),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: kMoodMint,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            offset: const Offset(2, 2),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.timer_outlined,
                        color: Colors.black87,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _completedSessions >= _totalSessions
                                ? 'Daily goal met'
                                : 'Deep work mode',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: Colors.black87,
                              letterSpacing: -0.3,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Completed blocks sync with the progress ring on Home.',
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
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (_summaryError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE4E6),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: Text(
                      _summaryError!,
                      style: const TextStyle(
                        color: Color(0xFF991B1B),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(kMoodFlowNeoRadius + 2),
                  border: Border.all(color: Colors.black, width: 2),
                  boxShadow: moodFlowNeoShadows(),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final maxW = constraints.maxWidth;
                    final side = math.min(248.0, maxW - 4);
                    return Center(
                      child: SizedBox(
                        width: side,
                        height: side,
                        child: CustomPaint(
                          painter: _CircleTimerPainter(
                            progress: _sessionProgress,
                            trackColor: const Color(0xFFE2E8F0),
                            progressColor: const Color(0xFF0D9488),
                            glowColor: const Color(0xFF5EEAD4),
                          ),
                          child: Center(
                            child: Container(
                              width: side * 0.74,
                              height: side * 0.74,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF115E59),
                                    Color(0xFF0D9488),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                border: Border.all(color: Colors.black, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.22),
                                    offset: const Offset(5, 5),
                                    blurRadius: 0,
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _formatTime(_remainingSeconds),
                                    style: const TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 1.2,
                                      height: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _isRunning
                                        ? 'In progress'
                                        : _remainingSeconds == 0
                                            ? 'Block complete'
                                            : 'Ready',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.4,
                                      color: Colors.white.withValues(alpha: 0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [kMoodCardCreamA, kMoodCardCreamB],
                  ),
                  borderRadius: BorderRadius.circular(kMoodFlowNeoRadius),
                  border: Border.all(color: Colors.black, width: 2),
                  boxShadow: moodFlowNeoShadows(),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Today's blocks",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                          child: Text(
                            '$_completedSessions / $_totalSessions',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: List.generate(_totalSessions, (i) {
                        final done = i < _completedSessions;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: i < _totalSessions - 1 ? 8 : 0,
                            ),
                            child: Column(
                              children: [
                                Container(
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: done ? kMoodMint : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.black, width: 2),
                                    boxShadow: done
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.12),
                                              offset: const Offset(2, 2),
                                              blurRadius: 0,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Center(
                                    child: Icon(
                                      done ? Icons.check_rounded : Icons.hourglass_empty_rounded,
                                      color: done
                                          ? Colors.black87
                                          : Colors.black.withValues(alpha: 0.22),
                                      size: 22,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black.withValues(alpha: 0.4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: moodFlowNeoShadows(),
                      ),
                      child: Material(
                        color: kMoodMint,
                        borderRadius: BorderRadius.circular(14),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: _toggleTimer,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.black, width: 2),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                  color: Colors.black87,
                                  size: 26,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isRunning ? 'Pause' : 'Start',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: moodFlowNeoShadows(),
                      ),
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: _resetTimer,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.black, width: 2),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.refresh_rounded, color: Colors.black87, size: 24),
                                SizedBox(width: 8),
                                Text(
                                  'Reset',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 88),
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
              icon: const Icon(Icons.home_outlined, color: kMoodFlowTealNav, size: 28),
              onPressed: () => moodFlowGoTo(context, const HomePage()),
            ),
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline_rounded, color: kMoodFlowTealNav, size: 28),
              onPressed: () => moodFlowGoTo(context, const EmotionBoardScreen()),
            ),
            IconButton(
              icon: const Icon(Icons.lightbulb_outline_rounded, color: kMoodFlowTealNav, size: 28),
              onPressed: () => moodFlowGoTo(context, const RecoveryTipsScreen()),
            ),
            IconButton(
              icon: const Icon(Icons.person_outline_rounded, color: kMoodFlowTealNav, size: 28),
              onPressed: () => moodFlowGoTo(context, const ProfileScreen()),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleTimerPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final Color glowColor;

  _CircleTimerPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.glowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const strokeWidth = 16.0;
    final radius = size.width / 2 - strokeWidth / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      final sweepAngle = 2 * math.pi * progress;

      final glowPaint = Paint()
        ..color = glowColor.withValues(alpha: 0.28)
        ..strokeWidth = strokeWidth + 8
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
        false,
        glowPaint,
      );

      final rect = Rect.fromCircle(center: center, radius: radius);
      final progressPaint = Paint()
        ..shader = SweepGradient(
          colors: const [
            Color(0xFF99F6E4),
            Color(0xFF0D9488),
          ],
          startAngle: 0,
          endAngle: 2 * math.pi,
          transform: GradientRotation(-math.pi / 2),
        ).createShader(rect)
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, progressPaint);

      final tipAngle = -math.pi / 2 + sweepAngle;
      final tipX = center.dx + radius * math.cos(tipAngle);
      final tipY = center.dy + radius * math.sin(tipAngle);

      canvas.drawCircle(
        Offset(tipX, tipY),
        strokeWidth / 2 + 1,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        Offset(tipX, tipY),
        strokeWidth / 2 - 3,
        Paint()
          ..color = progressColor
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(_CircleTimerPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
