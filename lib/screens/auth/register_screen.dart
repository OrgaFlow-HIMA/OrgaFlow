import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../enums/user_role.dart';
import '../../services/auth_service.dart';
import '../../services/cloudinary_service.dart';

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
  // ===== Layout Constants =====
  static const double _fieldRadius = 14;
  static const double _gapBetweenFields = 18;

  static const Color _borderColor = Color(0xFFE0E0E0);
  static const Color _hintColor = Color(0xFF9E9E9E);

  // ===== Controllers =====
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

  // ===== States =====
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isUploadingFile = false;
  bool _isManagement = false;

  String? _errorMessage;
  bool _showSuccessToast = false;
  String? _successRegisteredName;

  UserRole _selectedRole = UserRole.anggota;
  String _selectedDivisi = 'ristek';

  // ===== File Upload State =====
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;
  int? _selectedFileSize;

  late final AuthService _authService;
  late final CloudinaryService _cloudinaryService;

  final Map<String, String> _daftarDivisi = const {
    'ristek': 'Divisi Riset & Teknologi (Ristek)',
    'medkom': 'Divisi Media & Komunikasi (Medkom)',
    'psdm': 'Divisi Pengembangan Sumber Daya Mahasiswa (PSDM)',
  };

  @override
  void initState() {
    super.initState();

    _authService = widget.authService ?? AuthService();
    _cloudinaryService = CloudinaryService();
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

  // =========================================================
  // ROLE CATEGORY
  // =========================================================

  void _onRoleCategoryChanged(bool isManagement) {
    setState(() {
      _isManagement = isManagement;
      _selectedRole = isManagement ? UserRole.kepalaDivisi : UserRole.anggota;
      _errorMessage = null;
    });
  }

  // =========================================================
  // FILE PICKER
  // =========================================================

  Future<void> _pickDocumentFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        if (file.bytes != null && mounted) {
          setState(() {
            _selectedFileBytes = file.bytes;
            _selectedFileName = file.name;
            _selectedFileSize = file.size;
            _errorMessage = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memilih dokumen: $e';
        });
      }
    }
  }

  void _removeSelectedFile() {
    setState(() {
      _selectedFileBytes = null;
      _selectedFileName = null;
      _selectedFileSize = null;
    });
  }

  // =========================================================
  // REGISTER
  // =========================================================

  Future<void> _handleRegister() async {
    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) return;

    if (_isManagement &&
        _selectedFileBytes == null &&
        _suratTugasController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Pendaftar Pengurus wajib melampirkan file dokumen Surat Tugas/SK (PDF/Gambar) atau tautan link.';
      });
      return;
    }

    setState(() => _isLoading = true);

    String? finalSuratTugasUrl = _suratTugasController.text.trim().isNotEmpty
        ? _suratTugasController.text.trim()
        : null;

    // Upload dokumen ke Cloudinary
    if (_isManagement && _selectedFileBytes != null) {
      setState(() => _isUploadingFile = true);

      try {
        final uploadedUrl = await _cloudinaryService.uploadFile(
          fileBytes: _selectedFileBytes!,
          fileName: _selectedFileName ?? 'surat_tugas.pdf',
          folder: 'surat_tugas',
        );

        finalSuratTugasUrl = uploadedUrl;
      } on CloudinaryUploadException catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isUploadingFile = false;
            _errorMessage = e.message;
          });
        }
        return;
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isUploadingFile = false;
            _errorMessage = 'Gagal mengunggah berkas ke Cloudinary: $e';
          });
        }
        return;
      } finally {
        if (mounted) {
          setState(() => _isUploadingFile = false);
        }
      }
    }

    final namaInput = _namaController.text.trim();
    final needsDivisi =
        !_isManagement || _selectedRole == UserRole.kepalaDivisi;

    try {
      await _authService.registerUser(
        nama: namaInput,
        email: _emailController.text,
        password: _passwordController.text,
        nim: _nimController.text,
        noWa: _noWaController.text,
        role: _selectedRole,
        divisiId: needsDivisi ? _selectedDivisi : null,
        suratTugasUrl: _isManagement ? finalSuratTugasUrl : null,
      );

      if (!mounted) return;

      // Tampilkan banner floating di bagian paling atas RegisterScreen
      setState(() {
        _showSuccessToast = true;
        _successRegisteredName = namaInput.isNotEmpty ? namaInput : 'Pengguna';
      });

      // Beri waktu user membaca notifikasi floating di RegisterScreen sebelum berpindah
      await Future.delayed(const Duration(milliseconds: 3200));

      if (!mounted) return;

      widget.onRegisterSuccess?.call();
      widget.onBackToLogin?.call();
    } on AuthServiceException catch (e) {
      debugPrint(
        '[OrgaFlow RegisterScreen ERROR] AuthServiceException: ${e.message}',
      );
      if (mounted) {
        setState(() => _errorMessage = e.message);
      }
    } catch (e, stack) {
      debugPrint(
        '[OrgaFlow RegisterScreen ERROR] General Exception: $e\n$stack',
      );
      if (mounted) {
        setState(() {
          _errorMessage = 'Terjadi kesalahan saat pendaftaran: $e';
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
          widget.onBackToLogin?.call();
        },
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chevron_left, color: Colors.white, size: 26),
            Text(
              'Kembali',
              style: TextStyle(
                fontSize: 15,
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

  // =========================================================
  // LABELED DROPDOWN
  // =========================================================

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
          onChanged: _isLoading ? null : onChanged,
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
  // ROLE CATEGORY SELECTOR
  // =========================================================

  Widget _buildRoleCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Daftar Sebagai',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(
            4,
          ), // Jarak antar border luar dengan tombol
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(_fieldRadius),
          ),
          child: Row(
            children: [
              // --- TOMBOL ANGGOTA ---
              Expanded(
                child: InkWell(
                  onTap: _isLoading
                      ? null
                      : () => _onRoleCategoryChanged(false),
                  borderRadius: BorderRadius.circular(_fieldRadius),
                  child: Container(
                    // KECILKAN PADDING DI SINI (misal dari 14 jadi 10 atau 8)
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: !_isManagement
                          ? AppTheme.primaryBlue
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(_fieldRadius),
                    ),
                    child: Center(
                      child: Text(
                        'Anggota',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
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

              // --- TOMBOL PENGURUS ---
              Expanded(
                child: InkWell(
                  onTap: _isLoading ? null : () => _onRoleCategoryChanged(true),
                  borderRadius: BorderRadius.circular(_fieldRadius),
                  child: Container(
                    // SAMAKAN PADDING NYA (jangan 2, ubah jadi 10 atau 8)
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _isManagement
                          ? AppTheme.primaryBlue
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(_fieldRadius),
                    ),
                    child: Center(
                      child: Text(
                        'Pengurus',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
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
      ],
    );
  }

  // =========================================================
  // DOCUMENT UPLOAD
  // =========================================================

  Widget _buildDocumentUpload() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.lightBlue.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.verified_user_outlined,
                size: 18,
                color: AppTheme.primaryBlue,
              ),
              SizedBox(width: 8),
              Text(
                'Dokumen Surat Tugas / SK',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          const Text(
            'Wajib bagi pendaftar pengurus: Unggah file dokumen (PDF/Foto) atau masukkan tautan dokumen (Drive/Cloud).',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 14),

          // File picker
          if (_selectedFileName == null) ...[
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _pickDocumentFile,
              icon: const Icon(Icons.upload_file_rounded, size: 20),
              label: const Text(
                'Pilih File PDF / Foto dari HP',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryBlue,
                side: const BorderSide(color: AppTheme.primaryBlue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                minimumSize: const Size.fromHeight(44),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Row(
                children: [
                  Icon(
                    _selectedFileName!.toLowerCase().endsWith('.pdf')
                        ? Icons.picture_as_pdf
                        : Icons.image,
                    color: Colors.green.shade700,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedFileName!,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_selectedFileSize != null)
                          Text(
                            '${(_selectedFileSize! / 1024).toStringAsFixed(1)} KB (Siap diunggah)',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      size: 20,
                      color: Colors.redAccent,
                    ),
                    onPressed: _isLoading ? null : _removeSelectedFile,
                    tooltip: 'Hapus file',
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Divider
          const Row(
            children: [
              Expanded(child: Divider()),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'atau masukkan link',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ),
              Expanded(child: Divider()),
            ],
          ),

          const SizedBox(height: 8),

          _buildLabeledField(
            label: 'Link Alternatif (Opsional jika sudah pilih file)',
            hint: 'https://drive.google.com/...',
            controller: _suratTugasController,
            focusNode: _suratTugasFocus,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.done,
            validator: (v) {
              if (_isManagement &&
                  _selectedFileBytes == null &&
                  (v == null || v.trim().isEmpty)) {
                return 'Unggah file atau sertakan tautan Surat Tugas';
              }
              return null;
            },
            onSubmitted: _handleRegister,
          ),
        ],
      ),
    );
  }

  // =========================================================
  // REGISTER FORM
  // =========================================================

  Widget _buildRegisterForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Management role
          if (_isManagement) ...[
            _buildLabeledDropdown<UserRole>(
              label: 'Pilih Jabatan Pengurus',
              value: _selectedRole,
              items: const [
                DropdownMenuItem(value: UserRole.ketua, child: Text('Ketua')),
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
                if (val != null) {
                  setState(() => _selectedRole = val);
                }
              },
            ),
            const SizedBox(height: _gapBetweenFields),
          ],

          // Nama
          _buildLabeledField(
            label: 'Nama Lengkap',
            hint: 'Contoh: Dimas Kurniawan',
            controller: _namaController,
            focusNode: _namaFocus,
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Nama lengkap wajib diisi';
              }
              return null;
            },
            onSubmitted: () => _nimFocus.requestFocus(),
          ),

          const SizedBox(height: _gapBetweenFields),

          // NIM
          _buildLabeledField(
            label: 'Nomor Induk Mahasiswa (NIM)',
            hint: 'Contoh: 2110512048',
            controller: _nimController,
            focusNode: _nimFocus,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'NIM wajib diisi';
              }
              return null;
            },
            onSubmitted: () => _noWaFocus.requestFocus(),
          ),

          const SizedBox(height: _gapBetweenFields),

          // Divisi
          if (!_isManagement || _selectedRole == UserRole.kepalaDivisi) ...[
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
                if (val != null) {
                  setState(() => _selectedDivisi = val);
                }
              },
            ),
            const SizedBox(height: _gapBetweenFields),
          ],

          // WhatsApp
          _buildLabeledField(
            label: 'Nomor WhatsApp',
            hint: '+62 812-xxxx-xxxx',
            controller: _noWaController,
            focusNode: _noWaFocus,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            validator: (_) => null,
            onSubmitted: () => _emailFocus.requestFocus(),
          ),

          const SizedBox(height: _gapBetweenFields),

          // Email
          _buildLabeledField(
            label: 'Email Akun',
            hint: 'email@mahasiswa.ac.id',
            controller: _emailController,
            focusNode: _emailFocus,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Email wajib diisi';
              }
              if (!v.contains('@')) {
                return 'Format email tidak valid';
              }
              return null;
            },
            onSubmitted: () => _passwordFocus.requestFocus(),
          ),

          const SizedBox(height: _gapBetweenFields),

          // Password
          _buildLabeledField(
            label: 'Kata Sandi',
            hint: 'Minimal 6 karakter',
            controller: _passwordController,
            focusNode: _passwordFocus,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Kata sandi wajib diisi';
              }
              if (v.trim().length < 6) {
                return 'Minimal 6 karakter';
              }
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
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),

          // Management document
          if (_isManagement) ...[
            const SizedBox(height: _gapBetweenFields),
            _buildDocumentUpload(),
          ],
        ],
      ),
    );
  }

  // =========================================================
  // REGISTER BUTTON
  // =========================================================

  Widget _buildRegisterButton() {
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
        onPressed: _isLoading ? null : _handleRegister,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: _isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _isUploadingFile
                        ? 'Mengunggah Berkas...'
                        : 'Mendaftarkan...',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              )
            : const Text(
                'Daftar Sekarang',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  // =========================================================
  // LOGIN LINK
  // =========================================================

  Widget _buildLoginLink() {
    return Center(
      child: TextButton(
        onPressed: () {
          widget.onBackToLogin?.call();
        },
        child: const Text.rich(
          TextSpan(
            text: 'Sudah punya akun? ',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            children: [
              TextSpan(
                text: 'Masuk di sini',
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
  // REGISTER FORM CARD
  // =========================================================

  Widget _buildRegisterCard() {
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
                  'Buat Akun Baru',
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
                    'Lengkapi data diri Anda untuk bergabung ke portal HIMA Informatika.',
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

              // Role category
              _buildRoleCategorySelector(),

              const SizedBox(height: _gapBetweenFields),

              // Error message
              if (_errorMessage != null) ...[
                _buildErrorMessage(),
                const SizedBox(height: 16),
              ],

              // Form fields
              _buildRegisterForm(),

              const SizedBox(height: 26),

              // Register button
              _buildRegisterButton(),

              const SizedBox(height: 16),

              // Login link
              _buildLoginLink(),

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

                const SizedBox(height: 32),

                // White register card
                Expanded(flex: 6, child: _buildRegisterCard()),
              ],
            ),
          ),

          // =========================================================
          // FLOATING TOP NOTIFICATION (Z-INDEX TERATAS)
          // =========================================================
          if (_showSuccessToast)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              child: Material(
                color: Colors.transparent,
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutBack,
                  tween: Tween(begin: -50.0, end: 0.0),
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, value),
                      child: child,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F766E), Color(0xFF10B981)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.4),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Pendaftaran Berhasil!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Data akun ${_successRegisteredName ?? "Anda"} telah dicatat dan menunggu persetujuan Sekretaris.',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
