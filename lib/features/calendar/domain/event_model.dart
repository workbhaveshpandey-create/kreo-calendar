import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Recurrence pattern for events
enum RecurrenceType { none, daily, weekly, monthly, yearly }

/// Reminder timing before event
enum ReminderTime {
  atTime,
  fiveMinutes,
  tenMinutes,
  fifteenMinutes,
  thirtyMinutes,
  oneHour,
  twoHours,
  oneDay,
  twoDays,
  oneWeek,
}

/// Event model representing a calendar event
class EventModel extends Equatable {
  final String id;
  final String calendarId;
  final String userId;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final bool isAllDay;
  final String? location;
  final Color color;
  final RecurrenceType recurrence;
  final String? recurrenceRule;
  final List<ReminderTime> reminders;
  final String? googleEventId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EventModel({
    required this.id,
    required this.calendarId,
    required this.userId,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    this.isAllDay = false,
    this.location,
    required this.color,
    this.recurrence = RecurrenceType.none,
    this.recurrenceRule,
    this.reminders = const [],
    this.googleEventId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a new empty event
  factory EventModel.create({
    required String id,
    required String calendarId,
    required String userId,
    required DateTime startTime,
    Color? color,
  }) {
    final now = DateTime.now();
    return EventModel(
      id: id,
      calendarId: calendarId,
      userId: userId,
      title: '',
      startTime: startTime,
      endTime: startTime.add(const Duration(hours: 1)),
      color: color ?? const Color(0xFF6C5CE7),
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create from Firestore document
  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventModel(
      id: doc.id,
      calendarId: data['calendarId'] ?? '',
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'],
      startTime: (data['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endTime: (data['endTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isAllDay: data['isAllDay'] ?? false,
      location: data['location'],
      color: Color(data['color'] ?? 0xFF6C5CE7),
      recurrence: RecurrenceType.values[data['recurrence'] ?? 0],
      recurrenceRule: data['recurrenceRule'],
      reminders:
          (data['reminders'] as List<dynamic>?)
              ?.map((e) => ReminderTime.values[e as int])
              .toList() ??
          [],
      googleEventId: data['googleEventId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'calendarId': calendarId,
      'userId': userId,
      'title': title,
      'description': description,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'isAllDay': isAllDay,
      'location': location,
      'color': color.toARGB32(),
      'recurrence': recurrence.index,
      'recurrenceRule': recurrenceRule,
      'reminders': reminders.map((e) => e.index).toList(),
      'googleEventId': googleEventId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Check if event occurs on a specific date
  bool occursOnDate(DateTime date) {
    final eventDate = DateTime(startTime.year, startTime.month, startTime.day);
    final checkDate = DateTime(date.year, date.month, date.day);

    if (isAllDay) {
      final eventEndDate = DateTime(endTime.year, endTime.month, endTime.day);
      return !checkDate.isBefore(eventDate) && !checkDate.isAfter(eventEndDate);
    }

    return eventDate == checkDate;
  }

  /// Get duration of the event
  Duration get duration => endTime.difference(startTime);

  /// Check if event is multi-day
  bool get isMultiDay {
    final startDate = DateTime(startTime.year, startTime.month, startTime.day);
    final endDate = DateTime(endTime.year, endTime.month, endTime.day);
    return startDate != endDate;
  }

  /// Create a copy with updated fields
  EventModel copyWith({
    String? id,
    String? calendarId,
    String? userId,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    bool? isAllDay,
    String? location,
    Color? color,
    RecurrenceType? recurrence,
    String? recurrenceRule,
    List<ReminderTime>? reminders,
    String? googleEventId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EventModel(
      id: id ?? this.id,
      calendarId: calendarId ?? this.calendarId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isAllDay: isAllDay ?? this.isAllDay,
      location: location ?? this.location,
      color: color ?? this.color,
      recurrence: recurrence ?? this.recurrence,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      reminders: reminders ?? this.reminders,
      googleEventId: googleEventId ?? this.googleEventId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    calendarId,
    userId,
    title,
    description,
    startTime,
    endTime,
    isAllDay,
    location,
    color,
    recurrence,
    recurrenceRule,
    reminders,
    googleEventId,
    createdAt,
    updatedAt,
  ];

  @override
  String toString() =>
      'EventModel(id: $id, title: $title, startTime: $startTime)';
}
