import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../enums/user_role.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  final AuthService? authService;
  final VoidCallback? onBackToLogin;
  final VoidCallback? onRegisterSuccess;

  const RegisterScreen({
    super.key,
    this.authService,
    this.onBackToLogin,
    this.onRegisterSuccess,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const double _fieldRadius = 14;
  static const double _gapBetweenFields = 18;
  static const Color _borderColor = Color(0xFFE0E0E0);
  static const Color _hintColor = Color(0xFF9E9E9E);

  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nimController = TextEditingController();
  final _noWaController = TextEditingController();
  final _suratTugasController = TextEditingController();

  final _namaFocus = FocusNode();
  final _nimFocus = FocusNode();
  final _noWaFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _suratTugasFocus = FocusNode();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  bool _isManagement = false;
  UserRole _selectedRole = UserRole.anggota;
  String _selectedDivisi = 'ristek';

  late final AuthService _authService;

  final Map<String, String> _daftarDivisi = const {
    'ristek': 'Divisi Riset & Teknologi (Ristek)',
    'medkom': 'Divisi Media & Komunikasi (Medkom)',
    'psdm': 'Divisi Pengembangan Sumber Daya Mahasiswa (PSDM)',
  };

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nimController.dispose();
    _noWaController.dispose();
    _suratTugasController.dispose();
    _namaFocus.dispose();
    _nimFocus.dispose();
    _noWaFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _suratTugasFocus.dispose();
    super.dispose();
  }

  void _onRoleCategoryChanged(bool isManagement) {
    setState(() {
      _isManagement = isManagement;
      _selectedRole = isManagement ? UserRole.kepalaDivisi : UserRole.anggota;
    });
  }

  Future<void> _handleRegister() async {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;

    if (_isManagement && _suratTugasController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Pendaftar Pengurus wajib menyertakan link dokumen Surat Tugas / SK.';
      });
      return;
    }

    setState(() => _isLoading = true);
    final needsDivisi =
        !_isManagement || _selectedRole == UserRole.kepalaDivisi;

    try {
      await _authService.registerUser(
        nama: _namaController.text,
        email: _emailController.text,
        password: _passwordController.text,
        nim: _nimController.text,
        noWa: _noWaController.text,
        role: _selectedRole,
        divisiId: needsDivisi ? _selectedDivisi : null,
        suratTugasUrl: _isManagement ? _suratTugasController.text : null,
      );

      if (!mounted) return;

      if (widget.onRegisterSuccess != null) {
        widget.onRegisterSuccess!();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          duration: const Duration(seconds: 3),
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.success,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Pendaftaran berhasil! Akun Anda menunggu persetujuan Sekretaris.',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 3500));

      if (!mounted) return;

      if (widget.onBackToLogin != null) {
        widget.onBackToLogin!();
      }
    } on AuthServiceException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorMessage =
              'Terjadi kesalahan saat pendaftaran. Silakan coba lagi.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
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
          style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: _hintColor, fontSize: 14),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 18,
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
                width: 1.5,
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
              borderSide: const BorderSide(color: AppTheme.error, width: 1.5),
            ),
            errorStyle: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildLabeledDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        DropdownButtonFormField<T>(
          value: value,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: _hintColor,
          ),
          style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 14,
            ),
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
                width: 1.5,
              ),
            ),
          ),
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Background Gradient
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 380,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryBlue.withValues(alpha: 0.3),
                    AppTheme.accentBlue.withValues(alpha: 0.6),
                    const Color(0xFFE0E7FF),
                  ],
                ),
              ),
            ),
          ),

          // 2. Konten Utama
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tombol Back
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      if (widget.onBackToLogin != null) widget.onBackToLogin!();
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chevron_left,
                          color: AppTheme.textPrimary,
                          size: 26,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Back',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 60),

                // 3. Area Putih (Form)
                // Gunakan Expanded agar Container putih mengisi sisa layar,
                // lalu di dalamnya gunakan SingleChildScrollView.
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                    ),
                    // Gunakan ClipRRect agar scroll view tidak menutupi lengkungan container
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 32,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Center(
                              child: Text(
                                'Buat Akun Baru',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: FractionallySizedBox(
                                widthFactor: 0.85,
                                child: const Text(
                                  'Lengkapi data diri Anda untuk bergabung ke portal HIMA Informatika.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Kategori
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 4,
                                bottom: 8,
                              ),
                              child: const Text(
                                'Daftar Sebagai',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(
                                  _fieldRadius,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: () =>
                                          _onRoleCategoryChanged(false),
                                      borderRadius: BorderRadius.circular(
                                        _fieldRadius,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        decoration: BoxDecoration(
                                          color: !_isManagement
                                              ? AppTheme.primaryBlue
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            _fieldRadius,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            'Anggota',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: !_isManagement
                                                  ? Colors.white
                                                  : AppTheme.textSecondary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => _onRoleCategoryChanged(true),
                                      borderRadius: BorderRadius.circular(
                                        _fieldRadius,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _isManagement
                                              ? AppTheme.primaryBlue
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            _fieldRadius,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            'Pengurus',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: _isManagement
                                                  ? Colors.white
                                                  : AppTheme.textSecondary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: _gapBetweenFields),

                            // Error Banner
                            if (_errorMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.errorBg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppTheme.error.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
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
                                        style: const TextStyle(
                                          color: AppTheme.error,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: _gapBetweenFields),
                            ],

                            // Form Fields
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  if (_isManagement) ...[
                                    _buildLabeledDropdown<UserRole>(
                                      label: 'Pilih Jabatan Pengurus',
                                      value: _selectedRole,
                                      items: const [
                                        DropdownMenuItem(
                                          value: UserRole.ketua,
                                          child: Text('Ketua'),
                                        ),
                                        DropdownMenuItem(
                                          value: UserRole.wakilKetua,
                                          child: Text('Wakil Ketua'),
                                        ),
                                        DropdownMenuItem(
                                          value: UserRole.sekretaris,
                                          child: Text('Sekretaris'),
                                        ),
                                        DropdownMenuItem(
                                          value: UserRole.bendahara,
                                          child: Text('Bendahara'),
                                        ),
                                        DropdownMenuItem(
                                          value: UserRole.kepalaDivisi,
                                          child: Text('Kepala Divisi'),
                                        ),
                                      ],
                                      onChanged: (val) {
                                        if (val != null)
                                          setState(() => _selectedRole = val);
                                      },
                                    ),
                                    const SizedBox(height: _gapBetweenFields),
                                  ],
                                  _buildLabeledField(
                                    label: 'Nama Lengkap',
                                    hint: 'Contoh: Dimas Kurniawan',
                                    controller: _namaController,
                                    focusNode: _namaFocus,
                                    textInputAction: TextInputAction.next,
                                    validator: (v) =>
                                        v == null || v.trim().isEmpty
                                        ? 'Nama lengkap wajib diisi'
                                        : null,
                                    onSubmitted: () => _nimFocus.requestFocus(),
                                  ),
                                  const SizedBox(height: _gapBetweenFields),
                                  _buildLabeledField(
                                    label: 'Nomor Induk Mahasiswa (NIM)',
                                    hint: 'Contoh: 2110512048',
                                    controller: _nimController,
                                    focusNode: _nimFocus,
                                    keyboardType: TextInputType.number,
                                    textInputAction: TextInputAction.next,
                                    validator: (v) =>
                                        v == null || v.trim().isEmpty
                                        ? 'NIM wajib diisi'
                                        : null,
                                    onSubmitted: () =>
                                        _noWaFocus.requestFocus(),
                                  ),
                                  const SizedBox(height: _gapBetweenFields),
                                  if (!_isManagement ||
                                      _selectedRole ==
                                          UserRole.kepalaDivisi) ...[
                                    _buildLabeledDropdown<String>(
                                      label: 'Divisi Organisasi',
                                      value: _selectedDivisi,
                                      items: _daftarDivisi.entries
                                          .map(
                                            (e) => DropdownMenuItem(
                                              value: e.key,
                                              child: Text(
                                                e.value,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (val) {
                                        if (val != null)
                                          setState(() => _selectedDivisi = val);
                                      },
                                    ),
                                    const SizedBox(height: _gapBetweenFields),
                                  ],
                                  _buildLabeledField(
                                    label: 'Nomor WhatsApp',
                                    hint: '+62 812-xxxx-xxxx',
                                    controller: _noWaController,
                                    focusNode: _noWaFocus,
                                    keyboardType: TextInputType.phone,
                                    textInputAction: TextInputAction.next,
                                    validator: (_) => null,
                                    onSubmitted: () =>
                                        _emailFocus.requestFocus(),
                                  ),
                                  const SizedBox(height: _gapBetweenFields),
                                  _buildLabeledField(
                                    label: 'Email Akun',
                                    hint: 'email@mahasiswa.ac.id',
                                    controller: _emailController,
                                    focusNode: _emailFocus,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty)
                                        return 'Email wajib diisi';
                                      if (!v.contains('@'))
                                        return 'Format email tidak valid';
                                      return null;
                                    },
                                    onSubmitted: () =>
                                        _passwordFocus.requestFocus(),
                                  ),
                                  const SizedBox(height: _gapBetweenFields),
                                  _buildLabeledField(
                                    label: 'Kata Sandi',
                                    hint: 'Minimal 6 karakter',
                                    controller: _passwordController,
                                    focusNode: _passwordFocus,
                                    obscureText: _obscurePassword,
                                    textInputAction: TextInputAction.done,
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty)
                                        return 'Kata sandi wajib diisi';
                                      if (v.trim().length < 6)
                                        return 'Minimal 6 karakter';
                                      return null;
                                    },
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: _hintColor,
                                        size: 20,
                                      ),
                                      onPressed: () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      ),
                                    ),
                                  ),
                                  if (_isManagement) ...[
                                    const SizedBox(height: _gapBetweenFields),
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppTheme.lightBlue.withValues(
                                          alpha: 0.4,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Dokumen Bukti Surat Tugas / SK',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                              color: AppTheme.primaryBlue,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          const Text(
                                            'Khusus pendaftar pengurus, sertakan link URL file dokumen PDF atau foto Surat Tugas / SK kepengurusan dari Google Drive.',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textSecondary,
                                              height: 1.4,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          _buildLabeledField(
                                            label: 'Link Surat Tugas',
                                            hint:
                                                'https://drive.google.com/...',
                                            controller: _suratTugasController,
                                            focusNode: _suratTugasFocus,
                                            keyboardType: TextInputType.url,
                                            textInputAction:
                                                TextInputAction.done,
                                            validator: (v) {
                                              if (_isManagement &&
                                                  (v == null ||
                                                      v.trim().isEmpty)) {
                                                return 'Tautan wajib diisi untuk Pengurus';
                                              }
                                              return null;
                                            },
                                            onSubmitted: _handleRegister,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Tombol Submit
                            Container(
                              width: double.infinity,
                              height: 54,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBlue,
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryBlue.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleRegister,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
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
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : const Text(
                                        'Daftar Sekarang',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Link Login
                            Center(
                              child: TextButton(
                                onPressed: () {
                                  if (widget.onBackToLogin != null)
                                    widget.onBackToLogin!();
                                },
                                child: const Text.rich(
                                  TextSpan(
                                    text: 'Sudah punya akun? ',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 13,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Masuk di sini',
                                        style: TextStyle(
                                          color: AppTheme.primaryBlue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
