import 'package:flutter/material.dart';

import 'mood_flow_theme.dart';

const Color _accentPurple = Color(0xFF7C3AED);
const Color _accentTeal = Color(0xFF0D9488);
const Color _accentCoral = Color(0xFFEA580C);
const Color _logoMint = Color(0xFF98E2D6);
const Color _disclaimerCardBg = Color(0xFFFFF1F2);
const Color _disclaimerStripe = Color(0xFFE11D48);

/// Matches [pubspec.yaml] `version` — update when releasing.
const String kAppVersion = '1.0.0';
const String kAppBuildNumber = '1';

/// App version, purpose, and wellbeing disclaimer; matches profile neo UI.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

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
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'About',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
                letterSpacing: -0.5,
                height: 1.1,
              ),
            ),
            Text(
              'App version and info',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Colors.black.withValues(alpha: 0.38),
                letterSpacing: 0.12,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _HeroCard(
              version: kAppVersion,
              buildNumber: kAppBuildNumber,
            ),
            const SizedBox(height: 20),
            const _SectionLabel(title: 'App details'),
            const SizedBox(height: 8),
            _InfoCard(
              rows: [
                _InfoRow(
                  icon: Icons.tag_outlined,
                  label: 'Version',
                  value: kAppVersion,
                  accent: _accentPurple,
                ),
                _InfoRow(
                  icon: Icons.build_outlined,
                  label: 'Build',
                  value: kAppBuildNumber,
                  accent: _accentTeal,
                ),
                _InfoRow(
                  icon: Icons.phone_iphone_outlined,
                  label: 'Platform',
                  value: 'Flutter',
                  accent: _accentCoral,
                ),
              ],
            ),
            const SizedBox(height: 20),
            const _SectionLabel(title: 'What this app does'),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(kMoodFlowNeoRadius),
                border: Border.all(color: Colors.black, width: 2),
                boxShadow: moodFlowNeoShadows(),
              ),
              child: Text(
                'Examination Stress Recovery brings together mood check-ins, study focus tools, '
                'breathing exercises, music matched to how you feel, AI recovery tips, an AI chat '
                'assistant for encouragement and study support, and a supportive community board — '
                'all in one place for exam season wellbeing.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                  color: Colors.black.withValues(alpha: 0.62),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                _FeatureChip(
                  icon: Icons.favorite_outline,
                  label: 'Mood log',
                  color: _accentPurple,
                ),
                _FeatureChip(
                  icon: Icons.air_outlined,
                  label: 'Breathing',
                  color: _accentTeal,
                ),
                _FeatureChip(
                  icon: Icons.timer_outlined,
                  label: 'Focus timer',
                  color: _accentCoral,
                ),
                _FeatureChip(
                  icon: Icons.forum_outlined,
                  label: 'Emotion board',
                  color: Color(0xFF4F46E5),
                ),
                _FeatureChip(
                  icon: Icons.lightbulb_outline,
                  label: 'Recovery tips',
                  color: Color(0xFFCA8A04),
                ),
                _FeatureChip(
                  icon: Icons.music_note_outlined,
                  label: 'Music recommendations',
                  color: Color(0xFF2563EB),
                ),
                _FeatureChip(
                  icon: Icons.chat_bubble_outline,
                  label: 'AI chat',
                  color: Color(0xFF7C3AED),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              decoration: BoxDecoration(
                color: _disclaimerCardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black, width: 2),
                boxShadow: moodFlowNeoShadows(),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _disclaimerStripe.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.black, width: 1.5),
                    ),
                    child: Icon(
                      Icons.health_and_safety_outlined,
                      size: 20,
                      color: _disclaimerStripe.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This app supports everyday exam stress and study wellbeing. '
                      'It is not therapy, diagnosis, or emergency care.',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        height: 1.45,
                        color: Colors.black.withValues(alpha: 0.52),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Made with care for students',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.black.withValues(alpha: 0.32),
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w900,
        color: Colors.black87,
        letterSpacing: -0.3,
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.version,
    required this.buildNumber,
  });

  final String version;
  final String buildNumber;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
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
        children: [
          Center(
            child: SizedBox(
              width: 128,
              height: 128,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _logoMint,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.black, width: 2),
                  boxShadow: moodFlowNeoShadows(),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Image.asset(
                      'assets/AppLogo.png',
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _accentPurple.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.black, width: 1.5),
            ),
            child: Text(
              'v$version · Build $buildNumber',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.rows});

  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kMoodFlowNeoRadius),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: moodFlowNeoShadows(),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: rows[i].accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: Colors.black, width: 1.5),
                    ),
                    child: Icon(rows[i].icon, color: rows[i].accent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      rows[i].label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Text(
                    rows[i].value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.black.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
            if (i < rows.length - 1) Container(height: 2, color: Colors.black),
          ],
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            offset: const Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
