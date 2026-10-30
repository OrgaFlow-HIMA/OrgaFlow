import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../enums/user_role.dart';
import '../../widgets/role_badge.dart';

enum UserCategory { member, management }

typedef AddUserScreen = AddUserPage;

class AddUserPage extends StatefulWidget {
  const AddUserPage({super.key});

  @override
  State<AddUserPage> createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  final _formKey = GlobalKey<FormState>();

  UserCategory _selectedCategory = UserCategory.member;

  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nimController = TextEditingController();

  UserRole _selectedRole = UserRole.anggota;
  String _selectedDivisi = 'Divisi Riset & Teknologi';
  bool _statusAktif = true;
  bool _wajibGantiPassword = true;

  final List<String> _daftarDivisi = const [
    'Divisi Riset & Teknologi',
    'Divisi Media & Informasi',
    'Divisi Pengembangan Sumber Daya Mahasiswa',
    'Divisi Hubungan Masyarakat',
    'Divisi Pengabdian Masyarakat',
    'Sekretariat',
    'Badan Pengurus Harian',
  ];

  late final List<_DummyRegisteredUser> _registeredUsers;

  @override
  void initState() {
    super.initState();
    _registeredUsers = [
      _DummyRegisteredUser(
        nama: 'Farhan Ramadhan',
        email: 'farhan@hima-ti.org',
        nim: '22001122',
        role: UserRole.kepalaDivisi,
        divisi: 'Divisi Riset & Teknologi',
        statusAkun: 'aktif',
        wajibGantiPassword: false,
      ),
      _DummyRegisteredUser(
        nama: 'Aisyah Putri',
        email: 'aisyah@hima-ti.org',
        nim: '22003355',
        role: UserRole.anggota,
        divisi: 'Divisi Media & Informasi',
        statusAkun: 'aktif',
        wajibGantiPassword: true,
      ),
      _DummyRegisteredUser(
        nama: 'Rizky Pratama',
        email: 'rizky@hima-ti.org',
        nim: '22004466',
        role: UserRole.bendahara,
        divisi: 'Badan Pengurus Harian',
        statusAkun: 'aktif',
        wajibGantiPassword: false,
      ),
    ];
  }

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _nimController.dispose();
    super.dispose();
  }

  void _onCategoryChanged(UserCategory category) {
    setState(() {
      _selectedCategory = category;
      if (category == UserCategory.member) {
        _selectedRole = UserRole.anggota;
      } else {
        _selectedRole = UserRole.kepalaDivisi;
      }
    });
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final newUser = _DummyRegisteredUser(
      nama: _namaController.text.trim(),
      email: _emailController.text.trim(),
      nim: _nimController.text.trim().isNotEmpty
          ? _nimController.text.trim()
          : null,
      role: _selectedRole,
      divisi: _selectedDivisi,
      statusAkun: _statusAktif ? 'aktif' : 'nonaktif',
      wajibGantiPassword: _wajibGantiPassword,
    );

    setState(() {
      _registeredUsers.insert(0, newUser);
    });

    _showSuccessDialog(newUser);

    _namaController.clear();
    _emailController.clear();
    _nimController.clear();
    setState(() {
      _selectedCategory = UserCategory.member;
      _selectedRole = UserRole.anggota;
      _statusAktif = true;
      _wajibGantiPassword = true;
    });
  }

  void _showSuccessDialog(_DummyRegisteredUser user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 24),
            SizedBox(width: 8),
            Text(
              'Pengguna Terdaftar!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Akun untuk ${user.nama} berhasil dibuat secara dummy untuk pengujian frontend.',
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Email: ${user.email}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Role: ${user.role.label}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Divisi: ${user.divisi}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    user.wajibGantiPassword
                        ? 'Wajib ganti password pada login pertama'
                        : 'Password langsung aktif',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Tutup',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader(),
          const SizedBox(height: 20),
          // _buildSecretaryNoticeBanner(),
          // const SizedBox(height: 24),
          _buildRegistrationForm(),
          const SizedBox(height: 32),
          _buildRecentRegisteredUsersHeader(),
          const SizedBox(height: 12),
          _buildRecentUsersList(),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // PAGE HEADER
  // ─────────────────────────────────────────────────────────────
  Widget _buildPageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tambah Pengguna Baru',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Daftarkan akun anggota baru atau jajaran pengurus organisasi',
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // NOTICE BANNER
  // ─────────────────────────────────────────────────────────────
  // Widget _buildSecretaryNoticeBanner() {
  //   return Container(
  //     padding: const EdgeInsets.all(14),
  //     decoration: BoxDecoration(
  //       color: AppTheme.lightBlue,
  //       borderRadius: BorderRadius.circular(14),
  //       border: Border.all(color: AppTheme.borderLight),
  //     ),
  //     child: const Row(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Icon(
  //           Icons.admin_panel_settings_rounded,
  //           color: AppTheme.primaryBlue,
  //           size: 22,
  //         ),
  //         SizedBox(width: 12),
  //         Expanded(
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Text(
  //                 'Akses Khusus Sekretaris',
  //                 style: TextStyle(
  //                   fontSize: 13,
  //                   fontWeight: FontWeight.w700,
  //                   color: AppTheme.textPrimary,
  //                 ),
  //               ),
  //               SizedBox(height: 2),
  //               Text(
  //                 'Sekretaris memiliki wewenang untuk mendaftarkan akun baru bagi Anggota (Member) maupun Pengurus (Management).',
  //                 style: TextStyle(
  //                   fontSize: 11,
  //                   color: AppTheme.textSecondary,
  //                   height: 1.4,
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // ─────────────────────────────────────────────────────────────
  // REGISTRATION FORM CARD
  // ─────────────────────────────────────────────────────────────
  Widget _buildRegistrationForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── STEP 1: Pilih Kategori Akun ──
            _buildSectionLabel(
              number: '1',
              title: 'Kategori Akun',
              subtitle: 'Tentukan apakah akun untuk anggota atau pengurus',
            ),
            const SizedBox(height: 12),
            _buildCategorySelector(),
            const SizedBox(height: 24),

            const Divider(height: 1),
            const SizedBox(height: 24),

            // ── STEP 2: Informasi Pribadi ──
            _buildSectionLabel(
              number: '2',
              title: 'Informasi Pribadi & Akun',
              subtitle: 'Data dasar untuk identitas pengguna',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _namaController,
              label: 'Nama Lengkap',
              hint: 'Masukkan nama lengkap',
              icon: Icons.badge_outlined,
              isRequired: true,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Nama lengkap wajib diisi';
                }
                if (val.trim().length < 3) {
                  return 'Nama minimal 3 karakter';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _emailController,
              label: 'Alamat Email',
              hint: 'nama@hima-ti.org',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              isRequired: true,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Email wajib diisi';
                }
                if (!val.contains('@') || !val.contains('.')) {
                  return 'Format email tidak valid';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _nimController,
              label: 'NIM (Nomor Induk Mahasiswa)',
              hint: 'Contoh: 20240801001',
              icon: Icons.numbers_rounded,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),

            const Divider(height: 1),
            const SizedBox(height: 24),

            // ── STEP 3: Peran & Divisi ──
            _buildSectionLabel(
              number: '3',
              title: 'Peran & Penempatan Divisi',
              subtitle: 'Atur hak akses dan posisi dalam organisasi',
            ),
            const SizedBox(height: 16),
            if (_selectedCategory == UserCategory.management) ...[
              DropdownButtonFormField<UserRole>(
                value: _selectedRole,
                decoration: _inputDecoration(
                  label: 'Pilih Role Pengurus',
                  icon: Icons.workspaces_outline,
                  isRequired: true,
                ),
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
                onChanged: (role) {
                  if (role != null) {
                    setState(() => _selectedRole = role);
                  }
                },
              ),
              const SizedBox(height: 14),
            ] else ...[
              _buildMemberRoleNotice(),
              const SizedBox(height: 14),
            ],
            DropdownButtonFormField<String>(
              value: _selectedDivisi,
              isExpanded: true,

              selectedItemBuilder: (context) {
                return _daftarDivisi.map((divisi) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      divisi,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: Colors.black),
                    ),
                  );
                }).toList();
              },

              decoration: _inputDecoration(
                label: 'Penempatan Divisi',
                icon: Icons.corporate_fare_rounded,
                isRequired: true,
              ),

              items: _daftarDivisi.map((divisi) {
                return DropdownMenuItem<String>(
                  value: divisi,
                  child: Text(
                    divisi,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                );
              }).toList(),

              onChanged: (divisi) {
                if (divisi != null) {
                  setState(() => _selectedDivisi = divisi);
                }
              },
            ),
            const SizedBox(height: 24),

            const Divider(height: 1),
            const SizedBox(height: 20),

            // ── STEP 4: Pengaturan Keamanan ──
            _buildSectionLabel(
              number: '4',
              title: 'Status & Keamanan Akun',
              subtitle: 'Pengaturan tambahan untuk akun pengguna',
            ),
            const SizedBox(height: 8),
            _buildSwitchTile(
              title: 'Status Akun Aktif',
              subtitle: 'Akun dapat langsung login setelah didaftarkan',
              value: _statusAktif,
              onChanged: (val) => setState(() => _statusAktif = val),
            ),
            _buildSwitchTile(
              title: 'Wajib Ganti Password Pertama Kali',
              subtitle: 'Pengguna akan diminta membuat password baru saat login perdana',
              value: _wajibGantiPassword,
              onChanged: (val) => setState(() => _wajibGantiPassword = val),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _handleSubmit,
                icon: const Icon(Icons.person_add_rounded, size: 18),
                label: const Text('Daftarkan Pengguna'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // REUSABLE WIDGETS
  // ─────────────────────────────────────────────────────────────

  Widget _buildSectionLabel({
    required String number,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTheme.lightBlue,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryBlue,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    bool isRequired = false,
  }) {
    return InputDecoration(
      labelText: isRequired ? '$label *' : label,
      prefixIcon: Icon(icon, size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool isRequired = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        labelStyle: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildCategoryTab(
              category: UserCategory.member,
              icon: Icons.person_rounded,
              label: 'Anggota',
            ),
          ),
          Expanded(
            child: _buildCategoryTab(
              category: UserCategory.management,
              icon: Icons.manage_accounts_rounded,
              label: 'Pengurus',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTab({
    required UserCategory category,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () => _onCategoryChanged(category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberRoleNotice() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            color: AppTheme.primaryBlue,
            size: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Role Akun: Anggota Biasa (Member)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
              height: 1.35,
            ),
          ),
        ),
        value: value,
        activeColor: AppTheme.primaryBlue,
        onChanged: onChanged,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // RECENT USERS SECTION
  // ─────────────────────────────────────────────────────────────

  Widget _buildRecentRegisteredUsersHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Pengguna Baru Terdaftar',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.lightBlue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${_registeredUsers.length} Pengguna',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryBlue,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentUsersList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _registeredUsers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final user = _registeredUsers[index];
        final isActive = user.statusAkun == 'aktif';
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.lightBlue,
                child: Text(
                  user.nama.isNotEmpty ? user.nama[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryBlue,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            user.nama,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        RoleBadge(role: user.role),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.workspaces_outline,
                          size: 13,
                          color: AppTheme.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            user.divisi,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppTheme.successBg
                                : AppTheme.warningBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isActive ? 'Aktif' : 'Nonaktif',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isActive
                                  ? AppTheme.success
                                  : AppTheme.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DummyRegisteredUser {
  final String nama;
  final String email;
  final String? nim;
  final UserRole role;
  final String divisi;
  final String statusAkun;
  final bool wajibGantiPassword;

  _DummyRegisteredUser({
    required this.nama,
    required this.email,
    this.nim,
    required this.role,
    required this.divisi,
    required this.statusAkun,
    required this.wajibGantiPassword,
  });
}
