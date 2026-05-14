import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/notification_payload_handler.dart';

void main() {
  group('parseSocialPostNotificationPayload', () {
    test('returns null for null empty or non-social payload', () {
      expect(parseSocialPostNotificationPayload(null), isNull);
      expect(parseSocialPostNotificationPayload(''), isNull);
      expect(parseSocialPostNotificationPayload('   '), isNull);
      expect(parseSocialPostNotificationPayload('other:123'), isNull);
    });

    test('returns id after prefix', () {
      expect(
        parseSocialPostNotificationPayload('social_post:abc-123'),
        'abc-123',
      );
    });

    test('trims outer whitespace on payload', () {
      expect(
        parseSocialPostNotificationPayload('  social_post:xyz  '),
        'xyz',
      );
    });

    test('returns null when id segment empty', () {
      expect(parseSocialPostNotificationPayload('social_post:'), isNull);
      expect(parseSocialPostNotificationPayload('social_post: '), isNull);
    });
  });
}
