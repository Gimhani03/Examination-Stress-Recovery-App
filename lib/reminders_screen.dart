import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'mood_flow_theme.dart';
import 'services/reminder_service.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  bool _loading = true;
  bool _saving = false;

  bool _enMood = true;
  bool _enStudy = true;
  bool _enBreathe = true;
  bool _enRec = true;
  bool _enCh = true;
  bool _enEvents = true;

  TimeOfDay _tMood = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _tStudy = const TimeOfDay(hour: 14, minute: 0);
  TimeOfDay _tBreathe = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _tRec = const TimeOfDay(hour: 15, minute: 0);
  TimeOfDay _tCh = const TimeOfDay(hour: 18, minute: 0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }
    setState(() {
      _enMood = p.getBool(ReminderPrefKeys.enableMood) ?? true;
      _enStudy = p.getBool(ReminderPrefKeys.enableStudy) ?? true;
      _enBreathe = p.getBool(ReminderPrefKeys.enableBreathe) ?? true;
      _enRec = p.getBool(ReminderPrefKeys.enableRecovery) ?? true;
      _enCh = p.getBool(ReminderPrefKeys.enableChallenges) ?? true;
      _enEvents = p.getBool(ReminderPrefKeys.enableEvents) ?? true;
      _tMood = TimeOfDay(
        hour: p.getInt(ReminderPrefKeys.moodH) ?? 8,
        minute: p.getInt(ReminderPrefKeys.moodM) ?? 0,
      );
      _tStudy = TimeOfDay(
        hour: p.getInt(ReminderPrefKeys.studyH) ?? 14,
        minute: p.getInt(ReminderPrefKeys.studyM) ?? 0,
      );
      _tBreathe = TimeOfDay(
        hour: p.getInt(ReminderPrefKeys.breatheH) ?? 10,
        minute: p.getInt(ReminderPrefKeys.breatheM) ?? 0,
      );
      _tRec = TimeOfDay(
        hour: p.getInt(ReminderPrefKeys.recoveryH) ?? 15,
        minute: p.getInt(ReminderPrefKeys.recoveryM) ?? 0,
      );
      _tCh = TimeOfDay(
        hour: p.getInt(ReminderPrefKeys.challengesH) ?? 18,
        minute: p.getInt(ReminderPrefKeys.challengesM) ?? 0,
      );
      _loading = false;
    });
  }

  Future<void> _pickTime(TimeOfDay initial, void Function(TimeOfDay) onPick) async {
    final t = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (t != null) {
      onPick(t);
      setState(() {});
    }
  }

  Future<void> _save() async {
    if (_saving) {
      return;
    }
    if (Supabase.instance.client.auth.currentUser == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to use reminders.')),
      );
      return;
    }
    setState(() {
      _saving = true;
    });
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(ReminderPrefKeys.enableMood, _enMood);
      await p.setBool(ReminderPrefKeys.enableStudy, _enStudy);
      await p.setBool(ReminderPrefKeys.enableBreathe, _enBreathe);
      await p.setBool(ReminderPrefKeys.enableRecovery, _enRec);
      await p.setBool(ReminderPrefKeys.enableChallenges, _enCh);
      await p.setBool(ReminderPrefKeys.enableEvents, _enEvents);
      await p.setInt(ReminderPrefKeys.moodH, _tMood.hour);
      await p.setInt(ReminderPrefKeys.moodM, _tMood.minute);
      await p.setInt(ReminderPrefKeys.studyH, _tStudy.hour);
      await p.setInt(ReminderPrefKeys.studyM, _tStudy.minute);
      await p.setInt(ReminderPrefKeys.breatheH, _tBreathe.hour);
      await p.setInt(ReminderPrefKeys.breatheM, _tBreathe.minute);
      await p.setInt(ReminderPrefKeys.recoveryH, _tRec.hour);
      await p.setInt(ReminderPrefKeys.recoveryM, _tRec.minute);
      await p.setInt(ReminderPrefKeys.challengesH, _tCh.hour);
      await p.setInt(ReminderPrefKeys.challengesM, _tCh.minute);

      final granted = await ReminderService.instance.requestPermissions();
      await ReminderService.instance.applySchedulesFromPreferences(requestOsPermission: false);
      if (!mounted) {
        return;
      }
      if (!granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Notifications are off — open system Settings → Apps → this app → Notifications, then save again.',
            ),
          ),
        );
      } else {
        final passedMoodTime = _enMood &&
            ReminderService.nextDailyFiresTomorrow(_tMood.hour, _tMood.minute);
        final passedStudyTime = _enStudy &&
            ReminderService.nextDailyFiresTomorrow(_tStudy.hour, _tStudy.minute);
        var msg = 'Reminders saved and scheduled.';
        if (passedMoodTime || passedStudyTime) {
          msg =
              '$msg Because that time already passed today, the first alert for those is tomorrow at the time you set — not the next few minutes.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  PreferredSizeWidget _appBar() {
    return AppBar(
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
          }
        },
      ),
      title: const Text(
        'Notification settings',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: Colors.black87,
          letterSpacing: -0.5,
        ),
      ),
      centerTitle: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: kMoodFlowBg,
        appBar: _appBar(),
        body: const Center(
          child: CircularProgressIndicator(color: kMoodFlowTealAccent),
        ),
      );
    }

    final themedList = ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
          _ReminderRow(
            title: 'Daily mood & sleep',
            subtitle: 'Remember to check in',
            value: _enMood,
            onChanged: (v) => setState(() => _enMood = v),
            time: _tMood,
            onTimeTap: () => _pickTime(
              _tMood,
              (t) => setState(() => _tMood = t),
            ),
          ),
          const SizedBox(height: 10),
          _ReminderRow(
            title: 'Study (Focus Timer)',
            subtitle: 'Nudge to start a focus session',
            value: _enStudy,
            onChanged: (v) => setState(() => _enStudy = v),
            time: _tStudy,
            onTimeTap: () => _pickTime(
              _tStudy,
              (t) => setState(() => _tStudy = t),
            ),
          ),
          const SizedBox(height: 10),
          _ReminderRow(
            title: 'Breathing (mood-based)',
            subtitle: 'Tied to your last mood log',
            value: _enBreathe,
            onChanged: (v) => setState(() => _enBreathe = v),
            time: _tBreathe,
            onTimeTap: () => _pickTime(
              _tBreathe,
              (t) => setState(() => _tBreathe = t),
            ),
          ),
          const SizedBox(height: 10),
          _ReminderRow(
            title: 'Recovery tips (mood-based)',
            subtitle: 'Suggestions for your last mood',
            value: _enRec,
            onChanged: (v) => setState(() => _enRec = v),
            time: _tRec,
            onTimeTap: () => _pickTime(
              _tRec,
              (t) => setState(() => _tRec = t),
            ),
          ),
          const SizedBox(height: 10),
          _ReminderRow(
            title: 'Challenges (mood-based)',
            subtitle: 'Goals aligned with how you feel',
            value: _enCh,
            onChanged: (v) => setState(() => _enCh = v),
            time: _tCh,
            onTimeTap: () => _pickTime(
              _tCh,
              (t) => setState(() => _tCh = t),
            ),
          ),
          const SizedBox(height: 10),
          _reminderBox(
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: const Text(
                'Calendar events',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              subtitle: Text(
                'Day before at 9:00, and 3h before a timed event',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                  color: Colors.black.withValues(alpha: 0.45),
                  height: 1.25,
                ),
              ),
              trailing: _NeoReminderSwitch(
                value: _enEvents,
                onChanged: (v) => setState(() => _enEvents = v),
              ),
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: kMoodMint,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Colors.black, width: 2),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black87,
                      ),
                    )
                  : const Text(
                      'Save & schedule reminders',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
    );

    return Scaffold(
      backgroundColor: kMoodFlowBg,
      appBar: _appBar(),
      body: SafeArea(
        child: themedList,
      ),
    );
  }

  Widget _reminderBox({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kMoodFlowNeoRadius),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: moodFlowNeoShadows(),
      ),
      child: child,
    );
  }
}

