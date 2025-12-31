import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../domain/calendar_model.dart';
import '../../domain/event_model.dart';
import 'calendar_state.dart';

/// Calendar Events
abstract class CalendarEvent extends Equatable {
  const CalendarEvent();

  @override
  List<Object?> get props => [];
}

/// Load calendars and events for user
class CalendarLoadRequested extends CalendarEvent {
  final String userId;

  const CalendarLoadRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Date selected on calendar
class CalendarDateSelected extends CalendarEvent {
  final DateTime date;

  const CalendarDateSelected(this.date);

  @override
  List<Object?> get props => [date];
}

/// Page changed (month/week navigation)
class CalendarPageChanged extends CalendarEvent {
  final DateTime focusedDate;

  const CalendarPageChanged(this.focusedDate);

  @override
  List<Object?> get props => [focusedDate];
}

/// View type changed
class CalendarViewChanged extends CalendarEvent {
  final CalendarViewType viewType;

  const CalendarViewChanged(this.viewType);

  @override
  List<Object?> get props => [viewType];
}

/// Navigate to today
class CalendarTodayRequested extends CalendarEvent {
  const CalendarTodayRequested();
}

/// Create new event
class CalendarEventCreated extends CalendarEvent {
  final EventModel event;

  const CalendarEventCreated(this.event);

  @override
  List<Object?> get props => [event];
}

/// Update existing event
class CalendarEventUpdated extends CalendarEvent {
  final EventModel event;

  const CalendarEventUpdated(this.event);

  @override
  List<Object?> get props => [event];
}

/// Delete event
class CalendarEventDeleted extends CalendarEvent {
  final String eventId;

  const CalendarEventDeleted(this.eventId);

  @override
  List<Object?> get props => [eventId];
}

/// Create new calendar
class CalendarCreated extends CalendarEvent {
  final String name;
  final Color color;

  const CalendarCreated({required this.name, required this.color});

  @override
  List<Object?> get props => [name, color];
}

/// Update calendar
class CalendarUpdated extends CalendarEvent {
  final CalendarModel calendar;

  const CalendarUpdated(this.calendar);

  @override
  List<Object?> get props => [calendar];
}

/// Delete calendar
class CalendarDeleted extends CalendarEvent {
  final String calendarId;

  const CalendarDeleted(this.calendarId);

  @override
  List<Object?> get props => [calendarId];
}

/// Select a calendar for filtering
class CalendarFilterSelected extends CalendarEvent {
  final CalendarModel? calendar;

  const CalendarFilterSelected(this.calendar);

  @override
  List<Object?> get props => [calendar];
}

/// Refresh events (pull-to-refresh)
class CalendarRefreshRequested extends CalendarEvent {
  const CalendarRefreshRequested();
}

/// Events updated from real-time stream
class CalendarEventsUpdatedFromStream extends CalendarEvent {
  final List<EventModel> events;

  const CalendarEventsUpdatedFromStream(this.events);

  @override
  List<Object?> get props => [events];
}
