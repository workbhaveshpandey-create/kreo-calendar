import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_config.dart';
import '../../../../shared/services/ai_service.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/data/holiday_data.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/calendar_bloc.dart';
import '../bloc/calendar_event.dart';
import '../bloc/calendar_state.dart';
import '../../domain/event_model.dart';
import '../widgets/event_editor_sheet.dart';
import '../../../settings/presentation/views/settings_screen.dart';

/// Premium Calendar Home Screen
/// Dark navy design with hexagonal date highlights
class CalendarHomeScreen extends StatefulWidget {
  const CalendarHomeScreen({super.key});

  @override
  State<CalendarHomeScreen> createState() => _CalendarHomeScreenState();
}

class _CalendarHomeScreenState extends State<CalendarHomeScreen> {
  late DateTime _focusedMonth;
  late DateTime _selectedDate;
  late PageController _pageController;

  // ... (Keep existing Loading and Error states)

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'KREO',
                style: AppTextStyles.headlineMedium(
                  color: Theme.of(context).colorScheme.onSurface,
                ).copyWith(fontWeight: FontWeight.bold, letterSpacing: 2),
              ),
              Text(
                DateFormat('MMM d').format(DateTime.now()).toUpperCase(),
                style: AppTextStyles.bodyMedium(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ).copyWith(letterSpacing: 2),
              ),
            ],
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            icon: Icon(
              Icons.grid_view,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  // ... (Keep Calendar Grid and Days Grid logic)

  // ... (Keep Upcoming Events logic)

  // Navigation methods removed as per request to use only FAB

  // Voice Input State
  final SpeechToText _speechToText = SpeechToText();
  final _aiService = AIService();
  bool _speechEnabled = false;
  bool _isListening = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime.now();
    _selectedDate = DateTime.now();
    _pageController = PageController(initialPage: 500);
    _loadCalendar();
    _initSpeech();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _loadCalendar() {
    // Data is now pre-loaded in App's AuthWrapper
    // Only refresh if explicitly needed or check if not loaded
    final state = context.read<CalendarBloc>().state;
    if (state is CalendarInitial) {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        context.read<CalendarBloc>().add(
          CalendarLoadRequested(authState.user.uid),
        );
      }
    }
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    if (mounted) setState(() {});
  }

  // ... (Keep dispose and loadCalendar)

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Calculate available height for calendar
            final screenHeight = constraints.maxHeight;
            final calendarMinHeight =
                screenHeight * 0.55; // Minimum 55% for calendar

            return Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 10),

                // Calendar Grid - Takes priority
                SizedBox(
                  height: calendarMinHeight,
                  child: BlocBuilder<CalendarBloc, CalendarState>(
                    builder: (context, state) {
                      return state is CalendarLoaded
                          ? _buildCalendarGrid(state)
                          : _buildLoadingState();
                    },
                  ),
                ),

                // Upcoming Events - Flexible remaining space
                Expanded(
                  child: BlocBuilder<CalendarBloc, CalendarState>(
                    builder: (context, state) {
                      if (state is CalendarLoaded) {
                        return _buildUpcomingEvents(state);
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),

      // Bottom Dock
      bottomNavigationBar: Container(
        color: theme.colorScheme.surface,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.grid_view,
                    color: theme.colorScheme.onSurface,
                  ),
                ),

                // Mic Button
                GestureDetector(
                  onTap: _toggleListening,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface, // Invert for contrast
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.mic_none_rounded,
                      color: theme.colorScheme.surface,
                      size: 28,
                    ),
                  ),
                ),

                IconButton(
                  onPressed: () => _showEventEditor(),
                  icon: Icon(Icons.add, color: theme.colorScheme.onSurface),
                ),
              ],
            ),
          ),
        ),
      ),

      // Full Screen Voice HUD Overlay
      bottomSheet: _isListening || _isProcessing
          ? _buildMinimalVoiceHUD()
          : null,
    );
  }

  Widget _buildMinimalVoiceHUD() {
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height,
      color: theme.scaffoldBackgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Minimal Pulse
            Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.onSurface,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    _isProcessing ? Icons.hourglass_empty : Icons.graphic_eq,
                    color: theme.colorScheme.onSurface,
                    size: 30,
                  ),
                )
                .animate(onPlay: (c) => c.repeat())
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.5, 1.5),
                  duration: 1.5.seconds,
                )
                .fadeOut(curve: Curves.easeIn),

            const SizedBox(height: 40),

            Text(
              _isProcessing ? 'PROCESSING' : 'LISTENING',
              style: AppTextStyles.headlineSmall(
                color: theme.colorScheme.onSurface,
              ).copyWith(letterSpacing: 4),
            ),

            const SizedBox(height: 20),
            TextButton(
              onPressed: _toggleListening,
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.onSurfaceVariant,
              ),
              child: const Text('CANCEL'),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleListening() async {
    if (_isListening) {
      await _speechToText.stop();
      if (mounted) setState(() => _isListening = false);
    } else {
      if (!_speechEnabled) {
        _initSpeech();
        return;
      }

      setState(() => _isListening = true);

      await _speechToText.listen(
        onResult: (result) {
          if (result.finalResult) {
            _handleVoiceCommand(result.recognizedWords);
          }
        },
      );
    }
  }

  Future<void> _handleVoiceCommand(String text) async {
    setState(() {
      _isListening = false;
      _isProcessing = true;
    });

    try {
      final parsedEvent = await _aiService.parseEventFromText(text);

      if (!mounted) return;

      if (parsedEvent != null) {
        final authState = context.read<AuthBloc>().state;
        final calendarState = context.read<CalendarBloc>().state;

        if (authState is AuthAuthenticated && calendarState is CalendarLoaded) {
          final event = EventModel(
            id: const Uuid().v4(),
            calendarId: calendarState.defaultCalendar?.id ?? 'default',
            userId: authState.user.uid,
            title: parsedEvent.title,
            description: parsedEvent.description,
            startTime: parsedEvent.startTime ?? parsedEvent.date,
            endTime:
                parsedEvent.endTime ??
                parsedEvent.date.add(const Duration(hours: 1)),
            isAllDay: parsedEvent.isAllDay,
            location: parsedEvent.location,
            color: AppColors.eventColors[0],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          context.read<CalendarBloc>().add(CalendarEventCreated(event));

          _showMinimalToast('CREATED: ${event.title.toUpperCase()}');
        }
      }
    } catch (e) {
      if (mounted) {
        _showMinimalToast('ERROR: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showMinimalToast(String message, {bool isError = false}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Invert colors for high contrast toast
    final bgColor = isError
        ? AppColors.minimalError
        : (isDark ? Colors.white : Colors.black);
    final tColor = isDark || isError ? Colors.black : Colors.white;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.all(24),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: bgColor,
            // Sharp corners for minimalist look
            borderRadius: BorderRadius.zero,
            border: Border.all(
              color: isError
                  ? Colors.transparent
                  : theme.colorScheme.onSurface.withValues(alpha: 0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                color: tColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: AppTextStyles.labelLarge(
                    color: tColor,
                  ).copyWith(letterSpacing: 1.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ... (Keep existing methods)

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: ClipOval(
              child: Image.asset(
                'assets/images/kreo_logo.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(CalendarLoaded state) {
    return Column(
      children: [
        // Month Navigation
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => _changeMonth(-1),
                icon: Icon(
                  Icons.chevron_left_rounded,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                DateFormat('MMMM').format(_focusedMonth).toUpperCase(),
                style: AppTextStyles.calendarMonth(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              IconButton(
                onPressed: () => _changeMonth(1),
                icon: Icon(
                  Icons.chevron_right_rounded,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        // Weekday Headers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: AppTextStyles.calendarWeekday(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 8),

        // Calendar Days Grid
        Expanded(
          child: GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity! > 0) {
                _changeMonth(-1); // Swipe Right -> Prev Month
              } else if (details.primaryVelocity! < 0) {
                _changeMonth(1); // Swipe Left -> Next Month
              }
            },
            child: _buildDaysGrid(state),
          ),
        ),
      ],
    );
  }

  Widget _buildDaysGrid(CalendarLoaded state) {
    final firstDayOfMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month,
      1,
    );
    final lastDayOfMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
      0,
    );
    final firstWeekday = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;

    // Previous month days
    final prevMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    final daysInPrevMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month,
      0,
    ).day;

    final today = DateTime.now();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 1.0,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
        ),
        itemCount: 42,
        itemBuilder: (context, index) {
          int day;
          DateTime date;
          bool isCurrentMonth = true;

          if (index < firstWeekday - 1) {
            // Previous month
            day = daysInPrevMonth - (firstWeekday - 2 - index);
            date = DateTime(prevMonth.year, prevMonth.month, day);
            isCurrentMonth = false;
          } else if (index >= firstWeekday - 1 + daysInMonth) {
            // Next month
            day = index - (firstWeekday - 1 + daysInMonth) + 1;
            date = DateTime(_focusedMonth.year, _focusedMonth.month + 1, day);
            isCurrentMonth = false;
          } else {
            // Current month
            day = index - firstWeekday + 2;
            date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
          }

          final isToday =
              date.year == today.year &&
              date.month == today.month &&
              date.day == today.day;
          final isSelected =
              date.year == _selectedDate.year &&
              date.month == _selectedDate.month &&
              date.day == _selectedDate.day;
          final hasEvents = state.eventsForDate(date).isNotEmpty;
          final holiday = HolidayData.getHoliday(date);

          return _buildDayCell(
            day: day,
            date: date,
            isCurrentMonth: isCurrentMonth,
            isToday: isToday,
            isSelected: isSelected,
            hasEvents: hasEvents,
            holiday: holiday,
            state: state,
          );
        },
      ),
    );
  }

  Widget _buildDayCell({
    required int day,
    required DateTime date,
    required bool isCurrentMonth,
    required bool isToday,
    required bool isSelected,
    required bool hasEvents,
    required String? holiday,
    required CalendarLoaded state,
  }) {
    if (!isCurrentMonth) return const SizedBox.shrink();

    final theme = Theme.of(context);
    Color textColor;
    Color? bgColor;
    BoxBorder? border;

    if (isSelected) {
      // Selected day: Inverse colors
      bgColor = theme.colorScheme.onSurface;
      textColor = theme.colorScheme.surface;
    } else if (isToday) {
      // Today: Border and primary text color
      border = Border.all(color: theme.colorScheme.onSurface, width: 1);
      textColor = theme.colorScheme.onSurface;
    } else if (holiday != null) {
      textColor = AppColors.minimalError;
    } else {
      // Normal day: Muted text color
      textColor = theme.colorScheme.onSurface.withOpacity(0.6);
    }

    return GestureDetector(
      onTap: () {
        setState(() => _selectedDate = date);
        context.read<CalendarBloc>().add(CalendarDateSelected(date));
      },
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: bgColor,
          border: border,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                day.toString(),
                style: AppTextStyles.bodyMedium(color: textColor).copyWith(
                  fontWeight: isSelected || isToday
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              if (hasEvents && !isSelected)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingEvents(CalendarLoaded state) {
    final selectedEvents = _getEventsForSelectedDate(state);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    // Determine header based on selected date
    String headerText;
    if (selectedDay.isAtSameMomentAs(today)) {
      headerText = 'TODAY';
    } else if (selectedDay.isBefore(today)) {
      headerText = DateFormat('MMM d').format(_selectedDate).toUpperCase();
    } else {
      headerText = 'UPCOMING';
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.black : theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.08)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  headerText,
                  style: AppTextStyles.labelMedium(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                  ).copyWith(letterSpacing: 3, fontWeight: FontWeight.w600),
                ),
                GestureDetector(
                  onTap: () => _showEventEditor(),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: theme.colorScheme.onSurface.withOpacity(0.12),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.add,
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(
                        0.6,
                      ),
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: selectedEvents.isEmpty
                ? _buildNoEvents()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                    itemCount: selectedEvents.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final event = selectedEvents[index];
                      return Dismissible(
                        key: Key(event.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          decoration: BoxDecoration(
                            color: AppColors.minimalError.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'DELETE',
                                style: AppTextStyles.labelMedium(
                                  color: AppColors.minimalError,
                                ).copyWith(letterSpacing: 1),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.delete_outline,
                                color: AppColors.minimalError,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                        confirmDismiss: (direction) async {
                          // Show confirmation
                          return await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: const Color(0xFF1A1A1A),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  title: Text(
                                    'DELETE EVENT?',
                                    style: AppTextStyles.titleMedium(
                                      color: Colors.white,
                                    ).copyWith(letterSpacing: 1),
                                  ),
                                  content: Text(
                                    'Are you sure you want to delete "${event.title}"?',
                                    style: AppTextStyles.bodyMedium(
                                      color: Colors.white70,
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: Text(
                                        'CANCEL',
                                        style: AppTextStyles.labelMedium(
                                          color: Colors.white54,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: Text(
                                        'DELETE',
                                        style: AppTextStyles.labelMedium(
                                          color: AppColors.minimalError,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ) ??
                              false;
                        },
                        onDismissed: (direction) {
                          context.read<CalendarBloc>().add(
                            CalendarEventDeleted(event.id),
                          );
                          _showMinimalToast(
                            'DELETED: ${event.title.toUpperCase()}',
                          );
                        },
                        child: _buildPremiumEventCard(event),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoEvents() {
    return Center(
      child: Text(
        'NO EVENTS',
        style: AppTextStyles.bodyMedium(
          color: Theme.of(
            context,
          ).colorScheme.onSurfaceVariant.withOpacity(0.4),
        ).copyWith(letterSpacing: 2),
      ),
    );
  }

  Widget _buildPremiumEventCard(EventModel event) {
    final isAllDay = event.isAllDay;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => _showEventEditor(event: event),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.onSurface.withOpacity(0.06),
              theme.colorScheme.onSurface.withOpacity(0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.onSurface.withOpacity(0.08),
          ),
        ),
        child: Row(
          children: [
            // Time/Date Column
            Container(
              width: 56,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: event.color.withOpacity(0.5),
                    width: 2,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAllDay
                        ? 'ALL'
                        : DateFormat('HH:mm').format(event.startTime),
                    style: AppTextStyles.titleMedium(
                      color: theme.colorScheme.onSurface,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isAllDay
                        ? 'DAY'
                        : DateFormat(
                            'MMM d',
                          ).format(event.startTime).toUpperCase(),
                    style: AppTextStyles.labelSmall(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ).copyWith(letterSpacing: 1),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Event Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: AppTextStyles.titleSmall(
                      color: theme.colorScheme.onSurface,
                    ).copyWith(fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (event.location != null && event.location!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.location!,
                            style: AppTextStyles.labelSmall(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.6,
                              ),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Arrow indicator
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurface.withOpacity(0.24),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  /// Gets events for the currently selected date (works for past, present, and future)
  List<EventModel> _getEventsForSelectedDate(CalendarLoaded state) {
    final selectedDay = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // If selected date is today or future, show upcoming events
    if (selectedDay.isAtSameMomentAs(today) || selectedDay.isAfter(today)) {
      return _getUpcomingEvents(state);
    }

    // For past dates, show events on that specific day
    final seenIds = <String>{};
    final events = state.events.where((e) {
      if (seenIds.contains(e.id)) return false;

      final eventDay = DateTime(
        e.startTime.year,
        e.startTime.month,
        e.startTime.day,
      );
      if (eventDay.isAtSameMomentAs(selectedDay)) {
        seenIds.add(e.id);
        return true;
      }
      return false;
    }).toList();

    events.sort((a, b) => a.startTime.compareTo(b.startTime));
    return events;
  }

  List<EventModel> _getUpcomingEvents(CalendarLoaded state) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final seenIds = <String>{};
    final events = state.events.where((e) {
      // Deduplicate by ID
      if (seenIds.contains(e.id)) return false;

      final eventDay = DateTime(
        e.startTime.year,
        e.startTime.month,
        e.startTime.day,
      );

      if (e.isAllDay) {
        // Include all-day events for today and future
        if (eventDay.isAtSameMomentAs(today) || eventDay.isAfter(today)) {
          seenIds.add(e.id);
          return true;
        }
        return false;
      }

      // Include all events from today (even if time has passed) and future events
      if (eventDay.isAtSameMomentAs(today) || eventDay.isAfter(today)) {
        seenIds.add(e.id);
        return true;
      }
      return false;
    }).toList();

    events.sort((a, b) => a.startTime.compareTo(b.startTime));
    return events.take(10).toList();
  }

  void _changeMonth(int delta) {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + delta);
    });
  }

  void _showEventEditor({EventModel? event}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => Scaffold(
          // Ensure it has a dark/light background based on theme
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: EventEditorSheet(event: event),
        ),
      ),
    );
  }
}
