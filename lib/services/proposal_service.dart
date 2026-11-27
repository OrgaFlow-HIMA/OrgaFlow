import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../models/app_notification.dart';
import '../models/proposal.dart';
import 'notification_service.dart';

class ProposalServiceException implements Exception {
  final String message;
  const ProposalServiceException(this.message);

  @override
  String toString() => message;
}

class ProposalService {
  final FirebaseFirestore _firestore;

  ProposalService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _proposals =>
      _firestore.collection(AppConstants.proposalsCollection);

  /// Mengambil satu data proposal/pengajuan berdasarkan ID
  Future<Proposal?> getProposalById(String proposalId) async {
    try {
      final doc = await _proposals.doc(proposalId).get();
      if (!doc.exists || doc.data() == null) return null;
      return Proposal.fromMap(doc.data()!, doc.id);
    } catch (e) {
      debugPrint('[OrgaFlow ProposalService ERROR] getProposalById: $e');
      return null;
    }
  }

  /// Mengajukan proposal/surat persetujuan baru oleh pengurus (Sekretaris, Bendahara, Kadiv, dll.)
  Future<String> createProposal({
    required String title,
    required String description,
    required ProposalType type,
    required String applicantUid,
    required String applicantName,
    required String applicantRole,
    required String divisionId,
    String? divisionName,
    String? documentUrl,
    String? documentFileName,
  }) async {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) {
      throw const ProposalServiceException('Judul pengajuan wajib diisi.');
    }

