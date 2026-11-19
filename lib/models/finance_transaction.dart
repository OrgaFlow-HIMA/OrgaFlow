import 'package:cloud_firestore/cloud_firestore.dart';

class FinancePayment {
  final String id;
  final String userUid;
  final String userNama;
  final String? userNim;
  final String? divisiId;
  final int nominal;
  final String status; // 'belum_bayar', 'menunggu_verifikasi', 'lunas', 'ditolak'
  final String? metodeBayar; // 'qris', 'transfer_bank', 'tunai'
  final String? buktiTransferUrl;
  final String? catatanAnggota;
  final String? catatanBendahara;
  final DateTime? paidAt;
  final String? verifiedBy;
  final DateTime? verifiedAt;

  const FinancePayment({
    required this.id,
    required this.userUid,
    required this.userNama,
    this.userNim,
    this.divisiId,
    required this.nominal,
    this.status = 'belum_bayar',
    this.metodeBayar,
    this.buktiTransferUrl,
    this.catatanAnggota,
    this.catatanBendahara,
    this.paidAt,
    this.verifiedBy,
    this.verifiedAt,
  });

  bool get isLunas => status == 'lunas';
  bool get isMenungguVerifikasi => status == 'menunggu_verifikasi';
  bool get isDitolak => status == 'ditolak';
  bool get isBelumBayar => status == 'belum_bayar';

  factory FinancePayment.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return FinancePayment(
      id: doc.id,
      userUid: data['user_uid'] as String? ?? doc.id,
      userNama: data['user_nama'] as String? ?? 'Anggota',
      userNim: data['user_nim'] as String?,
      divisiId: data['divisi_id'] as String?,
      nominal: (data['nominal'] as num?)?.toInt() ?? 0,
      status: data['status'] as String? ?? 'belum_bayar',
      metodeBayar: data['metode_bayar'] as String?,
      buktiTransferUrl: data['bukti_transfer_url'] as String?,
      catatanAnggota: data['catatan_anggota'] as String?,
      catatanBendahara: data['catatan_bendahara'] as String?,
      paidAt: (data['paid_at'] as Timestamp?)?.toDate(),
      verifiedBy: data['verified_by'] as String?,
      verifiedAt: (data['verified_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_uid': userUid,
      'user_nama': userNama,
      if (userNim != null) 'user_nim': userNim,
      if (divisiId != null) 'divisi_id': divisiId,
      'nominal': nominal,
      'status': status,
      if (metodeBayar != null) 'metode_bayar': metodeBayar,
      if (buktiTransferUrl != null) 'bukti_transfer_url': buktiTransferUrl,
      if (catatanAnggota != null) 'catatan_anggota': catatanAnggota,
      if (catatanBendahara != null) 'catatan_bendahara': catatanBendahara,
      if (paidAt != null) 'paid_at': Timestamp.fromDate(paidAt!),
      if (verifiedBy != null) 'verified_by': verifiedBy,
      if (verifiedAt != null) 'verified_at': Timestamp.fromDate(verifiedAt!),
    };
  }
}

class FinanceTransaction {
  final String id;
  final String judul;
  final String deskripsi;
  final String kategori; // 'iuran', 'operasional', 'kegiatan', 'dana_usaha'
  final String jenis; // 'masuk', 'keluar'
  final int nominal;
  final bool isTagihanAnggota;
  final String? nomorRekening;
  final String? qrisUrl;
  final String statusKonfirmasi; // 'menunggu', 'dikonfirmasi'
  final String? dikonfirmasiOleh;
  final DateTime? dikonfirmasiPada;
  final DateTime? tenggatWaktu;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const FinanceTransaction({
    required this.id,
    required this.judul,
    required this.deskripsi,
    required this.kategori,
    required this.jenis,
    required this.nominal,
    this.isTagihanAnggota = false,
    this.nomorRekening,
    this.qrisUrl,
    this.statusKonfirmasi = 'menunggu',
    this.dikonfirmasiOleh,
    this.dikonfirmasiPada,
    this.tenggatWaktu,
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isIncome => jenis == 'masuk';
  bool get isExpense => jenis == 'keluar';
  bool get isDikonfirmasi => statusKonfirmasi == 'dikonfirmasi';
  bool get isIuran => isTagihanAnggota || kategori == 'iuran';

  factory FinanceTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return FinanceTransaction(
      id: doc.id,
      judul: data['judul'] as String? ?? 'Tanpa Judul',
      deskripsi: data['deskripsi'] as String? ?? '',
      kategori: data['kategori'] as String? ?? 'operasional',
      jenis: data['jenis'] as String? ?? 'masuk',
      nominal: (data['nominal'] as num?)?.toInt() ?? 0,
      isTagihanAnggota: data['is_tagihan_anggota'] as bool? ?? false,
      nomorRekening: data['nomor_rekening'] as String?,
      qrisUrl: data['qris_url'] as String?,
      statusKonfirmasi: data['status_konfirmasi'] as String? ?? 'menunggu',
      dikonfirmasiOleh: data['dikonfirmasi_oleh'] as String?,
      dikonfirmasiPada: (data['dikonfirmasi_pada'] as Timestamp?)?.toDate(),
      tenggatWaktu: (data['tenggat_waktu'] as Timestamp?)?.toDate(),
      createdBy: data['created_by'] as String? ?? '',
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'judul': judul,
      'deskripsi': deskripsi,
      'kategori': kategori,
      'jenis': jenis,
      'nominal': nominal,
      'is_tagihan_anggota': isTagihanAnggota,
      if (nomorRekening != null) 'nomor_rekening': nomorRekening,
      if (qrisUrl != null) 'qris_url': qrisUrl,
      'status_konfirmasi': statusKonfirmasi,
      if (dikonfirmasiOleh != null) 'dikonfirmasi_oleh': dikonfirmasiOleh,
      if (dikonfirmasiPada != null)
        'dikonfirmasi_pada': Timestamp.fromDate(dikonfirmasiPada!),
      if (tenggatWaktu != null)
        'tenggat_waktu': Timestamp.fromDate(tenggatWaktu!),
      'created_by': createdBy,
      'created_at': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updated_at': Timestamp.fromDate(updatedAt!),
    };
  }
}
