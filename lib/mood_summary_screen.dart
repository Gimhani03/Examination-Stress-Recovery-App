import 'package:flutter/material.dart';
import 'homepage.dart';
import 'emotion_board_screen.dart';
import 'profile_screen.dart';
import 'recovery_tips_screen.dart';
import 'challenges_screen.dart';
import 'mood_flow_theme.dart';

class MoodSummaryScreen extends StatelessWidget {
  final String mood;
  final String moodImage;
  final String sleepHours;
  final List<String> goals;

  const MoodSummaryScreen({
    super.key,
    required this.mood,
    required this.moodImage,
    required this.sleepHours,
    required this.goals,
  });

  String get _moodLabel {
    if (mood.isEmpty) return '—';
    return '${mood[0].toUpperCase()}${mood.substring(1)}';
  }

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
                  Navigator.popUntil(context, (route) => route.isFirst);
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
              'Today’s summary',
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
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 88),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Summary',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                            letterSpacing: -0.4,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                          child: Image.asset(
                            moodImage,
                            width: 48,
                            height: 48,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _SummaryLine(label: 'Mood :', value: _moodLabel),
                    const SizedBox(height: 12),
                    _SummaryLine(label: 'Sleep :', value: sleepHours.isEmpty ? '—' : sleepHours),
                    const SizedBox(height: 12),
                    const Text(
                      'Goals :',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color.fromARGB(221, 125, 124, 124),
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (goals.isEmpty)
                      Text(
                        '—',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black.withValues(alpha: 0.45),
                        ),
                      )
                    else
                      ...goals.map(
                        (goal) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '• ',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black87,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  goal,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Recommendations',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 14),
              _NeoActionCard(
                title: 'Personalized recovery tips',
                body: 'AI suggestions based on how you’re doing.',
                buttonLabel: 'Try tips',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RecoveryTipsScreen(
                        mood: mood,
                        moodImage: moodImage,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),
              _NeoActionCard(
                title: 'Daily challenges',
                body: 'Small tasks matched to your mood and goals.',
                buttonLabel: 'View challenges',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChallengesScreen()),
                  );
                },
              ),
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
              onPressed: () => moodFlowGoTo(
                context,
                RecoveryTipsScreen(mood: mood, moodImage: moodImage),
              ),
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

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.black.withValues(alpha: 0.45),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}

class _NeoActionCard extends StatelessWidget {
  const _NeoActionCard({
    required this.title,
    required this.body,
    required this.buttonLabel,
    required this.onPressed,
  });

  final String title;
  final String body;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kMoodFlowNeoRadius),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: moodFlowNeoShadows(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black.withValues(alpha: 0.48),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: moodFlowNeoShadows(),
            ),
            child: Material(
              color: kMoodMint,
              borderRadius: BorderRadius.circular(14),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onPressed,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: Text(
                    buttonLabel,
                    style: const TextStyle(
                      fontSize: 15,
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
