import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/profile_avatar_presets.dart';

void main() {
  group('ProfileAvatarPreset.byId', () {
    test('returns null for null or empty id', () {
      expect(ProfileAvatarPreset.byId(null), isNull);
      expect(ProfileAvatarPreset.byId(''), isNull);
      expect(ProfileAvatarPreset.byId('   '), isNull);
    });

    test('returns preset for known ids', () {
      expect(ProfileAvatarPreset.byId('calm')?.id, 'calm');
      expect(ProfileAvatarPreset.byId('focus')?.id, 'focus');
      expect(ProfileAvatarPreset.byId('coffee')?.id, 'coffee');
    });

    test('returns null for unknown id', () {
      expect(ProfileAvatarPreset.byId('unknown'), isNull);
    });

    test('library ids are unique', () {
      final ids = ProfileAvatarPreset.library.map((p) => p.id).toList();
      expect(ids.toSet().length, ids.length);
    });
  });
}
