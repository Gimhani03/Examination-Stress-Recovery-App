import 'package:flutter/material.dart';

/// Shared neo-brutalist tokens for mood log flow screens.
const Color kMoodFlowBg = Color(0xFFEDE9FE);
const double kMoodFlowNeoRadius = 22.0;
const Color kMoodFlowTealNav = Color(0xFF115E59);
const Color kMoodFlowTealAccent = Color(0xFF0D9488);
const Color kMoodCardCreamA = Color(0xFFFFF7ED);
const Color kMoodCardCreamB = Color(0xFFFFFBF5);
const Color kMoodMint = Color(0xFF5EEAD4);
/// Mint / green fill when a mood-flow option is selected.
const Color kMoodSelectedGreenA = Color(0xFFCCFBF1);
const Color kMoodSelectedGreenB = Color(0xFF99F6E4);

List<BoxShadow> moodFlowNeoShadows() => [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.28),
        offset: const Offset(4, 4),
        blurRadius: 0,
        spreadRadius: 0,
      ),
    ];

void moodFlowGoTo(BuildContext context, Widget screen) {
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (context) => screen),
    (route) => false,
  );
}

/// Same format as emotion-board post cards (local date · 12h time).
String formatEmotionPostTimestamp(dynamic raw) {
  if (raw == null) return '';
  DateTime? dt;
  if (raw is String) {
    dt = DateTime.tryParse(raw);
  } else if (raw is DateTime) {
    dt = raw;
  }
  if (dt == null) return '';
  final l = dt.toLocal();
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final mon = months[l.month - 1];
  var hour12 = l.hour % 12;
  if (hour12 == 0) hour12 = 12;
  final min = l.minute.toString().padLeft(2, '0');
  final ampm = l.hour < 12 ? 'AM' : 'PM';
  return '$mon ${l.day}, ${l.year} · $hour12:$min $ampm';
}
