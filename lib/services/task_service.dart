import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../enums/task_status.dart';
import '../enums/user_role.dart';
import '../models/app_notification.dart';
import '../models/task.dart';
import 'notification_service.dart';

class TaskServiceException implements Exception {
  final String message;
  const TaskServiceException(this.message);

  @override
  String toString() => message;
}

/// Layanan CRUD tugas pada koleksi `tasks`.
/// Pembuatan tugas hanya boleh dipanggil dari alur UI Sekretaris;
/// batas keamanan sebenarnya dijaga Firestore Security Rules.
class TaskService {
  final FirebaseFirestore _firestore;

  TaskService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _tasks =>
      _firestore.collection(AppConstants.tasksCollection);

  /// Buat tugas baru. `createdBy` wajib UID Sekretaris yang sedang login.
  Future<String> createTask({
    required String createdBy,
    required String title,
    required String description,
    required UserRole targetRole,
    DateTime? dueAt,
  }) async {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) {
      throw const TaskServiceException('Judul tugas wajib diisi.');
    }
    if (createdBy.trim().isEmpty) {
      throw const TaskServiceException('Pembuat tugas tidak valid.');
    }

    try {
      final doc = await _tasks.add({
        'title': cleanTitle,
        'description': description.trim(),
        'target_role': targetRole.firestoreValue,
        'status': TaskStatus.todo.firestoreValue,
        'created_by': createdBy.trim(),
        'created_at': FieldValue.serverTimestamp(),
        if (dueAt != null) 'due_at': Timestamp.fromDate(dueAt),
      });

      // Pemicu Notifikasi Otomatis
      try {
        final notifService = NotificationService(firestore: _firestore);
        // 1. Notifikasi untuk role target yang ditugaskan
        await notifService.createNotification(
          title: 'Tugas Baru Diberikan',
          message: 'Sekretaris menugaskan "$cleanTitle" untuk role ${targetRole.label}.',
          type: NotificationType.task,
          targetType: NotificationTargetType.role,
          targetRole: targetRole.firestoreValue,
          createdBy: createdBy.trim(),
        );

        // 2. Notifikasi konfirmasi untuk Sekretaris pembuat tugas
        await notifService.createNotification(
          title: 'Berhasil Membuat Tugas',
          message: 'Tugas "$cleanTitle" berhasil dibuat untuk ${targetRole.label}.',
          type: NotificationType.task,
          targetType: NotificationTargetType.user,
          targetUserId: createdBy.trim(),
          createdBy: createdBy.trim(),
        );
      } catch (notifErr) {
        debugPrint('[OrgaFlow TaskService WARNING] Gagal membuat notifikasi tugas: $notifErr');
      }

      return doc.id;
    } on FirebaseException catch (e) {
      debugPrint(
        '[OrgaFlow TaskService ERROR] create: ${e.code} - ${e.message}',
      );
      if (e.code == 'permission-denied') {
        throw const TaskServiceException(
          'Izin ditolak. Hanya Sekretaris yang dapat membuat tugas.',
        );
      }
      throw TaskServiceException('Gagal membuat tugas: ${e.message ?? e.code}');
    }
  }

  Stream<List<Task>> watchTasksForRole(UserRole role) {
    return _tasks
        .where('target_role', isEqualTo: role.firestoreValue)
        // .orderBy('created_at', descending: true) // <--- KOMENTARI ATAU HAPUS BARIS INI
        .snapshots()
        .map((snapshot) {
          final tasks = _mapSnapshot(snapshot);

          // Urutkan manual dari yang terbaru
          tasks.sort((a, b) {
            if (a.createdAt == null && b.createdAt == null) return 0;
            if (a.createdAt == null) return 1;
            if (b.createdAt == null) return -1;
            return b.createdAt!.compareTo(a.createdAt!);
          });

          return tasks;
        });
  }

  /// Stream seluruh tugas (dipakai halaman Sekretaris).
  Stream<List<Task>> watchAllTasks() {
    return _tasks
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(_mapSnapshot);
  }

  /// Ambil daftar tugas satu role sekali (one-shot).
  Future<List<Task>> getTasksForRole(UserRole role) async {
    try {
      final snapshot = await _tasks
          .where('target_role', isEqualTo: role.firestoreValue)
          .orderBy('created_at', descending: true)
          .get();
      return _mapSnapshot(snapshot);
    } on FirebaseException catch (e) {
      throw TaskServiceException('Gagal memuat tugas: ${e.message ?? e.code}');
    }
  }

  /// Tandai tugas selesai oleh penerima.
  Future<void> markTaskDone({
    required String taskId,
    required String completedBy,
  }) async {
    if (taskId.trim().isEmpty) {
      throw const TaskServiceException('ID tugas tidak valid.');
    }
    if (completedBy.trim().isEmpty) {
      throw const TaskServiceException('Penyelesai tugas tidak valid.');
    }

    try {
      await _tasks.doc(taskId).update({
        'status': TaskStatus.done.firestoreValue,
        'completed_by': completedBy.trim(),
        'completed_at': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      debugPrint('[OrgaFlow TaskService ERROR] done: ${e.code} - ${e.message}');
      if (e.code == 'permission-denied') {
        throw const TaskServiceException(
          'Izin ditolak. Hanya penerima role tugas ini yang dapat menyelesaikan.',
        );
      }
      throw TaskServiceException(
        'Gagal menyelesaikan tugas: ${e.message ?? e.code}',
      );
    }
  }

  List<Task> _mapSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final tasks = <Task>[];
    for (final doc in snapshot.docs) {
      try {
        tasks.add(Task.fromMap(doc.data(), doc.id));
      } on InvalidTaskException catch (e) {
        debugPrint('[OrgaFlow TaskService SKIP] ${doc.id}: $e');
      }
    }
    return tasks;
  }
}
