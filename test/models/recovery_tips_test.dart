import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/services/gemini_tips_service.dart';

void main() {
  group('RecoveryTips', () {
    test('toMap includes all keys', () {
      const tips = RecoveryTips(
        relaxationTitle: 'Breathe',
        relaxationInstruction: 'In and out',
        relaxationMinutes: 5,
        isBreathingExercise: true,
        breathingType: '4-7-8',
        recoveryTip: 'Tip',
        motivation: 'Go',
      );
      final m = tips.toMap();
      expect(m['relaxationTitle'], 'Breathe');
      expect(m['relaxationInstruction'], 'In and out');
      expect(m['relaxationMinutes'], 5);
      expect(m['isBreathingExercise'], true);
      expect(m['breathingType'], '4-7-8');
      expect(m['recoveryTip'], 'Tip');
      expect(m['motivation'], 'Go');
    });

    test('fromMap applies defaults', () {
      final t = RecoveryTips.fromMap({});
      expect(t.relaxationTitle, 'Relaxation');
      expect(t.relaxationInstruction, 'Take a short breathing break.');
      expect(t.relaxationMinutes, 2);
      expect(t.isBreathingExercise, false);
      expect(t.breathingType, isNull);
      expect(
        t.recoveryTip,
        'Break the task into smaller steps and do one at a time.',
      );
      expect(
        t.motivation,
        'You are making progress, even if it feels small.',
      );
    });

    test('fromMap reads breathing flag and type', () {
      final t = RecoveryTips.fromMap({
        'isBreathingExercise': true,
        'breathingType': 'box',
        'relaxationMinutes': 10,
      });
      expect(t.isBreathingExercise, true);
      expect(t.breathingType, 'box');
      expect(t.relaxationMinutes, 10);
    });
  });
}
