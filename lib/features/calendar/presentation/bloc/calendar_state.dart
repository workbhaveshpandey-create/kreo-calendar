import 'package:equatable/equatable.dart';

import '../../domain/calendar_model.dart';
import '../../domain/event_model.dart';

/// Calendar View Type
enum CalendarViewType { day, week, month, year }

/// Calendar States
abstract class CalendarState extends Equatable {
  const CalendarState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class CalendarInitial extends CalendarState {
  const CalendarInitial();
}

/// Loading calendars and events
class CalendarLoading extends CalendarState {
  const CalendarLoading();
}

/// Calendars and events loaded successfully
class CalendarLoaded extends CalendarState {
  final List<CalendarModel> calendars;
  final List<EventModel> events;
  final DateTime selectedDate;
  final DateTime focusedDate;
  final CalendarViewType viewType;
  final CalendarModel? selectedCalendar;
  final DateTime lastUpdated; // Forces state change detection

  CalendarLoaded({
    required this.calendars,
    required this.events,
    required this.selectedDate,
    required this.focusedDate,
    this.viewType = CalendarViewType.month,
    this.selectedCalendar,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  /// Get events for a specific date
  List<EventModel> eventsForDate(DateTime date) {
    return events.where((event) => event.occursOnDate(date)).toList();
  }

  /// Get events for selected date
  List<EventModel> get selectedDateEvents => eventsForDate(selectedDate);

  /// Get default calendar
  CalendarModel? get defaultCalendar =>
      calendars.where((c) => c.isDefault).firstOrNull ?? calendars.firstOrNull;

  CalendarLoaded copyWith({
    List<CalendarModel>? calendars,
    List<EventModel>? events,
    DateTime? selectedDate,
    DateTime? focusedDate,
    CalendarViewType? viewType,
    CalendarModel? selectedCalendar,
  }) {
    return CalendarLoaded(
      calendars: calendars ?? this.calendars,
      events: events ?? this.events,
      selectedDate: selectedDate ?? this.selectedDate,
      focusedDate: focusedDate ?? this.focusedDate,
      viewType: viewType ?? this.viewType,
      selectedCalendar: selectedCalendar ?? this.selectedCalendar,
      lastUpdated: DateTime.now(), // Always update timestamp
    );
  }

  @override
  List<Object?> get props => [
    calendars,
    events,
    selectedDate,
    focusedDate,
    viewType,
    selectedCalendar,
    lastUpdated,
  ];
}

/// Error state
class CalendarError extends CalendarState {
  final String message;

  const CalendarError(this.message);

  @override
  List<Object?> get props => [message];
}
