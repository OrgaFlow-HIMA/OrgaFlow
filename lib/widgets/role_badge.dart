import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../enums/user_role.dart';

class RoleBadge extends StatelessWidget {
  final UserRole role;
  final bool showSpecificRole;

  const RoleBadge({
    super.key,
    required this.role,
    this.showSpecificRole = false,
  });

  @override
  Widget build(BuildContext context) {
    final isPengurus = role.isPengurus;
    final primaryColor = isPengurus
        ? AppTheme.pengurusPrimary
        : AppTheme.anggotaPrimary;
    final bgColor = isPengurus ? AppTheme.pengurusBg : AppTheme.anggotaBg;
    final borderColor = isPengurus
        ? AppTheme.pengurusBorder
        : AppTheme.anggotaBorder;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ikon status
          Icon(
            isPengurus ? Icons.shield_outlined : Icons.person_outline_rounded,
            size: 13,
            color: primaryColor,
          ),
          const SizedBox(width: 5),

          // Label utama (Title Case, bukan ALL CAPS)
          Text(
            isPengurus ? 'Pengurus' : 'Anggota',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
              color: primaryColor,
            ),
          ),

          // Role spesifik dalam chip kecil
          if (showSpecificRole) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                role.label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                  color: primaryColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
