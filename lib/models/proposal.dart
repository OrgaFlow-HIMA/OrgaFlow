import 'package:cloud_firestore/cloud_firestore.dart';

enum ProposalStatus {
  draft('draft', 'Draft'),
  menunggu('menunggu', 'Menunggu Persetujuan'),
  disetujui('disetujui', 'Disetujui'),
  ditolak('ditolak', 'Ditolak'),
  revisi('revisi', 'Perlu Revisi');

  final String firestoreValue;
  final String label;

  const ProposalStatus(this.firestoreValue, this.label);

  static ProposalStatus fromFirestore(String? val) {
    if (val == null) return ProposalStatus.menunggu;
    return ProposalStatus.values.firstWhere(
      (s) => s.firestoreValue == val,
      orElse: () => ProposalStatus.menunggu,
    );
  }
}

enum ProposalType {
  kegiatan('kegiatan', 'Kegiatan'),
  dana('dana', 'Pengajuan Dana / Anggaran'),
  surat('surat', 'Surat & Administrasi'),
  fasilitas('fasilitas', 'Peminjaman Fasilitas'),
  lainnya('lainnya', 'Lainnya');

  final String firestoreValue;
  final String label;

  const ProposalType(this.firestoreValue, this.label);

  static ProposalType fromFirestore(String? val) {
    if (val == null) return ProposalType.kegiatan;
    return ProposalType.values.firstWhere(
      (t) => t.firestoreValue == val,
      orElse: () => ProposalType.kegiatan,
    );
  }
}

class Proposal {
  final String id;
  final String title;
  final String description;
  final ProposalType type;
  final ProposalStatus status;
  final String applicantUid;
  final String applicantName;
  final String applicantRole;
  final String divisionId;
  final String? divisionName;
  final String? documentUrl;
  final String? documentFileName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Persetujuan Ketua
  final bool approvedByKetua;
  final String? ketuaUid;
  final String? ketuaName;
  final DateTime? ketuaApprovedAt;
  final String? ketuaNote;

  // Persetujuan Dekan
  final bool approvedByDekan;
  final String? dekanUid;
  final String? dekanName;
  final DateTime? dekanApprovedAt;
  final String? dekanNote;

  // Penolakan / Catatan Revisi
  final String? rejectionReason;
  final String? rejectedByRole; // 'ketua' atau 'dekan'

  const Proposal({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.applicantUid,
    required this.applicantName,
    required this.applicantRole,
    required this.divisionId,
    this.divisionName,
    this.documentUrl,
    this.documentFileName,
    this.createdAt,
    this.updatedAt,
    this.approvedByKetua = false,
    this.ketuaUid,
    this.ketuaName,
    this.ketuaApprovedAt,
    this.ketuaNote,
    this.approvedByDekan = false,
    this.dekanUid,
    this.dekanName,
    this.dekanApprovedAt,
    this.dekanNote,
    this.rejectionReason,
    this.rejectedByRole,
  });

  bool get isFullyApproved => approvedByKetua && approvedByDekan;

  factory Proposal.fromMap(Map<String, dynamic> data, String id) {
    return Proposal(
      id: id,
      title: (data['title'] as String?)?.trim() ?? '',
      description: (data['description'] as String?)?.trim() ?? '',
      type: ProposalType.fromFirestore(data['type'] as String?),
      status: ProposalStatus.fromFirestore(data['status'] as String?),
      applicantUid: (data['applicant_uid'] as String?)?.trim() ?? '',
      applicantName: (data['applicant_name'] as String?)?.trim() ?? 'Pengurus',
      applicantRole: (data['applicant_role'] as String?)?.trim() ?? 'Pengurus',
      divisionId: (data['division_id'] as String?)?.trim() ?? 'umum',
      divisionName: (data['division_name'] as String?)?.trim(),
      documentUrl: (data['document_url'] as String?)?.trim(),
      documentFileName: (data['document_file_name'] as String?)?.trim(),
      createdAt: _parseTimestamp(data['created_at']),
      updatedAt: _parseTimestamp(data['updated_at']),
      approvedByKetua: data['approved_by_ketua'] == true,
      ketuaUid: (data['ketua_uid'] as String?)?.trim(),
      ketuaName: (data['ketua_name'] as String?)?.trim(),
      ketuaApprovedAt: _parseTimestamp(data['ketua_approved_at']),
      ketuaNote: (data['ketua_note'] as String?)?.trim(),
      approvedByDekan: data['approved_by_dekan'] == true,
      dekanUid: (data['dekan_uid'] as String?)?.trim(),
      dekanName: (data['dekan_name'] as String?)?.trim(),
      dekanApprovedAt: _parseTimestamp(data['dekan_approved_at']),
      dekanNote: (data['dekan_note'] as String?)?.trim(),
      rejectionReason: (data['rejection_reason'] as String?)?.trim(),
      rejectedByRole: (data['rejected_by_role'] as String?)?.trim(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'type': type.firestoreValue,
      'status': status.firestoreValue,
      'applicant_uid': applicantUid,
      'applicant_name': applicantName,
      'applicant_role': applicantRole,
      'division_id': divisionId,
      if (divisionName != null) 'division_name': divisionName,
      if (documentUrl != null) 'document_url': documentUrl,
      if (documentFileName != null) 'document_file_name': documentFileName,
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
      'approved_by_ketua': approvedByKetua,
      if (ketuaUid != null) 'ketua_uid': ketuaUid,
      if (ketuaName != null) 'ketua_name': ketuaName,
      if (ketuaApprovedAt != null) 'ketua_approved_at': Timestamp.fromDate(ketuaApprovedAt!),
      if (ketuaNote != null) 'ketua_note': ketuaNote,
      'approved_by_dekan': approvedByDekan,
      if (dekanUid != null) 'dekan_uid': dekanUid,
      if (dekanName != null) 'dekan_name': dekanName,
      if (dekanApprovedAt != null) 'dekan_approved_at': Timestamp.fromDate(dekanApprovedAt!),
      if (dekanNote != null) 'dekan_note': dekanNote,
      if (rejectionReason != null) 'rejection_reason': rejectionReason,
      if (rejectedByRole != null) 'rejected_by_role': rejectedByRole,
    };
  }

  static DateTime? _parseTimestamp(dynamic raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }
}
