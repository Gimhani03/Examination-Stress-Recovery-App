import 'dart:io';
import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

import 'event_service.dart';
import 'event_time_parse.dart';
import 'mood_log_service.dart';
import '../notification_payload_handler.dart';

/// Local notification id ranges (must stay stable for cancel/reschedule).
abstract final class ReminderIds {
  static const int moodDaily = 101;
  static const int studyDaily = 102;
  static const int breatheDaily = 103;
  static const int recoveryDaily = 104;
  static const int challengesDaily = 105;

  static int eventDayBefore(String eventId) =>
      1_000_000 + (eventId.hashCode & 0x3FFFFF);

  static int eventThreeHours(String eventId) =>
      4_000_000 + (eventId.hashCode & 0x3FFFFF);
}

abstract final class ReminderPrefKeys {
  static const enableMood = 'reminder_enable_mood';
  static const enableStudy = 'reminder_enable_study';
  static const enableBreathe = 'reminder_enable_breathe';
  static const enableRecovery = 'reminder_enable_recovery';
  static const enableChallenges = 'reminder_enable_challenges';
  static const enableEvents = 'reminder_enable_events';

  static const moodH = 'reminder_h_mood';
  static const moodM = 'reminder_m_mood';
  static const studyH = 'reminder_h_study';
  static const studyM = 'reminder_m_study';
  static const breatheH = 'reminder_h_breathe';
  static const breatheM = 'reminder_m_breathe';
  static const recoveryH = 'reminder_h_recovery';
  static const recoveryM = 'reminder_m_recovery';
  static const challengesH = 'reminder_h_challenges';
  static const challengesM = 'reminder_m_challenges';

  static const storedEventIds = 'reminder_scheduled_event_ids';
}

/// Drives platform-specific “nice” notification styling (Android BigText + color; iOS subtitle).
enum ReminderNotificationStyle {
  mood,
  focus,
  breathe,
  recovery,
  challenge,
  event,
}

/// Schedules local notifications: daily wellbeing + calendar (day before & 3h).
class ReminderService {
  ReminderService._();
  static final ReminderService instance = ReminderService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  final EventService _eventService = EventService();
  static const String _androidChannelId = 'exam_recovery_reminders';
  static const String _androidSocialChannelId = 'exam_recovery_social';
  static const String _kBrandName = 'Examination Stress Recovery';
  static const int _kDayBeforeHour = 9;
  static const int _kDayBeforeMinute = 0;

  static Color _accent(ReminderNotificationStyle s) {
    switch (s) {
      case ReminderNotificationStyle.mood:
        return const Color(0xFF7C3AED);
      case ReminderNotificationStyle.focus:
        return const Color(0xFFEA580C);
      case ReminderNotificationStyle.breathe:
        return const Color(0xFF0D9488);
      case ReminderNotificationStyle.recovery:
        return const Color(0xFF6B21A8);
      case ReminderNotificationStyle.challenge:
        return const Color(0xFFF59E0B);
      case ReminderNotificationStyle.event:
        return const Color(0xFF0F766E);
    }
  }

  static String _shortTag(ReminderNotificationStyle s) {
    switch (s) {
      case ReminderNotificationStyle.mood:
        return 'Daily mood & sleep';
      case ReminderNotificationStyle.focus:
        return 'Focus session';
      case ReminderNotificationStyle.breathe:
        return 'Breathe for your mood';
      case ReminderNotificationStyle.recovery:
        return 'Recovery tips';
      case ReminderNotificationStyle.challenge:
        return 'Challenges';
      case ReminderNotificationStyle.event:
        return 'Calendar';
    }
  }

