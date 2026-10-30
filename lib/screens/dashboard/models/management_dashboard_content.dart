import 'package:flutter/material.dart';

import '../../../enums/user_role.dart';

class ManagementNavItem {
  final String label;
  final IconData icon;

  const ManagementNavItem({required this.label, required this.icon});
}

class ManagementDashboardContent {
  final SummaryCardContent firstSummary;
  final SummaryCardContent secondSummary;
  final String approvalTitle;
  final int pendingCount;
  final List<ApprovalCardContent> approvals;

  const ManagementDashboardContent({
    required this.firstSummary,
    required this.secondSummary,
    required this.approvalTitle,
    required this.pendingCount,
    required this.approvals,
  });
}

class SummaryCardContent {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  const SummaryCardContent({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });
}

class ApprovalCardContent {
  final String title;
  final String status;
  final String dueLabel;
  final IconData dueIcon;
  final String actionLabel;

  const ApprovalCardContent({
    required this.title,
    required this.status,
    required this.dueLabel,
    required this.dueIcon,
    required this.actionLabel,
  });
}

const List<ManagementNavItem> managementNavItems = [
  ManagementNavItem(label: 'Beranda', icon: Icons.dashboard_outlined),
  ManagementNavItem(label: 'Tugas', icon: Icons.assignment_outlined),
  ManagementNavItem(label: 'Agenda', icon: Icons.event_available_outlined),
  ManagementNavItem(label: 'Kas', icon: Icons.account_balance_wallet_outlined),
];

