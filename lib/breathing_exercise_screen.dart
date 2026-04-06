import 'package:flutter/material.dart';
import 'dart:async';
import 'homepage.dart';
import 'emotion_board_screen.dart';
import 'recovery_tips_screen.dart';
import 'profile_screen.dart';

// ─── Data models ─────────────────────────────────────────────────────────────

class _Phase {
  final String label;
  final int seconds;
  const _Phase(this.label, this.seconds);
}

class _Technique {
  final String name;
  final String subtitle;
  /// Shown when [iconAsset] is null.
  final String emoji;
  /// If set, shown instead of [emoji] in the technique selector.
  final String? iconAsset;
  final List<_Phase> phases;
  final List<Color> gradient;

  const _Technique({
    required this.name,
    required this.subtitle,
    this.emoji = '',
    this.iconAsset,
    required this.phases,
    required this.gradient,
  });
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class BreathingExerciseScreen extends StatefulWidget {
  /// Optional mood from the mood log (e.g. 'anxious', 'sad', 'calm', 'tired').
  /// Used for mood-based auto-selection when [breathingType] is not provided.
  final String? mood;

  /// Explicit technique override from Recovery Tips ('4-7-8' or 'box').
  /// Takes highest priority over [mood]-based selection.
  final String? breathingType;

  const BreathingExerciseScreen({super.key, this.mood, this.breathingType});

  @override
  State<BreathingExerciseScreen> createState() =>
      _BreathingExerciseScreenState();
}

class _BreathingExerciseScreenState extends State<BreathingExerciseScreen>
    with TickerProviderStateMixin {
  static const _techniques = [
    _Technique(
      name: '4-7-8 Breathing',
      subtitle: 'Calm anxiety & stress',
      iconAsset: 'assets/BreathIcon.png',
      phases: [
        _Phase('Inhale', 4),
        _Phase('Hold', 7),
        _Phase('Exhale', 8),
      ],
      // Matches home “Breathing Exercise” card (readable deep teal)
      gradient: [Color(0xFF115E59), Color(0xFF0D9488)],
    ),
    _Technique(
      name: 'Box Breathing',
      subtitle: 'Restore focus & calm',
      emoji: '🧘',
      phases: [
        _Phase('Inhale', 4),
        _Phase('Hold', 4),
        _Phase('Exhale', 4),
        _Phase('Hold', 4),
      ],
      // Cyan-teal sibling — distinct from 4-7-8, still calm (not purple/blue)
      gradient: [Color(0xFF0E7490), Color(0xFF0891B2)],
    ),
  ];

  static const _totalRounds = 4;

  late AnimationController _circleController;
  late Animation<double> _sizeAnimation;

  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  int _techniqueIndex = 0;
  int _phaseIndex = 0;
  int _round = 0;

  bool _isRunning = false;
  bool _isCompleted = false;
  int _countdown = 0;
  Timer? _countdownTimer;

  _Technique get _technique => _techniques[_techniqueIndex];
  _Phase get _currentPhase => _technique.phases[_phaseIndex];

  @override
  void initState() {
    super.initState();

    // Priority 1 — explicit technique recommended by Recovery Tips
    if (widget.breathingType != null) {
      _techniqueIndex = (widget.breathingType == '4-7-8') ? 0 : 1;
    }
    // Priority 2 — mood-based auto-selection (no Recovery Tips recommendation)
    else if (widget.mood != null) {
      final m = widget.mood!.toLowerCase();
      _techniqueIndex = (m == 'anxious') ? 0 : 1;
    }
    // Priority 3 — no context at all: default to 4-7-8 (index 0, already set)

    _circleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _sizeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _circleController, curve: Curves.easeInOut),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _circleController.dispose();
    _glowController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  // ─── Session control ───────────────────────────────────────────────────────

  void _start() {
    setState(() {
      _isRunning = true;
      _isCompleted = false;
      _phaseIndex = 0;
      _round = 1;
    });
    _runPhase();
  }

  void _stop() {
    _countdownTimer?.cancel();
    _circleController
      ..stop()
      ..value = 0.0;
    setState(() {
      _isRunning = false;
      _phaseIndex = 0;
      _round = 0;
      _countdown = 0;
    });
  }

  void _runPhase() {
    if (!mounted) return;
    final phase = _currentPhase;
    setState(() => _countdown = phase.seconds);

    _circleController.duration = Duration(seconds: phase.seconds);

    if (phase.label == 'Inhale') {
      _circleController.forward(from: _circleController.value);
    } else if (phase.label == 'Exhale') {
      _circleController.reverse(from: _circleController.value);
    } else {
      // Hold — keep circle where it is
      _circleController.stop();
    }

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdown > 1) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
        _nextPhase();
      }
    });
  }

  void _nextPhase() {
    if (!_isRunning || !mounted) return;

    final phases = _technique.phases;
    final nextPhase = _phaseIndex + 1;

    if (nextPhase >= phases.length) {
      if (_round >= _totalRounds) {
        _circleController
          ..stop()
          ..value = 0.0;
        setState(() {
          _isRunning = false;
          _isCompleted = true;
          _phaseIndex = 0;
          _round = 0;
          _countdown = 0;
        });
        _showCompletionSheet();
        return;
      }
      setState(() {
        _round++;
        _phaseIndex = 0;
      });
    } else {
      setState(() => _phaseIndex = nextPhase);
    }

    _runPhase();
  }

  // ─── Completion sheet ──────────────────────────────────────────────────────

  void _showCompletionSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 24),
            const Text('🎉', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 12),
            const Text(
              'Session Complete!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'You finished all 4 rounds.\nTake a moment to notice how you feel.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.black54, height: 1.5),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: const BorderSide(color: Color(0xFF0D9488), width: 1.5),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F766E),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black,
                          offset: Offset(3, 3),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _start();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5EEAD4),
                        foregroundColor: Colors.black,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: Colors.black, width: 1.5),
                        ),
                      ),
                      child: const Text(
                        'Again',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  String get _phaseLabel {
    if (_isCompleted) return 'Great job!';
    if (!_isRunning) return 'Ready?';
    return _currentPhase.label;
  }

  Color get _accentColor => _technique.gradient.first;

  void _goTo(Widget screen) {
    _stop();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => screen),
      (route) => false,
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final minSize = screenW * 0.38;
    final maxSize = screenW * 0.65;

    return Scaffold(
      backgroundColor: const Color(0xFFEDE9FE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEDE9FE),
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
                _stop();
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  _goTo(const HomePage());
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
        title: const Text(
          'Breathing',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Technique selector (hidden while running) ──────────────────
              if (!_isRunning) ...[
                const SizedBox(height: 8),
                Row(
                  children: List.generate(_techniques.length, (i) {
                    final t = _techniques[i];
                    final selected = _techniqueIndex == i;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _techniqueIndex = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          margin: EdgeInsets.only(
                            right: i == 0 ? 8 : 0,
                            left: i == 1 ? 8 : 0,
                          ),
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 10),
                          decoration: BoxDecoration(
                            gradient: selected
                                ? LinearGradient(
                                    colors: t.gradient,
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: selected ? null : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: selected
                                  ? Colors.transparent
                                  : const Color(0xFF0D9488),
                              width: 2,
                            ),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color:
                                          t.gradient.first.withOpacity(0.38),
                                      blurRadius: 14,
                                      offset: const Offset(0, 5),
                                    )
                                  ]
                                : [],
                          ),
                          child: Column(
                            children: [
                              SizedBox(
                                height: 32,
                                width: 32,
                                child: t.iconAsset != null
                                    ? Image.asset(
                                        t.iconAsset!,
                                        fit: BoxFit.contain,
                                      )
                                    : Center(
                                        child: Text(
                                          t.emoji,
                                          style: const TextStyle(
                                              fontSize: 28),
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                t.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      selected ? Colors.white : Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                t.subtitle,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: selected
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),

                // ── Phase steps breakdown ──────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(0xFF0D9488), width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _technique.phases
                        .map(
                          (p) => Column(
                            children: [
                              Text(
                                p.label,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${p.seconds}s',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _accentColor,
                                ),
                              ),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // ── Round indicator (visible while running) ───────────────────
              if (_isRunning) ...[
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Round $_round of $_totalRounds',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              const SizedBox(height: 16),

              // ── Animated breathing circle ─────────────────────────────────
              SizedBox(
                height: maxSize + 60,
                child: Center(
                  child: AnimatedBuilder(
                    animation:
                        Listenable.merge([_sizeAnimation, _glowAnimation]),
                    builder: (context, _) {
                      final sz =
                          minSize + (maxSize - minSize) * _sizeAnimation.value;
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer glow halo
                          Container(
                            width: sz * _glowAnimation.value + 32,
                            height: sz * _glowAnimation.value + 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _accentColor.withOpacity(0.07),
                            ),
                          ),
                          // Mid ring
                          Container(
                            width: sz + 16,
                            height: sz + 16,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _accentColor.withOpacity(0.13),
                            ),
                          ),
                          // Main circle
                          Container(
                            width: sz,
                            height: sz,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: _technique.gradient,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _accentColor.withOpacity(0.45),
                                  blurRadius: 28,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _phaseLabel,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                if (_isRunning) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    '$_countdown',
                                    style: const TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),

              // ── Phase progress dots ───────────────────────────────────────
              if (_isRunning) ...[
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      _technique.phases.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        width: i == _phaseIndex ? 28 : 10,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _phaseIndex
                              ? _accentColor
                              : Colors.black12,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ] else
                const SizedBox(height: 12),

              // ── Start / Stop button ───────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black,
                      offset: Offset(3, 3),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isRunning ? _stop : _start,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isRunning
                        ? Colors.white
                        : const Color(0xFF5EEAD4),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: Colors.black, width: 1.5),
                    ),
                  ),
                  child: Text(
                    _isRunning ? 'Stop Session' : 'Start Breathing',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),

      // ── Bottom navigation ──────────────────────────────────────────────────
      bottomNavigationBar: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
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
              onPressed: () => _goTo(const HomePage()),
            ),
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline,
                  color: Color(0xFF115E59), size: 28),
              onPressed: () => _goTo(const EmotionBoardScreen()),
            ),
            IconButton(
              icon: const Icon(Icons.lightbulb_outline,
                  color: Color(0xFF115E59), size: 28),
              onPressed: () => _goTo(const RecoveryTipsScreen()),
            ),
            IconButton(
              icon: const Icon(Icons.person_outline,
                  color: Color(0xFF115E59), size: 28),
              onPressed: () => _goTo(const ProfileScreen()),
            ),
          ],
        ),
      ),
    );
  }
}
