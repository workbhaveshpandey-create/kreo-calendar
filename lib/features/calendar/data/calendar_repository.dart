import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/calendar_model.dart';
import '../domain/event_model.dart';

/// Calendar Repository
/// Handles all calendar and event CRUD operations with Firestore
/// Data is isolated per user - each user only sees their own calendars and events
class CalendarRepository {
  final FirebaseFirestore _firestore;

  CalendarRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // ==================== CALENDAR OPERATIONS ====================

  /// Get all calendars for a user (real-time stream)
  Stream<List<CalendarModel>> getCalendarsStream(String userId) {
    return _firestore
        .collection('calendars')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final calendars = snapshot.docs
              .map((doc) => CalendarModel.fromFirestore(doc))
              .toList();
          // Sort client-side to avoid needing composite index
          calendars.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return calendars;
        });
  }

  /// Get all calendars for a user (one-time fetch)
  Future<List<CalendarModel>> getCalendars(String userId) async {
    final snapshot = await _firestore
        .collection('calendars')
        .where('userId', isEqualTo: userId)
        .get();

    final calendars = snapshot.docs
        .map((doc) => CalendarModel.fromFirestore(doc))
        .toList();
    // Sort client-side to avoid needing composite index
    calendars.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return calendars;
  }

  /// Get a single calendar by ID
  Future<CalendarModel?> getCalendar(String calendarId) async {
    final doc = await _firestore.collection('calendars').doc(calendarId).get();
    if (!doc.exists) return null;
    return CalendarModel.fromFirestore(doc);
  }

  /// Create a new calendar
  Future<CalendarModel> createCalendar(CalendarModel calendar) async {
    final docRef = _firestore.collection('calendars').doc();
    final newCalendar = calendar.copyWith(
      id: docRef.id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await docRef.set(newCalendar.toFirestore());
    return newCalendar;
  }

  /// Update a calendar
  Future<void> updateCalendar(CalendarModel calendar) async {
    final updated = calendar.copyWith(updatedAt: DateTime.now());
    await _firestore
        .collection('calendars')
        .doc(calendar.id)
        .update(updated.toFirestore());
  }

  /// Delete a calendar and all its events
  Future<void> deleteCalendar(String calendarId) async {
    // Delete all events in the calendar
    final events = await _firestore
        .collection('events')
        .where('calendarId', isEqualTo: calendarId)
        .get();

    final batch = _firestore.batch();
    for (final event in events.docs) {
      batch.delete(event.reference);
    }
    batch.delete(_firestore.collection('calendars').doc(calendarId));
    await batch.commit();
  }

  // ==================== EVENT OPERATIONS ====================

  /// Get all events for a user (real-time stream)
  Stream<List<EventModel>> getEventsStream(String userId) {
    return _firestore
        .collection('events')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final events = snapshot.docs
              .map((doc) => EventModel.fromFirestore(doc))
              .toList();
          // Sort client-side to avoid needing composite index
          events.sort((a, b) => a.startTime.compareTo(b.startTime));
          return events;
        });
  }

  /// Get events for a specific date range
  Future<List<EventModel>> getEventsInRange({
    required String userId,
    required DateTime start,
    required DateTime end,
  }) async {
    // Fetch all user events and filter client-side to avoid composite index
    final snapshot = await _firestore
        .collection('events')
        .where('userId', isEqualTo: userId)
        .get();

    final events = snapshot.docs
        .map((doc) => EventModel.fromFirestore(doc))
        .where(
          (e) =>
              e.startTime.isAfter(start.subtract(const Duration(seconds: 1))) &&
              e.startTime.isBefore(end.add(const Duration(seconds: 1))),
        )
        .toList();
    events.sort((a, b) => a.startTime.compareTo(b.startTime));
    return events;
  }

  /// Get events for a specific date
  Future<List<EventModel>> getEventsForDate({
    required String userId,
    required DateTime date,
  }) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // Fetch all user events and filter client-side to avoid composite index
    final snapshot = await _firestore
        .collection('events')
        .where('userId', isEqualTo: userId)
        .get();

    final events = snapshot.docs
        .map((doc) => EventModel.fromFirestore(doc))
        .where(
          (e) =>
              e.startTime.isAfter(
                startOfDay.subtract(const Duration(seconds: 1)),
              ) &&
              e.startTime.isBefore(endOfDay),
        )
        .toList();
    events.sort((a, b) => a.startTime.compareTo(b.startTime));
    return events;
  }

  /// Get events for a specific month
  Stream<List<EventModel>> getEventsForMonthStream({
    required String userId,
    required int year,
    required int month,
  }) {
    // Fetch all user events and let UI handle filtering
    // This prevents issues with timezones or boundary conditions
    return _firestore
        .collection('events')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final events = snapshot.docs
              .map((doc) => EventModel.fromFirestore(doc))
              .toList();
          events.sort((a, b) => a.startTime.compareTo(b.startTime));
          return events;
        });
  }

  /// Get a single event by ID
  Future<EventModel?> getEvent(String eventId) async {
    final doc = await _firestore.collection('events').doc(eventId).get();
    if (!doc.exists) return null;
    return EventModel.fromFirestore(doc);
  }

  /// Create a new event
  Future<EventModel> createEvent(EventModel event) async {
    final docRef = _firestore.collection('events').doc();
    final newEvent = event.copyWith(
      id: docRef.id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await docRef.set(newEvent.toFirestore());
    return newEvent;
  }

  /// Update an event
  Future<void> updateEvent(EventModel event) async {
    final updated = event.copyWith(updatedAt: DateTime.now());
    await _firestore
        .collection('events')
        .doc(event.id)
        .update(updated.toFirestore());
  }

  /// Delete an event
  Future<void> deleteEvent(String eventId) async {
    await _firestore.collection('events').doc(eventId).delete();
  }

  /// Search events by title
  Future<List<EventModel>> searchEvents({
    required String userId,
    required String query,
  }) async {
    // Firestore doesn't support full-text search, so we'll fetch and filter
    // For production, consider using Algolia or Firebase Extensions
    final snapshot = await _firestore
        .collection('events')
        .where('userId', isEqualTo: userId)
        .get();

    final queryLower = query.toLowerCase();
    return snapshot.docs
        .map((doc) => EventModel.fromFirestore(doc))
        .where(
          (event) =>
              event.title.toLowerCase().contains(queryLower) ||
              (event.description?.toLowerCase().contains(queryLower) ??
                  false) ||
              (event.location?.toLowerCase().contains(queryLower) ?? false),
        )
        .toList();
  }

  // ==================== BATCH OPERATIONS ====================

  /// Import events from Google Calendar
  Future<void> importGoogleEvents({
    required String userId,
    required String calendarId,
    required List<EventModel> events,
  }) async {
    final batch = _firestore.batch();

    for (final event in events) {
      final docRef = _firestore.collection('events').doc();
      final newEvent = event.copyWith(
        id: docRef.id,
        userId: userId,
        calendarId: calendarId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      batch.set(docRef, newEvent.toFirestore());
    }

    await batch.commit();
  }

  /// Sync event to Google Calendar (mark as synced)
  Future<void> markEventSynced(String eventId, String googleEventId) async {
    await _firestore.collection('events').doc(eventId).update({
      'googleEventId': googleEventId,
      'updatedAt': Timestamp.now(),
    });
  }
}
