import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../models/app_notification.dart';
import '../models/finance_transaction.dart';
import 'notification_service.dart';

class FinanceService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FinanceService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  CollectionReference get _financeRef =>
      _firestore.collection(AppConstants.financeCollection);

  /// Mengambil satu transaksi berdasarkan ID
  Future<FinanceTransaction?> getTransactionById(String txId) async {
    try {
      final doc = await _financeRef.doc(txId).get();
      if (!doc.exists || doc.data() == null) return null;
      return FinanceTransaction.fromFirestore(doc);
    } catch (e) {
      debugPrint('[OrgaFlow FinanceService ERROR] getTransactionById: $e');
      return null;
    }
  }

  /// Mengambil data pembayaran anggota pada transaksi kas
  Future<FinancePayment?> getUserPayment(String txId, String userUid) async {
    try {
      final doc = await _financeRef
          .doc(txId)
          .collection(AppConstants.financePaymentsSubcollection)
          .doc(userUid)
          .get();
      if (!doc.exists || doc.data() == null) return null;
      return FinancePayment.fromFirestore(doc);
    } catch (e) {
      debugPrint('[OrgaFlow FinanceService ERROR] getUserPayment: $e');
      return null;
    }
  }

  /// Stream semua transaksi kas terurut dari yang terbaru
  Stream<List<FinanceTransaction>> watchTransactions() {
    return _financeRef
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FinanceTransaction.fromFirestore(doc))
              .toList(),
        );
  }

  /// Stream semua tagihan kas yang wajib dibayar anggota
  Stream<List<FinanceTransaction>> watchMemberBills() {
    return _financeRef
        .where('is_tagihan_anggota', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => FinanceTransaction.fromFirestore(doc))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  /// Stream status pembayaran anggota pada transaksi kas tertentu
  Stream<FinancePayment?> watchUserPayment(String txId, String userUid) {
    return _financeRef
        .doc(txId)
        .collection(AppConstants.financePaymentsSubcollection)
        .doc(userUid)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          return FinancePayment.fromFirestore(doc);
        });
  }

  /// Stream seluruh daftar pembayaran anggota pada suatu transaksi kas (untuk Bendahara)
  Stream<List<FinancePayment>> watchAllPaymentsForTransaction(String txId) {
    return _financeRef
        .doc(txId)
        .collection(AppConstants.financePaymentsSubcollection)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FinancePayment.fromFirestore(doc))
              .toList(),
        );
  }

  /// Membuat transaksi atau kas baru (Oleh Bendahara)
  Future<String> createTransaction({
    required String judul,
    required String deskripsi,
    required String kategori,
    required String jenis,
    required int nominal,
    bool isTagihanAnggota = false,
    String? nomorRekening,
    String? qrisUrl,
    DateTime? tenggatWaktu,
  }) async {
    final user = _auth.currentUser;
    final now = DateTime.now();

    final docRef = await _financeRef.add({
      'judul': judul.trim(),
      'deskripsi': deskripsi.trim(),
      'kategori': kategori,
      'jenis': jenis,
      'nominal': nominal,
      'is_tagihan_anggota': isTagihanAnggota,
      'nomor_rekening': nomorRekening?.trim(),
      'qris_url': qrisUrl?.trim(),
      'status_konfirmasi': 'menunggu',
      'tenggat_waktu': tenggatWaktu != null
          ? Timestamp.fromDate(tenggatWaktu)
          : null,
      'created_by': user?.uid ?? '',
      'created_at': Timestamp.fromDate(now),
    });

    // Pemicu Notifikasi Otomatis
    try {
      final notifService = NotificationService(firestore: _firestore);
      final cleanJudul = judul.trim();
      final senderUid = user?.uid ?? '';

      if (isTagihanAnggota) {
        // Broadcast tagihan ke seluruh anggota
        await notifService.createNotification(
          title: 'Tagihan Iuran Kas Baru',
          message: 'Tagihan kas "$cleanJudul" sebesar Rp $nominal telah diterbitkan.',
          type: NotificationType.finance,
          targetType: NotificationTargetType.broadcast,
          referenceId: docRef.id,
          createdBy: senderUid,
        );
      } else {
        // Notifikasi ke Ketua / Wakil Ketua untuk konfirmasi
        await notifService.createNotification(
          title: 'Transaksi Kas Perlu Konfirmasi',
          message: 'Bendahara mencatat transaksi kas "$cleanJudul" sebesar Rp $nominal.',
          type: NotificationType.finance,
          targetType: NotificationTargetType.role,
          targetRole: 'ketua',
          referenceId: docRef.id,
          createdBy: senderUid,
        );
      }

      // Konfirmasi personal ke Bendahara pembuat
      if (senderUid.isNotEmpty) {
        await notifService.createNotification(
          title: 'Berhasil Mencatat Kas',
          message: 'Transaksi "$cleanJudul" berhasil disimpan dan diajukan.',
          type: NotificationType.finance,
          targetType: NotificationTargetType.user,
          targetUserId: senderUid,
          referenceId: docRef.id,
          createdBy: senderUid,
        );
      }
    } catch (notifErr) {
      debugPrint('[OrgaFlow FinanceService WARNING] Gagal membuat notifikasi keuangan: $notifErr');
    }

    return docRef.id;
  }

  /// Konfirmasi transaksi atau rekonsiliasi kas (Oleh Ketua / Wakil Ketua)
  Future<void> confirmTransaction({
    required String txId,
    required String status, // 'dikonfirmasi'
  }) async {
    final user = _auth.currentUser;
    await _financeRef.doc(txId).update({
      'status_konfirmasi': status,
      'dikonfirmasi_oleh': user?.uid,
      'dikonfirmasi_pada': Timestamp.fromDate(DateTime.now()),
      'updated_at': Timestamp.fromDate(DateTime.now()),
    });

    try {
      final doc = await _financeRef.doc(txId).get();
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final String judul = data['judul'] as String? ?? 'Transaksi Kas';
      final String createdBy = data['created_by'] as String? ?? '';
      if (createdBy.isNotEmpty) {
        final notifService = NotificationService(firestore: _firestore);
        await notifService.createNotification(
          title: 'Transaksi Kas Dikonfirmasi',
          message: 'Transaksi "$judul" telah disetujui dan dikonfirmasi oleh Ketua.',
          type: NotificationType.finance,
          targetType: NotificationTargetType.user,
          targetUserId: createdBy,
          referenceId: txId,
          createdBy: user?.uid ?? '',
        );
      }
    } catch (e) {
      debugPrint('[OrgaFlow FinanceService WARNING] Notif confirm error: $e');
    }
  }

  /// Menghapus transaksi kas (Oleh Bendahara)
  Future<void> deleteTransaction(String txId) async {
    await _financeRef.doc(txId).delete();
  }

  /// Mengirim bukti pembayaran kas (Oleh Anggota / Kadiv)
  Future<void> submitPayment({
    required String txId,
    required String userUid,
    required String userNama,
    String? userNim,
    String? divisiId,
    required int nominal,
    required String metodeBayar,
    String? buktiTransferUrl,
    String? catatanAnggota,
  }) async {
    final paymentDoc = _financeRef
        .doc(txId)
        .collection(AppConstants.financePaymentsSubcollection)
        .doc(userUid);

    await paymentDoc.set({
      'user_uid': userUid,
      'user_nama': userNama,
      'user_nim': userNim,
      'divisi_id': divisiId,
      'nominal': nominal,
      'status': 'menunggu_verifikasi',
      'metode_bayar': metodeBayar,
      'bukti_transfer_url': buktiTransferUrl ?? '',
      'catatan_anggota': catatanAnggota ?? '',
      'paid_at': Timestamp.fromDate(DateTime.now()),
    }, SetOptions(merge: true));

    // Notifikasi ke Bendahara bahwa ada pembayaran baru menunggu verifikasi
    try {
      final doc = await _financeRef.doc(txId).get();
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final String judul = data['judul'] as String? ?? 'Iuran Kas';
      final notifService = NotificationService(firestore: _firestore);
      await notifService.createNotification(
        title: 'Bukti Pembayaran Kas Masuk',
        message: '$userNama telah mengirim bukti pembayaran untuk "$judul". Silakan verifikasi.',
        type: NotificationType.finance,
        targetType: NotificationTargetType.role,
        targetRole: 'bendahara',
        referenceId: txId,
        createdBy: userUid,
      );
    } catch (e) {
      debugPrint('[OrgaFlow FinanceService WARNING] Notif submitPayment error: $e');
    }
  }

  /// Verifikasi pembayaran kas anggota (Oleh Bendahara: 'lunas' atau 'ditolak')
  Future<void> verifyPayment({
    required String txId,
    required String userUid,
    required String status, // 'lunas' atau 'ditolak'
    String? catatanBendahara,
  }) async {
    final user = _auth.currentUser;
    final paymentDoc = _financeRef
        .doc(txId)
        .collection(AppConstants.financePaymentsSubcollection)
        .doc(userUid);

    await paymentDoc.update({
      'status': status,
      'catatan_bendahara': catatanBendahara ?? '',
      'verified_by': user?.uid,
      'verified_at': Timestamp.fromDate(DateTime.now()),
    });

    // Notifikasi ke Anggota mengenai hasil verifikasi pembayaran
    try {
      final doc = await _financeRef.doc(txId).get();
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final String judul = data['judul'] as String? ?? 'Iuran Kas';
      final bool isLunas = status == 'lunas';
      final notifService = NotificationService(firestore: _firestore);
      await notifService.createNotification(
        title: isLunas ? 'Pembayaran Kas Diverifikasi' : 'Pembayaran Kas Ditolak',
        message: isLunas
            ? 'Pembayaran kas Anda untuk "$judul" telah dinyatakan lunas.'
            : 'Pembayaran kas Anda untuk "$judul" ditolak. ${catatanBendahara != null && catatanBendahara.isNotEmpty ? 'Catatan: $catatanBendahara' : 'Silakan periksa kembali bukti bayar.'}',
        type: NotificationType.finance,
        targetType: NotificationTargetType.user,
        targetUserId: userUid,
        referenceId: txId,
        createdBy: user?.uid ?? '',
      );
    } catch (e) {
      debugPrint('[OrgaFlow FinanceService WARNING] Notif verifyPayment error: $e');
    }
  }
}
