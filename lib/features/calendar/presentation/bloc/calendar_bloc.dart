import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../data/calendar_repository.dart';
import '../../domain/calendar_model.dart';
import '../../../../shared/services/notification_service.dart';
import 'calendar_event.dart';
import 'calendar_state.dart';

/// Calendar BLoC
/// Manages calendar and event state with real-time Firestore sync
class CalendarBloc extends Bloc<CalendarEvent, CalendarState> {
  final CalendarRepository _calendarRepository;
  final Uuid _uuid = const Uuid();

  String? _currentUserId;
  StreamSubscription? _eventsSubscription;
  StreamSubscription? _calendarsSubscription;

  CalendarBloc({required CalendarRepository calendarRepository})
    : _calendarRepository = calendarRepository,
      super(const CalendarInitial()) {
    on<CalendarLoadRequested>(_onLoadRequested);
    on<CalendarDateSelected>(_onDateSelected);
    on<CalendarPageChanged>(_onPageChanged);
    on<CalendarViewChanged>(_onViewChanged);
    on<CalendarTodayRequested>(_onTodayRequested);
    on<CalendarEventCreated>(_onEventCreated);
    on<CalendarEventUpdated>(_onEventUpdated);
    on<CalendarEventDeleted>(_onEventDeleted);
    on<CalendarCreated>(_onCalendarCreated);
    on<CalendarUpdated>(_onCalendarUpdated);
    on<CalendarDeleted>(_onCalendarDeleted);
    on<CalendarFilterSelected>(_onFilterSelected);
    on<CalendarRefreshRequested>(_onRefreshRequested);
  }

  @override
  Future<void> close() {
    _eventsSubscription?.cancel();
    _calendarsSubscription?.cancel();
    return super.close();
  }

  /// Load calendars and events for user
  Future<void> _onLoadRequested(
    CalendarLoadRequested event,
    Emitter<CalendarState> emit,
  ) async {
    emit(const CalendarLoading());
    _currentUserId = event.userId;

    try {
      // Cancel existing subscriptions
      await _eventsSubscription?.cancel();
      await _calendarsSubscription?.cancel();

      // Get initial data
      final calendars = await _calendarRepository.getCalendars(event.userId);

      // Get current month events
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      final events = await _calendarRepository.getEventsInRange(
        userId: event.userId,
        start: startOfMonth,
        end: endOfMonth,
      );

      emit(
        CalendarLoaded(
          calendars: calendars,
          events: events,
          selectedDate: now,
          focusedDate: now,
        ),
      );

      // Set up real-time sync
      _setupRealtimeSync(event.userId);
    } catch (e) {
      emit(CalendarError('Failed to load calendar: ${e.toString()}'));
    }
  }

  /// Set up real-time synchronization
  void _setupRealtimeSync(String userId) {
    // Listen to events changes
    _eventsSubscription = _calendarRepository.getEventsStream(userId).listen((
      events,
    ) {
      final currentState = state;
      if (currentState is CalendarLoaded) {
        add(CalendarRefreshRequested());
      }
    });

    // Listen to calendars changes
    _calendarsSubscription = _calendarRepository
        .getCalendarsStream(userId)
        .listen((calendars) {
          // Use add to trigger refresh instead of direct emit
          add(const CalendarRefreshRequested());
        });
  }

  /// Handle date selection
  void _onDateSelected(
    CalendarDateSelected event,
    Emitter<CalendarState> emit,
  ) {
    final currentState = state;
    if (currentState is CalendarLoaded) {
      emit(currentState.copyWith(selectedDate: event.date));
    }
  }

  /// Handle page change (month navigation)
  Future<void> _onPageChanged(
    CalendarPageChanged event,
    Emitter<CalendarState> emit,
  ) async {
    final currentState = state;
    if (currentState is CalendarLoaded && _currentUserId != null) {
      // Load events for new month
      final startOfMonth = DateTime(
        event.focusedDate.year,
        event.focusedDate.month,
        1,
      );
      final endOfMonth = DateTime(
        event.focusedDate.year,
        event.focusedDate.month + 1,
        0,
        23,
        59,
        59,
      );

      final events = await _calendarRepository.getEventsInRange(
        userId: _currentUserId!,
        start: startOfMonth,
        end: endOfMonth,
      );

      emit(
        currentState.copyWith(focusedDate: event.focusedDate, events: events),
      );
    }
  }

  /// Handle view type change
  void _onViewChanged(CalendarViewChanged event, Emitter<CalendarState> emit) {
    final currentState = state;
    if (currentState is CalendarLoaded) {
      emit(currentState.copyWith(viewType: event.viewType));
    }
  }

  /// Navigate to today
  void _onTodayRequested(
    CalendarTodayRequested event,
    Emitter<CalendarState> emit,
  ) {
    final currentState = state;
    if (currentState is CalendarLoaded) {
      final today = DateTime.now();
      emit(currentState.copyWith(selectedDate: today, focusedDate: today));
      add(CalendarPageChanged(today));
    }
  }

