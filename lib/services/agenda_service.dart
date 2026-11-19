import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../models/agenda.dart';

class AgendaServiceException implements Exception {
  final String message;
  const AgendaServiceException(this.message);

  @override
  String toString() => message;
}

class AgendaService {
  final FirebaseFirestore _firestore;

  AgendaService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _agendas =>
      _firestore.collection(AppConstants.agendasCollection);

  /// Stream real-time seluruh agenda, diurutkan dari yang paling dekat
  Stream<List<Agenda>> watchAgendas() {
    return _agendas.snapshots().map((snapshot) {
      final list = <Agenda>[];
      for (final doc in snapshot.docs) {
        try {
          list.add(Agenda.fromMap(doc.data(), doc.id));
        } catch (e) {
          debugPrint(
            '[OrgaFlow AgendaService] Gagal parse agenda ${doc.id}: $e',
          );
        }
      }

      // Urutkan berdasarkan tanggal pelaksanaan (paling dekat lebih awal)
      list.sort((a, b) => a.tanggalWaktu.compareTo(b.tanggalWaktu));
      return list;
    });
  }

  /// Membuat agenda baru (Khusus Sekretaris)
  Future<String> createAgenda({
    required String createdBy,
    required String judul,
    required String deskripsi,
    required String kategori,
    required String tipe,
    required String lokasi,
    String? linkMeeting,
    required DateTime tanggalWaktu,
    DateTime? selesaiWaktu,
  }) async {
    final cleanJudul = judul.trim();
    if (cleanJudul.isEmpty) {
      throw const AgendaServiceException('Judul agenda tidak boleh kosong.');
    }
    if (createdBy.trim().isEmpty) {
      throw const AgendaServiceException('Pengguna tidak valid.');
    }

    try {
      final docRef = await _agendas.add({
        'judul': cleanJudul,
        'deskripsi': deskripsi.trim(),
        'kategori': kategori.trim().isEmpty ? 'Umum' : kategori.trim(),
        'tipe': tipe.trim().toLowerCase(),
        'lokasi': lokasi.trim(),
        if (linkMeeting != null && linkMeeting.trim().isNotEmpty)
          'link_meeting': linkMeeting.trim(),
        'tanggal_waktu': Timestamp.fromDate(tanggalWaktu),
        if (selesaiWaktu != null)
          'selesai_waktu': Timestamp.fromDate(selesaiWaktu),
        'created_by': createdBy.trim(),
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } on FirebaseException catch (e) {
      debugPrint(
        '[OrgaFlow AgendaService ERROR] create: ${e.code} - ${e.message}',
      );
      throw AgendaServiceException(
        'Gagal menyimpan agenda: ${e.message ?? e.code}',
      );
    } catch (e) {
      throw AgendaServiceException('Terjadi kesalahan: $e');
    }
  }

  /// Memperbarui agenda yang sudah ada (Khusus Sekretaris)
  Future<void> updateAgenda({
    required String agendaId,
    required String judul,
    required String deskripsi,
    required String kategori,
    required String tipe,
    required String lokasi,
    String? linkMeeting,
    required DateTime tanggalWaktu,
    DateTime? selesaiWaktu,
  }) async {
    final cleanJudul = judul.trim();
    if (cleanJudul.isEmpty) {
      throw const AgendaServiceException('Judul agenda tidak boleh kosong.');
    }

    try {
      await _agendas.doc(agendaId).update({
        'judul': cleanJudul,
        'deskripsi': deskripsi.trim(),
        'kategori': kategori.trim().isEmpty ? 'Umum' : kategori.trim(),
        'tipe': tipe.trim().toLowerCase(),
        'lokasi': lokasi.trim(),
        'link_meeting': (linkMeeting != null && linkMeeting.trim().isNotEmpty)
            ? linkMeeting.trim()
            : FieldValue.delete(),
        'tanggal_waktu': Timestamp.fromDate(tanggalWaktu),
        'selesai_waktu': selesaiWaktu != null
            ? Timestamp.fromDate(selesaiWaktu)
            : FieldValue.delete(),
        'updated_at': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      debugPrint(
        '[OrgaFlow AgendaService ERROR] update: ${e.code} - ${e.message}',
      );
      throw AgendaServiceException(
        'Gagal memperbarui agenda: ${e.message ?? e.code}',
      );
    } catch (e) {
      throw AgendaServiceException('Terjadi kesalahan: $e');
    }
  }

  /// Menghapus agenda (Khusus Sekretaris)
  Future<void> deleteAgenda(String agendaId) async {
    try {
      await _agendas.doc(agendaId).delete();
    } on FirebaseException catch (e) {
      debugPrint(
        '[OrgaFlow AgendaService ERROR] delete: ${e.code} - ${e.message}',
      );
      throw AgendaServiceException(
        'Gagal menghapus agenda: ${e.message ?? e.code}',
      );
    } catch (e) {
      throw AgendaServiceException('Terjadi kesalahan: $e');
    }
  }
}
