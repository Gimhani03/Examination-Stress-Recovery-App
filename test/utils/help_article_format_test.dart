import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/utils/help_article_format.dart';

void main() {
  group('stripHelpHtmlEntities', () {
    test('replaces common entities', () {
      expect(stripHelpHtmlEntities('a &amp; b &lt; c &gt;'), 'a & b < c >');
    });
  });

  group('helpArticleParagraphs', () {
    test('splits on blank lines', () {
      expect(
        helpArticleParagraphs('First.\n\nSecond line.'),
        ['First.', 'Second line.'],
      );
    });

    test('collapses internal whitespace per paragraph', () {
      expect(
        helpArticleParagraphs('Hello   world\n\nNext'),
        ['Hello world', 'Next'],
      );
    });

    test('single block with no double newline wraps whole trimmed body', () {
      expect(helpArticleParagraphs('Only one'), ['Only one']);
    });
  });

  group('isHelpDisclaimerParagraph', () {
    test('detects therapy / emergency phrasing', () {
      expect(
        isHelpDisclaimerParagraph(
          'This is not therapy or emergency care. Call 911.',
        ),
        isTrue,
      );
      expect(
        isHelpDisclaimerParagraph('Not therapy and emergency care here'),
        isTrue,
      );
    });

    test('detects urgent / crisis phrasing', () {
      expect(isHelpDisclaimerParagraph('Need urgent help now'), isTrue);
      expect(
        isHelpDisclaimerParagraph('Open Crisis and helplines from Profile'),
        isTrue,
      );
      expect(
        isHelpDisclaimerParagraph('call your local emergency number'),
        isTrue,
      );
      expect(
        isHelpDisclaimerParagraph('If you are unsafe you need urgent care'),
        isTrue,
      );
    });

    test('returns false for unrelated copy', () {
      expect(isHelpDisclaimerParagraph('How to use the focus timer'), isFalse);
    });
  });

  group('helpArticlePreviewLine', () {
    test('returns short text unchanged', () {
      const s = 'Short';
      expect(helpArticlePreviewLine(s), s);
    });

    test('truncates long single line with ellipsis', () {
      final long = List.filled(130, 'a').join();
      final out = helpArticlePreviewLine(long);
      expect(out.endsWith('…'), isTrue);
      expect(out.length, 117 + '…'.length);
    });
  });
}
