// models/task.dart
// Mirrors the TaskOut schema from the Python backend exactly.

import 'package:flutter/material.dart';

/// The four possible statuses a task can have.
enum TaskStatus {
  todo('To-Do'),
  inProgress('In Progress'),
  done('Done');

  const TaskStatus(this.label);
  final String label;

  static TaskStatus fromString(String s) => TaskStatus.values.firstWhere(
        (e) => e.label == s,
        orElse: () => TaskStatus.todo,
      );
}

/// Whether a task repeats automatically when marked Done.
enum RecurringType {
  none('None'),
  daily('Daily'),
  weekly('Weekly');

  const RecurringType(this.label);
  final String label;

  static RecurringType fromString(String s) => RecurringType.values.firstWhere(
        (e) => e.label == s,
        orElse: () => RecurringType.none,
      );
}

class Task {
  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final TaskStatus status;
  final String? blockedById;
  final RecurringType recurringType;
  final int sortOrder;
  final DateTime createdAt;

  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.status,
    this.blockedById,
    this.recurringType = RecurringType.none,
    this.sortOrder = 0,
    required this.createdAt,
  });

  bool get isRecurring => recurringType != RecurringType.none;

  /// Deserialize from the JSON object returned by the backend.
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      dueDate: DateTime.parse(json['due_date'] as String),
      status: TaskStatus.fromString(json['status'] as String),
      blockedById: json['blocked_by_id'] as String?,
      recurringType:
          RecurringType.fromString(json['recurring_type'] as String? ?? 'None'),
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Serialize to JSON for sending to the backend.
  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'due_date': dueDate.toIso8601String().split('T').first, // date only
        'status': status.label,
        'blocked_by_id': blockedById,
        'recurring_type': recurringType.label,
      };

  /// Create a modified copy (immutability pattern).
  Task copyWith({
    String? title,
    String? description,
    DateTime? dueDate,
    TaskStatus? status,
    String? blockedById,
    bool clearBlockedBy = false,
    RecurringType? recurringType,
    int? sortOrder,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      blockedById: clearBlockedBy ? null : (blockedById ?? this.blockedById),
      recurringType: recurringType ?? this.recurringType,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
    );
  }
}

// ── Visual helpers ────────────────────────────────────────────────────────────

extension TaskStatusVisuals on TaskStatus {
  Color get color {
    switch (this) {
      case TaskStatus.todo:
        return const Color(0xFF6C8EEF);
      case TaskStatus.inProgress:
        return const Color(0xFFFFB347);
      case TaskStatus.done:
        return const Color(0xFF56C596);
    }
  }

  IconData get icon {
    switch (this) {
      case TaskStatus.todo:
        return Icons.radio_button_unchecked_rounded;
      case TaskStatus.inProgress:
        return Icons.timelapse_rounded;
      case TaskStatus.done:
        return Icons.check_circle_rounded;
    }
  }
}
