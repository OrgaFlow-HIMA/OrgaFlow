import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_orgaflow/enums/user_role.dart';
import 'package:flutter_orgaflow/models/user_profile.dart';

void main() {
  group('UserProfile Model Tests', () {
    test('Berhasil mem-parsing profil dengan data lengkap', () {
      final data = {
        'uid': 'user-123',
        'nama': 'Fakhri Herlambang',
        'email': 'fakhri@hima-ti.org',
        'nim': '22001122',
        'role': 'ketua',
        'divisi_id': 'divisi-inti',
        'foto_url': 'https://example.com/foto.jpg',
        'wajib_ganti_password': false,
        'status_akun': 'aktif',
      };

      final profile = UserProfile.fromMap(data, 'user-123');

      expect(profile.uid, 'user-123');
      expect(profile.nama, 'Fakhri Herlambang');
      expect(profile.email, 'fakhri@hima-ti.org');
      expect(profile.nim, '22001122');
      expect(profile.role, UserRole.ketua);
      expect(profile.role.isPengurus, isTrue);
      expect(profile.divisiId, 'divisi-inti');
      expect(profile.wajibGantiPassword, isFalse);
      expect(profile.statusAkun, 'aktif');
      expect(profile.isActive, isTrue);
    });

    test('Melemparkan InvalidRoleException jika role tidak valid', () {
      final invalidData = {
        'uid': 'user-999',
        'nama': 'Hacker',
        'email': 'hacker@example.com',
        'role': 'admin', // Bukan role resmi OrgaFlow
        'status_akun': 'aktif',
      };

      expect(
        () => UserProfile.fromMap(invalidData, 'user-999'),
        throwsA(isA<InvalidRoleException>()),
      );
    });

    test('Menangani parsing jika field opsional bernilai null', () {
      final minimalData = {
        'nama': 'Budi Santoso',
        'email': 'budi@example.com',
        'role': 'anggota',
        'wajib_ganti_password': true,
        'status_akun': 'aktif',
      };

      final profile = UserProfile.fromMap(minimalData, 'doc-uid-abc');

      expect(profile.uid, 'doc-uid-abc');
      expect(profile.nim, isNull);
      expect(profile.divisiId, isNull);
      expect(profile.fotoUrl, isNull);
      expect(profile.role, UserRole.anggota);
      expect(profile.role.isAnggota, isTrue);
      expect(profile.wajibGantiPassword, isTrue);
      expect(profile.isActive, isTrue);
    });

    test('Memeriksa akun nonaktif', () {
      final inactiveData = {
        'nama': 'User Nonaktif',
        'email': 'inactive@example.com',
        'role': 'anggota',
        'status_akun': 'nonaktif',
      };

      final profile = UserProfile.fromMap(inactiveData, 'user-inactive');
      expect(profile.isActive, isFalse);
    });
  });
}
