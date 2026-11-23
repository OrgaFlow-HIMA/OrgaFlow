import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/division_service.dart';
import '../../widgets/confirmation_dialog.dart';
import '../auth/change_password_screen.dart';

class ProfilePage extends StatelessWidget {
  final UserProfile profile;
  final AuthService? authService;
  final DivisionNameLoader? divisionNameLoader;

  const ProfilePage({
    super.key,
    required this.profile,
    this.authService,
    this.divisionNameLoader,
  });

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Konfirmasi Keluar',
      message: 'Apakah Anda yakin ingin keluar dari akun ${profile.nama}?',
      confirmText: 'Keluar',
      cancelText: 'Batal',
      isDestructive: true,
    );

    if (confirmed == true && context.mounted) {
      final service = authService ?? AuthService();
      await service.signOut();
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  void _showNotificationSettings(BuildContext context) {
    // 1. Inisialisasi state awal untuk notifikasi (bisa disesuaikan dengan backend)
    bool notifAgenda = true;
    bool notifTugas = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== GRABBER =====
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
                  const SizedBox(height: 16),

                  // ===== HEADER =====
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.lightBlue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.notifications_active_outlined,
                          color: AppTheme.primaryBlue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pemberitahuan',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Atur notifikasi push di perangkat ini',
                              style: TextStyle(
                                fontSize: 12,
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
                        onPressed: () => Navigator.of(bottomSheetContext).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ===== TOMBOL SWITCH 1: AGENDA =====
                  _buildSwitchTile(
                    title: 'Agenda & Rapat Baru',
                    subtitle: 'Pemberitahuan saat rapat dijadwalkan',
                    value: notifAgenda,
                    onChanged: (val) {
                      setModalState(() => notifAgenda = val);
                      // TODO: Simpan perubahan ke backend/SharedPreferences
                    },
                  ),
                  const SizedBox(height: 10),

                  // ===== TOMBOL SWITCH 2: TUGAS =====
                  _buildSwitchTile(
                    title: 'Tugas & Tagihan Kas',
                    subtitle: 'Pengingat tugas dan tenggat iuran kas',
                    value: notifTugas,
                    onChanged: (val) {
                      setModalState(() => notifTugas = val);
                      // TODO: Simpan perubahan ke backend/SharedPreferences
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ===== HELPER WIDGET UNTUK SWITCH =====
  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.background, // Background abu tipis
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: SwitchListTile.adaptive(
        // Pakai .adaptive agar gaya native di iOS/Android
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
        ),
        value: value,
        activeColor: Colors.white, // Warna bulatan saat aktif
        activeTrackColor: AppTheme.primaryBlue, // Warna track saat aktif
        inactiveThumbColor: Colors.grey.shade400,
        inactiveTrackColor: Colors.grey.shade200,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onChanged: onChanged, // Fungsi ini yang membuat switch bisa diklik
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFDCE7FF),
              Color(0xFFEDF2FF),
              AppTheme.background,
              Colors.white,
            ],
            stops: [0.0, 0.25, 0.65, 1.0],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 380,
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _ProfileSoftBackgroundPainter(),
                  size: Size.infinite,
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 8, bottom: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProfileHeroCard(),
                          const SizedBox(height: 14),
                          _buildAccountInfoCard(),
                          const SizedBox(height: 14),
                          _buildPreferenceCard(context),
                          const SizedBox(height: 20),
                          _buildLogoutButton(context),
                          const SizedBox(height: 20),
                          const Center(
                            child: Text(
                              'OrgaFlow • HIMA Teknik Informatika\nFakultas Ilmu Komputer',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                color: Color.fromARGB(255, 118, 130, 147),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ HEADER ============

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildCircleIcon(
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profil Saya',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Informasi akun & preferensi',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _buildCircleIcon(
            icon: Icons.help_outline_rounded,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Bantuan OrgaFlow: hubungi sekretariat HIMA TI',
                  ),
                  backgroundColor: AppTheme.primaryBlue,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCircleIcon({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Icon(icon, color: AppTheme.textPrimary, size: 20),
      ),
    );
  }

  // ============ HERO CARD ============

  Widget _buildProfileHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.lightBlue, width: 3),
            ),
            child: CircleAvatar(
              radius: 44,
              backgroundColor: AppTheme.lightBlue,
              backgroundImage: profile.fotoUrl?.isNotEmpty == true
                  ? NetworkImage(profile.fotoUrl!)
                  : null,
              child: profile.fotoUrl?.isNotEmpty == true
                  ? null
                  : const Icon(
                      Icons.person_rounded,
                      size: 44,
                      color: AppTheme.primaryBlue,
                    ),
            ),
          ),
          const SizedBox(height: 14),

          // Nama
          Text(
            profile.nama.isNotEmpty ? profile.nama : '-',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),

          // NIM
          Text(
            'NIM ${_safe(profile.nim)}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),

          // Chip Role & Divisi & Periode
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              _buildChip(
                icon: Icons.shield_outlined,
                label: profile.role.label,
                color: AppTheme.primaryBlue,
                bgColor: AppTheme.lightBlue,
              ),
              if (profile.divisiId != null && profile.divisiId!.isNotEmpty)
                _buildDivisionChip(),
              if (profile.periode.isNotEmpty)
                _buildChip(
                  icon: Icons.calendar_today_outlined,
                  label: profile.periode,
                  color: AppTheme.textSecondary,
                  bgColor: AppTheme.background,
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Chip divisi yang resolve nama dari Firestore lewat `divisionNameLoader`.
  /// Jika loader null / error → fallback ke ID mentah.
  Widget _buildDivisionChip() {
    if (divisionNameLoader == null) {
      return _buildChip(
        icon: Icons.groups_outlined,
        label: profile.divisiId!,
        color: AppTheme.primaryBlue,
        bgColor: AppTheme.lightBlue,
      );
    }

    return FutureBuilder<String?>(
      future: divisionNameLoader!.getDivisionName(profile.divisiId!),
      builder: (context, snap) {
        final label = (snap.data != null && snap.data!.isNotEmpty)
            ? snap.data!
            : profile.divisiId!;
        return _buildChip(
          icon: Icons.groups_outlined,
          label: label,
          color: AppTheme.primaryBlue,
          bgColor: AppTheme.lightBlue,
        );
      },
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============ ACCOUNT INFO CARD ============

  Widget _buildAccountInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.lightBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.badge_outlined,
                  size: 16,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Informasi Akun',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              _buildStatusChip(),
            ],
          ),
          const SizedBox(height: 14),

          // === Semua field dari database ===
          _buildInfoTile(
            icon: Icons.alternate_email_rounded,
            iconColor: AppTheme.primaryBlue,
            label: 'Email Kampus',
            value: _safe(profile.email),
          ),
          const SizedBox(height: 10),
          _buildInfoTile(
            icon: Icons.phone_rounded,
            iconColor: AppTheme.success,
            label: 'Nomor WhatsApp',
            value: _safe(profile.noWa),
          ),
          if (profile.divisiId != null && profile.divisiId!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildInfoTile(
              icon: Icons.groups_outlined,
              iconColor: AppTheme.accentBlue,
              label: 'Divisi',
              value: profile.divisiId!,
            ),
          ],
          if (profile.periode.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildInfoTile(
              icon: Icons.calendar_month_outlined,
              iconColor: AppTheme.warning,
              label: 'Periode Kepengurusan',
              value: profile.periode,
            ),
          ],
        ],
      ),
    );
  }

  /// Chip status (Aktif / Menunggu / Ditolak) berdasarkan `profile`.
  Widget _buildStatusChip() {
    String label;
    Color bg;
    Color fg;

    if (profile.isActive) {
      label = 'Aktif';
      bg = AppTheme.successBg;
      fg = AppTheme.success;
    } else if (profile.isPending) {
      label = 'Menunggu';
      bg = AppTheme.warningBg;
      fg = AppTheme.warning;
    } else if (profile.isRejected) {
      label = 'Ditolak';
      bg = AppTheme.errorBg;
      fg = AppTheme.error;
    } else {
      label = 'Tidak Diketahui';
      bg = const Color(0xFFF1F5F9);
      fg = AppTheme.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============ PREFERENCE CARD ============

  Widget _buildPreferenceCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.lightBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.settings_outlined,
                  size: 16,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Preferensi',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildPreferenceTile(
            icon: Icons.lock_outline_rounded,
            label: 'Ubah Kata Sandi',
            subtitle: 'Perbarui kata sandi akun secara berkala',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ChangePasswordScreen(
                    profile: profile,
                    authService: authService,
                    onSuccess: () => Navigator.of(context).pop(),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          _buildPreferenceTile(
            icon: Icons.notifications_none_rounded,
            label: 'Pemberitahuan & Notifikasi',
            subtitle: 'Atur notifikasi rapat dan surat masuk',
            onTap: () => _showNotificationSettings(context),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: AppTheme.primaryBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============ LOGOUT BUTTON ============

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: OutlinedButton.icon(
        onPressed: () => _handleLogout(context),
        icon: const Icon(Icons.logout_rounded, size: 16, color: AppTheme.error),
        label: const Text(
          'Keluar dari Akun',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTheme.error,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: AppTheme.errorBg,
          side: BorderSide(color: AppTheme.error.withOpacity(0.3)),
          shape: const StadiumBorder(),
          padding: EdgeInsets.zero,
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  // ============ HELPER ============

  /// Kembalikan `-` jika string null/kosong.
  String _safe(String? value) {
    if (value == null || value.trim().isEmpty) return '-';
    return value;
  }
}

// ============ SOFT BACKGROUND PAINTER ============

class _ProfileSoftBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    final wave1 = Path()
      ..moveTo(0, 0)
      ..lineTo(width, 0)
      ..lineTo(width, height * 0.48)
      ..cubicTo(
        width * 0.78,
        height * 0.58,
        width * 0.55,
        height * 0.35,
        width * 0.30,
        height * 0.48,
      )
      ..cubicTo(
        width * 0.15,
        height * 0.56,
        width * 0.08,
        height * 0.50,
        0,
        height * 0.43,
      )
      ..close();

    final paint1 = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0x80B8CCFF), Color(0x66D5E1FF), Color(0x33EAF0FF)],
      ).createShader(Rect.fromLTWH(0, 0, width, height));
    canvas.drawPath(wave1, paint1);

    final wave2 = Path()
      ..moveTo(0, height * 0.28)
      ..cubicTo(
        width * 0.25,
        height * 0.42,
        width * 0.55,
        height * 0.18,
        width,
        height * 0.38,
      )
      ..lineTo(width, height * 0.65)
      ..cubicTo(
        width * 0.68,
        height * 0.53,
        width * 0.35,
        height * 0.72,
        0,
        height * 0.55,
      )
      ..close();

    final paint2 = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [Color(0x3386A8FF), Color(0x1F86A8FF), Color(0x00FFFFFF)],
      ).createShader(Rect.fromLTWH(0, 0, width, height));
    canvas.drawPath(wave2, paint2);

    final wave3 = Path()
      ..moveTo(0, height * 0.48)
      ..cubicTo(
        width * 0.30,
        height * 0.65,
        width * 0.65,
        height * 0.38,
        width,
        height * 0.55,
      )
      ..lineTo(width, height * 0.78)
      ..cubicTo(
        width * 0.60,
        height * 0.67,
        width * 0.30,
        height * 0.83,
        0,
        height * 0.68,
      )
      ..close();

    canvas.drawPath(wave3, Paint()..color = const Color(0x1486A8FF));
  }

  @override
  bool shouldRepaint(covariant _ProfileSoftBackgroundPainter oldDelegate) =>
      false;
}
