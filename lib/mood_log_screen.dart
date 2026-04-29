import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/app_main_bottom_nav.dart';
import 'sleep_hours_screen.dart';
import 'homepage.dart';
import 'mood_summary_screen.dart';
import 'mood_flow_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/mood_log_service.dart';

class MoodLogScreen extends StatefulWidget {
  const MoodLogScreen({super.key});

  @override
  State<MoodLogScreen> createState() => _MoodLogScreenState();
}

class _MoodLogScreenState extends State<MoodLogScreen> {
  String? selectedMood;
  String? selectedMoodImage;
  int currentPage = 1;
  int totalPages = 3;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkExistingLog();
  }

  Future<void> _checkExistingLog() async {
    try {
      final existing = await MoodLogService().getTodayMoodLog();
      if (existing != null && mounted) {
        Navigator.pushReplacement(
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
        return;
      }
    } on AuthException {
      // Allow navigation to log when not signed in.
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        backgroundColor: kMoodFlowBg,
        body: Center(
          child: CircularProgressIndicator(color: kMoodFlowTealAccent),
        ),
      );
    }
    return Scaffold(
      backgroundColor: kMoodFlowBg,
      appBar: AppBar(
        backgroundColor: kMoodFlowBg,
        elevation: 0,
        leading: IconButton(
          iconSize: 26,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              moodFlowGoTo(context, const HomePage());
            }
          },
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
                'How are you feeling\ntoday?',
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
                'Pick the mood that fits best right now.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black.withValues(alpha: 0.45),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 22),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  children: [
                    _buildMoodCard('assets/CalmIcon.png', 'Calm', 'calm'),
                    _buildMoodCard('assets/AnxiousIcon.png', 'Anxious', 'anxious'),
                    _buildMoodCard('assets/TiredIcon.png', 'Tired', 'tired'),
                    _buildMoodCard('assets/SadIcon.png', 'Sad', 'sad'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: selectedMood != null ? moodFlowNeoShadows() : const [],
                ),
                child: Material(
                  color: selectedMood != null ? kMoodMint : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(14),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: selectedMood != null
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SleepHoursScreen(
                                  mood: selectedMood!,
                                  moodImage: selectedMoodImage!,
                                ),
                              ),
                            );
                          }
                        : null,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      child: Text(
                        'Next',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: selectedMood != null
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
      bottomNavigationBar: const AppMainBottomNav(),
    );
  }

  Widget _buildMoodCard(String imagePath, String label, String moodValue) {
    final isSelected = selectedMood == moodValue;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedMood = moodValue;
          selectedMoodImage = imagePath;
        });
      },
      child: Container(
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
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  imagePath,
                  width: 60,
                  height: 60,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            if (isSelected)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.black87,
                    size: 18,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
