import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/announcement.dart';
import '../models/app_notification.dart';
import 'notification_service.dart';

class AnnouncementServiceException implements Exception {
  final String message;
  const AnnouncementServiceException(this.message);

  @override
  String toString() => message;
}

class AnnouncementService {
  final FirebaseFirestore _firestore;

  AnnouncementService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String announcementsCollection = 'announcements';

  CollectionReference<Map<String, dynamic>> get _announcementsRef =>
      _firestore.collection(announcementsCollection);

  /// Stream semua pengumuman terurut dari yang paling baru
  Stream<List<Announcement>> watchAnnouncements() {
    return _announcementsRef
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => Announcement.fromMap(doc.data(), doc.id))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  /// Membuat pengumuman baru oleh Sekretaris
  Future<String> createAnnouncement({
    required String createdBy,
    String? authorName,
    required String judul,
    required String deskripsi,
    required String kategori,
    required String tipe,
    String? lokasi,
    String? linkKegiatan,
    String? posterUrl,
    required DateTime tanggalWaktu,
  }) async {
    final cleanJudul = judul.trim();
    if (cleanJudul.isEmpty) {
      throw const AnnouncementServiceException('Judul pengumuman wajib diisi.');
    }
    if (createdBy.trim().isEmpty) {
      throw const AnnouncementServiceException('Pengguna tidak valid.');
    }

    try {
      final docRef = await _announcementsRef.add({
        'judul': cleanJudul,
        'deskripsi': deskripsi.trim(),
        'kategori': kategori.trim().isEmpty ? 'Informasi Umum' : kategori.trim(),
        'tipe': tipe.trim().toLowerCase(),
        if (lokasi != null && lokasi.trim().isNotEmpty) 'lokasi': lokasi.trim(),
        if (linkKegiatan != null && linkKegiatan.trim().isNotEmpty)
          'link_kegiatan': linkKegiatan.trim(),
        if (posterUrl != null && posterUrl.trim().isNotEmpty)
          'poster_url': posterUrl.trim(),
        'tanggal_waktu': Timestamp.fromDate(tanggalWaktu),
        'created_by': createdBy.trim(),
        if (authorName != null && authorName.trim().isNotEmpty)
          'author_name': authorName.trim(),
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Pemicu Notifikasi Otomatis
      try {
        final notifService = NotificationService(firestore: _firestore);
        // 1. Broadcast ke seluruh anggota & pengurus organisasi
        await notifService.createNotification(
          title: 'Pengumuman Baru: $cleanJudul',
          message: '$kategori • ${deskripsi.trim().isNotEmpty ? deskripsi.trim() : 'Buka untuk melihat detail lengkap.'}',
          type: NotificationType.general,
          targetType: NotificationTargetType.broadcast,
          createdBy: createdBy.trim(),
        );

        // 2. Konfirmasi personal untuk Sekretaris pembuat
        await notifService.createNotification(
          title: 'Berhasil Menerbitkan Pengumuman',
          message: 'Pengumuman "$cleanJudul" berhasil dipublikasikan ke seluruh anggota.',
          type: NotificationType.general,
          targetType: NotificationTargetType.user,
          targetUserId: createdBy.trim(),
          createdBy: createdBy.trim(),
        );
      } catch (notifErr) {
        debugPrint('[OrgaFlow AnnouncementService WARNING] Gagal membuat notifikasi pengumuman: $notifErr');
      }

      return docRef.id;
    } on FirebaseException catch (e) {
      debugPrint('[OrgaFlow AnnouncementService ERROR] $e');
      throw AnnouncementServiceException('Gagal menyimpan pengumuman: ${e.message ?? e.code}');
    } catch (e) {
      throw AnnouncementServiceException('Terjadi kesalahan: $e');
    }
  }

  /// Menghapus pengumuman (Khusus Sekretaris)
  Future<void> deleteAnnouncement(String id) async {
    try {
      await _announcementsRef.doc(id).delete();
    } on FirebaseException catch (e) {
      throw AnnouncementServiceException('Gagal menghapus pengumuman: ${e.message ?? e.code}');
    }
  }
}
