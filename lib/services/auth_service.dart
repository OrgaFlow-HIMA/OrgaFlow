import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/auth_error_mapper.dart';
import '../enums/user_role.dart';
import '../models/user_profile.dart';
import 'user_service.dart';

class AuthServiceException implements Exception {
  final String message;
  const AuthServiceException(this.message);

  @override
  String toString() => message;
}

class AuthService {
  final FirebaseAuth _auth;
  final UserService _userService;

  AuthService({
    FirebaseAuth? auth,
    UserService? userService,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _userService = userService ?? UserService();

  /// Aliran perubahan status autentikasi pengguna
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Pengguna yang sedang aktif di Firebase Authentication
  User? get currentUser => _auth.currentUser;

  /// Mendaftarkan pengguna baru secara mandiri.
  /// Status akun awal adalah 'menunggu_persetujuan' (pending).
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
    final cleanEmail = email.trim().toLowerCase();
    final cleanNama = nama.trim();
    final cleanPassword = password;
    final cleanNim = nim?.trim();
    final cleanNoWa = noWa?.trim();

    if (cleanEmail.isEmpty) throw const AuthServiceException('Email wajib diisi.');
    if (cleanPassword.length < 6) throw const AuthServiceException('Password minimal 6 karakter.');
    if (cleanNama.isEmpty) throw const AuthServiceException('Nama lengkap wajib diisi.');
    if (role.isPengurus && (suratTugasUrl == null || suratTugasUrl.trim().isEmpty)) {
      throw const AuthServiceException('Pendaftar Pengurus wajib melampirkan berkas/tautan Surat Tugas.');
    }

    UserCredential credential;
    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: cleanPassword,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthServiceException(AuthErrorMapper.mapFirebaseAuthError(e));
    } catch (e) {
      throw const AuthServiceException('Gagal membuat akun autentikasi. Silakan coba lagi.');
    }

    final user = credential.user;
    if (user == null) {
      throw const AuthServiceException('Gagal mengidentifikasi pengguna baru.');
    }

    final now = DateTime.now();
    final newProfile = UserProfile(
      uid: user.uid,
      nama: cleanNama,
      email: cleanEmail,
      nim: cleanNim?.isNotEmpty == true ? cleanNim : null,
      noWa: cleanNoWa?.isNotEmpty == true ? cleanNoWa : null,
      role: role,
      divisiId: divisiId?.trim(),
      suratTugasUrl: suratTugasUrl?.trim(),
      statusAkun: AppConstants.statusPending,
      createdAt: now,
    );

    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .set(newProfile.toMap());
    } on FirebaseException catch (e) {
      // Jika penulisan Firestore gagal, hapus user auth agar tidak menggantung
      await user.delete();
      throw AuthServiceException('Gagal menyimpan profil pendaftaran: ${e.message ?? e.code}');
    } catch (e) {
      await user.delete();
      throw const AuthServiceException('Terjadi kesalahan saat menyimpan data pendaftaran.');
    }

    // Keluarkan dari sesi agar tidak langsung login sebelum di-ACC
    await _auth.signOut();

    return newProfile;
  }

  /// Masuk menggunakan email dan password
  /// Mengembalikan [UserProfile] jika kredensial dan data Firestore valid.
  Future<UserProfile> loginWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim();
    final cleanPassword = password;

    if (cleanEmail.isEmpty) {
      throw const AuthServiceException('Email wajib diisi.');
    }
    if (cleanPassword.isEmpty) {
      throw const AuthServiceException('Password wajib diisi.');
    }

    UserCredential credential;
    try {
      credential = await _auth.signInWithEmailAndPassword(
        email: cleanEmail,
        password: cleanPassword,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthServiceException(AuthErrorMapper.mapFirebaseAuthError(e));
    } catch (e) {
      throw const AuthServiceException(
        'Terjadi gangguan koneksi. Silakan coba lagi.',
      );
    }

    final user = credential.user;
    if (user == null) {
      await _auth.signOut();
      throw const AuthServiceException('Gagal mengidentifikasi sesi login.');
    }

    // Ambil profil dari Cloud Firestore
    UserProfile? profile;
    try {
      profile = await _userService.getUserProfile(user.uid);
    } on InvalidRoleException {
      // Role tidak valid -> keluarkan pengguna dan tolak akses
      await _auth.signOut();
      throw const AuthServiceException(
        'Role akun tidak valid. Silakan hubungi pengurus.',
      );
    } catch (e) {
      await _auth.signOut();
      throw const AuthServiceException(
        'Gagal memverifikasi data pengguna. Silakan coba lagi nanti.',
      );
    }

    // Validasi keberadaan dokumen profil pengguna
    if (profile == null) {
      await _auth.signOut();
      throw const AuthServiceException(
        'Akun belum terdaftar pada data pengguna OrgaFlow.',
      );
    }

    // Validasi status keaktifan akun
    if (profile.isPending) {
      await _auth.signOut();
      throw const AuthServiceException(
        'Akun Anda sedang menunggu verifikasi & persetujuan dari Sekretaris. Silakan cek berkala.',
      );
    }

    if (profile.isRejected) {
      final alasan = profile.catatanPersetujuan?.isNotEmpty == true
          ? ': ${profile.catatanPersetujuan}'
          : '.';
      await _auth.signOut();
      throw AuthServiceException(
        'Pendaftaran akun Anda ditolak oleh Sekretaris$alasan',
      );
    }

    if (!profile.isActive) {
      await _auth.signOut();
      throw const AuthServiceException(
        'Akun Anda sedang tidak aktif. Silakan hubungi pengurus.',
      );
    }

    return profile;
  }

  /// Memperbarui password pada Firebase Authentication dan status wajib ganti password di Firestore
  Future<void> changePassword({required String newPassword}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthServiceException(
        'Sesi login tidak ditemukan. Silakan login kembali.',
      );
    }

    if (newPassword.trim().length < 6) {
      throw const AuthServiceException('Password minimal 6 karakter.');
    }

    try {
      // Perbarui password di Firebase Auth
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw AuthServiceException(AuthErrorMapper.mapFirebaseAuthError(e));
    } catch (e) {
      throw const AuthServiceException('Gagal mengubah password pada sistem autentikasi.');
    }
  }

  /// Keluar dari sesi aplikasi
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
