import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Calendar model representing a user's calendar
/// Each user can have multiple calendars
class CalendarModel extends Equatable {
  final String id;
  final String userId;
  final String name;
  final Color color;
  final bool isDefault;
  final bool isGoogleSync;
  final String? googleCalendarId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CalendarModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.color,
    this.isDefault = false,
    this.isGoogleSync = false,
    this.googleCalendarId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a default calendar for a new user
  factory CalendarModel.createDefault({
    required String id,
    required String userId,
  }) {
    final now = DateTime.now();
    return CalendarModel(
      id: id,
      userId: userId,
      name: 'My Calendar',
      color: const Color(0xFF6C5CE7), // Primary purple
      isDefault: true,
      isGoogleSync: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create from Firestore document
  factory CalendarModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CalendarModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? 'Untitled',
      color: Color(data['color'] ?? 0xFF6C5CE7),
      isDefault: data['isDefault'] ?? false,
      isGoogleSync: data['isGoogleSync'] ?? false,
      googleCalendarId: data['googleCalendarId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'color': color.toARGB32(),
      'isDefault': isDefault,
      'isGoogleSync': isGoogleSync,
      'googleCalendarId': googleCalendarId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create a copy with updated fields
  CalendarModel copyWith({
    String? id,
    String? userId,
    String? name,
    Color? color,
    bool? isDefault,
    bool? isGoogleSync,
    String? googleCalendarId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CalendarModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      color: color ?? this.color,
      isDefault: isDefault ?? this.isDefault,
      isGoogleSync: isGoogleSync ?? this.isGoogleSync,
      googleCalendarId: googleCalendarId ?? this.googleCalendarId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    name,
    color,
    isDefault,
    isGoogleSync,
    googleCalendarId,
    createdAt,
    updatedAt,
  ];

  @override
  String toString() =>
      'CalendarModel(id: $id, name: $name, isDefault: $isDefault)';
}
