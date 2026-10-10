import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../models/user_profile.dart';

class UserService {
  final FirebaseFirestore _firestore;

  UserService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Mengambil profil pengguna dari Firestore berdasarkan UID dan opsional email untuk deteksi Auto-ID
  Future<UserProfile?> getUserProfile(String uid, {String? email}) async {
    try {
      debugPrint('[OrgaFlow UserService] Mencari dokumen: users/$uid');
      final docSnapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        debugPrint(
          '[OrgaFlow UserService] Dokumen users/$uid ditemukan: ${docSnapshot.data()}',
        );
        return UserProfile.fromMap(docSnapshot.data()!, docSnapshot.id);
      }

      debugPrint('[OrgaFlow UserService] Dokumen users/$uid TIDAK DITEMUKAN!');

      // Deteksi jika dokumen dibuat dengan Auto-ID bukan UID
      if (email != null && email.trim().isNotEmpty) {
        try {
          final query = await _firestore
              .collection(AppConstants.usersCollection)
              .where('email', isEqualTo: email.trim())
              .limit(1)
              .get();

          if (query.docs.isNotEmpty) {
            final doc = query.docs.first;
            debugPrint(
              '[OrgaFlow UserService WARNING] Dokumen email ${email.trim()} ditemukan dengan Document ID: ${doc.id}, '
              'namun seharusnya Document ID = $uid!',
            );
            throw Exception(
              'Dokumen pengguna terdaftar dengan ID "${doc.id}". Document ID di Firestore WAJIB sama persis dengan User UID ("$uid"). Hapus dokumen tersebut dan buat ulang dengan ID = $uid.',
            );
          }
        } catch (e) {
          if (e.toString().contains('WAJIB sama persis')) {
            rethrow;
          }
          // Abaikan error query sekunder jika rules membatasi query
        }
      }

      return null;
    } on InvalidRoleException {
      rethrow;
    } on FirebaseException catch (e) {
      debugPrint(
        '[OrgaFlow UserService ERROR] FirebaseException: ${e.code} - ${e.message}',
      );
      if (e.code == 'permission-denied') {
        throw Exception(
          'Izin akses Firestore ditolak (permission-denied). Pastikan Security Rules di Firebase Console sudah diatur dan di-Publish.',
        );
      }
      throw Exception('Gagal memuat profil pengguna: ${e.message ?? e.code}');
    } catch (e) {
      debugPrint('[OrgaFlow UserService ERROR] $e');
      rethrow;
    }
  }

  /// Memperbarui status kewajiban ganti password pengguna di Firestore
  Future<void> updatePasswordStatus(
    String uid, {
    required bool wajibGantiPassword,
  }) async {
    try {
      await _firestore.collection(AppConstants.usersCollection).doc(uid).update(
        {'wajib_ganti_password': wajibGantiPassword},
      );
    } on FirebaseException catch (e) {
      throw Exception(
        'Gagal memperbarui status password di database: ${e.message ?? e.code}',
      );
    } catch (e) {
      throw Exception('Terjadi kesalahan saat memperbarui status password: $e');
    }
  }
}
