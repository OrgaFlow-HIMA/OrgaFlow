import 'package:cloud_firestore/cloud_firestore.dart';

import '../enums/task_status.dart';

class InvalidTaskException implements Exception {
  final String message;
  const InvalidTaskException(this.message);

  @override
  String toString() => message;
}

/// Model tugas pada koleksi `tasks`.
/// Satu tugas ditujukan untuk satu divisi, lalu didelegasikan oleh Kadiv ke anggota spesifik.
class Task {
  final String id;
  final String title;
  final String description;
  final String divisiId;
  final String? divisiNama;
  final String? targetRole; // Misal: 'bendahara' jika tugas khusus untuk Bendahara
  final String? assignedToUid;
  final String? assignedToNama;
  final TaskStatus status;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? dueAt;
  final String? submissionType; // 'file' atau 'link'
  final String? submissionUrl;
  final String? submissionFileName;
  final String? submissionNote;
  final DateTime? submittedAt;
  final String? completedBy;
  final DateTime? completedAt;
  final String? confirmedByKadiv;
  final DateTime? confirmedAt;

  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.divisiId,
    this.divisiNama,
    this.targetRole,
    this.assignedToUid,
    this.assignedToNama,
    required this.status,
    required this.createdBy,
    this.createdAt,
    this.dueAt,
    this.submissionType,
    this.submissionUrl,
    this.submissionFileName,
    this.submissionNote,
    this.submittedAt,
    this.completedBy,
    this.completedAt,
    this.confirmedByKadiv,
    this.confirmedAt,
  });

  bool get isDone => status == TaskStatus.done;
  bool get isSubmitted => status == TaskStatus.submitted;
  bool get isPendingDelegation => status == TaskStatus.pendingDelegation;

  bool get isOverdue {
    if (isDone || dueAt == null) return false;
    return DateTime.now().isAfter(dueAt!);
  }

  /// Factory parsing dokumen Firestore.
  factory Task.fromMap(Map<String, dynamic> data, String documentId) {
    final status = TaskStatus.fromFirestore(data['status'] as String?) ??
        (data['status'] == 'todo' ? TaskStatus.todo : TaskStatus.done);

    final title = (data['title'] as String?)?.trim() ?? '';
    if (title.isEmpty) {
      throw const InvalidTaskException('Tugas tidak memiliki judul.');
    }

    // Dukung legacy divisiId atau target_role fallback
    final divisiId = (data['divisi_id'] as String?)?.trim() ??
        (data['target_role'] as String?)?.trim() ??
        'umum';

    return Task(
      id: documentId,
      title: title,
      description: (data['description'] as String?)?.trim() ?? '',
      divisiId: divisiId,
      divisiNama: (data['divisi_nama'] as String?)?.trim(),
      targetRole: (data['target_role'] as String?)?.trim(),
      assignedToUid: (data['assigned_to_uid'] as String?)?.trim(),
      assignedToNama: (data['assigned_to_nama'] as String?)?.trim(),
      status: status,
      createdBy: (data['created_by'] as String?)?.trim() ?? '',
      createdAt: _parseTimestamp(data['created_at']),
      dueAt: _parseTimestamp(data['due_at']),
      submissionType: (data['submission_type'] as String?)?.trim(),
      submissionUrl: (data['submission_url'] as String?)?.trim(),
      submissionFileName: (data['submission_file_name'] as String?)?.trim(),
      submissionNote: (data['submission_note'] as String?)?.trim(),
      submittedAt: _parseTimestamp(data['submitted_at']),
      completedBy: (data['completed_by'] as String?)?.trim(),
      completedAt: _parseTimestamp(data['completed_at']),
      confirmedByKadiv: (data['confirmed_by_kadiv'] as String?)?.trim(),
      confirmedAt: _parseTimestamp(data['confirmed_at']),
    );
  }

  /// Konversi untuk penulisan awal dokumen ke Firestore oleh Sekretaris.
  Map<String, dynamic> toCreateMap() {
    return {
      'title': title,
      'description': description,
      'divisi_id': divisiId,
      if (divisiNama != null) 'divisi_nama': divisiNama,
      if (targetRole != null) 'target_role': targetRole,
      'status': TaskStatus.pendingDelegation.firestoreValue,
      'created_by': createdBy,
      'created_at': FieldValue.serverTimestamp(),
      if (dueAt != null) 'due_at': Timestamp.fromDate(dueAt!),
    };
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? divisiId,
    String? divisiNama,
    String? targetRole,
    String? assignedToUid,
    String? assignedToNama,
    TaskStatus? status,
    String? createdBy,
    DateTime? createdAt,
    DateTime? dueAt,
    String? submissionType,
    String? submissionUrl,
    String? submissionFileName,
    String? submissionNote,
    DateTime? submittedAt,
    String? completedBy,
    DateTime? completedAt,
    String? confirmedByKadiv,
    DateTime? confirmedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      divisiId: divisiId ?? this.divisiId,
      divisiNama: divisiNama ?? this.divisiNama,
      targetRole: targetRole ?? this.targetRole,
      assignedToUid: assignedToUid ?? this.assignedToUid,
      assignedToNama: assignedToNama ?? this.assignedToNama,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      dueAt: dueAt ?? this.dueAt,
      submissionType: submissionType ?? this.submissionType,
      submissionUrl: submissionUrl ?? this.submissionUrl,
      submissionFileName: submissionFileName ?? this.submissionFileName,
      submissionNote: submissionNote ?? this.submissionNote,
      submittedAt: submittedAt ?? this.submittedAt,
      completedBy: completedBy ?? this.completedBy,
      completedAt: completedAt ?? this.completedAt,
      confirmedByKadiv: confirmedByKadiv ?? this.confirmedByKadiv,
      confirmedAt: confirmedAt ?? this.confirmedAt,
    );
  }

  static DateTime? _parseTimestamp(dynamic raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }
}
