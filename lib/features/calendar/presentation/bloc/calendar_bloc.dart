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
    on<CalendarEventsUpdatedFromStream>(_onEventsUpdatedFromStream);
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
      final now = DateTime.now();

      // Pre-load events to prevent "pop-in"
      // We get the stream, take the first element (initial data), and await it.
      final eventStream = _calendarRepository.getEventsForMonthStream(
        userId: event.userId,
        year: now.year,
        month: now.month,
      );

      final initialEvents = await eventStream.first;

      emit(
        CalendarLoaded(
          calendars: calendars,
          events: initialEvents,
          selectedDate: now,
          focusedDate: now,
        ),
      );

      // Set up real-time sync for calendars
      _setupRealtimeSync(event.userId);

      // Subscribe to events for continuous updates
      // We re-subscribe to the stream for future updates
      _eventsSubscription = eventStream.listen((events) {
        add(CalendarEventsUpdatedFromStream(events));
      });
    } catch (e) {
      print('DEBUG: Error loading calendar: $e');
      emit(CalendarError('Failed to load calendar: ${e.toString()}'));
    }
  }

  /// Set up real-time synchronization
  void _setupRealtimeSync(String userId) {
    // Listen to calendars changes
    _calendarsSubscription = _calendarRepository
        .getCalendarsStream(userId)
        .listen((calendars) {
          // Use add to trigger refresh instead of direct emit
          add(const CalendarRefreshRequested());
        });
  }

  /// Subscribe to events for a specific month
  void _subscribeToMonthEvents(String userId, DateTime focusedDate) {
    _eventsSubscription?.cancel();
    _eventsSubscription = _calendarRepository
        .getEventsForMonthStream(
          userId: userId,
          year: focusedDate.year,
          month: focusedDate.month,
        )
        .listen((events) {
          add(CalendarEventsUpdatedFromStream(events));
        });
  }

  /// Handle stream update
  void _onEventsUpdatedFromStream(
    CalendarEventsUpdatedFromStream event,
    Emitter<CalendarState> emit,
  ) {
    final currentState = state;
    if (currentState is CalendarLoaded) {
      emit(currentState.copyWith(events: event.events));
    }
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
      // Update focused date
      emit(currentState.copyWith(focusedDate: event.focusedDate));

      // Update subscription to new month
      _subscribeToMonthEvents(_currentUserId!, event.focusedDate);
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
        // Stream will handle the update automatically via Firestore latency compensation
      } catch (e) {
        print('DEBUG: Error creating event: $e');
        // Do not emit error state to prevent UI flickers/wipes
        // emit(CalendarError('Failed to create event: ${e.toString()}'));
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
        // Stream will handle the update
      } catch (e) {
        print('DEBUG: Error updating event: $e');
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

        // Stream will handle the update
      } catch (e) {
        print('DEBUG: Error deleting event: $e');
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

        await _calendarRepository.createCalendar(newCalendar);
        // Stream will handle the update
      } catch (e) {
        print('DEBUG: Error creating calendar: $e');
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
        // Stream will handle the update
      } catch (e) {
        print('DEBUG: Error updating calendar: $e');
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
        // Stream will handle the update
      } catch (e) {
        print('DEBUG: Error deleting calendar: $e');
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
    final currentState = state; // Keep this one
    if (currentState is CalendarLoaded && _currentUserId != null) {
      // Re-subscribe to ensure connection is alive
      _subscribeToMonthEvents(_currentUserId!, currentState.focusedDate);

      // Also refresh calendars
      try {
        final calendars = await _calendarRepository.getCalendars(
          _currentUserId!,
        );
        emit(currentState.copyWith(calendars: calendars));
      } catch (_) {}
    }
  }
}