  /// Create new event
  Future<void> _onEventCreated(
    CalendarEventCreated event,
    Emitter<CalendarState> emit,
  ) async {
    print('DEBUG: _onEventCreated called for event: ${event.event.title}');
    final currentState = state;
    if (currentState is CalendarLoaded && _currentUserId != null) {
      try {
        print('DEBUG: Calling _calendarRepository.createEvent...');
        final newEvent = await _calendarRepository.createEvent(event.event);
        print('DEBUG: Event created successfully with id: ${newEvent.id}');

        // Schedule notification reminder (5 min before)
        if (!newEvent.isAllDay) {
          final notificationService = NotificationService();
          await notificationService.scheduleEventReminder(
            eventId: newEvent.id,
            eventTitle: newEvent.title,
            eventStartTime: newEvent.startTime,
            eventLocation: newEvent.location,
          );
        }

        // Add to current events list
        final updatedEvents = [...currentState.events, newEvent];
        print(
          'DEBUG: Emitting updated state with ${updatedEvents.length} events',
        );
        emit(currentState.copyWith(events: updatedEvents));
      } catch (e) {
        print('DEBUG: Error creating event: $e');
        emit(CalendarError('Failed to create event: ${e.toString()}'));
        emit(currentState);
      }
    } else {
      print(
        'DEBUG: Cannot create event - state: $currentState, userId: $_currentUserId',
      );
    }
  }

  /// Update existing event
  Future<void> _onEventUpdated(
    CalendarEventUpdated event,
    Emitter<CalendarState> emit,
  ) async {
    final currentState = state;
    if (currentState is CalendarLoaded) {
      try {
        await _calendarRepository.updateEvent(event.event);

        // Update in current events list
        final updatedEvents = currentState.events.map((e) {
          return e.id == event.event.id ? event.event : e;
        }).toList();
        emit(currentState.copyWith(events: updatedEvents));
      } catch (e) {
        emit(CalendarError('Failed to update event: ${e.toString()}'));
        emit(currentState);
      }
    }
  }

  /// Delete event
  Future<void> _onEventDeleted(
    CalendarEventDeleted event,
    Emitter<CalendarState> emit,
  ) async {
    final currentState = state;
    if (currentState is CalendarLoaded) {
      try {
        await _calendarRepository.deleteEvent(event.eventId);

        // Cancel scheduled notification
        final notificationService = NotificationService();
        await notificationService.cancelEventReminder(event.eventId);

        // Remove from current events list
        final updatedEvents = currentState.events
            .where((e) => e.id != event.eventId)
            .toList();
        emit(currentState.copyWith(events: updatedEvents));
      } catch (e) {
        emit(CalendarError('Failed to delete event: ${e.toString()}'));
        emit(currentState);
      }
    }
  }

  /// Create new calendar
  Future<void> _onCalendarCreated(
    CalendarCreated event,
    Emitter<CalendarState> emit,
  ) async {
    final currentState = state;
    if (currentState is CalendarLoaded && _currentUserId != null) {
      try {
        final now = DateTime.now();
        final newCalendar = CalendarModel(
          id: _uuid.v4(),
          userId: _currentUserId!,
          name: event.name,
          color: event.color,
          createdAt: now,
          updatedAt: now,
        );

        final created = await _calendarRepository.createCalendar(newCalendar);

        // Add to current calendars list
        final updatedCalendars = [...currentState.calendars, created];
        emit(currentState.copyWith(calendars: updatedCalendars));
      } catch (e) {
        emit(CalendarError('Failed to create calendar: ${e.toString()}'));
        emit(currentState);
      }
    }
  }

  /// Update calendar
  Future<void> _onCalendarUpdated(
    CalendarUpdated event,
    Emitter<CalendarState> emit,
  ) async {
    final currentState = state;
    if (currentState is CalendarLoaded) {
      try {
        await _calendarRepository.updateCalendar(event.calendar);

        // Update in current calendars list
        final updatedCalendars = currentState.calendars.map((c) {
          return c.id == event.calendar.id ? event.calendar : c;
        }).toList();
        emit(currentState.copyWith(calendars: updatedCalendars));
      } catch (e) {
        emit(CalendarError('Failed to update calendar: ${e.toString()}'));
        emit(currentState);
      }
    }
  }

  /// Delete calendar
  Future<void> _onCalendarDeleted(
    CalendarDeleted event,
    Emitter<CalendarState> emit,
  ) async {
    final currentState = state;
    if (currentState is CalendarLoaded) {
      try {
        await _calendarRepository.deleteCalendar(event.calendarId);

        // Remove from current calendars list and related events
        final updatedCalendars = currentState.calendars
            .where((c) => c.id != event.calendarId)
            .toList();
        final updatedEvents = currentState.events
            .where((e) => e.calendarId != event.calendarId)
            .toList();

        emit(
          currentState.copyWith(
            calendars: updatedCalendars,
            events: updatedEvents,
          ),
        );
      } catch (e) {
        emit(CalendarError('Failed to delete calendar: ${e.toString()}'));
        emit(currentState);
      }
    }
  }

  /// Handle calendar filter selection
  void _onFilterSelected(
    CalendarFilterSelected event,
    Emitter<CalendarState> emit,
  ) {
    final currentState = state;
    if (currentState is CalendarLoaded) {
      emit(currentState.copyWith(selectedCalendar: event.calendar));
    }
  }

  /// Refresh events
  Future<void> _onRefreshRequested(
    CalendarRefreshRequested event,
    Emitter<CalendarState> emit,
  ) async {
    final currentState = state;
    if (currentState is CalendarLoaded && _currentUserId != null) {
      try {
        final startOfMonth = DateTime(
          currentState.focusedDate.year,
          currentState.focusedDate.month,
          1,
        );
        final endOfMonth = DateTime(
          currentState.focusedDate.year,
          currentState.focusedDate.month + 1,
          0,
          23,
          59,
          59,
        );

        final events = await _calendarRepository.getEventsInRange(
          userId: _currentUserId!,
          start: startOfMonth,
          end: endOfMonth,
        );

        emit(currentState.copyWith(events: events));
      } catch (e) {
        // Silently fail on refresh
      }
    }
  }
}
