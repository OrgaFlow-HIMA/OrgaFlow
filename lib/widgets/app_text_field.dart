import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final bool enabled;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.enabled = true,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  // ===== Style seragam — konsisten dengan AddEditAgendaModal, CreateTaskModal, dll. =====
  static const TextStyle _inputTextStyle = TextStyle(
    fontSize: 12,
    color: AppTheme.textPrimary,
    height: 1.35,
  );
  static const TextStyle _hintStyle = TextStyle(
    fontSize: 12,
    color: AppTheme.textSecondary,
    height: 1.35,
  );
  static const TextStyle _labelStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppTheme.textPrimary,
    letterSpacing: 0.1,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _labelStyle),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          enabled: enabled,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          validator: validator,
          style: _inputTextStyle,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: _hintStyle,
            filled: true,
            fillColor: enabled ? AppTheme.background : const Color(0xFFF1F5F9),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            prefixIcon: prefixIcon != null
                ? Padding(
                    padding: const EdgeInsets.only(left: 12, right: 8),
                    child: Icon(
                      prefixIcon,
                      size: 18,
                      color: enabled
                          ? AppTheme.textSecondary
                          : AppTheme.textMuted,
                    ),
                  )
                : null,
            prefixIconConstraints: prefixIcon != null
                ? const BoxConstraints(minWidth: 0, minHeight: 0)
                : null,
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppTheme.primaryBlue,
                width: 1.4,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.borderLight),
            ),
            errorStyle: const TextStyle(fontSize: 11),
          ),
        ),
      ],
    );
  }
}
