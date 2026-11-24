import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../enums/user_role.dart';
import '../models/user_profile.dart';

class UserService {
  final FirebaseFirestore _firestore;

  UserService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Mengambil profil pengguna dari Firestore berdasarkan UID dan opsional email untuk deteksi Auto-ID.
  /// Secara default mencoba mengambil data terbaru dari [Source.server] terlebih dahulu
  /// agar status terbaru (seperti approval sekretaris) langsung terbaca tanpa terhalang cache lokal.
  Future<UserProfile?> getUserProfile(
    String uid, {
    String? email,
    Source source = Source.serverAndCache,
  }) async {
    try {
      debugPrint(
        '[OrgaFlow UserService] Mencari dokumen: users/$uid (requested source: $source)',
      );

      // CEK SEMUA DOKUMEN DENGAN EMAIL INI DI FIRESTORE UNTUK MENDETEKSI DUPLIKASI/AUTO-ID
      if (email != null && email.trim().isNotEmpty) {
        try {
          final allEmailDocs = await _firestore
              .collection(AppConstants.usersCollection)
              .where('email', isEqualTo: email.trim().toLowerCase())
              .get(const GetOptions(source: Source.server));
          debugPrint(
            '[OrgaFlow UserService DIAGNOSTIK] Ditemukan ${allEmailDocs.docs.length} dokumen dengan email ${email.trim()}:',
          );
          for (final d in allEmailDocs.docs) {
            debugPrint(
              ' -> docId: ${d.id}, uid: ${d.data()['uid']}, status_akun: ${d.data()['status_akun']}',
            );
          }
        } catch (e) {
          debugPrint('[OrgaFlow UserService DIAGNOSTIK ERROR] $e');
        }
      }

      DocumentSnapshot<Map<String, dynamic>> docSnapshot;
      try {
        docSnapshot = await _firestore
            .collection(AppConstants.usersCollection)
            .doc(uid)
            .get(const GetOptions(source: Source.server));
        debugPrint(
          '[OrgaFlow UserService] Berhasil ambil dari SERVER! isFromCache: ${docSnapshot.metadata.isFromCache}',
        );
      } catch (serverErr) {
        debugPrint(
          '[OrgaFlow UserService WARNING] Gagal mengambil dari server ($serverErr), fallback ke default get()...',
        );
        docSnapshot = await _firestore
            .collection(AppConstants.usersCollection)
            .doc(uid)
            .get();
        debugPrint(
          '[OrgaFlow UserService] Fallback get() selesai. isFromCache: ${docSnapshot.metadata.isFromCache}',
        );
      }

      if (docSnapshot.exists && docSnapshot.data() != null) {
        debugPrint(
          '[OrgaFlow UserService] Data users/$uid: status_akun="${docSnapshot.data()?['status_akun']}" (isFromCache: ${docSnapshot.metadata.isFromCache})',
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

  /// Membuat akun Auth dan profil pengguna di Firestore.
  /// Menggunakan aplikasi Firebase sekunder untuk Auth agar tidak memutus sesi admin,
  /// dan menulis dokumen ke Firestore menggunakan instance utama (admin/sekretaris).
  Future<UserProfile> createUser({
    required String nama,
    required String email,
    String? nim,
    required UserRole role,
    required String divisiId,
    required bool statusAktif,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanNama = nama.trim();
    final cleanNim = nim?.trim();
    final temporaryPassword = _temporaryPassword();

    FirebaseApp? secondaryApp;
    String uid;

    try {
      try {
        final defaultApp = Firebase.app();
        try {
          secondaryApp = Firebase.app('AddUserApp');
        } catch (_) {
          secondaryApp = await Firebase.initializeApp(
            name: 'AddUserApp',
            options: defaultApp.options,
          );
        }
        final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
        final credential = await secondaryAuth.createUserWithEmailAndPassword(
          email: cleanEmail,
          password: temporaryPassword,
        );
        uid = credential.user!.uid;
      } catch (authErr) {
        if (authErr is FirebaseAuthException) {
          rethrow;
        }
        final credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: cleanEmail,
              password: temporaryPassword,
            );
        uid = credential.user!.uid;
      }

      final profile = UserProfile(
        uid: uid,
        nama: cleanNama,
        email: cleanEmail,
        nim: cleanNim?.isEmpty == true ? null : cleanNim,
        role: role,
        divisiId: divisiId.trim(),
        statusAkun: statusAktif
            ? AppConstants.statusActive
            : AppConstants.statusInactive,
        createdAt: DateTime.now(),
      );

      // Tulis profil menggunakan _firestore utama (admin/sekretaris yang sedang aktif)
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .set(profile.toMap());

      return profile;
    } on FirebaseAuthException catch (e) {
      throw Exception(_authErrorMessage(e));
    } on FirebaseException catch (e) {
      throw Exception(
        'Gagal menyimpan akun ke database (Firestore permission error): ${e.message ?? e.code}',
      );
    } catch (e) {
      throw Exception(
        'Gagal mendaftarkan pengguna: ${e.toString().replaceAll('Exception: ', '')}',
      );
    } finally {
      if (secondaryApp != null) {
        await secondaryApp.delete();
      }
    }
  }

  /// Aliran real-time daftar seluruh pengguna dari Firestore
  Stream<List<UserProfile>> streamUsers() {
    return _firestore.collection(AppConstants.usersCollection).snapshots().map((
      snapshot,
    ) {
      final users = snapshot.docs
          .map((doc) {
            try {
              return UserProfile.fromMap(doc.data(), doc.id);
            } catch (e) {
              debugPrint(
                '[OrgaFlow UserService ERROR] Gagal parse user ${doc.id}: $e',
              );
              return null;
            }
          })
          .whereType<UserProfile>()
          .toList();

      users.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });

      return users;
    });
  }

  /// Aliran real-time pendaftar yang berstatus 'menunggu_persetujuan' (untuk Sekretaris)
  Stream<List<UserProfile>> streamPendingRegistrations() {
    return _firestore
        .collection(AppConstants.usersCollection)
        .where('status_akun', isEqualTo: AppConstants.statusPending)
        .snapshots()
        .map((snapshot) {
          final users = snapshot.docs
              .map((doc) {
                try {
                  return UserProfile.fromMap(doc.data(), doc.id);
                } catch (e) {
                  debugPrint(
                    '[OrgaFlow UserService ERROR] Gagal parse user pending ${doc.id}: $e',
                  );
                  return null;
                }
              })
              .whereType<UserProfile>()
              .toList();

          users.sort((a, b) {
            if (a.createdAt == null && b.createdAt == null) return 0;
            if (a.createdAt == null) return 1;
            if (b.createdAt == null) return -1;
            return b.createdAt!.compareTo(a.createdAt!);
          });

          return users;
        });
  }

  /// Menyetujui pendaftaran akun oleh Sekretaris (status menjadi 'aktif')
  Future<void> approveRegistration(String uid, {String? catatan}) async {
    try {
      debugPrint('[OrgaFlow UserService] Menyetujui akun users/$uid...');
      final docRef = _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid);
      await docRef.set({
        'status_akun': AppConstants.statusActive,
        'catatan_persetujuan': catatan ?? 'Disetujui oleh Sekretaris',
        'updated_at': Timestamp.fromDate(DateTime.now()),
      }, SetOptions(merge: true));

      // Verifikasi langsung pembacaan dari server
      final checkDoc = await docRef.get(
        const GetOptions(source: Source.server),
      );
      debugPrint(
        '[OrgaFlow UserService] Verifikasi setelah approve: users/$uid status_akun="${checkDoc.data()?['status_akun']}" (isFromCache: ${checkDoc.metadata.isFromCache})',
      );
    } on FirebaseException catch (e) {
      debugPrint(
        '[OrgaFlow UserService ERROR] FirebaseException saat approve: ${e.code} - ${e.message}',
      );
      throw Exception('Gagal menyetujui akun: ${e.message ?? e.code}');
    } catch (e) {
      debugPrint(
        '[OrgaFlow UserService ERROR] General Exception saat approve: $e',
      );
      throw Exception('Terjadi kesalahan saat menyetujui akun: $e');
    }
  }

  /// Menolak pendaftaran akun oleh Sekretaris (status menjadi 'ditolak')
  Future<void> rejectRegistration(String uid, {required String alasan}) async {
    try {
      await _firestore.collection(AppConstants.usersCollection).doc(uid).update(
        {
          'status_akun': AppConstants.statusRejected,
          'catatan_persetujuan': alasan,
          'updated_at': Timestamp.fromDate(DateTime.now()),
        },
      );
    } on FirebaseException catch (e) {
      throw Exception('Gagal menolak akun: ${e.message ?? e.code}');
    } catch (e) {
      throw Exception('Terjadi kesalahan saat menolak akun: $e');
    }
  }

  String _temporaryPassword() {
    final random = Random.secure();
    const chars =
        'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#';
    return List.generate(14, (_) => chars[random.nextInt(chars.length)]).join();
  }

  String _authErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Email sudah terdaftar dalam sistem.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'operation-not-allowed':
        return 'Metode pendaftaran Email/Password belum diaktifkan di Firebase Console.';
      case 'weak-password':
        return 'Password acak tidak memenuhi standar keamanan Firebase.';
      default:
        return 'Gagal membuat akun Auth: ${e.message ?? e.code}';
    }
  }
}
