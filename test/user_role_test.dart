import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_orgaflow/enums/user_role.dart';

void main() {
  group('Sistem Enam Role OrgaFlow Tests', () {
    test('Hanya memiliki tepat enam role resmi tanpa role Admin', () {
      expect(UserRole.values.length, 6);
      expect(UserRole.values, contains(UserRole.ketua));
      expect(UserRole.values, contains(UserRole.wakilKetua));
      expect(UserRole.values, contains(UserRole.sekretaris));
      expect(UserRole.values, contains(UserRole.bendahara));
      expect(UserRole.values, contains(UserRole.kepalaDivisi));
      expect(UserRole.values, contains(UserRole.anggota));
    });

    test('Parsing dari nilai Firestore valid untuk seluruh 6 role', () {
      expect(UserRole.fromFirestore('ketua'), UserRole.ketua);
      expect(UserRole.fromFirestore('wakil_ketua'), UserRole.wakilKetua);
      expect(UserRole.fromFirestore('sekretaris'), UserRole.sekretaris);
      expect(UserRole.fromFirestore('bendahara'), UserRole.bendahara);
      expect(UserRole.fromFirestore('kepala_divisi'), UserRole.kepalaDivisi);
      expect(UserRole.fromFirestore('anggota'), UserRole.anggota);
    });

    test('Case-insensitive dan whitespace-tolerant parsing', () {
      expect(UserRole.fromFirestore('  ketua  '), UserRole.ketua);
      expect(UserRole.fromFirestore('WAKIL_KETUA'), UserRole.wakilKetua);
      expect(UserRole.fromFirestore('Sekretaris'), UserRole.sekretaris);
    });

    test('Role tidak dikenal TIDAK BOLEH fallback ke anggota atau default (harus null)', () {
      expect(UserRole.fromFirestore('admin'), isNull);
      expect(UserRole.fromFirestore('superadmin'), isNull);
      expect(UserRole.fromFirestore('pembina'), isNull);
      expect(UserRole.fromFirestore('guest'), isNull);
      expect(UserRole.fromFirestore(''), isNull);
      expect(UserRole.fromFirestore(null), isNull);
    });

    test('Label resmi Bahasa Indonesia', () {
      expect(UserRole.ketua.label, 'Ketua');
      expect(UserRole.wakilKetua.label, 'Wakil Ketua');
      expect(UserRole.sekretaris.label, 'Sekretaris');
      expect(UserRole.bendahara.label, 'Bendahara');
      expect(UserRole.kepalaDivisi.label, 'Kepala Divisi');
      expect(UserRole.anggota.label, 'Anggota');
    });

    test('Pengelompokan role Pengurus vs Anggota', () {
      final pengurusRoles = [
        UserRole.ketua,
        UserRole.wakilKetua,
        UserRole.sekretaris,
        UserRole.bendahara,
        UserRole.kepalaDivisi,
      ];

      for (final role in pengurusRoles) {
        expect(role.isPengurus, isTrue, reason: '$role harus bernilai isPengurus == true');
        expect(role.isAnggota, isFalse, reason: '$role harus bernilai isAnggota == false');
        expect(role.groupBadgeLabel, 'PENGURUS');
      }

      expect(UserRole.anggota.isPengurus, isFalse);
      expect(UserRole.anggota.isAnggota, isTrue);
      expect(UserRole.anggota.groupBadgeLabel, 'ANGGOTA');
    });
  });
}
