import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../enums/task_status.dart';
import '../../../enums/user_role.dart';
import '../../../models/task.dart';
import 'task_detail_modal.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final UserRole userRole;
  final VoidCallback? onDelegate;
  final VoidCallback? onSubmit;
  final VoidCallback? onConfirm;
  final VoidCallback? onTapDetail;
  final bool isConfirming;

  const TaskCard({
    super.key,
    required this.task,
    required this.userRole,
    this.onDelegate,
    this.onSubmit,
    this.onConfirm,
    this.onTapDetail,
    this.isConfirming = false,
  });

  bool get _isKadiv => userRole == UserRole.kepalaDivisi;
  bool get _isAnggota => userRole == UserRole.anggota;
  bool get _isBendahara => userRole == UserRole.bendahara;
  bool get _isSekretaris => userRole == UserRole.sekretaris;

  bool get _isBendaharaTask =>
      task.targetRole == 'bendahara' || task.divisiId == 'bendahara';

  @override
  Widget build(BuildContext context) {
    final isDone = task.isDone;
    final isOverdue = task.isOverdue;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTapDetail ??
            () {
              TaskDetailModal.show(
                context,
                task: task,
                userRole: userRole,
                onDelegate: onDelegate,
                onSubmit: onSubmit,
                onConfirm: onConfirm,
                isConfirming: isConfirming,
              );
            },
        borderRadius: BorderRadius.circular(17),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: isOverdue
                  ? AppTheme.error.withValues(alpha: 0.3)
                  : AppTheme.borderLight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withValues(alpha: 0.035),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // ===== BADGE ROW =====
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Badge Divisi
              _buildBadge(
                label:
                    task.divisiNama ?? 'Divisi ${task.divisiId.toUpperCase()}',
                bgColor: AppTheme.lightBlue,
                fgColor: AppTheme.primaryBlue,
              ),
              _buildStatusBadge(task.status, isOverdue: isOverdue),
            ],
          ),
          const SizedBox(height: 10),

          // ===== JUDUL =====
          Text(
            task.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
              height: 1.3,
            ),
          ),

          // ===== DESKRIPSI =====
          if (task.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              task.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ],

          // ===== PENANGGUNG JAWAB / ANGGOTA YANG DITUGASKAN =====
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                _isBendaharaTask
                    ? Icons.account_balance_wallet_outlined
                    : (task.assignedToNama != null
                          ? Icons.person_outline_rounded
                          : Icons.person_add_disabled_outlined),
                size: 14,
                color: (_isBendaharaTask || task.assignedToNama != null)
                    ? AppTheme.primaryBlue
                    : AppTheme.textSecondary,
              ),
              const SizedBox(width: 5),
              Text(
                _isBendaharaTask
                    ? 'Penanggung Jawab: Bendahara'
                    : (task.assignedToNama != null
                          ? 'Bertugas: ${task.assignedToNama}'
                          : 'Belum ditugaskan ke anggota'),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: (_isBendaharaTask || task.assignedToNama != null)
                      ? FontWeight.w600
                      : FontWeight.w500,
                  color: (_isBendaharaTask || task.assignedToNama != null)
                      ? AppTheme.textPrimary
                      : AppTheme.textSecondary,
                ),
              ),
            ],
          ),

          // ===== HASIL SUBMISSION (FILE / LINK) JIKA SUDAH ADA =====
          if (task.submissionUrl != null && task.submissionUrl!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Row(
                children: [
                  Icon(
                    task.submissionType == 'link'
                        ? Icons.link_rounded
                        : Icons.file_present_rounded,
                    color: AppTheme.primaryBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.submissionFileName ??
                              (task.submissionType == 'link'
                                  ? 'Tautan Hasil Pengerjaan'
                                  : 'Lampiran Berkas'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        if (task.submissionNote != null &&
                            task.submissionNote!.isNotEmpty)
                          Text(
                            'Catatan: ${task.submissionNote}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  TextButton.icon(
                    onPressed: () {
                      TaskDetailModal.show(
                        context,
                        task: task,
                        userRole: userRole,
                        onDelegate: onDelegate,
                        onSubmit: onSubmit,
                        onConfirm: onConfirm,
                        isConfirming: isConfirming,
                      );
                    },
                    icon: const Icon(Icons.visibility_rounded, size: 14),
                    label: const Text('Lihat / Unduh', style: TextStyle(fontSize: 11)),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ===== INFO TENGGAT & SELESAI =====
          if (task.dueAt != null || (isDone && task.completedAt != null)) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  if (task.dueAt != null)
                    Expanded(
                      child: _buildInfoRow(
                        icon: isOverdue
                            ? Icons.warning_amber_rounded
                            : Icons.access_time_rounded,
                        label: 'Tenggat',
                        value: _formatDate(task.dueAt!),
                        color: isOverdue
                            ? AppTheme.error
                            : AppTheme.textPrimary,
                      ),
                    ),
                  if (isDone && task.completedAt != null)
                    Expanded(
                      child: _buildInfoRow(
                        icon: Icons.check_circle_outline_rounded,
                        label: 'Selesai',
                        value: _formatDate(task.completedAt!),
                        color: AppTheme.success,
                      ),
                    ),
                ],
              ),
            ),
          ],

          // ===== TOMBOL AKSI SESUAI ROLE & STATUS =====
          // 1. Tombol Kadiv: Delegasikan Tugas ke Anggota (Hanya untuk tugas divisi)
          if (_isKadiv &&
              !_isBendaharaTask &&
              task.status == TaskStatus.pendingDelegation &&
              onDelegate != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: onDelegate,
                label: const Text(
                  'Tugaskan ke Anggota Divisi',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
              ),
            ),
          ],

          // 2. Tombol Anggota / Bendahara: Kumpulkan Hasil Tugas
          if (((_isAnggota && !_isBendaharaTask) ||
                  (_isBendahara && _isBendaharaTask)) &&
              task.status == TaskStatus.todo &&
              onSubmit != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: onSubmit,
                label: const Text(
                  'Kumpulkan Hasil Tugas',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
              ),
            ),
          ],

          // 3. Tombol Verifikasi/Konfirmasi:
          // - Kadiv untuk tugas divisi yang telah dikumpulkan anggota
          // - Sekretaris untuk tugas Bendahara yang telah dikumpulkan bendahara
          if (((_isKadiv && !_isBendaharaTask) ||
                  (_isSekretaris && _isBendaharaTask)) &&
              task.status == TaskStatus.submitted &&
              onConfirm != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: isConfirming ? null : onConfirm,
                label: Text(
                  isConfirming ? 'Menyetujui...' : 'Periksa & Setujui Tugas',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  ),
);
  }

  Widget _buildBadge({
    required String label,
    required Color bgColor,
    required Color fgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: fgColor,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(TaskStatus status, {required bool isOverdue}) {
    switch (status) {
      case TaskStatus.done:
        return _buildBadge(
          label: 'Selesai',
          bgColor: AppTheme.successBg,
          fgColor: AppTheme.success,
        );
      case TaskStatus.submitted:
        return _buildBadge(
          label: 'Menunggu Konfirmasi',
          bgColor: const Color(0xFFFEF3C7),
          fgColor: const Color(0xFFB45309),
        );
      case TaskStatus.pendingDelegation:
        return _buildBadge(
          label: 'Perlu Didelegasikan',
          bgColor: const Color(0xFFE0E7FF),
          fgColor: const Color(0xFF4338CA),
        );
      case TaskStatus.todo:
        return _buildBadge(
          label: isOverdue ? 'Terlambat' : 'Sedang Dikerjakan',
          bgColor: isOverdue ? AppTheme.errorBg : AppTheme.warningBg,
          fgColor: isOverdue ? AppTheme.error : AppTheme.warning,
        );
    }
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}
