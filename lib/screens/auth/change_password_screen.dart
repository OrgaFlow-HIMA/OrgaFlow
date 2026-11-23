import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  final UserProfile profile;
  final AuthService? authService;
  final VoidCallback onSuccess;

  const ChangePasswordScreen({
    super.key,
    required this.profile,
    this.authService,
    required this.onSuccess,
  });

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  // ===== Layout Constants =====
  static const double _fieldRadius = 12;
  static const double _gapBetweenFields = 18;

  static const Color _borderColor = Color(0xFFE0E0E0);
  static const Color _hintColor = Color(0xFF9E9E9E);

  // ===== Controllers =====
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _newPasswordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  // ===== States =====
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;

  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _newPasswordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  // =========================================================
  // SUBMIT
  // =========================================================

  Future<void> _handleSubmit() async {
    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) return;

    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;

    if (newPass != confirmPass) {
      setState(() => _errorMessage = 'Konfirmasi password tidak cocok.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.changePassword(newPassword: newPass);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.success,
          content: Text('Password berhasil diperbarui!'),
        ),
      );

      widget.onSuccess();
    } on AuthServiceException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Terjadi kesalahan saat mengubah password. Silakan coba lagi.';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // =========================================================
  // BACKGROUND
  // =========================================================

  Widget _buildBackground() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 380,
      child: ClipPath(
        clipper: _HeaderWaveClipper(),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF172554),
                Color(0xFF1E3A8A),
                Color(0xFF2563EB),
                Color(0xFF3B82F6),
              ],
              stops: [0.0, 0.35, 0.75, 1.0],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -110,
                right: -75,
                child: Container(
                  width: 290,
                  height: 290,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
                ),
              ),
              Positioned(
                top: 125,
                left: -105,
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ),
              Positioned(
                top: 245,
                right: -45,
                child: Container(
                  width: 145,
                  height: 145,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // BACK BUTTON
  // =========================================================

  Widget _buildBackButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        },
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chevron_left, color: Colors.white, size: 26),
            Text(
              'Kembali',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // LABELED INPUT FIELD
  // =========================================================

  Widget _buildLabeledField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String? Function(String?) validator,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    Widget? suffixIcon,
    VoidCallback? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          validator: validator,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          enabled: !_isLoading,
          onFieldSubmitted: (_) => onSubmitted?.call(),
          style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: _hintColor, fontSize: 13),
            isDense: true,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 16,
            ),
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_fieldRadius),
              borderSide: const BorderSide(color: _borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_fieldRadius),
              borderSide: const BorderSide(color: _borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_fieldRadius),
              borderSide: const BorderSide(
                color: AppTheme.primaryBlue,
                width: 1.4,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_fieldRadius),
              borderSide: BorderSide(
                color: AppTheme.error.withValues(alpha: 0.6),
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_fieldRadius),
              borderSide: const BorderSide(color: AppTheme.error, width: 1.4),
            ),
            errorStyle: const TextStyle(fontSize: 11),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // ERROR MESSAGE
  // =========================================================

  Widget _buildErrorMessage() {
    if (_errorMessage == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.errorBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppTheme.error,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: AppTheme.error, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // SUBMIT BUTTON
  // =========================================================

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Simpan Kata Sandi',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  // =========================================================
  // CHANGE PASSWORD CARD
  // =========================================================

  Widget _buildChangePasswordCard() {
    return ClipPath(
      clipper: _WhiteWaveClipper(),
      child: Container(
        width: double.infinity,
        color: Colors.white,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 55, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              const Center(
                child: Text(
                  'Perbarui Kata Sandi',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: FractionallySizedBox(
                  widthFactor: 0.9,
                  child: const Text(
                    'Masukkan kata sandi baru untuk meningkatkan keamanan akun Anda.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 26),

              // Error message
              if (_errorMessage != null) ...[
                _buildErrorMessage(),
                const SizedBox(height: 16),
              ],

              // Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildLabeledField(
                      label: 'Password Baru',
                      hint: 'Minimal 6 karakter',
                      controller: _newPasswordController,
                      focusNode: _newPasswordFocus,
                      obscureText: _obscureNew,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Password baru wajib diisi.';
                        }
                        if (value.trim().length < 6) {
                          return 'Password minimal 6 karakter.';
                        }
                        return null;
                      },
                      onSubmitted: () => _confirmPasswordFocus.requestFocus(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureNew
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: _hintColor,
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _obscureNew = !_obscureNew),
                      ),
                    ),
                    const SizedBox(height: _gapBetweenFields),
                    _buildLabeledField(
                      label: 'Konfirmasi Password Baru',
                      hint: 'Ulangi password baru',
                      controller: _confirmPasswordController,
                      focusNode: _confirmPasswordFocus,
                      obscureText: _obscureConfirm,
                      textInputAction: TextInputAction.done,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Konfirmasi password wajib diisi.';
                        }
                        return null;
                      },
                      onSubmitted: _handleSubmit,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: _hintColor,
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 26),

              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // MAIN BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBackButton(),
                const Spacer(),
                Expanded(flex: 6, child: _buildChangePasswordCard()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// HEADER WAVE CLIPPER
// =============================================================

class _HeaderWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    path.lineTo(0, size.height - 55);

    path.cubicTo(
      size.width * 0.20,
      size.height - 115,
      size.width * 0.36,
      size.height - 5,
      size.width * 0.56,
      size.height - 35,
    );

    path.cubicTo(
      size.width * 0.75,
      size.height - 65,
      size.width * 0.88,
      size.height - 75,
      size.width,
      size.height - 40,
    );

    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }
}

// =============================================================
// WHITE CARD WAVE CLIPPER
// =============================================================

class _WhiteWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    path.moveTo(0, 38);

    path.cubicTo(
      size.width * 0.18,
      5,
      size.width * 0.32,
      0,
      size.width * 0.50,
      20,
    );

    path.cubicTo(size.width * 0.70, 45, size.width * 0.84, 5, size.width, 25);

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }
}
