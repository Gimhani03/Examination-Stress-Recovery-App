import 'package:flutter/material.dart';
import 'homepage.dart';
import 'emotion_board_screen.dart';
import 'profile_screen.dart';
import 'recovery_tips_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/mood_log_service.dart';
import 'services/event_service.dart';
import 'models/event_model.dart';
import 'mood_flow_theme.dart';

const double _kCalNeoRadius = 22;

List<BoxShadow> _calendarNeoShadows() => [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.28),
        offset: const Offset(4, 4),
        blurRadius: 0,
        spreadRadius: 0,
      ),
    ];

BoxDecoration _calendarNeoDecoration(Color background) {
  return BoxDecoration(
    color: background,
    borderRadius: BorderRadius.circular(_kCalNeoRadius),
    border: Border.all(color: Colors.black, width: 2),
    boxShadow: _calendarNeoShadows(),
  );
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  final Map<DateTime, List<Event>> _eventsByDate = {};
  final Map<DateTime, Map<String, dynamic>> _moodLogsByDate = {};
  bool _isLoadingMoods = false;
  final EventService _eventService = EventService();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month);
    _selectedDate = DateTime(now.year, now.month, now.day);
    _loadMoodLogsForMonth(_currentMonth);
    _loadEventsForMonth(_currentMonth);
  }

  Future<void> _loadMoodLogsForMonth(DateTime month) async {
    setState(() {
      _isLoadingMoods = true;
    });

    final startLocal = DateTime(month.year, month.month, 1);
    final endLocal = DateTime(month.year, month.month + 1, 1);

    try {
      final logs = await MoodLogService().getMoodLogsForRange(
        start: startLocal.toUtc(),
        end: endLocal.toUtc(),
      );

      if (!mounted) return;
      _moodLogsByDate.clear();
      for (final log in logs) {
        final logDate = log['log_date'];
        if (logDate is String) {
          final date = DateTime.tryParse(logDate);
          if (date != null) {
            _moodLogsByDate[_normalizeDate(date)] = log;
          }
        }
      }
    } on AuthException {
      if (!mounted) return;
      _moodLogsByDate.clear();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMoods = false;
        });
      }
    }
  }

  Future<void> _loadEventsForMonth(DateTime month) async {
    final startLocal = DateTime(month.year, month.month, 1);
    final endLocal = DateTime(month.year, month.month + 1, 0);

    try {
      final eventMaps = await _eventService.getEventsForRange(
        start: startLocal,
        end: endLocal,
      );

      if (!mounted) return;
      _eventsByDate.clear();
      for (final eventMap in eventMaps) {
        final event = Event.fromDatabase(eventMap);
        final dateKey = _normalizeDate(event.eventDate);
        _eventsByDate.putIfAbsent(dateKey, () => []);
        _eventsByDate[dateKey]!.add(event);
      }
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      _eventsByDate.clear();
      setState(() {});
    }
  }

  void _goTo(BuildContext context, Widget screen) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => screen),
      (route) => false,
    );
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  String _formatDialogDate(DateTime d) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${days[d.weekday - 1]} · ${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  Widget _calendarDialogTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        textCapitalization: TextCapitalization.sentences,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          labelStyle: TextStyle(
            fontWeight: FontWeight.w800,
            color: Colors.black.withValues(alpha: 0.75),
            fontSize: 13,
          ),
          hintStyle: TextStyle(
            color: Colors.black.withValues(alpha: 0.38),
            fontWeight: FontWeight.w600,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.black, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.black, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: kMoodFlowTealAccent, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }

  Future<void> _addEventDialog(DateTime date) async {
    final titleController = TextEditingController();
    final timeController = TextEditingController();
    final descriptionController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [kMoodCardCreamA, kMoodCardCreamB],
              ),
              borderRadius: BorderRadius.circular(_kCalNeoRadius),
              border: Border.all(color: Colors.black, width: 2),
              boxShadow: _calendarNeoShadows(),
            ),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Add event',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatDialogDate(date),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.black.withValues(alpha: 0.45),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _calendarDialogTextField(
                    controller: titleController,
                    label: 'Event title',
                    hint: 'What’s happening?',
                  ),
                  _calendarDialogTextField(
                    controller: timeController,
                    label: 'Time',
                    hint: 'e.g. 9:00 AM — leave empty for all day',
                  ),
                  _calendarDialogTextField(
                    controller: descriptionController,
                    label: 'Description',
                    hint: 'Optional notes',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: Colors.black.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: _calendarNeoShadows(),
                        ),
                        child: Material(
                          color: kMoodMint,
                          borderRadius: BorderRadius.circular(12),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => Navigator.pop(dialogContext, true),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.black, width: 2),
                              ),
                              child: const Text(
                                'Add',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (result == true) {
      final title = titleController.text.trim();
      final time = timeController.text.trim();
      final description = descriptionController.text.trim();

      if (title.isNotEmpty) {
        try {
          await _eventService.addEvent(
            title: title,
            eventDate: date,
            time: time.isEmpty ? 'Any time' : time,
            description: description.isEmpty ? null : description,
          );

          if (!mounted) return;
          setState(() {
            final dateKey = _normalizeDate(date);
            _eventsByDate.putIfAbsent(dateKey, () => []);
          });
          _loadEventsForMonth(_currentMonth);

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event added successfully')),
          );
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add event: ${e.toString()}')),
          );
        }
      }
    }
  }

  String _formatMonthYear(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _weekdayLabel(int weekday) {
    const labels = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return labels[weekday - 1];
  }

  List<Widget> _buildEventList(DateTime date) {
    final key = _normalizeDate(date);
    final items = _eventsByDate[key] ?? [];
    if (items.isEmpty) {
      return [
        Text(
          'No events yet — tap a day or use + Add event',
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: Colors.black.withValues(alpha: 0.45),
            height: 1.35,
          ),
        ),
      ];
    }

    return items
        .map((event) => _buildEventCard(event.title, event.time, event.id))
        .toList();
  }

  Widget _buildEventCard(String title, String time, String? eventId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: _calendarNeoDecoration(const Color(0xFFF5F0FF)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEDE4FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.25),
              ),
            ),
            child: const Icon(
              Icons.event_note_rounded,
              color: Color(0xFF5B21B6),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
          if (eventId != null)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: Color(0xFFDC2626), size: 22),
              onPressed: () => _deleteEvent(eventId),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
        ],
      ),
    );
  }

  Future<void> _deleteEvent(String eventId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 360),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_kCalNeoRadius),
            border: Border.all(color: Colors.black, width: 2),
            boxShadow: _calendarNeoShadows(),
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Delete event?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'This removes it from your calendar. You can’t undo this.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                  color: Colors.black.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: Colors.black.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: _calendarNeoShadows(),
                    ),
                    child: Material(
                      color: const Color(0xFFFFE4E6),
                      borderRadius: BorderRadius.circular(12),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => Navigator.pop(dialogContext, true),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                          child: const Text(
                            'Delete',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFB91C1C),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      try {
        await _eventService.deleteEvent(eventId);
        if (!mounted) return;
        _loadEventsForMonth(_currentMonth);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event deleted successfully')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete event: ${e.toString()}')),
        );
      }
    }
  }

  Widget _buildCalendarCard() {
    final monthLabel = _formatMonthYear(_currentMonth);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 16),
      decoration: _calendarNeoDecoration(Colors.white),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded,
                    color: Color(0xFF115E59), size: 28),
                onPressed: () {
                  setState(() {
                    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
                  });
                  _loadMoodLogsForMonth(_currentMonth);
                  _loadEventsForMonth(_currentMonth);
                },
              ),
              Text(
                monthLabel,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                  letterSpacing: -0.2,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded,
                    color: Color(0xFF115E59), size: 28),
                onPressed: () {
                  setState(() {
                    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
                  });
                  _loadMoodLogsForMonth(_currentMonth);
                  _loadEventsForMonth(_currentMonth);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final d in ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'])
                Expanded(
                  child: Text(
                    d,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.black.withValues(alpha: 0.38),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildCalendarGrid(_currentMonth),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingEmpty = firstDay.weekday - 1; // Monday = 1
    final totalCells = ((leadingEmpty + daysInMonth) / 7).ceil() * 7;

    final selectedDay = _selectedDate.year == month.year && _selectedDate.month == month.month
        ? _selectedDate.day
        : 0;

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: totalCells,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        mainAxisExtent: 50,
      ),
      itemBuilder: (context, index) {
        if (index < leadingEmpty || index >= leadingEmpty + daysInMonth) {
          return const SizedBox.shrink();
        }

        final dayNumber = index - leadingEmpty + 1;

        final isSelected = dayNumber == selectedDay;
        final dateKey = _normalizeDate(DateTime(month.year, month.month, dayNumber));
        final moodLog = _moodLogsByDate[dateKey];
        final moodAsset = moodLog?['mood_image'] as String?;
        final hasEvent = _eventsByDate[dateKey]?.isNotEmpty == true;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDate = DateTime(month.year, month.month, dayNumber);
            });
            _addEventDialog(_selectedDate);
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFCCFBF1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: Colors.black, width: 2)
                  : Border.all(color: Colors.transparent, width: 2),
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$dayNumber',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, height: 1.0),
                    ),
                    if (moodAsset != null)
                      Image.asset(
                        moodAsset,
                        width: 18,
                        height: 18,
                        fit: BoxFit.contain,
                      )
                    else if (hasEvent)
                      const Icon(Icons.circle, size: 6, color: Color(0xFF0D9488)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDE9FE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEDE9FE),
        elevation: 0,
        leadingWidth: 56,
        leading: Center(
          child: PhysicalModel(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            elevation: 4,
            shadowColor: Colors.black38,
            child: GestureDetector(
              onTap: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  _goTo(context, const HomePage());
                }
              },
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 18),
              ),
            ),
          ),
        ),
        title: const Text(
          'Calendar',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCalendarCard(),
              const SizedBox(height: 22),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      '${_selectedDate.day} ${_weekdayLabel(_selectedDate.weekday)}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Mood',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.black.withValues(alpha: 0.4),
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_isLoadingMoods)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF0D9488),
                          ),
                        )
                      else
                        Builder(
                          builder: (context) {
                            final moodLog = _moodLogsByDate[_normalizeDate(_selectedDate)];
                            final moodAsset = moodLog?['mood_image'] as String?;
                            if (moodAsset == null || moodAsset.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F0FF),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.black.withValues(alpha: 0.12),
                                  ),
                                ),
                                child: Text(
                                  '—',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black.withValues(alpha: 0.35),
                                  ),
                                ),
                              );
                            }
                            return Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.black, width: 2),
                              ),
                              child: Image.asset(
                                moodAsset,
                                width: 22,
                                height: 22,
                                fit: BoxFit.contain,
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ..._buildEventList(_selectedDate),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black,
                      offset: Offset(3, 3),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () => _addEventDialog(_selectedDate),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5EEAD4),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: Colors.black, width: 2),
                    ),
                  ),
                  child: const Text(
                    '+ Add event',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.home_outlined,
                  color: Color(0xFF115E59), size: 28),
              onPressed: () => _goTo(context, const HomePage()),
            ),
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline_rounded,
                  color: Color(0xFF115E59), size: 28),
              onPressed: () => _goTo(context, const EmotionBoardScreen()),
            ),
            IconButton(
              icon: const Icon(Icons.lightbulb_outline_rounded,
                  color: Color(0xFF115E59), size: 28),
              onPressed: () => _goTo(context, const RecoveryTipsScreen()),
            ),
            IconButton(
              icon: const Icon(Icons.person_outline_rounded,
                  color: Color(0xFF115E59), size: 28),
              onPressed: () => _goTo(context, const ProfileScreen()),
            ),
          ],
        ),
      ),
    );
  }
}
