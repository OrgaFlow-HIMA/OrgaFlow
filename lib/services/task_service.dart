import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../enums/task_status.dart';
import '../models/app_notification.dart';
import '../models/task.dart';
import '../models/user_profile.dart';
import 'notification_service.dart';

class TaskServiceException implements Exception {
  final String message;
  const TaskServiceException(this.message);

  @override
  String toString() => message;
}

/// Layanan CRUD dan alur siklus hidup tugas pada koleksi `tasks`.
class TaskService {
  final FirebaseFirestore _firestore;

  TaskService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _tasks =>
      _firestore.collection(AppConstants.tasksCollection);

  /// Mengambil satu data tugas berdasarkan ID
  Future<Task?> getTaskById(String taskId) async {
    try {
      final doc = await _tasks.doc(taskId).get();
      if (!doc.exists || doc.data() == null) return null;
      return Task.fromMap(doc.data()!, doc.id);
    } catch (e) {
      debugPrint('[OrgaFlow TaskService ERROR] getTaskById: $e');
      return null;
    }
  }

  /// 1. Sekretaris membuat tugas yang dilimpahkan ke divisi tertentu ATAU langsung ke Bendahara.
  Future<String> createTask({
    required String createdBy,
    required String title,
    required String description,
    required String divisiId,
    String? divisiNama,
    String? targetRole, // 'bendahara' jika ditujukan khusus ke Bendahara
    DateTime? dueAt,
  }) async {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) {
      throw const TaskServiceException('Judul tugas wajib diisi.');
    }
    if (createdBy.trim().isEmpty) {
      throw const TaskServiceException('Pembuat tugas tidak valid.');
    }
    if (divisiId.trim().isEmpty) {
      throw const TaskServiceException('Tujuan tugas wajib dipilih.');
    }

    final isTargetBendahara =
        targetRole == 'bendahara' || divisiId == 'bendahara';

