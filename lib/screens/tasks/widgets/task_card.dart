import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/task.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final bool showRoleBadge;
  final bool showActionButton;
  final VoidCallback? onMarkDone;
  final bool isMarkingDone;

  const TaskCard({
    super.key,
    required this.task,
    this.showRoleBadge = true,
    this.showActionButton = true,
    this.onMarkDone,
    this.isMarkingDone = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = task.isDone;
    final isOverdue = task.isOverdue;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: isOverdue
              ? AppTheme.error.withOpacity(0.3)
              : AppTheme.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.035),
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
              if (showRoleBadge)
                _buildBadge(
                  label: task.targetRole.label,
                  bgColor: AppTheme.lightBlue,
                  fgColor: AppTheme.primaryBlue,
                )
              else
                const SizedBox.shrink(),
              _buildStatusBadge(isDone: isDone, isOverdue: isOverdue),
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

          // ===== INFO TENGGAT & SELESAI =====
          if (task.dueAt != null || (isDone && task.completedAt != null)) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (task.dueAt != null)
                    _buildInfoRow(
                      icon: isOverdue
                          ? Icons.warning_amber_rounded
                          : Icons.access_time_rounded,
                      label: 'Tenggat',
                      value: _formatDate(task.dueAt!),
                      color: isOverdue ? AppTheme.error : AppTheme.textPrimary,
                    ),
                  if (isDone && task.completedAt != null && task.dueAt != null)
                    const SizedBox(height: 6),
                  if (isDone && task.completedAt != null)
                    _buildInfoRow(
                      icon: Icons.check_circle_outline_rounded,
                      label: 'Selesai',
                      value: _formatDate(task.completedAt!),
                      color: AppTheme.success,
                    ),
                ],
              ),
            ),
          ],

          // ===== TOMBOL AKSI =====
          if (showActionButton && !isDone && onMarkDone != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: FilledButton.icon(
                onPressed: isMarkingDone ? null : onMarkDone,
                icon: isMarkingDone
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline, size: 16),
                label: Text(
                  isMarkingDone ? 'Menyimpan...' : 'Tandai Selesai',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ===== BADGE UMUM =====

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

  // ===== BADGE STATUS =====

  Widget _buildStatusBadge({required bool isDone, required bool isOverdue}) {
    if (isDone) {
      return _buildBadge(
        label: 'Selesai',
        bgColor: AppTheme.successBg,
        fgColor: AppTheme.success,
      );
    }
    if (isOverdue) {
      return _buildBadge(
        label: 'Terlambat',
        bgColor: AppTheme.errorBg,
        fgColor: AppTheme.error,
      );
    }
    return _buildBadge(
      label: 'Belum Selesai',
      bgColor: AppTheme.warningBg,
      fgColor: AppTheme.warning,
    );
  }

  // ===== INFO ROW DALAM KOTAK =====

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          '$label:',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  // ===== FORMAT TANGGAL =====

  String _formatDate(DateTime date) {
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
    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day $month $year • $hour:$minute';
  }
}