  /// Android: BigText (expand for full copy), accent color, sub-line. iOS: subtitle + grouping.
  NotificationDetails _buildNotificationDetails({
    required ReminderNotificationStyle style,
    required String title,
    required String body,
  }) {
    final big = StringBuffer()
      ..writeln(body)
      ..writeln()
      ..writeln('—')
      ..writeln(_kBrandName)
      ..writeln()
      ..write('Tap to open the app.');

    return NotificationDetails(
      android: AndroidNotificationDetails(
        _androidChannelId,
        'Reminders',
        channelDescription: 'Mood, focus, wellness, and calendar',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        visibility: NotificationVisibility.public,
        channelShowBadge: true,
        color: _accent(style),
        subText: _shortTag(style),
        ticker: title,
        styleInformation: BigTextStyleInformation(
          big.toString(),
          summaryText: _kBrandName,
        ),
        category: AndroidNotificationCategory.reminder,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: true,
        presentBanner: true,
        presentList: true,
        subtitle: _shortTag(style),
        threadIdentifier: 'moodflow.exam_stress.reminders',
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    );
  }

  bool _initialized = false;

  Future<void> ensureInitialized() async {
    if (_initialized) {
      return;
    }
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: handleLocalNotificationResponse,
    );

    if (Platform.isAndroid) {
      final androidImpl =
          _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.createNotificationChannel(
        const AndroidNotificationChannel(
          _androidChannelId,
          'Reminders',
          description: 'Mood, focus, wellness, and calendar',
          importance: Importance.max,
        ),
      );
      await androidImpl?.createNotificationChannel(
        const AndroidNotificationChannel(
          _androidSocialChannelId,
          'Social',
          description: 'Likes and replies on your Emotion board posts',
          importance: Importance.high,
        ),
      );
    }
    _initialized = true;
  }

