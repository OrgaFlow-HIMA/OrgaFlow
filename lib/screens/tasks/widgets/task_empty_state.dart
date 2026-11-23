import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class TaskEmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;

  const TaskEmptyState({
    super.key,
    this.title = 'Belum Ada Tugas',
    this.subtitle = 'Tidak ada tugas pada kategori ini saat ini.',
    this.icon = Icons.assignment_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 23, horizontal: 17),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppTheme.lightBlue,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 25, color: AppTheme.primaryBlue),
          ),
          const SizedBox(height: 11),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
