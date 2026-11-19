import 'package:cloud_firestore/cloud_firestore.dart';

class Agenda {
  final String id;
  final String judul;
  final String deskripsi;
  final String kategori;
  final String tipe; // 'online' atau 'offline'
  final String lokasi;
  final String? linkMeeting;
  final DateTime tanggalWaktu;
  final DateTime? selesaiWaktu;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Agenda({
    required this.id,
    required this.judul,
    required this.deskripsi,
    required this.kategori,
    required this.tipe,
    required this.lokasi,
    this.linkMeeting,
    required this.tanggalWaktu,
    this.selesaiWaktu,
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  bool get isOnline => tipe.trim().toLowerCase() == 'online';

  bool get isPast {
    final now = DateTime.now();
    if (selesaiWaktu != null) {
      return now.isAfter(selesaiWaktu!);
    }
    return now.isAfter(tanggalWaktu.add(const Duration(hours: 3)));
  }

  /// Menghitung status tag seperti: "Hari Ini", "Besok", "Mendatang", "Selesai"
  String get statusTag {
    if (isPast) return 'Selesai';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(
      tanggalWaktu.year,
      tanggalWaktu.month,
      tanggalWaktu.day,
    );

    final difference = eventDay.difference(today).inDays;
    if (difference == 0) return 'Hari Ini';
    if (difference == 1) return 'Besok';
    return 'Mendatang';
  }

  bool get isStatusDanger => statusTag == 'Hari Ini' || statusTag == 'Besok';

  String get formattedDateTime {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final day = tanggalWaktu.day;
    final month = months[tanggalWaktu.month - 1];
    final year = tanggalWaktu.year;
    final hour = tanggalWaktu.hour.toString().padLeft(2, '0');
    final minute = tanggalWaktu.minute.toString().padLeft(2, '0');

    String result = '$day $month $year • $hour:$minute WIB';
    if (selesaiWaktu != null) {
      final endHour = selesaiWaktu!.hour.toString().padLeft(2, '0');
      final endMinute = selesaiWaktu!.minute.toString().padLeft(2, '0');
      result = '$day $month $year • $hour:$minute - $endHour:$endMinute WIB';
    }
    return result;
  }

  factory Agenda.fromMap(Map<String, dynamic> data, String documentId) {
    return Agenda(
      id: documentId,
      judul: (data['judul'] as String?)?.trim() ?? 'Agenda Tanpa Judul',
      deskripsi: (data['deskripsi'] as String?)?.trim() ?? '',
      kategori: (data['kategori'] as String?)?.trim() ?? 'Umum',
      tipe: (data['tipe'] as String?)?.trim() ?? 'offline',
      lokasi: (data['lokasi'] as String?)?.trim() ?? 'Tempat belum ditentukan',
      linkMeeting: (data['link_meeting'] as String?)?.trim(),
      tanggalWaktu: _parseTimestamp(data['tanggal_waktu']) ?? DateTime.now(),
      selesaiWaktu: _parseTimestamp(data['selesai_waktu']),
      createdBy: (data['created_by'] as String?)?.trim() ?? '',
      createdAt: _parseTimestamp(data['created_at']),
      updatedAt: _parseTimestamp(data['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'judul': judul,
      'deskripsi': deskripsi,
      'kategori': kategori,
      'tipe': tipe,
      'lokasi': lokasi,
      if (linkMeeting != null && linkMeeting!.isNotEmpty)
        'link_meeting': linkMeeting,
      'tanggal_waktu': Timestamp.fromDate(tanggalWaktu),
      if (selesaiWaktu != null)
        'selesai_waktu': Timestamp.fromDate(selesaiWaktu!),
      'created_by': createdBy,
      'created_at': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  Agenda copyWith({
    String? id,
    String? judul,
    String? deskripsi,
    String? kategori,
    String? tipe,
    String? lokasi,
    String? linkMeeting,
    DateTime? tanggalWaktu,
    DateTime? selesaiWaktu,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Agenda(
      id: id ?? this.id,
      judul: judul ?? this.judul,
      deskripsi: deskripsi ?? this.deskripsi,
      kategori: kategori ?? this.kategori,
      tipe: tipe ?? this.tipe,
      lokasi: lokasi ?? this.lokasi,
      linkMeeting: linkMeeting ?? this.linkMeeting,
      tanggalWaktu: tanggalWaktu ?? this.tanggalWaktu,
      selesaiWaktu: selesaiWaktu ?? this.selesaiWaktu,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime? _parseTimestamp(Object? raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    return null;
  }
}