  /// If the app was opened by tapping a local notification (cold start).
  Future<void> handleNotificationAppLaunch() async {
    await ensureInitialized();
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp == true) {
      final r = details!.notificationResponse;
      if (r != null) {
        handleLocalNotificationResponse(r);
      }
    }
  }

  /// Immediate system banner for Emotion board likes / replies (Realtime or foreground).
  Future<void> showSocialInteractionNotification({
    required String title,
    required String body,
    required String postId,
    int? notificationId,
  }) async {
    await ensureInitialized();
    final id = notificationId ?? DateTime.now().millisecondsSinceEpoch.remainder(2000000000);
    const accent = Color(0xFF7C3AED);
    const sub = 'Emotion board';
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _androidSocialChannelId,
        'Social',
        channelDescription: 'Likes and replies on your Emotion board posts',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        color: accent,
        subText: sub,
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
          summaryText: sub,
        ),
        category: AndroidNotificationCategory.social,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: true,
        presentBanner: true,
        presentList: true,
        subtitle: 'Emotion board',
        threadIdentifier: 'moodflow.exam_stress.social',
        interruptionLevel: InterruptionLevel.active,
      ),
    );
    await _plugin.show(
      id,
      title,
      body,
      details,
      payload: 'social_post:$postId',
    );
  }

  static const List<String> _timezoneFallbacks = <String>[
    'Asia/Colombo',
    'Asia/Kolkata',
    'UTC',
  ];

  static Future<void> initTimeZone() async {
    tzdata.initializeTimeZones();
    String? primary;
    try {
      primary = await FlutterTimezone.getLocalTimezone();
    } catch (e) {
      debugPrint('reminder: getLocalTimezone $e');
    }
    final candidates = <String>[
      if (primary != null && primary.isNotEmpty) primary,
      ..._timezoneFallbacks,
    ];
    for (final name in candidates) {
      try {
        tz.setLocalLocation(tz.getLocation(name));
        debugPrint('reminder: using timezone $name');
        return;
      } catch (e) {
        debugPrint('reminder: getLocation($name) $e');
      }
    }
    debugPrint('reminder: all timezone inits failed');
    tz.setLocalLocation(tz.UTC);
  }

  /// Asks the OS to allow notifications. On Android 12 and below, [null] is returned; treat that as allowed.
  Future<bool> requestPermissions() async {
    if (Platform.isIOS) {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      return await ios?.requestPermissions(alert: true, badge: true, sound: true) ?? false;
    }
    if (Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final r = await android?.requestNotificationsPermission();
      if (r == true) {
        return true;
      }
      if (r == false) {
        return false;
      }
      // API < 33: no runtime permission; null means not needed.
      return true;
    }
    return true;
  }

  /// For UI copy: if you choose [hour]:[minute] and save **after** that moment today, the *next* alarm is **tomorrow**.
  static bool nextDailyFiresTomorrow(int hour, int minute) {
    final now = DateTime.now();
    final s = DateTime(now.year, now.month, now.day, hour, minute);
    if (!s.isAfter(now)) {
      return true;
    }
    return false;
  }

  Future<AndroidScheduleMode> _androidScheduleMode() async {
    if (!Platform.isAndroid) {
      return AndroidScheduleMode.exact;
    }
    final android = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    // Prefer exact times. If the OS disallows, use inexact or scheduling throws
    // ExactAlarmPermissionException on the native side.
    final can = await android?.canScheduleExactNotifications();
    if (can == true) {
      // match example app: more reliable for wake-up delivery than plain exact on some devices.
      return AndroidScheduleMode.exactAllowWhileIdle;
    }
    if (can == false) {
      return AndroidScheduleMode.inexact;
    }
    // Unknown / older API: avoid native exact-alarm exception.
    return AndroidScheduleMode.inexact;
  }

  /// Load prefs with defaults, schedule everything (when signed in for events).
  /// Set [requestOsPermission] to false if you already called [requestPermissions] (e.g. Reminders save).
  Future<void> applySchedulesFromPreferences({bool requestOsPermission = true}) async {
    await ensureInitialized();
    if (requestOsPermission) {
      // Required on Android 13+ (and iOS) or nothing will ever show.
      await requestPermissions();
    }
    final mode = await _androidScheduleMode();
    final prefs = await SharedPreferences.getInstance();
    final user = Supabase.instance.client.auth.currentUser;

    final mH = prefs.getInt(ReminderPrefKeys.moodH) ?? 8;
    final mM = prefs.getInt(ReminderPrefKeys.moodM) ?? 0;
    final sH = prefs.getInt(ReminderPrefKeys.studyH) ?? 14;
    final sM = prefs.getInt(ReminderPrefKeys.studyM) ?? 0;
    final bH = prefs.getInt(ReminderPrefKeys.breatheH) ?? 10;
    final bM = prefs.getInt(ReminderPrefKeys.breatheM) ?? 0;
    final rH = prefs.getInt(ReminderPrefKeys.recoveryH) ?? 15;
    final rM = prefs.getInt(ReminderPrefKeys.recoveryM) ?? 0;
    final cH = prefs.getInt(ReminderPrefKeys.challengesH) ?? 18;
    final cM = prefs.getInt(ReminderPrefKeys.challengesM) ?? 0;

    final enMood = prefs.getBool(ReminderPrefKeys.enableMood) ?? true;
    final enStudy = prefs.getBool(ReminderPrefKeys.enableStudy) ?? true;
    final enBreathe = prefs.getBool(ReminderPrefKeys.enableBreathe) ?? true;
    final enRec = prefs.getBool(ReminderPrefKeys.enableRecovery) ?? true;
    final enCh = prefs.getBool(ReminderPrefKeys.enableChallenges) ?? true;
    final enEvents = prefs.getBool(ReminderPrefKeys.enableEvents) ?? true;

    String? lastMood;
    if (user != null) {
      try {
        final latest = await MoodLogService().getLatestMoodLog();
        lastMood = latest?['mood'] as String?;
      } on AuthException {
        lastMood = null;
      } catch (e) {
        debugPrint('reminder: latest mood $e');
      }
    }
    final moodLabel = friendlyMoodLabel(lastMood);

    await _scheduleDaily(
      id: ReminderIds.moodDaily,
      style: ReminderNotificationStyle.mood,
      title: 'Log your mood',
      body: 'Take a moment to check in and log your mood and sleep for today.',
      hour: mH,
      minute: mM,
      enabled: enMood,
      androidMode: mode,
    );
    await _scheduleDaily(
      id: ReminderIds.studyDaily,
      style: ReminderNotificationStyle.focus,
      title: 'Study session',
      body: 'Time for a focus block — open Focus Timer and start a study session.',
      hour: sH,
      minute: sM,
      enabled: enStudy,
      androidMode: mode,
    );
    final breatheBody = lastMood == null
        ? 'Log your mood, then try a breathing exercise matched to how you feel.'
        : 'Try a breathing exercise tailored to your $moodLabel mood today.';
    await _scheduleDaily(
      id: ReminderIds.breatheDaily,
      style: ReminderNotificationStyle.breathe,
      title: 'Breathing exercise',
      body: breatheBody,
      hour: bH,
      minute: bM,
      enabled: enBreathe,
      androidMode: mode,
    );
    final recoveryBody = lastMood == null
        ? 'Open Recovery Tips after you log your mood for ideas that fit you.'
        : 'See recovery tips and relaxation ideas for your $moodLabel mood.';
    await _scheduleDaily(
      id: ReminderIds.recoveryDaily,
      style: ReminderNotificationStyle.recovery,
      title: 'Recovery tips',
      body: recoveryBody,
      hour: rH,
      minute: rM,
      enabled: enRec,
      androidMode: mode,
    );
    final chBody = lastMood == null
        ? 'Check Challenges for small goals — they work best after you log your mood.'
        : 'Today’s challenges can match your $moodLabel mood — have a look.';
    await _scheduleDaily(
      id: ReminderIds.challengesDaily,
      style: ReminderNotificationStyle.challenge,
      title: 'Challenges',
      body: chBody,
      hour: cH,
      minute: cM,
      enabled: enCh,
      androidMode: mode,
    );

    if (enEvents && user != null) {
      await syncCalendarEventReminders(androidMode: mode);
    } else {
      await _cancelAllEventReminders(prefs);
    }
  }

  Future<void> _cancelAllEventReminders(SharedPreferences prefs) async {
    final prev = prefs.getStringList(ReminderPrefKeys.storedEventIds) ?? [];
    for (final id in prev) {
      await _plugin.cancel(ReminderIds.eventDayBefore(id));
      await _plugin.cancel(ReminderIds.eventThreeHours(id));
    }
    await prefs.setStringList(ReminderPrefKeys.storedEventIds, []);
  }

  /// One-shot and recurring calendar reminders from Supabase [events].
  Future<void> syncCalendarEventReminders({AndroidScheduleMode? androidMode}) async {
    await ensureInitialized();
    final mode = androidMode ?? await _androidScheduleMode();
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final enEvents = prefs.getBool(ReminderPrefKeys.enableEvents) ?? true;
    if (!enEvents) {
      await _cancelAllEventReminders(prefs);
      return;
    }

    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final end = now.add(const Duration(days: 400));
    List<Map<String, dynamic>> eventMaps;
    try {
      eventMaps =
          await _eventService.getEventsForRange(start: startOfToday, end: end);
    } catch (e) {
      debugPrint('reminder: events fetch $e');
      return;
    }

    final currentIds = <String>{};
    for (final m in eventMaps) {
      final id = m['id']?.toString();
      if (id == null || id.isEmpty) {
        continue;
      }
      currentIds.add(id);
    }

    final prev = prefs.getStringList(ReminderPrefKeys.storedEventIds) ?? [];
    for (final id in prev) {
      if (!currentIds.contains(id)) {
        await _plugin.cancel(ReminderIds.eventDayBefore(id));
        await _plugin.cancel(ReminderIds.eventThreeHours(id));
      }
    }

    for (final m in eventMaps) {
      final id = m['id']?.toString();
      if (id == null || id.isEmpty) {
        continue;
      }
      final title = (m['title'] as String?)?.trim().isNotEmpty == true
          ? m['title'] as String
          : 'Event';
      final dateStr = m['event_date'] as String?;
      final localDate = parseEventDateLocal(dateStr);
      if (localDate == null) {
        continue;
      }
      if (localDate.isBefore(startOfToday)) {
        continue;
      }
      final timeStr = (m['time'] as String?) ?? 'Any time';

      await _plugin.cancel(ReminderIds.eventDayBefore(id));
      await _plugin.cancel(ReminderIds.eventThreeHours(id));

      final whenEvent = parseEventTimeToLocalDateTime(timeStr, localDate);
      if (whenEvent == null) {
        // All-day: only day-before reminder
        await _scheduleDayBefore(
            id: id, title: title, eventDay: localDate, androidMode: mode);
        continue;
      }
      await _scheduleDayBefore(
          id: id, title: title, eventDay: localDate, androidMode: mode);
      await _scheduleThreeHoursBefore(
        id: id,
        title: title,
        at: whenEvent,
        androidMode: mode,
      );
    }

    await prefs.setStringList(
      ReminderPrefKeys.storedEventIds,
      currentIds.toList(),
    );
  }

  /// One-shot calendar alerts; mirrors [_scheduleDaily] Android exact-alarm fallback.
  Future<void> _scheduleOneShotEvent({
    required int notificationId,
    required String title,
    required String body,
    required tz.TZDateTime when,
    required AndroidScheduleMode androidMode,
  }) async {
    final details = _buildNotificationDetails(
      style: ReminderNotificationStyle.event,
      title: title,
      body: body,
    );
    try {
      await _plugin.zonedSchedule(
        notificationId,
        title,
        body,
        when,
        details,
        androidScheduleMode: androidMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.wallClockTime,
      );
    } on Object catch (e) {
      if (!Platform.isAndroid) {
        rethrow;
      }
      debugPrint('reminder: event one-shot $notificationId $e, retrying inexact');
      await _plugin.zonedSchedule(
        notificationId,
        title,
        body,
        when,
        details,
        androidScheduleMode: AndroidScheduleMode.inexact,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.wallClockTime,
      );
    }
  }

  Future<void> _scheduleDayBefore({
    required String id,
    required String title,
    required DateTime eventDay,
    required AndroidScheduleMode androidMode,
  }) async {
    final dayBefore = eventDay.subtract(const Duration(days: 1));
    var fire = tz.TZDateTime(
      tz.local,
      dayBefore.year,
      dayBefore.month,
      dayBefore.day,
      _kDayBeforeHour,
      _kDayBeforeMinute,
    );
    final tNow = tz.TZDateTime.now(tz.local);
    if (!fire.isAfter(tNow)) {
      if (kDebugMode) {
        debugPrint(
          'reminder: skip day-before for "$title" — 9:00 on ${dayBefore.year}-${dayBefore.month}-${dayBefore.day} '
          'already passed (now $tNow). Open Notification settings & save after adding events before that time.',
        );
      }
      return;
    }
    const sub = 'Your calendar event is tomorrow. Want to prep or rest tonight?';
    final head = 'Tomorrow: $title';
    await _scheduleOneShotEvent(
      notificationId: ReminderIds.eventDayBefore(id),
      title: head,
      body: sub,
      when: fire,
      androidMode: androidMode,
    );
  }

  Future<void> _scheduleThreeHoursBefore({
    required String id,
    required String title,
    required DateTime at,
    required AndroidScheduleMode androidMode,
  }) async {
    var fire = tz.TZDateTime.from(at.subtract(const Duration(hours: 3)), tz.local);
    final tNow = tz.TZDateTime.now(tz.local);
    if (!fire.isAfter(tNow)) {
      if (kDebugMode) {
        debugPrint(
          'reminder: skip 3h-before for "$title" — fire time $fire not after now $tNow '
          '(check event time text parses, e.g. "2:00 PM" or "14:00").',
        );
      }
      return;
    }
    const sub = 'Starting in 3 hours — a heads-up from your calendar.';
    final head = 'Soon: $title';
    await _scheduleOneShotEvent(
      notificationId: ReminderIds.eventThreeHours(id),
      title: head,
      body: sub,
      when: fire,
      androidMode: androidMode,
    );
  }

  Future<void> _scheduleDaily({
    required int id,
    required ReminderNotificationStyle style,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required bool enabled,
    required AndroidScheduleMode androidMode,
  }) async {
    if (!enabled) {
      await _plugin.cancel(id);
      return;
    }
    await _plugin.cancel(id);
    final when = _nextInstanceOfTime(hour, minute);
    final details = _buildNotificationDetails(
      style: style,
      title: title,
      body: body,
    );
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        when,
        details,
        androidScheduleMode: androidMode,
        matchDateTimeComponents: DateTimeComponents.time,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.wallClockTime,
      );
    } on Object catch (e) {
      // Android: ExactAlarmPermissionException surfaces as a platform error; fall back.
      if (!Platform.isAndroid) {
        rethrow;
      }
      debugPrint('reminder: zonedSchedule $id $e, retrying inexact');
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        when,
        details,
        androidScheduleMode: AndroidScheduleMode.inexact,
        matchDateTimeComponents: DateTimeComponents.time,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.wallClockTime,
      );
    }
  }

  /// Uses the device [DateTime] wall clock first so the fire instant matches the user’s time picker
  /// even if [tz.local] was mis-initialized.
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = DateTime.now();
    var s = DateTime(now.year, now.month, now.day, hour, minute);
    if (!s.isAfter(now)) {
      s = s.add(const Duration(days: 1));
    }
    return tz.TZDateTime.from(s, tz.local);
  }

  /// After a new mood log, refresh mood-related notification copy.
  Future<void> onMoodLogged() => applySchedulesFromPreferences();
}
