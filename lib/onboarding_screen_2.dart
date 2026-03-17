import 'package:flutter/material.dart';
import 'package:flutter_application_1/signup_screen.dart';

class OnboardingScreen2 extends StatelessWidget {
  const OnboardingScreen2({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF90CAF9),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              // Skip button row
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const SignUpScreen()),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A3A6A),
                      ),
                    ),
                  ),
                ),
              ),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: "Explore Your\n",
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0A1E3A),
                              height: 1.2,
                            ),
                          ),
                          WidgetSpan(
                            child: _HighlightedText(text: 'Potential'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Discover tools that keep you focused,\nmotivated, and ready for anything.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A3A6A),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      flex: 1,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: const [
                          Expanded(
                            child: _OnboardingCard(
                              imagePath: 'assets/Onboarding4.png',
                              title: 'Motivational\nQuotes',
                              subtitle:
                                  'Get inspired with\npositive and\nuplifting sayings',
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: _OnboardingCard(
                              imagePath: 'assets/Onboarding5.png',
                              title: 'Focus Timer',
                              subtitle:
                                  'Stay focused and\nstress-free\nbefore exams',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      flex: 1,
                      child: _OnboardingWideCard(
                        imagePathLeft: 'assets/Onboarding6.png',
                        imagePathRight: 'assets/Onboarding7.png',
                        title: 'Daily Personalized Challenges',
                        subtitle: 'Adopts healthy habits and stay\nbalanced',
                        onNext: () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const SignUpScreen()),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Bottom bar: dots only
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: const Color(0xFF0A1E3A).withValues(alpha: 0.3), borderRadius: BorderRadius.circular(4))),
                    const SizedBox(width: 6),
                    Container(width: 20, height: 8, decoration: BoxDecoration(color: const Color(0xFF0A1E3A), borderRadius: BorderRadius.circular(4))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String subtitle;

  const _OnboardingCard({
    required this.imagePath,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: Image(
              image: AssetImage(imagePath),
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0A1E3A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF3A5A7A),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingWideCard extends StatelessWidget {
  final String imagePathLeft;
  final String imagePathRight;
  final String title;
  final String subtitle;
  final VoidCallback? onNext;

  const _OnboardingWideCard({
    required this.imagePathLeft,
    required this.imagePathRight,
    required this.title,
    required this.subtitle,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Image(
                      image: AssetImage(imagePathLeft),
                      fit: BoxFit.contain,
                    ),
                  ),
                  Flexible(
                    child: Image(
                      image: AssetImage(imagePathRight),
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0A1E3A),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF3A5A7A),
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: onNext,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC4AAEE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black, width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black,
                        offset: Offset(3, 3),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.arrow_forward, color: Colors.black, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HighlightedText extends StatelessWidget {
  final String text;
  const _HighlightedText({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFCDDC39),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w900,
          color: Color(0xFF0A1E3A),
          height: 1.2,
        ),
      ),
    );
  }
}
