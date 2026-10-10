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
    required this.role,
    this.divisiId,
    this.fotoUrl,
    required this.wajibGantiPassword,
    required this.statusAkun,
    this.createdAt,
  });

  /// Status akun aktif
  bool get isActive => statusAkun.trim().toLowerCase() == 'aktif';

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
      role: role ?? this.role,
      divisiId: divisiId ?? this.divisiId,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      wajibGantiPassword: wajibGantiPassword ?? this.wajibGantiPassword,
      statusAkun: statusAkun ?? this.statusAkun,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
