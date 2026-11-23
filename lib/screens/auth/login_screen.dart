import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final AuthService? authService;
  final String? initialErrorMessage;
  final void Function(UserProfile profile)? onLoginSuccess;
  final VoidCallback? onBack;
  final VoidCallback? onNavigateToRegister;

  const LoginScreen({
    super.key,
    this.authService,
    this.initialErrorMessage,
    this.onLoginSuccess,
    this.onBack,
    this.onNavigateToRegister,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ===== Layout Constants =====
  static const double _fieldRadius = 12;
  static const double _gapBetweenFields = 18;

  static const Color _borderColor = Color(0xFFE0E0E0);
  static const Color _hintColor = Color(0xFF9E9E9E);

  // ===== Controllers =====
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  // ===== States =====
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;

  String? _errorMessage;

  late final AuthService _authService;

  @override
  void initState() {
    super.initState();

    _authService = widget.authService ?? AuthService();
    _errorMessage = widget.initialErrorMessage;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();

    _emailFocus.dispose();
    _passwordFocus.dispose();

    super.dispose();
  }

  // =========================================================
  // VALIDATION
  // =========================================================

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email wajib diisi.';
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Format email tidak valid.';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Password wajib diisi.';
    }

    return null;
  }

  // =========================================================
  // LOGIN
  // =========================================================

  Future<void> _handleLogin() async {
    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final profile = await _authService.loginWithEmailPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (widget.onLoginSuccess != null && mounted) {
        widget.onLoginSuccess!(profile);
      }
    } on AuthServiceException catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Terjadi gangguan koneksi. Silakan coba lagi.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
      height: 420,
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
              // Large decorative circles
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
          if (widget.onBack != null) {
            widget.onBack!();
          } else if (Navigator.of(context).canPop()) {
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
              fontSize: 13, // ← sebelumnya 14
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
          style: const TextStyle(
            fontSize: 13, // ← sebelumnya 15
            color: AppTheme.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: _hintColor,
              fontSize: 13, // ← sebelumnya 14
            ),
            isDense: true, // ← baru: tinggi field lebih ramping
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14, // ← sebelumnya 18
              vertical: 16, // ← sebelumnya 18
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
                width: 1.4, // ← sebelumnya 1.5
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
              borderSide: const BorderSide(
                color: AppTheme.error,
                width: 1.4, // ← sebelumnya 1.5
              ),
            ),
            errorStyle: const TextStyle(fontSize: 11), // ← sebelumnya 12
          ),
        ),
      ],
    );
  }

  // =========================================================
  // ERROR MESSAGE
  // =========================================================

  Widget _buildErrorMessage() {
    if (_errorMessage == null) {
      return const SizedBox.shrink();
    }

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
  // REMEMBER ME & FORGOT PASSWORD
  // =========================================================

  Widget _buildRememberMeRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _isLoading
                ? null
                : () => setState(() => _rememberMe = !_rememberMe),
            child: Row(
              children: [
                SizedBox(
                  height: 16,
                  width: 16,
                  child: Checkbox(
                    value: _rememberMe,
                    onChanged: _isLoading
                        ? null
                        : (val) => setState(() => _rememberMe = val ?? false),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    side: const BorderSide(color: _hintColor, width: 1.5),
                    activeColor: AppTheme.primaryBlue,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Ingat saya',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),

          TextButton(
            onPressed: () {
              // TODO: Implementasi lupa password.
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Lupa password?',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // LOGIN BUTTON
  // =========================================================

  Widget _buildLoginButton() {
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
        onPressed: _isLoading ? null : _handleLogin,
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
                'Masuk',
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
  // REGISTER LINK
  // =========================================================

  Widget _buildRegisterLink() {
    return Center(
      child: TextButton(
        onPressed: () {
          widget.onNavigateToRegister?.call();
        },
        child: const Text.rich(
          TextSpan(
            text: 'Belum punya akun? ',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            children: [
              TextSpan(
                text: 'Daftar di sini',
                style: TextStyle(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // LOGIN FORM CARD
  // =========================================================

  Widget _buildLoginCard() {
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
                  'Selamat Datang Kembali!',
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
                    'Masuk ke portal HIMA Informatika untuk melanjutkan aktivitas organisasi.',
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
                      label: 'Email',
                      hint: 'Masukkan email',
                      controller: _emailController,
                      focusNode: _emailFocus,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: _validateEmail,
                      onSubmitted: () {
                        _passwordFocus.requestFocus();
                      },
                    ),

                    const SizedBox(height: _gapBetweenFields),

                    _buildLabeledField(
                      label: 'Password',
                      hint: 'Masukkan password',
                      controller: _passwordController,
                      focusNode: _passwordFocus,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      validator: _validatePassword,
                      onSubmitted: _handleLogin,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: _hintColor,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              _buildRememberMeRow(),

              const SizedBox(height: 26),

              _buildLoginButton(),

              const SizedBox(height: 8),

              _buildRegisterLink(),

              const SizedBox(height: 16),
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
          // Background gradient + organic wave
          _buildBackground(),

          // Main content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button
                _buildBackButton(),

                const Spacer(),

                // White login card
                Expanded(flex: 6, child: _buildLoginCard()),
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

    // Organic white panel top edge
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
