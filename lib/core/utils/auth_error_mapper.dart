import 'package:firebase_auth/firebase_auth.dart';

class AuthErrorMapper {
  AuthErrorMapper._();

  /// Memetakan error code dari Firebase Authentication ke pesan Bahasa Indonesia yang ramah dan aman.
  /// Menghindari kebocoran informasi sensitif sistem atau stack trace.
  static String mapFirebaseAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-credential':
      case 'user-not-found':
      case 'wrong-password':
        return 'Email atau password tidak sesuai.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'user-disabled':
        return 'Akun Anda sedang tidak aktif. Silakan hubungi pengurus.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan masuk yang gagal. Silakan tunggu beberapa saat lagi.';
      case 'network-request-failed':
        return 'Terjadi gangguan koneksi. Silakan periksa jaringan internet Anda.';
      case 'weak-password':
        return 'Password terlalu lemah. Gunakan minimal 6 karakter.';
      case 'requires-recent-login':
        return 'Sesi autentikasi telah berakhir. Silakan masuk kembali sebelum mengganti password.';
      default:
        return 'Terjadi kesalahan saat autentikasi. Silakan coba beberapa saat lagi.';
    }
  }

  /// Memetakan error umum atau Firestore exception
  static String mapGeneralError(Object error) {
    if (error is FirebaseAuthException) {
      return mapFirebaseAuthError(error);
    }
    return error.toString().replaceFirst('Exception: ', '');
  }
}
