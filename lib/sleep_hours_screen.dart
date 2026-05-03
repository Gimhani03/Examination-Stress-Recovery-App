import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/app_main_bottom_nav.dart';
import 'goal_screen.dart';
import 'homepage.dart';
import 'mood_flow_theme.dart';

class SleepHoursScreen extends StatefulWidget {
  final String mood;
  final String moodImage;

  const SleepHoursScreen({super.key, required this.mood, required this.moodImage});

  @override
  State<SleepHoursScreen> createState() => _SleepHoursScreenState();
}

class _SleepHoursScreenState extends State<SleepHoursScreen> {
  String? selectedSleep;
  int currentPage = 2;
  int totalPages = 3;

  @override
  Widget build(BuildContext context) {
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
                'How many hours\ndid you sleep?',
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
                'Rough estimate is fine.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black.withValues(alpha: 0.45),
                ),
              ),
              const SizedBox(height: 22),
              Expanded(
                child: Column(
                  children: [
                    _buildSleepOption('assets/emoji1.png', '< 4 h', 'less4'),
                    const SizedBox(height: 14),
                    _buildSleepOption('assets/emoji2.png', '4 - 6 h', '4to6'),
                    const SizedBox(height: 14),
                    _buildSleepOption('assets/emoji3.png', '7 h', '7plus'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: selectedSleep != null ? moodFlowNeoShadows() : const [],
                ),
                child: Material(
                  color: selectedSleep != null ? kMoodMint : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(14),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: selectedSleep != null
                        ? () {
                            final sleepLabel = selectedSleep == 'less4'
                                ? '< 4 h'
                                : selectedSleep == '4to6'
                                    ? '4 - 6 h'
                                    : '7 h';
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => GoalScreen(
                                  mood: widget.mood,
                                  moodImage: widget.moodImage,
                                  sleepHours: sleepLabel,
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
                          color: selectedSleep != null
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
      bottomNavigationBar: AppMainBottomNav(
        tipsMood: widget.mood,
        tipsMoodImage: widget.moodImage,
      ),
    );
  }

  Widget _buildSleepOption(String imagePath, String label, String sleepValue) {
    final isSelected = selectedSleep == sleepValue;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedSleep = sleepValue;
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
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(left: 100),
                child: Row(
                  children: [
                    Image.asset(
                      imagePath,
                      width: 44,
                      height: 44,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isSelected)
              Positioned(
                right: 14,
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
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.black87,
                      size: 18,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
