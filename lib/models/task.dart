import 'package:cloud_firestore/cloud_firestore.dart';

import '../enums/task_status.dart';
import '../enums/user_role.dart';

class InvalidTaskException implements Exception {
  final String message;
  const InvalidTaskException(this.message);

  @override
  String toString() => message;
}

/// Model tugas pada koleksi `tasks`.
/// Satu tugas ditujukan untuk satu role penerima.
class Task {
  final String id;
  final String title;
  final String description;
  final UserRole targetRole;
  final TaskStatus status;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? dueAt;
  final String? completedBy;
  final DateTime? completedAt;

  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.targetRole,
    required this.status,
    required this.createdBy,
    this.createdAt,
    this.dueAt,
    this.completedBy,
    this.completedAt,
  });

  bool get isDone => status == TaskStatus.done;

  bool get isOverdue {
    if (isDone || dueAt == null) return false;
    return DateTime.now().isAfter(dueAt!);
  }

  /// Factory parsing dokumen Firestore dengan validasi ketat.
  factory Task.fromMap(Map<String, dynamic> data, String documentId) {
    final targetRole = UserRole.fromFirestore(data['target_role'] as String?);
    if (targetRole == null) {
      throw const InvalidTaskException(
        'Tugas memiliki target role tidak valid.',
      );
    }

    final status = TaskStatus.fromFirestore(data['status'] as String?);
    if (status == null) {
      throw const InvalidTaskException(
        'Tugas memiliki status tidak valid.',
      );
    }

    final title = (data['title'] as String?)?.trim() ?? '';
    if (title.isEmpty) {
      throw const InvalidTaskException('Tugas tidak memiliki judul.');
    }

    return Task(
      id: documentId,
      title: title,
      description: (data['description'] as String?)?.trim() ?? '',
      targetRole: targetRole,
      status: status,
      createdBy: (data['created_by'] as String?)?.trim() ?? '',
      createdAt: _parseTimestamp(data['created_at']),
      dueAt: _parseTimestamp(data['due_at']),
      completedBy: (data['completed_by'] as String?)?.trim(),
      completedAt: _parseTimestamp(data['completed_at']),
    );
  }

  /// Konversi untuk penulisan awal dokumen ke Firestore.
  Map<String, dynamic> toCreateMap() {
    return {
      'title': title,
      'description': description,
      'target_role': targetRole.firestoreValue,
      'status': TaskStatus.todo.firestoreValue,
      'created_by': createdBy,
      'created_at': FieldValue.serverTimestamp(),
      if (dueAt != null) 'due_at': Timestamp.fromDate(dueAt!),
    };
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    UserRole? targetRole,
    TaskStatus? status,
    String? createdBy,
    DateTime? createdAt,
    DateTime? dueAt,
    String? completedBy,
    DateTime? completedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      targetRole: targetRole ?? this.targetRole,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      dueAt: dueAt ?? this.dueAt,
      completedBy: completedBy ?? this.completedBy,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  static DateTime? _parseTimestamp(Object? raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    return null;
  }
}
