import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'mood_summary_screen.dart';
import 'homepage.dart';
import 'emotion_board_screen.dart';
import 'profile_screen.dart';
import 'recovery_tips_screen.dart';
import 'mood_flow_theme.dart';
import 'services/mood_log_service.dart';

class GoalScreen extends StatefulWidget {
  final String mood;
  final String moodImage;
  final String sleepHours;

  const GoalScreen({
    super.key,
    required this.mood,
    required this.moodImage,
    required this.sleepHours,
  });

  @override
  State<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  final Set<String> selectedGoals = {};
  int currentPage = 3;
  int totalPages = 3;
  bool _isSaving = false;

  Future<void> _submitGoals() async {
    if (selectedGoals.isEmpty || _isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final goalLabels = selectedGoals.map((goal) {
      if (goal == 'exam') return 'Preparing for exam';
      if (goal == 'stress') return 'Reducing the stress';
      return 'Finish the syllabus';
    }).toList();

    try {
      await MoodLogService().logMood(
        mood: widget.mood,
        moodImage: widget.moodImage,
        sleepHours: widget.sleepHours,
        goals: goalLabels,
      );

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MoodSummaryScreen(
            mood: widget.mood,
            moodImage: widget.moodImage,
            sleepHours: widget.sleepHours,
            goals: goalLabels,
          ),
        ),
      );
    } on MoodLogExistsException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
      try {
        final existing = await MoodLogService().getTodayMoodLog();
        if (!mounted || existing == null) return;
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
      } on AuthException {
        if (!mounted) return;
      }
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save mood log. Try again.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedGoals.isNotEmpty;

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
              'Mood Log',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
                letterSpacing: -0.5,
                height: 1.1,
              ),
            ),
            Text(
              'Step $currentPage of $totalPages',
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'What are you\nworking toward?',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.black.withValues(alpha: 0.9),
                  letterSpacing: -0.6,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select one or more — you can change this anytime.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black.withValues(alpha: 0.45),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 22),
              Expanded(
                child: Column(
                  children: [
                    _buildGoalOption('assets/goal1.png', 'Preparing for exam', 'exam'),
                    const SizedBox(height: 14),
                    _buildGoalOption('assets/goal2.png', 'Reducing the stress', 'stress'),
                    const SizedBox(height: 14),
                    _buildGoalOption('assets/goal3.png', 'Finish the syllabus', 'syllabus'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: hasSelection ? moodFlowNeoShadows() : const [],
                ),
                child: Material(
                  color: hasSelection ? kMoodMint : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(14),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: hasSelection && !_isSaving ? _submitGoals : null,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: kMoodFlowTealAccent,
                              ),
                            )
                          : Text(
                              'Submit',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: hasSelection
                                    ? Colors.black87
                                    : Colors.black.withValues(alpha: 0.35),
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
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

  Widget _buildGoalOption(String imagePath, String label, String goalValue) {
    final isSelected = selectedGoals.contains(goalValue);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            selectedGoals.remove(goalValue);
          } else {
            selectedGoals.add(goalValue);
          }
        });
      },
      child: Container(
        height: 76,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isSelected
                ? const [kMoodSelectedGreenA, kMoodSelectedGreenB]
                : const [kMoodCardCreamA, kMoodCardCreamB],
          ),
          borderRadius: BorderRadius.circular(kMoodFlowNeoRadius),
          border: Border.all(color: Colors.black, width: 2),
          boxShadow: moodFlowNeoShadows(),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Stack(
            children: [
              Center(
                child: Row(
                  children: [
                    Image.asset(
                      imagePath,
                      width: 44,
                      height: 44,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.black87,
                            size: 18,
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
