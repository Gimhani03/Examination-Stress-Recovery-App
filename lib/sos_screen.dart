import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'mood_flow_theme.dart';

/// Native iOS opens `tel:` via [UIApplication.shared.open] (registered in AppDelegate).
final MethodChannel _iosSosPhoneChannel =
    MethodChannel('flutter_application_1/sos_phone');

const Color _accentPurple = Color(0xFF7C3AED);
const Color _warmCoral = Color(0xFFEA580C);
const Color _alertRose = Color(0xFFB91C1C);

List<BoxShadow> _sosNeoShadows() => moodFlowNeoShadows();

class SosContact {
  const SosContact({
    required this.title,
    required this.description,
    required this.phoneLabel,
    required this.telDigits,
    required this.icon,
    required this.accent,
    required this.onAccent,
  });

  final String title;
  final String description;
  final String phoneLabel;
  /// Digits/local format for tel: URI (spaces stripped when dialling).
  final String telDigits;
  final IconData icon;
  final Color accent;
  final Color onAccent;
}

/// Crisis / SOS support: helplines and signposting. Matches mood-flow neo UI.
class SosScreen extends StatelessWidget {
  const SosScreen({super.key});

  static const List<SosContact> _emergency = [
    SosContact(
      title: 'Police emergency',
      description:
          'If you are in immediate physical danger, need police, or a crime is in progress.',
      phoneLabel: '119',
      telDigits: '119',
      icon: Icons.shield_outlined,
      accent: Color(0xFFFEE2E2),
      onAccent: _alertRose,
    ),
    SosContact(
      title: 'Suwa Seriya ambulance',
      description:
          'Free government pre-hospital ambulance for serious medical emergencies.',
      phoneLabel: '1990',
      telDigits: '1990',
      icon: Icons.local_hospital_outlined,
      accent: Color(0xFFFFEDD5),
      onAccent: _warmCoral,
    ),
  ];

  static const List<SosContact> _mentalHealth = [
    SosContact(
      title: 'National Mental Health Helpline',
      description:
          'National Institute of Mental Health, Sri Lanka — support for psychological distress and crisis (verify hours on official channels).',
      phoneLabel: '1926',
      telDigits: '1926',
      icon: Icons.psychology_outlined,
      accent: Color(0xFFCCFBF1),
      onAccent: kMoodFlowTealNav,
    ),
    SosContact(
      title: 'Sumithrayo',
      description:
          'Free, confidential emotional support (check official website for current hours and regional numbers).',
      phoneLabel: '011 269 6666',
      telDigits: '0112696666',
      icon: Icons.volunteer_activism_outlined,
      accent: Color(0xFFE9D5FF),
      onAccent: _accentPurple,
    ),
  ];

  /// Opens the system phone UI with [telDigits] prefilled (dial pad, user confirms).
  ///
  /// Android: [AndroidIntent] with plugin action `action_dial` (maps to ACTION_DIAL),
  /// then [url_launcher] as fallback. iOS requires `tel` under
  /// `LSApplicationQueriesSchemes` in Info.plist for reliable dialling.
  Future<void> _dial(BuildContext context, String telDigits) async {
    final cleaned = telDigits.replaceAll(RegExp(r'\s+'), '');
    if (cleaned.isEmpty) return;

    // Prefer opaque `tel:number` — avoids hierarchical Uri quirks on some platforms.
    final uri = Uri.parse('tel:$cleaned');

    Future<void> offerClipboardFallback() async {
      await Clipboard.setData(ClipboardData(text: cleaned));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Copied $cleaned — paste into the Phone app to dial. '
            'Note: iOS Simulator usually cannot open tel: links; use a real iPhone to test.',
          ),
          duration: const Duration(seconds: 6),
        ),
      );
    }

    try {
      // iOS: native channel bypasses url_launcher's canOpenURL checks (common failure source).
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        try {
          final dynamic ok = await _iosSosPhoneChannel.invokeMethod(
            'openTel',
            <String, dynamic>{'number': cleaned},
          );
          if (ok == true) return;
        } catch (_) {
          // Channel not ready or isolate without iOS embedding — fall through.
        }
      }

      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        try {
          await AndroidIntent(
            action: 'action_dial',
            data: uri.toString(),
          ).launch();
          return;
        } catch (_) {
          // Emulator without dialer — try url_launcher.
        }
      }

      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!opened && context.mounted) {
        await offerClipboardFallback();
      }
    } catch (_) {
      if (context.mounted) {
        await offerClipboardFallback();
      }
    }
  }

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
              'Crisis support',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
                letterSpacing: -0.5,
                height: 1.1,
              ),
            ),
            Text(
              'Numbers you can rely on · Sri Lanka focus',
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
            _HeroBanner(),
            const SizedBox(height: 14),
            _DisclaimerCard(),
            const SizedBox(height: 22),
            const _SectionLabel('If you need help right now'),
            const SizedBox(height: 8),
            ..._emergency.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ContactCard(contact: c, onCall: () => _dial(context, c.telDigits)),
              ),
            ),
            const SizedBox(height: 8),
            const _SectionLabel('Mental health & emotional listening'),
            const SizedBox(height: 8),
            ..._mentalHealth.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ContactCard(contact: c, onCall: () => _dial(context, c.telDigits)),
              ),
            ),
            const SizedBox(height: 8),
            const _SectionLabel('At your university'),
            const SizedBox(height: 8),
            _UniversityCard(),
            const SizedBox(height: 18),
            Text(
              'This app gives signposting only. It does not provide diagnosis, counselling, '
              'or emergency response. Telephone services may update their numbers; '
              'confirm on official government or organisation websites when you can.',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                height: 1.45,
                color: Colors.black.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kMoodFlowTealNav,
            kMoodFlowTealAccent,
          ],
        ),
        borderRadius: BorderRadius.circular(kMoodFlowNeoRadius),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: _sosNeoShadows(),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'You matter',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.4,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'If things feel overwhelming, reaching out is a strong step. '
                  'Use the numbers below or talk to someone you trust.',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DisclaimerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kMoodCardCreamA,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            offset: const Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: kMoodFlowTealNav, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Examination Stress Recovery can support day-to-day coping. '
              'It is not an emergency service. For acute risk, use emergency lines or go to the nearest hospital.',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                height: 1.4,
                color: Colors.black.withValues(alpha: 0.58),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w900,
        color: Colors.black87,
        letterSpacing: -0.2,
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.contact, required this.onCall});

  final SosContact contact;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kMoodCardCreamA, kMoodCardCreamB],
        ),
        borderRadius: BorderRadius.circular(kMoodFlowNeoRadius),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: _sosNeoShadows(),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: contact.accent,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: Icon(contact.icon, color: contact.onAccent, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                          letterSpacing: -0.35,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        contact.description,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                          color: Colors.black.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: Text(
                      contact.phoneLabel,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Material(
                  color: kMoodMint,
                  borderRadius: BorderRadius.circular(14),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: onCall,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.phone_forwarded_rounded,
                              color: Colors.black87, size: 20),
                          SizedBox(width: 6),
                          Text(
                            'Dial',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Colors.black87,
                            ),
                          ),
                        ],
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
}

class _UniversityCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kMoodFlowNeoRadius),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: _sosNeoShadows(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kMoodSelectedGreenA,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: Icon(Icons.school_outlined, color: kMoodFlowTealNav, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'University counselling',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Many institutions run student counselling and welfare units. '
            'Check your faculty handbook, student portal, or notice boards for the official phone number, email, and walk-in hours on your campus.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.4,
              color: Colors.black.withValues(alpha: 0.52),
            ),
          ),
        ],
      ),
    );
  }
}
