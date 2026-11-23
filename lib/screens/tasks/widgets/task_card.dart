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
          // Baris badge (role & status)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (showRoleBadge)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.lightBlue,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    task.targetRole.label,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                )
              else
                const SizedBox.shrink(),
              _buildStatusBadge(isDone: isDone, isOverdue: isOverdue),
            ],
          ),
          const SizedBox(height: 10),

          // Judul
          Text(
            task.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
              height: 1.3,
            ),
          ),

          // Deskripsi
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

          // Tanggal
          if (task.dueAt != null || (isDone && task.completedAt != null)) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                if (task.dueAt != null)
                  _buildDateChip(
                    icon: isOverdue
                        ? Icons.warning_amber_rounded
                        : Icons.access_time_rounded,
                    label: 'Tenggat: ${_formatDate(task.dueAt!)}',
                    color: isOverdue ? AppTheme.error : AppTheme.textSecondary,
                  ),
                if (isDone && task.completedAt != null)
                  _buildDateChip(
                    icon: Icons.check_circle_outline_rounded,
                    label: 'Selesai: ${_formatDate(task.completedAt!)}',
                    color: AppTheme.success,
                  ),
              ],
            ),
          ],

          // Tombol aksi
          if (showActionButton && !isDone && onMarkDone != null) ...[
            const SizedBox(height: 14),
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

  Widget _buildStatusBadge({required bool isDone, required bool isOverdue}) {
    Color bg;
    Color fg;
    String label;

    if (isDone) {
      bg = AppTheme.successBg;
      fg = AppTheme.success;
      label = 'Selesai';
    } else if (isOverdue) {
      bg = AppTheme.errorBg;
      fg = AppTheme.error;
      label = 'Terlambat';
    } else {
      bg = AppTheme.warningBg;
      fg = AppTheme.warning;
      label = 'Belum Selesai';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }

  Widget _buildDateChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

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
    return '$day $month $year, $hour:$minute';
  }
}
