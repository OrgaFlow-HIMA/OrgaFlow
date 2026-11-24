import 'package:cloud_firestore/cloud_firestore.dart';

enum AttendanceStatus {
  hadir('H', 'Hadir'),
  izin('I', 'Izin'),
  sakit('S', 'Sakit'),
  alpha('A', 'Alpha');

  final String code;
  final String label;

  const AttendanceStatus(this.code, this.label);

  static AttendanceStatus fromCode(String? code) {
    switch (code?.trim().toUpperCase()) {
      case 'H':
        return AttendanceStatus.hadir;
      case 'I':
        return AttendanceStatus.izin;
      case 'S':
        return AttendanceStatus.sakit;
      case 'A':
      default:
        return AttendanceStatus.alpha;
    }
  }
}

class AttendanceRecord {
  final String id;
  final String agendaId;
  final String? agendaJudul;
  final String userId;
  final String nama;
  final String email;
  final String? nim;
  final String? role;
  final String? divisiId;
  final AttendanceStatus status;
  final String? keterangan;
  final String? updatedBy;
  final DateTime? updatedAt;

  const AttendanceRecord({
    required this.id,
    required this.agendaId,
    this.agendaJudul,
    required this.userId,
    required this.nama,
    required this.email,
    this.nim,
    this.role,
    this.divisiId,
    this.status = AttendanceStatus.alpha,
    this.keterangan,
    this.updatedBy,
    this.updatedAt,
  });

  factory AttendanceRecord.fromMap(Map<String, dynamic> data, String documentId) {
    DateTime? parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return AttendanceRecord(
      id: documentId,
      agendaId: (data['agenda_id'] as String?)?.trim() ?? '',
      agendaJudul: (data['agenda_judul'] as String?)?.trim(),
      userId: (data['user_id'] as String?)?.trim() ?? '',
      nama: (data['nama'] as String?)?.trim() ?? 'Pengguna',
      email: (data['email'] as String?)?.trim() ?? '',
      nim: (data['nim'] as String?)?.trim(),
      role: (data['role'] as String?)?.trim(),
      divisiId: (data['divisi_id'] as String?)?.trim(),
      status: AttendanceStatus.fromCode(data['status'] as String?),
      keterangan: (data['keterangan'] as String?)?.trim(),
      updatedBy: (data['updated_by'] as String?)?.trim(),
      updatedAt: parseDate(data['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'agenda_id': agendaId,
      if (agendaJudul != null) 'agenda_judul': agendaJudul,
      'user_id': userId,
      'nama': nama,
      'email': email,
      if (nim != null) 'nim': nim,
      if (role != null) 'role': role,
      if (divisiId != null) 'divisi_id': divisiId,
      'status': status.code,
      if (keterangan != null) 'keterangan': keterangan,
      if (updatedBy != null) 'updated_by': updatedBy,
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  AttendanceRecord copyWith({
    String? id,
    String? agendaId,
    String? agendaJudul,
    String? userId,
    String? nama,
    String? email,
    String? nim,
    String? role,
    String? divisiId,
    AttendanceStatus? status,
    String? keterangan,
    String? updatedBy,
    DateTime? updatedAt,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      agendaId: agendaId ?? this.agendaId,
      agendaJudul: agendaJudul ?? this.agendaJudul,
      userId: userId ?? this.userId,
      nama: nama ?? this.nama,
      email: email ?? this.email,
      nim: nim ?? this.nim,
      role: role ?? this.role,
      divisiId: divisiId ?? this.divisiId,
      status: status ?? this.status,
      keterangan: keterangan ?? this.keterangan,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
