import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../enums/task_status.dart';
import '../enums/user_role.dart';
import '../models/task.dart';
import '../models/user_profile.dart';

class DivisionPerformance {
  final String divisionId;
  final String divisionName;
  final String? kadivName;
  final String? kadivUid;
  final List<UserProfile> members;
  final List<Task> tasks;
  final String? activeProkerTitle;

  const DivisionPerformance({
    required this.divisionId,
    required this.divisionName,
    this.kadivName,
    this.kadivUid,
    this.members = const [],
    this.tasks = const [],
    this.activeProkerTitle,
  });

  int get totalTasks => tasks.length;
  int get completedTasks => tasks.where((t) => t.isDone).length;
  int get inProgressTasks => tasks.where((t) => !t.isDone).length;
  int get overdueTasks => tasks.where((t) => t.isOverdue && !t.isDone).length;

  /// Persentase progres kerja (0 - 100%)
  int get progressPercentage {
    if (totalTasks == 0) return 0;
    return ((completedTasks / totalTasks) * 100).round();
  }

  /// Status performa untuk badge
  /// 'Sesuai Jadwal' (Hijau), 'Aktif Berjalan' (Teal/Biru), 'Perlu Koordinasi' (Oranye/Kuning)
  String get statusBadge {
    if (overdueTasks > 0) {
      return 'Perlu Koordinasi';
    }
    if (progressPercentage >= 80) {
      return 'Sesuai Jadwal';
    }
    if (totalTasks > 0) {
      return 'Aktif Berjalan';
    }
    return 'Belum Ada Tugas';
  }
}

class DivisionMonitoringService {
  final FirebaseFirestore _firestore;

  DivisionMonitoringService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Stream seluruh ringkasan performa per divisi secara real-time
  Stream<List<DivisionPerformance>> watchAllDivisionsPerformance() {
    // Dengarkan perubahan pada koleksi tasks
    return _firestore.collection(AppConstants.tasksCollection).snapshots().asyncMap((taskSnap) async {
      final allTasks = <Task>[];
      for (final doc in taskSnap.docs) {
        try {
          allTasks.add(Task.fromMap(doc.data(), doc.id));
        } catch (_) {}
      }

      // Ambil seluruh divisi resmi
      final divSnap = await _firestore.collection(AppConstants.divisionsCollection).get();
      final usersSnap = await _firestore
          .collection(AppConstants.usersCollection)
          .where('status_akun', isEqualTo: AppConstants.statusActive)
          .get();

      final allUsers = usersSnap.docs
          .map((doc) => UserProfile.fromMap(doc.data(), doc.id))
          .toList();

      final result = <DivisionPerformance>[];

      for (final divDoc in divSnap.docs) {
        final divId = divDoc.id;
        final divName = divDoc.data()['nama'] as String? ?? divId;

        // Cari Kadiv divisi ini
        final kadiv = allUsers.firstWhere(
          (u) =>
              (u.divisiId == divId || u.divisiId?.toLowerCase() == divName.toLowerCase()) &&
              u.role.firestoreValue == 'kepala_divisi',
          orElse: () => allUsers.firstWhere(
            (u) => u.divisiId == divId && u.role.firestoreValue == 'kepala_divisi',
            orElse: () => UserProfile(
              uid: '',
              nama: 'Belum ditentukan',
              email: '',
              role: UserRole.kepalaDivisi,
              statusAkun: 'active',
            ),
          ),
        );

        // Anggota divisi
        final members = allUsers
            .where((u) => u.divisiId == divId && u.role.firestoreValue == 'anggota')
            .toList();

        // Tugas-tugas divisi ini
        final divTasks = allTasks.where((t) {
          final isSameId = t.divisiId == divId;
          final isSameName = t.divisiNama != null &&
              t.divisiNama!.toLowerCase() == divName.toLowerCase();
          return isSameId || isSameName;
        }).toList();

        divTasks.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));

        // Proker aktif (tugas terbaru yang belum tuntas atau tugas pertama)
        final activeTask = divTasks.firstWhere(
          (t) => !t.isDone,
          orElse: () => divTasks.isNotEmpty ? divTasks.first : Task(
            id: '',
            title: 'Belum ada tugas atau proker yang dialokasikan',
            description: '',
            divisiId: divId,
            createdBy: '',
            status: TaskStatus.todo,
          ),
        );

        result.add(
          DivisionPerformance(
            divisionId: divId,
            divisionName: divName,
            kadivName: kadiv.uid.isNotEmpty ? kadiv.nama : 'Belum ditentukan',
            kadivUid: kadiv.uid.isNotEmpty ? kadiv.uid : null,
            members: members,
            tasks: divTasks,
            activeProkerTitle: activeTask.title,
          ),
        );
      }

      // Urutkan alfabetis nama divisi
      result.sort((a, b) => a.divisionName.toLowerCase().compareTo(b.divisionName.toLowerCase()));
      return result;
    });
  }
}
