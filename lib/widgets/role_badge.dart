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
    final bgColor = isPengurus
        ? AppTheme.pengurusBg
        : AppTheme.anggotaBg;
    final borderColor = isPengurus
        ? AppTheme.pengurusBorder
        : AppTheme.anggotaBorder;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPengurus ? Icons.shield_outlined : Icons.person_outline,
            size: 14,
            color: primaryColor,
          ),
          const SizedBox(width: 5),
          Text(
            isPengurus ? 'PENGURUS' : 'ANGGOTA',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: primaryColor,
            ),
          ),
          if (showSpecificRole) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              width: 3,
              height: 3,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
            ),
            Text(
              role.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: primaryColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
