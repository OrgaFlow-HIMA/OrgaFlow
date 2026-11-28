import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/division_helper.dart';
import '../../../models/user_profile.dart';
import '../../../services/auth_service.dart';

class EditProfileModal extends StatefulWidget {
  final UserProfile profile;
  final AuthService? authService;
  final ValueChanged<UserProfile>? onProfileUpdated;

  const EditProfileModal({
    super.key,
    required this.profile,
    this.authService,
    this.onProfileUpdated,
  });

  static Future<void> show(
    BuildContext context, {
    required UserProfile profile,
    AuthService? authService,
    ValueChanged<UserProfile>? onProfileUpdated,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EditProfileModal(
        profile: profile,
        authService: authService,
        onProfileUpdated: onProfileUpdated,
      ),
    );
  }

  @override
  State<EditProfileModal> createState() => _EditProfileModalState();
}

class _EditProfileModalState extends State<EditProfileModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _namaController;
  late final TextEditingController _emailController;
  late final TextEditingController _noWaController;

  bool _isSaving = false;
  String? _errorMessage;

  // ===== Style Seragam =====
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
  );

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(text: widget.profile.nama);
    _emailController = TextEditingController(text: widget.profile.email);
    _noWaController = TextEditingController(text: widget.profile.noWa ?? '');
  }

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _noWaController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final auth = widget.authService ?? AuthService();
      final updatedProfile = await auth.updateUserProfile(
        uid: widget.profile.uid,
        nama: _namaController.text.trim(),
        email: _emailController.text.trim(),
        noWa: _noWaController.text.trim().isNotEmpty
            ? _noWaController.text.trim()
            : null,
      );

      if (!mounted) return;
      widget.onProfileUpdated?.call(updatedProfile);
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil berhasil diperbarui.'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final divisionDisplay =
        widget.profile.divisiId != null && widget.profile.divisiId!.isNotEmpty
        ? DivisionHelper.getFullName(widget.profile.divisiId)
        : 'Tidak terikat divisi';

    return Padding(
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Grabber
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.lightBlue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.edit_note_rounded,
                      color: AppTheme.primaryBlue,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit Profil',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Perbarui data pribadi Anda',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppTheme.textSecondary,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppTheme.borderLight),

            // Form Konten
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  24 + mediaQuery.padding.bottom,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.errorBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppTheme.error.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: AppTheme.error,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Field: Nama Lengkap
                      _buildFieldLabel('Nama Lengkap', required: true),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _namaController,
                        style: _inputTextStyle,
                        decoration: _inputDecoration(
                          hint: 'Masukkan nama lengkap',
                          icon: Icons.person_outline_rounded,
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Nama lengkap tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Field: Email
                      _buildFieldLabel('Email Akun', required: true),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: _inputTextStyle,
                        decoration: _inputDecoration(
                          hint: 'nama@example.com',
                          icon: Icons.mail_outline_rounded,
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Email tidak boleh kosong';
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                              .hasMatch(val.trim())) {
                            return 'Format email tidak valid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Field: No WhatsApp
                      _buildFieldLabel('Nomor WhatsApp', required: false),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _noWaController,
                        keyboardType: TextInputType.phone,
                        style: _inputTextStyle,
                        decoration: _inputDecoration(
                          hint: '081234567890',
                          icon: Icons.phone_outlined,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Section Keterangan Field Terkunci (Role & Divisi)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.borderLight),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.lock_outline_rounded,
                                  size: 14,
                                  color: AppTheme.textSecondary,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Informasi Organisasi (Terkunci)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _buildLockedInfoRow(
                              'Peran / Role',
                              widget.profile.role.label,
                            ),
                            const SizedBox(height: 6),
                            _buildLockedInfoRow('Divisi', divisionDisplay),
                            const SizedBox(height: 6),
                            const Text(
                              '* Peran dan Divisi hanya dapat diubah oleh administrator.',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.textSecondary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Tombol Simpan
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: FilledButton.icon(
                          onPressed: _isSaving ? null : _handleSave,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_rounded, size: 16),
                          label: Text(
                            _isSaving ? 'Menyimpan...' : 'Simpan Perubahan',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            shape: const StadiumBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, {bool required = false}) {
    return Row(
      children: [
        Text(label, style: _labelStyle),
        if (required) ...[
          const SizedBox(width: 4),
          const Text(
            '*',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.error,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLockedInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: _hintStyle,
      prefixIcon: Icon(icon, size: 20, color: AppTheme.primaryBlue),
      prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      filled: true,
      fillColor: AppTheme.background,
      isDense: false, // Kunci tinggi field
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
        borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.4),
      ),
    );
  }
}
