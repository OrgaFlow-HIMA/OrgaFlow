import 'package:cloud_firestore/cloud_firestore.dart';
import '../enums/user_role.dart';

class InvalidRoleException implements Exception {
  final String message;
  const InvalidRoleException(this.message);

  @override
  String toString() => message;
}

class UserProfile {
  final String uid;
  final String nama;
  final String email;
  final String? nim;
  final String? noWa;
  final UserRole role;
  final String? divisiId;
  final String? fotoUrl;
  final bool wajibGantiPassword;
  final String statusAkun;
  final DateTime? createdAt;

  const UserProfile({
    required this.uid,
    required this.nama,
    required this.email,
    this.nim,
    this.noWa,
    required this.role,
    this.divisiId,
    this.fotoUrl,
    required this.wajibGantiPassword,
    required this.statusAkun,
    this.createdAt,
  });

  /// Status akun aktif
  bool get isActive => statusAkun.trim().toLowerCase() == 'aktif';

  /// Menghitung periode dari 4 digit depan NIM (misal NIM 2024xxxx -> "Periode 2024 / 2025")
  String get periode {
    if (nim == null || nim!.length < 4) {
      final currentYear = DateTime.now().year;
      return 'Periode $currentYear / ${currentYear + 1}';
    }
    final fourDigits = nim!.substring(0, 4);
    final year = int.tryParse(fourDigits);
    if (year != null && year > 2000 && year < 2100) {
      return 'Periode $year / ${year + 1}';
    }
    // Jika 2 digit tahun, misal 21xxxxxx -> 2021
    final twoDigits = int.tryParse(nim!.substring(0, 2));
    if (twoDigits != null) {
      final fullYear = 2000 + twoDigits;
      return 'Periode $fullYear / ${fullYear + 1}';
    }
    return 'Periode 2024 / 2025';
  }

  /// Factory untuk parsing dokumen Cloud Firestore secara aman
  factory UserProfile.fromMap(Map<String, dynamic> data, String documentId) {
    final rawRole = data['role'] as String?;
    final parsedRole = UserRole.fromFirestore(rawRole);

    if (parsedRole == null) {
      throw const InvalidRoleException(
        'Role akun tidak valid atau tidak terdaftar. Akses ditolak.',
      );
    }

    DateTime? parsedCreatedAt;
    final rawCreatedAt = data['created_at'];
    if (rawCreatedAt is Timestamp) {
      parsedCreatedAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt is DateTime) {
      parsedCreatedAt = rawCreatedAt;
    }

    return UserProfile(
      uid: (data['uid'] as String?)?.trim().isNotEmpty == true
          ? (data['uid'] as String).trim()
          : documentId,
      nama: (data['nama'] as String?)?.trim() ?? 'Pengguna OrgaFlow',
      email: (data['email'] as String?)?.trim() ?? '',
      nim: (data['nim'] as String?)?.trim(),
      noWa: (data['no_wa'] as String?)?.trim() ?? (data['telepon'] as String?)?.trim(),
      role: parsedRole,
      divisiId: (data['divisi_id'] as String?)?.trim(),
      fotoUrl: (data['foto_url'] as String?)?.trim(),
      wajibGantiPassword: data['wajib_ganti_password'] as bool? ?? false,
      statusAkun: (data['status_akun'] as String?)?.trim() ?? 'nonaktif',
      createdAt: parsedCreatedAt,
    );
  }

  /// Konversi ke map untuk penulisan data ke Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nama': nama,
      'email': email,
      'nim': nim,
      if (noWa != null) 'no_wa': noWa,
      'role': role.firestoreValue,
      'divisi_id': divisiId,
      'foto_url': fotoUrl,
      'wajib_ganti_password': wajibGantiPassword,
      'status_akun': statusAkun,
      if (createdAt != null) 'created_at': Timestamp.fromDate(createdAt!),
    };
  }

  UserProfile copyWith({
    String? uid,
    String? nama,
    String? email,
    String? nim,
    String? noWa,
    UserRole? role,
    String? divisiId,
    String? fotoUrl,
    bool? wajibGantiPassword,
    String? statusAkun,
    DateTime? createdAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      nama: nama ?? this.nama,
      email: email ?? this.email,
      nim: nim ?? this.nim,
      noWa: noWa ?? this.noWa,
      role: role ?? this.role,
      divisiId: divisiId ?? this.divisiId,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      wajibGantiPassword: wajibGantiPassword ?? this.wajibGantiPassword,
      statusAkun: statusAkun ?? this.statusAkun,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
