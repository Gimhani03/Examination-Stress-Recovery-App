import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/app_main_bottom_nav.dart';
import 'dart:async';
import 'homepage.dart';
import 'mood_flow_theme.dart';

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
  /// If set, shown instead of a fallback icon in the technique selector.
  final String? iconAsset;
  final List<_Phase> phases;
  /// Flat accent for neo UI (breathing disk + highlights).
  final Color accent;
  /// Slightly darker companion for text on mint surfaces.
  final Color onAccent;
  /// Gradient for the animated breathing orb (inhale / exhale).
  final List<Color> diskGradient;

  const _Technique({
    required this.name,
    required this.subtitle,
    this.iconAsset,
    required this.phases,
    required this.accent,
    required this.onAccent,
    required this.diskGradient,
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
      accent: kMoodFlowTealNav,
      onAccent: Color(0xFF042F2E),
      diskGradient: [Color(0xFF115E59), Color(0xFF0D9488)],
    ),
    _Technique(
      name: 'Box Breathing',
      subtitle: 'Restore focus & calm',
      iconAsset: 'assets/Breathing3.png',
      phases: [
        _Phase('Inhale', 4),
        _Phase('Hold', 4),
        _Phase('Exhale', 4),
        _Phase('Hold', 4),
      ],
      // Same orb / halo palette as 4-7-8
      accent: kMoodFlowTealNav,
      onAccent: Color(0xFF042F2E),
      diskGradient: [Color(0xFF115E59), Color(0xFF0D9488)],
    ),
  ];

  static const _totalRounds = 4;

  late AnimationController _circleController;
  late Animation<double> _sizeAnimation;

  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  /// Hot reload keeps [State] but skips [initState]; lazily create glow animators.
  bool _glowAnimatorsReady = false;

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

    _ensureGlowAnimators();
  }

  void _ensureGlowAnimators() {
    if (_glowAnimatorsReady) return;
    _glowAnimatorsReady = true;
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void reassemble() {
    super.reassemble();
    if (_glowAnimatorsReady) {
      _glowController.dispose();
      _glowAnimatorsReady = false;
    }
    _ensureGlowAnimators();
  }

  @override
  void dispose() {
    _circleController.dispose();
    if (_glowAnimatorsReady) {
      _glowController.dispose();
    }
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
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(kMoodFlowNeoRadius)),
        side: BorderSide(color: Colors.black, width: 2),
      ),
      backgroundColor: kMoodCardCreamA,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          24 + MediaQuery.of(ctx).padding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: kMoodMint,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black, width: 2),
                boxShadow: moodFlowNeoShadows(),
              ),
              child: const Text(
                '✓',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.black),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Session complete',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: kMoodFlowTealNav,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'You finished all 4 rounds.\nNotice how you feel for a moment.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.black.withValues(alpha: 0.55),
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 26),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(kMoodFlowNeoRadius - 6),
                      ),
                      side: const BorderSide(color: Colors.black, width: 2),
                      foregroundColor: Colors.black87,
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(kMoodFlowNeoRadius - 6),
                      boxShadow: moodFlowNeoShadows(),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _start();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kMoodMint,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(kMoodFlowNeoRadius - 6),
                          side: const BorderSide(color: Colors.black, width: 2),
                        ),
                      ),
                      child: const Text(
                        'Again',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
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

  Color get _accentColor => _technique.accent;

  void _goTo(Widget screen) {
    _stop();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => screen),
      (route) => false,
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    _ensureGlowAnimators();

    final screenW = MediaQuery.of(context).size.width;
    final minSize = screenW * 0.38;
    final maxSize = screenW * 0.65;
    final frame = (maxSize * 1.16 + 40).clamp(maxSize + 28, 420.0);

    const neoBorder = BorderSide(color: Colors.black, width: 2);

    return Scaffold(
      backgroundColor: kMoodFlowBg,
      appBar: AppBar(
        backgroundColor: kMoodFlowBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          iconSize: 22,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () {
            _stop();
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              _goTo(const HomePage());
            }
          },
        ),
        title: const Text(
          'Breathing',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_isRunning) ...[
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(_techniques.length, (i) {
                    final t = _techniques[i];
                    final selected = _techniqueIndex == i;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: i == 0 ? 8 : 0, left: i == 1 ? 8 : 0),
                        child: GestureDetector(
                          onTap: () => setState(() => _techniqueIndex = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOutCubic,
                            transform: Matrix4.translationValues(
                              selected ? -2 : 0,
                              selected ? -2 : 0,
                              0,
                            ),
                            padding: const EdgeInsets.fromLTRB(10, 14, 10, 14),
                            decoration: BoxDecoration(
                              color: selected ? kMoodMint : kMoodCardCreamA,
                              borderRadius: BorderRadius.circular(kMoodFlowNeoRadius),
                              border: Border.fromBorderSide(neoBorder),
                              boxShadow: selected ? moodFlowNeoShadows() : const [],
                            ),
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 36,
                                  width: 36,
                                  child: t.iconAsset != null
                                      ? Image.asset(
                                          t.iconAsset!,
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) => const Icon(
                                            Icons.air_rounded,
                                            size: 28,
                                            color: Colors.black87,
                                          ),
                                        )
                                      : const Center(
                                          child: Icon(Icons.air_rounded, size: 30, color: Colors.black87),
                                        ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  t.name,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    height: 1.2,
                                    color: selected ? t.onAccent : Colors.black87,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  t.subtitle,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: selected
                                        ? t.onAccent.withValues(alpha: 0.72)
                                        : Colors.black.withValues(alpha: 0.45),
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(kMoodFlowNeoRadius),
                    border: Border.fromBorderSide(neoBorder),
                    boxShadow: moodFlowNeoShadows(),
                  ),
                  child: Row(
                    children: [
                      for (var i = 0; i < _technique.phases.length; i++) ...[
                        if (i > 0)
                          Container(
                            width: 1,
                            height: 44,
                            color: Colors.black.withValues(alpha: 0.12),
                          ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                _technique.phases[i].label.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                  color: Colors.black.withValues(alpha: 0.4),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${_technique.phases[i].seconds}s',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: _accentColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],

              if (_isRunning) ...[
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.fromBorderSide(neoBorder),
                    ),
                    child: Text(
                      'ROUND $_round / $_totalRounds',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              SizedBox(
                height: frame + 36,
                child: Center(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_sizeAnimation, _glowAnimation]),
                    builder: (context, _) {
                      final sz =
                          minSize + (maxSize - minSize) * _sizeAnimation.value;
                      final g = _glowAnimation.value;
                      final haloOuter = sz * g + 32;
                      final midRing = sz + 16;
                      return SizedBox(
                        width: frame,
                        height: frame,
                        child: Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: haloOuter.clamp(0.0, frame),
                              height: haloOuter.clamp(0.0, frame),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _accentColor.withValues(alpha: 0.08),
                              ),
                            ),
                            Container(
                              width: midRing.clamp(0.0, frame),
                              height: midRing.clamp(0.0, frame),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _accentColor.withValues(alpha: 0.14),
                              ),
                            ),
                            Container(
                              width: sz,
                              height: sz,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: _technique.diskGradient,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                border: Border.fromBorderSide(neoBorder),
                                boxShadow: [
                                  BoxShadow(
                                    color: _accentColor.withValues(alpha: 0.38),
                                    blurRadius: 22,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _phaseLabel,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  if (_isRunning) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      '$_countdown',
                                      style: const TextStyle(
                                        fontSize: 44,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        height: 1,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

              if (_isRunning) ...[
                const SizedBox(height: 8),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      _technique.phases.length,
                      (i) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 240),
                          curve: Curves.easeOutCubic,
                          width: i == _phaseIndex ? 36 : 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: i == _phaseIndex ? _accentColor : Colors.white,
                            borderRadius: BorderRadius.circular(3),
                            border: Border.fromBorderSide(neoBorder),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
              ] else
                const SizedBox(height: 8),

              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(kMoodFlowNeoRadius - 4),
                  boxShadow: _isRunning ? const [] : moodFlowNeoShadows(),
                ),
                child: ElevatedButton(
                  onPressed: _isRunning ? _stop : _start,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isRunning ? Colors.white : kMoodMint,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kMoodFlowNeoRadius - 4),
                      side: neoBorder,
                    ),
                  ),
                  child: Text(
                    _isRunning ? 'Stop session' : 'Start',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),

      bottomNavigationBar: const AppMainBottomNav(),
    );
  }
}
