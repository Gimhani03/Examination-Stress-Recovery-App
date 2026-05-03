// Help center article text helpers (pure functions for search + display).

String stripHelpHtmlEntities(String raw) {
  return raw
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>');
}

List<String> helpArticleParagraphs(String body) {
  final parts = body
      .split(RegExp(r'\n\s*\n'))
      .map((e) => e.trim().replaceAll(RegExp(r'\s+'), ' '))
      .where((e) => e.isNotEmpty)
      .toList();
  if (parts.isNotEmpty) return parts;
  return [body.trim()];
}

bool isHelpDisclaimerParagraph(String paragraph) {
  final t = paragraph.toLowerCase();
  return t.contains('not therapy or emergency care') ||
      t.contains('not therapy') && t.contains('emergency care') ||
      t.contains('urgent help') ||
      t.contains('crisis and helpline') ||
      t.contains('local emergency') ||
      (t.contains('unsafe') && t.contains('urgent'));
}

String helpArticlePreviewLine(String body) {
  final oneLine = body.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (oneLine.length <= 120) return oneLine;
  return '${oneLine.substring(0, 117)}…';
}
