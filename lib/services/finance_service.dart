import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/constants/app_constants.dart';
import '../models/finance_transaction.dart';

class FinanceService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FinanceService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  CollectionReference get _financeRef =>
      _firestore.collection(AppConstants.financeCollection);

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
  }
}
