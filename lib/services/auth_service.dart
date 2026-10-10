import 'package:firebase_auth/firebase_auth.dart';
import '../core/utils/auth_error_mapper.dart';
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

    try {
      // Perbarui status wajib_ganti_password di Cloud Firestore
      await _userService.updatePasswordStatus(
        user.uid,
        wajibGantiPassword: false,
      );
    } catch (e) {
      // Password auth sudah terganti, tetapi update flag firestore gagal
      throw const AuthServiceException(
        'Password berhasil diubah, namun sinkronisasi profil gagal. Silakan masuk kembali dengan password baru Anda.',
      );
    }
  }

  /// Keluar dari sesi aplikasi
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