    try {
      final doc = await _proposals.add({
        'title': cleanTitle,
        'description': description.trim(),
        'type': type.firestoreValue,
        'status': ProposalStatus.menunggu.firestoreValue,
        'applicant_uid': applicantUid.trim(),
        'applicant_name': applicantName.trim(),
        'applicant_role': applicantRole.trim(),
        'division_id': divisionId.trim(),
        if (divisionName != null) 'division_name': divisionName.trim(),
        if (documentUrl != null && documentUrl.trim().isNotEmpty)
          'document_url': documentUrl.trim(),
        if (documentFileName != null && documentFileName.trim().isNotEmpty)
          'document_file_name': documentFileName.trim(),
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'approved_by_ketua': false,
        'approved_by_dekan': false,
      });

      // Notifikasi ke Ketua & Dekan bahwa ada pengajuan baru
      try {
        final notifService = NotificationService(firestore: _firestore);
        // Ke Ketua
        await notifService.createNotification(
          title: 'Pengajuan Baru Menunggu Persetujuan',
          message: '$applicantName ($applicantRole) mengajukan ${type.label}: "$cleanTitle".',
          type: NotificationType.proposal,
          targetType: NotificationTargetType.role,
          targetRole: 'ketua',
          referenceId: doc.id,
          createdBy: applicantUid,
        );
        // Ke Dekan
        await notifService.createNotification(
          title: 'Pengajuan Baru Menunggu Persetujuan Dekan',
          message: '$applicantName ($applicantRole) mengajukan ${type.label}: "$cleanTitle".',
          type: NotificationType.proposal,
          targetType: NotificationTargetType.role,
          targetRole: 'dekan',
          referenceId: doc.id,
          createdBy: applicantUid,
        );
      } catch (e) {
        debugPrint('[ProposalService WARNING] Notif error: $e');
      }

      return doc.id;
    } on FirebaseException catch (e) {
      throw ProposalServiceException('Gagal membuat pengajuan: ${e.message ?? e.code}');
    }
  }

  /// Persetujuan oleh Ketua
  Future<void> approveByKetua({
    required String proposalId,
    required String ketuaUid,
    required String ketuaName,
    String? note,
  }) async {
    try {
      final doc = await _proposals.doc(proposalId).get();
      final data = doc.data() ?? {};
      final bool alreadyApprovedByDekan = data['approved_by_dekan'] == true;
      final String applicantUid = data['applicant_uid'] ?? '';
      final String title = data['title'] ?? 'Pengajuan';

      // Jika dekan juga sudah acc, maka status menjadi disetujui (fully approved)
      final newStatus = alreadyApprovedByDekan
          ? ProposalStatus.disetujui.firestoreValue
          : ProposalStatus.menunggu.firestoreValue;

      await _proposals.doc(proposalId).update({
        'approved_by_ketua': true,
        'ketua_uid': ketuaUid,
        'ketua_name': ketuaName,
        'ketua_approved_at': FieldValue.serverTimestamp(),
        if (note != null && note.isNotEmpty) 'ketua_note': note.trim(),
        'status': newStatus,
        'updated_at': FieldValue.serverTimestamp(),
      });

      try {
        final notifService = NotificationService(firestore: _firestore);
        await notifService.createNotification(
          title: alreadyApprovedByDekan
              ? 'Pengajuan Disetujui Sepenuhnya'
              : 'Disetujui oleh Ketua Himpunan',
          message: alreadyApprovedByDekan
              ? 'Pengajuan "$title" telah disetujui oleh Ketua dan Dekan. Kegiatan/program siap berjalan!'
              : 'Ketua telah menyetujui pengajuan "$title". Menunggu persetujuan Dekan.',
          type: NotificationType.proposal,
          targetType: NotificationTargetType.user,
          targetUserId: applicantUid,
          referenceId: proposalId,
          createdBy: ketuaUid,
        );
      } catch (e) {
        debugPrint('[ProposalService WARNING] Notif error: $e');
      }
    } on FirebaseException catch (e) {
      throw ProposalServiceException('Gagal menyetujui pengajuan: ${e.message ?? e.code}');
    }
  }

  /// Persetujuan oleh Dekan
  Future<void> approveByDekan({
    required String proposalId,
    required String dekanUid,
    required String dekanName,
    String? note,
  }) async {
    try {
      final doc = await _proposals.doc(proposalId).get();
      final data = doc.data() ?? {};
      final bool alreadyApprovedByKetua = data['approved_by_ketua'] == true;
      final String applicantUid = data['applicant_uid'] ?? '';
      final String title = data['title'] ?? 'Pengajuan';

      final newStatus = alreadyApprovedByKetua
          ? ProposalStatus.disetujui.firestoreValue
          : ProposalStatus.menunggu.firestoreValue;

      await _proposals.doc(proposalId).update({
        'approved_by_dekan': true,
        'dekan_uid': dekanUid,
        'dekan_name': dekanName,
        'dekan_approved_at': FieldValue.serverTimestamp(),
        if (note != null && note.isNotEmpty) 'dekan_note': note.trim(),
        'status': newStatus,
        'updated_at': FieldValue.serverTimestamp(),
      });

      try {
        final notifService = NotificationService(firestore: _firestore);
        await notifService.createNotification(
          title: alreadyApprovedByKetua
              ? 'Pengajuan Disetujui Sepenuhnya'
              : 'Disetujui oleh Dekan',
          message: alreadyApprovedByKetua
              ? 'Pengajuan "$title" telah disetujui oleh Dekan dan Ketua. Kegiatan/program siap berjalan!'
              : 'Dekan telah menyetujui pengajuan "$title". Menunggu persetujuan Ketua.',
          type: NotificationType.proposal,
          targetType: NotificationTargetType.user,
          targetUserId: applicantUid,
          referenceId: proposalId,
          createdBy: dekanUid,
        );
      } catch (e) {
        debugPrint('[ProposalService WARNING] Notif error: $e');
      }
    } on FirebaseException catch (e) {
      throw ProposalServiceException('Gagal menyetujui pengajuan: ${e.message ?? e.code}');
    }
  }

  /// Penolakan atau Permintaan Revisi
  Future<void> rejectOrRequestRevision({
    required String proposalId,
    required String role, // 'ketua' atau 'dekan'
    required String reviewerUid,
    required ProposalStatus status, // ProposalStatus.ditolak atau ProposalStatus.revisi
    required String reason,
  }) async {
    try {
      final doc = await _proposals.doc(proposalId).get();
      final data = doc.data() ?? {};
      final String applicantUid = data['applicant_uid'] ?? '';
      final String title = data['title'] ?? 'Pengajuan';

      await _proposals.doc(proposalId).update({
        'status': status.firestoreValue,
        'rejection_reason': reason.trim(),
        'rejected_by_role': role,
        'updated_at': FieldValue.serverTimestamp(),
      });

      try {
        final notifService = NotificationService(firestore: _firestore);
        final isRevisi = status == ProposalStatus.revisi;
        await notifService.createNotification(
          title: isRevisi ? 'Pengajuan Perlu Revisi' : 'Pengajuan Ditolak',
          message: isRevisi
              ? 'Pengajuan "$title" memerlukan revisi: "$reason".'
              : 'Pengajuan "$title" ditolak: "$reason".',
          type: NotificationType.proposal,
          targetType: NotificationTargetType.user,
          targetUserId: applicantUid,
          referenceId: proposalId,
          createdBy: reviewerUid,
        );
      } catch (e) {
        debugPrint('[ProposalService WARNING] Notif error: $e');
      }
    } on FirebaseException catch (e) {
      throw ProposalServiceException('Gagal memproses penolakan: ${e.message ?? e.code}');
    }
  }

  /// Watch seluruh proposal (untuk Ketua & Dekan)
  Stream<List<Proposal>> watchAllProposals() {
    return _proposals.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) => Proposal.fromMap(doc.data(), doc.id)).toList();
      list.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
      return list;
    });
  }

  /// Watch proposal yang diajukan oleh pengguna tertentu (untuk pengurus pengaju)
  Stream<List<Proposal>> watchProposalsByApplicant(String applicantUid) {
    return _proposals
        .where('applicant_uid', isEqualTo: applicantUid.trim())
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => Proposal.fromMap(doc.data(), doc.id)).toList();
      list.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
      return list;
    });
  }
}
