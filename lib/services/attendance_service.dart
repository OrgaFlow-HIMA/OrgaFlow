import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../models/attendance_record.dart';
import '../models/user_profile.dart';

class AttendanceService {
  final FirebaseFirestore _firestore;

  AttendanceService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String attendanceCollection = 'absensi';

  /// Menghasilkan document ID unik: `{agendaId}_{userId}`
  String _generateDocId(String agendaId, String userId) {
    return '${agendaId}_$userId';
  }

  /// Aliran data absensi untuk suatu agenda tertentu (digunakan oleh Sekretaris)
  Stream<List<AttendanceRecord>> streamAttendanceForAgenda(String agendaId) {
    return _firestore
        .collection(attendanceCollection)
        .where('agenda_id', isEqualTo: agendaId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AttendanceRecord.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Aliran seluruh data riwayat absensi untuk user tertentu (semua agenda)
  Stream<List<AttendanceRecord>> streamUserAttendance(String userId) {
    return _firestore
        .collection(attendanceCollection)
        .where('user_id', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AttendanceRecord.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Mengambil daftar semua anggota & pengurus aktif yang wajib absensi (kecuali dekan)
  Future<List<UserProfile>> getAttendanceEligibleUsers() async {
    final querySnapshot = await _firestore
        .collection(AppConstants.usersCollection)
        .where('status_akun', isEqualTo: AppConstants.statusActive)
        .get();

    final users = querySnapshot.docs
        .map((doc) => UserProfile.fromMap(doc.data(), doc.id))
        // Dekan tidak wajib mengikuti absensi kegiatan
        .where((user) => user.role.firestoreValue != 'dekan')
        .toList();

    // Urutkan berdasarkan nama
    users.sort((a, b) => a.nama.toLowerCase().compareTo(b.nama.toLowerCase()));
    return users;
  }

  /// Memperbarui atau menyimpan status absensi seorang user untuk suatu agenda
  Future<void> setAttendanceStatus({
    required String agendaId,
    required String agendaJudul,
    required UserProfile user,
    required AttendanceStatus status,
    String? keterangan,
    required String secretaryUid,
  }) async {
    final docId = _generateDocId(agendaId, user.uid);
    final docRef = _firestore.collection(attendanceCollection).doc(docId);

    await docRef.set({
      'id': docId,
      'agenda_id': agendaId,
      'agenda_judul': agendaJudul,
      'user_id': user.uid,
      'nama': user.nama,
      'email': user.email,
      'nim': user.nim,
      'role': user.role.firestoreValue,
      'divisi_id': user.divisiId,
      'status': status.code,
      'keterangan': keterangan ?? '',
      'updated_by': secretaryUid,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Set semua user yang belum diabsen menjadi default tertentu (misal Hadir / Alpha) secara batch
  Future<void> batchInitializeAttendance({
    required String agendaId,
    required String agendaJudul,
    required List<UserProfile> users,
    required AttendanceStatus defaultStatus,
    required String secretaryUid,
  }) async {
    final batch = _firestore.batch();
    for (final user in users) {
      final docId = _generateDocId(agendaId, user.uid);
      final docRef = _firestore.collection(attendanceCollection).doc(docId);
      batch.set(
        docRef,
        {
          'id': docId,
          'agenda_id': agendaId,
          'agenda_judul': agendaJudul,
          'user_id': user.uid,
          'nama': user.nama,
          'email': user.email,
          'nim': user.nim,
          'role': user.role.firestoreValue,
          'divisi_id': user.divisiId,
          'status': defaultStatus.code,
          'updated_by': secretaryUid,
          'updated_at': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }
}