    try {
      final doc = await _tasks.add({
        'title': cleanTitle,
        'description': description.trim(),
        'divisi_id': divisiId.trim(),
        if (divisiNama != null && divisiNama.trim().isNotEmpty)
          'divisi_nama': divisiNama.trim(),
        if (isTargetBendahara) 'target_role': 'bendahara',
        // Jika tugas untuk Bendahara, langsung 'todo' (tidak butuh pendelegasian Kadiv)
        'status': isTargetBendahara
            ? TaskStatus.todo.firestoreValue
            : TaskStatus.pendingDelegation.firestoreValue,
        'created_by': createdBy.trim(),
        'created_at': FieldValue.serverTimestamp(),
        if (dueAt != null) 'due_at': Timestamp.fromDate(dueAt),
      });

      // Pemicu Notifikasi Otomatis
      try {
        final notifService = NotificationService(firestore: _firestore);
        if (isTargetBendahara) {
          // Notifikasi langsung ke Bendahara
          await notifService.createNotification(
            title: 'Tugas Baru untuk Bendahara',
            message: 'Sekretaris memberikan tugas keuangan "$cleanTitle".',
            type: NotificationType.task,
            targetType: NotificationTargetType.role,
            targetRole: 'bendahara',
            referenceId: doc.id,
            createdBy: createdBy.trim(),
          );
        } else {
          // Notifikasi ke Kepala Divisi terkait
          await notifService.createNotification(
            title: 'Tugas Baru untuk Divisi',
            message:
                'Sekretaris melimpahkan tugas "$cleanTitle" ke divisi ${divisiNama ?? divisiId}. Silakan delegasikan ke anggota.',
            type: NotificationType.task,
            targetType: NotificationTargetType.role,
            targetRole: 'kepala_divisi',
            referenceId: doc.id,
            createdBy: createdBy.trim(),
          );
        }

        // Notifikasi konfirmasi untuk Sekretaris pembuat
        await notifService.createNotification(
          title: 'Berhasil Membuat Tugas',
          message:
              'Tugas "$cleanTitle" berhasil dibuat untuk ${isTargetBendahara ? 'Bendahara' : (divisiNama ?? divisiId)}.',
          type: NotificationType.task,
          targetType: NotificationTargetType.user,
          targetUserId: createdBy.trim(),
          referenceId: doc.id,
          createdBy: createdBy.trim(),
        );
      } catch (notifErr) {
        debugPrint(
          '[OrgaFlow TaskService WARNING] Gagal membuat notifikasi tugas: $notifErr',
        );
      }

      return doc.id;
    } on FirebaseException catch (e) {
      debugPrint(
        '[OrgaFlow TaskService ERROR] create: ${e.code} - ${e.message}',
      );
      throw TaskServiceException('Gagal membuat tugas: ${e.message ?? e.code}');
    }
  }

  /// 2. Kadiv mendelegasikan tugas ke anggota spesifik di divisinya.
  Future<void> delegateTaskToMember({
    required String taskId,
    required String memberUid,
    required String memberNama,
    required String kadivUid,
  }) async {
    try {
      final taskDoc = await _tasks.doc(taskId).get();
      final taskTitle = taskDoc.data()?['title'] ?? 'Tugas';

      await _tasks.doc(taskId).update({
        'assigned_to_uid': memberUid.trim(),
        'assigned_to_nama': memberNama.trim(),
        'status': TaskStatus.todo.firestoreValue,
        'delegated_at': FieldValue.serverTimestamp(),
      });

      // Notifikasi ke anggota yang ditunjuk
      try {
        final notifService = NotificationService(firestore: _firestore);
        await notifService.createNotification(
          title: 'Anda Mendapatkan Tugas Baru',
          message:
              'Kepala Divisi menugaskan Anda untuk mengerjakan "$taskTitle".',
          type: NotificationType.task,
          targetType: NotificationTargetType.user,
          targetUserId: memberUid.trim(),
          referenceId: taskId,
          createdBy: kadivUid,
        );
      } catch (e) {
        debugPrint('[OrgaFlow TaskService WARNING] Notif delegasi error: $e');
      }
    } on FirebaseException catch (e) {
      throw TaskServiceException(
        'Gagal mendelegasikan tugas: ${e.message ?? e.code}',
      );
    }
  }

  /// 3. Anggota mengunggah hasil pengerjaan tugas (File atau Link) -> status menjadi 'submitted'.
  Future<void> submitTaskResult({
    required String taskId,
    required String submissionType, // 'file' atau 'link'
    required String submissionUrl,
    String? submissionFileName,
    String? submissionNote,
    required String memberUid,
  }) async {
    try {
      final taskDoc = await _tasks.doc(taskId).get();
      final taskTitle = taskDoc.data()?['title'] ?? 'Tugas';

      await _tasks.doc(taskId).update({
        'status': TaskStatus.submitted.firestoreValue,
        'submission_type': submissionType,
        'submission_url': submissionUrl.trim(),
        if (submissionFileName != null)
          'submission_file_name': submissionFileName.trim(),
        if (submissionNote != null) 'submission_note': submissionNote.trim(),
        'completed_by': memberUid,
        'submitted_at': FieldValue.serverTimestamp(),
      });

      // Notifikasi bahwa tugas siap diperiksa:
      // Jika tugas ditujukan ke Bendahara, kirim notifikasi ke Sekretaris
      // Jika tugas divisi, kirim notifikasi ke Kepala Divisi
      try {
        final notifService = NotificationService(firestore: _firestore);
        final targetRole = taskDoc.data()?['target_role'] as String?;
        final divisiId = taskDoc.data()?['divisi_id'] as String?;
        final isBendaharaTask =
            targetRole == 'bendahara' || divisiId == 'bendahara';

        if (isBendaharaTask) {
          await notifService.createNotification(
            title: 'Tugas Bendahara Diserahkan',
            message:
                'Bendahara telah mengumpulkan hasil tugas "$taskTitle". Silakan periksa dan konfirmasi.',
            type: NotificationType.task,
            targetType: NotificationTargetType.role,
            targetRole: 'sekretaris',
            referenceId: taskId,
            createdBy: memberUid,
          );
        } else {
          await notifService.createNotification(
            title: 'Tugas Selesai Dikerjakan',
            message:
                'Tugas "$taskTitle" telah diserahkan oleh anggota. Silakan periksa dan konfirmasi.',
            type: NotificationType.task,
            targetType: NotificationTargetType.role,
            targetRole: 'kepala_divisi',
            referenceId: taskId,
            createdBy: memberUid,
          );
        }
      } catch (e) {
        debugPrint('[OrgaFlow TaskService WARNING] Notif submit error: $e');
      }
    } on FirebaseException catch (e) {
      throw TaskServiceException(
        'Gagal menyerahkan tugas: ${e.message ?? e.code}',
      );
    }
  }

  /// 4. Kadiv mengonfirmasi dan menyetujui hasil pengerjaan -> status tuntas 'done'.
  Future<void> confirmTaskByKadiv({
    required String taskId,
    required String kadivUid,
  }) async {
    try {
      final taskDoc = await _tasks.doc(taskId).get();
      final taskTitle = taskDoc.data()?['title'] ?? 'Tugas';
      final assignedToUid = taskDoc.data()?['assigned_to_uid'] as String?;
      final createdBy = taskDoc.data()?['created_by'] as String?;

      await _tasks.doc(taskId).update({
        'status': TaskStatus.done.firestoreValue,
        'confirmed_by_kadiv': kadivUid,
        'confirmed_at': FieldValue.serverTimestamp(),
        'completed_at': FieldValue.serverTimestamp(),
      });

      // Notifikasi ke Sekretaris dan Anggota bahwa tugas tuntas
      try {
        final notifService = NotificationService(firestore: _firestore);
        if (createdBy != null && createdBy.isNotEmpty) {
          await notifService.createNotification(
            title: 'Tugas Divisi Telah Tuntas',
            message:
                'Tugas "$taskTitle" telah selesai dan disetujui oleh Kepala Divisi.',
            type: NotificationType.task,
            targetType: NotificationTargetType.user,
            targetUserId: createdBy,
            referenceId: taskId,
            createdBy: kadivUid,
          );
        }
        if (assignedToUid != null && assignedToUid.isNotEmpty) {
          await notifService.createNotification(
            title: 'Tugas Anda Disetujui',
            message:
                'Hasil pengerjaan tugas "$taskTitle" telah diverifikasi dan disetujui Kadiv.',
            type: NotificationType.task,
            targetType: NotificationTargetType.user,
            targetUserId: assignedToUid,
            referenceId: taskId,
            createdBy: kadivUid,
          );
        }
      } catch (e) {
        debugPrint('[OrgaFlow TaskService WARNING] Notif konfirmasi error: $e');
      }
    } on FirebaseException catch (e) {
      throw TaskServiceException(
        'Gagal mengonfirmasi tugas: ${e.message ?? e.code}',
      );
    }
  }

  /// 5. Sekretaris mengonfirmasi dan menyetujui hasil pengerjaan tugas (khususnya untuk tugas Bendahara).
  Future<void> confirmTaskBySecretary({
    required String taskId,
    required String secretaryUid,
  }) async {
    try {
      final taskDoc = await _tasks.doc(taskId).get();
      final taskTitle = taskDoc.data()?['title'] ?? 'Tugas';
      final completedBy =
          taskDoc.data()?['completed_by'] as String? ??
          taskDoc.data()?['assigned_to_uid'] as String?;

      await _tasks.doc(taskId).update({
        'status': TaskStatus.done.firestoreValue,
        'confirmed_by_kadiv': secretaryUid,
        'confirmed_at': FieldValue.serverTimestamp(),
        'completed_at': FieldValue.serverTimestamp(),
      });

      try {
        final notifService = NotificationService(firestore: _firestore);
        if (completedBy != null && completedBy.isNotEmpty) {
          await notifService.createNotification(
            title: 'Tugas Anda Telah Disetujui',
            message:
                'Tugas "$taskTitle" telah diverifikasi dan disetujui oleh Sekretaris.',
            type: NotificationType.task,
            targetType: NotificationTargetType.user,
            targetUserId: completedBy,
            referenceId: taskId,
            createdBy: secretaryUid,
          );
        }
      } catch (e) {
        debugPrint(
          '[OrgaFlow TaskService WARNING] Notif konfirmasi sekretaris error: $e',
        );
      }
    } on FirebaseException catch (e) {
      throw TaskServiceException(
        'Gagal menyetujui tugas: ${e.message ?? e.code}',
      );
    }
  }

  /// Stream seluruh tugas (dipakai Sekretaris).
  Stream<List<Task>> watchAllTasks() {
    return _tasks.snapshots().map((snapshot) {
      final tasks = _mapSnapshot(snapshot);
      tasks.sort(
        (a, b) =>
            (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)),
      );
      return tasks;
    });
  }

  /// Stream tugas untuk Kadiv berdasarkan ID divisi miliknya.
  Stream<List<Task>> watchTasksForDivision(String divisionId) {
    return _tasks
        .where('divisi_id', isEqualTo: divisionId.trim())
        .snapshots()
        .map((snapshot) {
          final tasks = _mapSnapshot(snapshot);
          tasks.sort(
            (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
              a.createdAt ?? DateTime(0),
            ),
          );
          return tasks;
        });
  }

  /// Stream tugas untuk Anggota spesifik berdasarkan UID dirinya.
  Stream<List<Task>> watchTasksForMember(String memberUid) {
    return _tasks
        .where('assigned_to_uid', isEqualTo: memberUid.trim())
        .snapshots()
        .map((snapshot) {
          final tasks = _mapSnapshot(snapshot);
          tasks.sort(
            (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
              a.createdAt ?? DateTime(0),
            ),
          );
          return tasks;
        });
  }

  /// Stream tugas untuk Bendahara (baik ditargetkan ke peran 'bendahara' maupun UID-nya).
  Stream<List<Task>> watchTasksForBendahara(String bendaharaUid) {
    return _tasks.snapshots().map((snapshot) {
      final all = _mapSnapshot(snapshot);
      final filtered = all.where((task) {
        final isRoleBendahara =
            task.targetRole == 'bendahara' || task.divisiId == 'bendahara';
        final isAssigned = task.assignedToUid == bendaharaUid;
        return isRoleBendahara || isAssigned;
      }).toList();
      filtered.sort(
        (a, b) =>
            (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)),
      );
      return filtered;
    });
  }

  /// Mengambil daftar anggota aktif dalam satu divisi (khusus anggota biasa, tidak termasuk Kadiv/role lain).
  Future<List<UserProfile>> getMembersByDivision(
    String divisionId, {
    String? excludeUid,
  }) async {
    final snapshot = await _firestore
        .collection(AppConstants.usersCollection)
        .where('divisi_id', isEqualTo: divisionId.trim())
        .where('status_akun', isEqualTo: AppConstants.statusActive)
        .where('role', isEqualTo: 'anggota')
        .get();

    final members = snapshot.docs
        .map((doc) => UserProfile.fromMap(doc.data(), doc.id))
        .where((m) => excludeUid == null || m.uid != excludeUid)
        .toList();

    members.sort(
      (a, b) => a.nama.toLowerCase().compareTo(b.nama.toLowerCase()),
    );
    return members;
  }

  /// Mengambil semua dokumen divisi resmi untuk pilihan dropdown Sekretaris.
  Future<List<Map<String, String>>> getAllDivisions() async {
    final snapshot = await _firestore
        .collection(AppConstants.divisionsCollection)
        .get();

    final divisions = snapshot.docs.map((doc) {
      final name = doc.data()['nama'] as String? ?? doc.id;
      return {'id': doc.id, 'nama': name};
    }).toList();

    divisions.sort(
      (a, b) => a['nama']!.toLowerCase().compareTo(b['nama']!.toLowerCase()),
    );
    return divisions;
  }

  List<Task> _mapSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final tasks = <Task>[];
    for (final doc in snapshot.docs) {
      try {
        tasks.add(Task.fromMap(doc.data(), doc.id));
      } catch (e) {
        debugPrint('[OrgaFlow TaskService ERROR] parsing task ${doc.id}: $e');
      }
    }
    return tasks;
  }
}
