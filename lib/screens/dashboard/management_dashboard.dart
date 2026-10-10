import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/role_badge.dart';

class ManagementDashboard extends StatelessWidget {
  final UserProfile profile;
  final AuthService? authService;

  const ManagementDashboard({
    super.key,
    required this.profile,
    this.authService,
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.hub_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              AppConstants.appName,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Keluar Akun',
            icon: const Icon(Icons.logout_rounded, color: AppTheme.error),
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kartu Identitas & Sambutan Pengurus
            _buildOfficerHeaderCard(),

            const SizedBox(height: 24),

            // Header Bagian
            Row(
              children: [
                const Icon(
                  Icons.dashboard_customize_rounded,
                  size: 20,
                  color: AppTheme.primaryBlue,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Dashboard Pengurus',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Ringkasan Organisasi & Modul Pengurus',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),

            const SizedBox(height: 16),

            // Grid Kartu Placeholder Pengurus
            _buildModuleGrid(),

            const SizedBox(height: 20),

            // Banner Informasi Tahap Pengembangan
            _buildDevelopmentNotice(),

            const SizedBox(height: 28),

            // Tombol Logout Bawah
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.error, width: 1.2),
                foregroundColor: AppTheme.error,
              ),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text(
                'Keluar dari Aplikasi',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              onPressed: () => _handleLogout(context),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildOfficerHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris Badge PENGURUS & Label Role
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RoleBadge(role: profile.role),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.lightBlue,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Role: ${profile.role.label}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.accentBlue,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            'Selamat datang, ${profile.nama}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            AppConstants.organizationName,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),

          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Detail Info Pengurus
          Row(
            children: [
              const Icon(
                Icons.email_outlined,
                size: 15,
                color: AppTheme.textMuted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  profile.email,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (profile.nim != null && profile.nim!.isNotEmpty) ...[
                const SizedBox(width: 12),
                const Icon(
                  Icons.badge_outlined,
                  size: 15,
                  color: AppTheme.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  'NIM: ${profile.nim}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModuleGrid() {
    final modules = [
      _ModuleItem(
        icon: Icons.event_note_rounded,
        title: 'Kegiatan Organisasi',
        description: 'Kelola jadwal, perencanaan, dan status kegiatan HIMA TI.',
      ),
      _ModuleItem(
        icon: Icons.assignment_outlined,
        title: 'Tugas Divisi',
        description: 'Distribusi serta pemantauan perkembangan tugas divisi.',
      ),
      _ModuleItem(
        icon: Icons.groups_outlined,
        title: 'Data Anggota',
        description:
            'Manajemen direktori pengurus dan seluruh anggota organisasi.',
      ),
      _ModuleItem(
        icon: Icons.campaign_outlined,
        title: 'Pengumuman',
        description: 'Publikasi informasi resmi kepada seluruh anggota.',
      ),
    ];

    return Column(children: modules.map((m) => _buildModuleCard(m)).toList());
  }

  Widget _buildModuleCard(_ModuleItem module) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.lightBlue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(module.icon, color: AppTheme.accentBlue, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        module.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: const Text(
                        'Tahap Berikutnya',
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  module.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDevelopmentNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.lightBlue,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accentBlue.withValues(alpha: 0.2)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: AppTheme.accentBlue,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tahap Pertama: Autentikasi dan identitas role pengurus telah aktif. Fitur CRUD kegiatan, tugas, data anggota, dan pengumuman akan diimplementasikan pada tahap selanjutnya.',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.primaryBlue,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleItem {
  final IconData icon;
  final String title;
  final String description;

  _ModuleItem({
    required this.icon,
    required this.title,
    required this.description,
  });
}