/// Neo-brutalist toggle: black track outline; white thumb with black border.
class _NeoReminderSwitch extends StatelessWidget {
  const _NeoReminderSwitch({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  static const double _trackH = 30;
  static const double _thumb = 22;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onChanged(!value),
          borderRadius: BorderRadius.circular(_trackH / 2),
          splashColor: Colors.black.withValues(alpha: 0.07),
          child: Ink(
            width: 52,
            height: _trackH,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_trackH / 2),
              border: Border.all(color: Colors.black, width: 2),
              color: value ? kMoodMint : const Color(0xFFE8E8E8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: _thumb,
                height: _thumb,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.black, width: 2),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final TimeOfDay time;
  final VoidCallback onTimeTap;

  const _ReminderRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.time,
    required this.onTimeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kMoodFlowNeoRadius),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: moodFlowNeoShadows(),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            subtitle: Text(
              subtitle,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
                color: Colors.black.withValues(alpha: 0.45),
                height: 1.25,
              ),
            ),
            trailing: _NeoReminderSwitch(
              value: value,
              onChanged: onChanged,
            ),
          ),
          if (value) ...[
            Divider(
              height: 1,
              thickness: 1,
              color: Colors.black.withValues(alpha: 0.12),
            ),
            ListTile(
              title: const Text('Time', style: TextStyle(fontWeight: FontWeight.w700)),
              trailing: TextButton(
                onPressed: onTimeTap,
                child: Text(
                  time.format(context),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: kMoodFlowTealNav,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
