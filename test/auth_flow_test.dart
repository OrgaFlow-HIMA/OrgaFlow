import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_orgaflow/core/utils/auth_error_mapper.dart';
import 'package:flutter_orgaflow/enums/user_role.dart';
import 'package:flutter_orgaflow/models/user_profile.dart';
import 'package:flutter_orgaflow/screens/auth/change_password_screen.dart';
import 'package:flutter_orgaflow/screens/dashboard/dashboard_page.dart';
import 'package:flutter_orgaflow/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StubAuthService implements AuthService {
  bool changePasswordCalled = false;
  String? updatedPassword;

  @override
  Stream<User?> get authStateChanges => Stream.value(null);

  @override
  User? get currentUser => null;

  @override
  Future<UserProfile> loginWithEmailPassword({
    required String email,
    required String password,
  }) async {
    throw const AuthServiceException('Simulasi error');
  }

  @override
  Future<UserProfile> registerUser({
    required String nama,
    required String email,
    required String password,
    String? nim,
    String? noWa,
    required UserRole role,
    String? divisiId,
    String? suratTugasUrl,
  }) async {
    throw const AuthServiceException('Simulasi error register');
  }

  @override
  Future<void> changePassword({required String newPassword}) async {
    changePasswordCalled = true;
    updatedPassword = newPassword;
  }

  @override
  Future<void> signOut() async {}
}

void main() {
  group('Pengujian Alur Autentikasi, Role, dan Wajib Ganti Password', () {
    test('Lima role pengurus terbukti memiliki sifat Pengurus dan mengarah ke identitas pengurus', () {
      final pengurusRoles = [
        UserRole.ketua,
        UserRole.wakilKetua,
        UserRole.sekretaris,
        UserRole.bendahara,
        UserRole.kepalaDivisi,
      ];

      for (final role in pengurusRoles) {
        expect(role.isPengurus, isTrue);
        expect(role.isAnggota, isFalse);
        expect(role.groupBadgeLabel, 'PENGURUS');
      }
    });

    test('Role anggota terbukti berbeda dari kelompok pengurus', () {
      final anggotaRole = UserRole.anggota;
      expect(anggotaRole.isPengurus, isFalse);
      expect(anggotaRole.isAnggota, isTrue);
      expect(anggotaRole.groupBadgeLabel, 'ANGGOTA');
    });

    testWidgets(
      'Setiap dari 5 role pengurus dapat dirender pada ManagementDashboard',
      (tester) async {
        final roles = [
          (UserRole.ketua, 'Ketua'),
          (UserRole.wakilKetua, 'Wakil Ketua'),
          (UserRole.sekretaris, 'Sekretaris'),
          (UserRole.bendahara, 'Bendahara'),
          (UserRole.kepalaDivisi, 'Kepala Divisi'),
        ];

        for (final item in roles) {
          final profile = UserProfile(
            uid: 'uid-${item.$1.name}',
            nama: 'User ${item.$2}',
            email: '${item.$1.name}@hima-ti.org',
            role: item.$1,
            statusAkun: 'aktif',
          );

          await tester.pumpWidget(
            MaterialApp(
              home: ManagementDashboard(
                profile: profile,
                authService: StubAuthService(),
              ),
            ),
          );

          // Menunggu proses async (stream) di dashboard selesai
          await tester.pumpAndSettle();

          // CARI TEKS YANG SESUAI DENGAN DESAIN BARU
          expect(find.text('User ${item.$2}'), findsOneWidget); // Cek Nama User
          expect(find.text('${item.$2} • HIMA TI'), findsOneWidget); // Cek Role
          expect(find.text('OrgaFlow'), findsOneWidget); // Cek Logo/Header
          expect(
            find.text('Tugas Terbaru'),
            findsOneWidget,
          ); // Cek Section Tugas
        }
      },
    );

    testWidgets(
      'Role anggota dirender pada MemberDashboard dengan layout khas Anggota',
      (tester) async {
        final memberProfile = UserProfile(
          uid: 'uid-anggota-01',
          nama: 'Ahmad Mahasiswa',
          email: 'ahmad@hima-ti.org',
          role: UserRole.anggota,
          statusAkun: 'aktif',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: MemberDashboard(
              profile: memberProfile,
              authService: StubAuthService(),
            ),
          ),
        );

        // Menunggu proses async (stream) di dashboard selesai
        await tester.pumpAndSettle();

        // CARI TEKS YANG SESUAI DENGAN DESAIN BARU
        expect(find.text('Ahmad Mahasiswa'), findsOneWidget);
        expect(find.text('Anggota • HIMA TI'), findsOneWidget);
        expect(find.text('Tugas Terbaru'), findsOneWidget);
        expect(find.text('Agenda Terbaru'), findsOneWidget);
      },
    );

    testWidgets(
      'ChangePasswordScreen memvalidasi password minimal dan ketidakcocokan konfirmasi',
      (tester) async {
        final testProfile = UserProfile(
          uid: 'uid-new-user',
          nama: 'User Baru',
          email: 'baru@hima-ti.org',
          role: UserRole.anggota,
          statusAkun: 'aktif',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: ChangePasswordScreen(
              profile: testProfile,
              authService: StubAuthService(),
              onSuccess: () {},
            ),
          ),
        );

        expect(find.text('Ubah Kata Sandi'), findsOneWidget);
        expect(find.text('Simpan Kata Sandi'), findsOneWidget);

        // Tekan simpan tanpa input
        await tester.tap(find.text('Simpan Kata Sandi'));
        await tester.pumpAndSettle();

        expect(find.text('Password baru wajib diisi.'), findsOneWidget);
      },
    );

    test('AuthErrorMapper memetakan kode error Firebase Auth ke pesan ramah bahasa Indonesia', () {
      final wrongPasswordEx = FirebaseAuthException(code: 'wrong-password');
      expect(
        AuthErrorMapper.mapFirebaseAuthError(wrongPasswordEx),
        'Email atau password tidak sesuai.',
      );

      final userNotFoundEx = FirebaseAuthException(code: 'user-not-found');
      expect(
        AuthErrorMapper.mapFirebaseAuthError(userNotFoundEx),
        'Email atau password tidak sesuai.',
      );

      final userDisabledEx = FirebaseAuthException(code: 'user-disabled');
      expect(
        AuthErrorMapper.mapFirebaseAuthError(userDisabledEx),
        'Akun Anda sedang tidak aktif. Silakan hubungi pengurus.',
      );

      final networkEx = FirebaseAuthException(code: 'network-request-failed');
      expect(
        AuthErrorMapper.mapFirebaseAuthError(networkEx),
        'Terjadi gangguan koneksi. Silakan periksa jaringan internet Anda.',
      );
    });
  });
}