const Map<UserRole, ManagementDashboardContent> dashboardByRole = {
  UserRole.dekan: ManagementDashboardContent(
    firstSummary: SummaryCardContent(
      title: 'Persetujuan Dekanat',
      value: '1 Menunggu',
      subtitle: 'Perlu ditinjau',
      icon: Icons.rule_rounded,
    ),
    secondSummary: SummaryCardContent(
      title: 'Proker Berjalan',
      value: '2 Proker',
      subtitle: 'Dari total 6 proker',
      icon: Icons.account_balance_rounded,
    ),
    approvalTitle: 'Persetujuan Penting Dekanat',
    pendingCount: 2,
    approvals: [
      ApprovalCardContent(
        title: 'Proposal IT Fest (Rekomendasi Dekanat)',
        status: 'Menunggu Persetujuan',
        dueLabel: 'Hari ini, 20:00 WIB',
        dueIcon: Icons.access_time_rounded,
        actionLabel: 'Tinjau Proposal',
      ),
      ApprovalCardContent(
        title: 'LPJ Makrab Mahasiswa Baru',
        status: 'Menunggu',
        dueLabel: 'Besok, 17:00 WIB',
        dueIcon: Icons.event_outlined,
        actionLabel: 'Lihat Detail',
      ),
    ],
  ),
  UserRole.ketua: ManagementDashboardContent(
    firstSummary: SummaryCardContent(
      title: 'Persetujuan',
      value: '1 Menunggu',
      subtitle: 'Perlu ditinjau',
      icon: Icons.rule_rounded,
    ),
    secondSummary: SummaryCardContent(
      title: 'Proker Berjalan',
      value: '2 Proker',
      subtitle: 'Dari total 6 proker',
      icon: Icons.folder_open_rounded,
    ),
    approvalTitle: 'Persetujuan Penting',
    pendingCount: 2,
    approvals: [
      ApprovalCardContent(
        title: 'Proposal IT Fest (Revisi Anggaran)',
        status: 'Menunggu Persetujuan',
        dueLabel: 'Hari ini, 20:00 WIB',
        dueIcon: Icons.access_time_rounded,
        actionLabel: 'Tinjau Proposal',
      ),
      ApprovalCardContent(
        title: 'LPJ Makrab Mahasiswa Baru',
        status: 'Menunggu',
        dueLabel: 'Besok, 17:00 WIB',
        dueIcon: Icons.event_outlined,
        actionLabel: 'Lihat Detail',
      ),
    ],
  ),
  UserRole.wakilKetua: ManagementDashboardContent(
    firstSummary: SummaryCardContent(
      title: 'Program Dipantau',
      value: '3 Program',
      subtitle: 'Perlu evaluasi',
      icon: Icons.track_changes_rounded,
    ),
    secondSummary: SummaryCardContent(
      title: 'Proker Berjalan',
      value: '2 Proker',
      subtitle: 'Dari total 6 proker',
      icon: Icons.folder_open_rounded,
    ),
    approvalTitle: 'Pemantauan Penting',
    pendingCount: 2,
    approvals: [
      ApprovalCardContent(
        title: 'Evaluasi Progres IT Fest',
        status: 'Perlu Ditinjau',
        dueLabel: 'Hari ini, 20:00 WIB',
        dueIcon: Icons.access_time_rounded,
        actionLabel: 'Tinjau Progres',
      ),
      ApprovalCardContent(
        title: 'Laporan Kegiatan Divisi',
        status: 'Menunggu',
        dueLabel: 'Besok, 17:00 WIB',
        dueIcon: Icons.event_outlined,
        actionLabel: 'Lihat Detail',
      ),
    ],
  ),
  UserRole.sekretaris: ManagementDashboardContent(
    firstSummary: SummaryCardContent(
      title: 'Surat Masuk',
      value: '2 Surat',
      subtitle: 'Perlu ditindaklanjuti',
      icon: Icons.mail_outline_rounded,
    ),
    secondSummary: SummaryCardContent(
      title: 'Agenda Tercatat',
      value: '4 Agenda',
      subtitle: 'Bulan ini',
      icon: Icons.event_note_rounded,
    ),
    approvalTitle: 'Dokumen Perlu Ditinjau',
    pendingCount: 2,
    approvals: [
      ApprovalCardContent(
        title: 'Surat Permohonan Peminjaman Ruang',
        status: 'Menunggu Pemeriksaan',
        dueLabel: 'Hari ini, 20:00 WIB',
        dueIcon: Icons.access_time_rounded,
        actionLabel: 'Tinjau Surat',
      ),
      ApprovalCardContent(
        title: 'Notulen Rapat Pengurus',
        status: 'Perlu Dilengkapi',
        dueLabel: 'Besok, 17:00 WIB',
        dueIcon: Icons.event_outlined,
        actionLabel: 'Lihat Detail',
      ),
    ],
  ),
  UserRole.bendahara: ManagementDashboardContent(
    firstSummary: SummaryCardContent(
      title: 'Verifikasi Bayar',
      value: '4 transfer',
      subtitle: 'Perlu konfirmasi',
      icon: Icons.payments_outlined,
    ),
    secondSummary: SummaryCardContent(
      title: 'Saldo Kas Aktif',
      value: 'Rp. 4.250.000',
      subtitle: 'Update hari ini',
      icon: Icons.account_balance_wallet_outlined,
    ),
    approvalTitle: 'Verifikasi dan Tugas Keuangan',
    pendingCount: 2,
    approvals: [
      ApprovalCardContent(
        title: 'Konfirmasi Bukti Transfer Kas Bulanan (4 Anggota)',
        status: 'Menunggu Verifikasi',
        dueLabel: 'Hari ini, 20:00 WIB',
        dueIcon: Icons.access_time_rounded,
        actionLabel: 'Tinjau Proposal',
      ),
      ApprovalCardContent(
        title: 'LPJ Makrab Mahasiswa Baru',
        status: 'Menunggu',
        dueLabel: 'Besok, 17:00 WIB',
        dueIcon: Icons.event_outlined,
        actionLabel: 'Lihat Detail',
      ),
    ],
  ),
  UserRole.kepalaDivisi: ManagementDashboardContent(
    firstSummary: SummaryCardContent(
      title: 'Tugas Tim',
      value: '5 Tugas',
      subtitle: '2 perlu direview',
      icon: Icons.checklist_rounded,
    ),
    secondSummary: SummaryCardContent(
      title: 'Anggota Divisi',
      value: '8 Orang',
      subtitle: 'Semua aktif',
      icon: Icons.workspaces_outline,
    ),
    approvalTitle: 'Review dan Tugas Divisi',
    pendingCount: 2,
    approvals: [
      ApprovalCardContent(
        title: 'Review Hasil Desain Feed Instagram TI Fest (Nadia)',
        status: 'Perlu Review',
        dueLabel: 'Hari ini, 20:00 WIB',
        dueIcon: Icons.access_time_rounded,
        actionLabel: 'Tinjau Progres',
      ),
      ApprovalCardContent(
        title: 'Laporan Tugas Anggota Divisi',
        status: 'Menunggu',
        dueLabel: 'Besok, 17:00 WIB',
        dueIcon: Icons.event_outlined,
        actionLabel: 'Lihat Detail',
      ),
    ],
  ),
};
