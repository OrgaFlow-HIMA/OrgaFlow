import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../enums/user_role.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/division_service.dart';
import '../../widgets/confirmation_dialog.dart';
import '../agenda/agenda_page.dart';
import '../finance/finance_page.dart';
import '../tasks/bendahara_tugas_page.dart';
import '../tasks/ketua_tugas_page.dart';
import '../tasks/sekretaris_tugas_page.dart';
import '../tasks/wakil_ketua_tugas_page.dart';
import '../users/add_user_screen.dart';
import 'models/management_dashboard_content.dart';
import 'views/management_home_view.dart';

// Re-export halaman agar backward-compatible dengan import yang sudah ada
export '../agenda/agenda_page.dart';
export '../finance/finance_page.dart';
export '../tasks/bendahara_tugas_page.dart';
export '../tasks/ketua_tugas_page.dart';
export '../tasks/sekretaris_tugas_page.dart';
export '../tasks/wakil_ketua_tugas_page.dart';
export '../users/add_user_screen.dart';
export 'models/management_dashboard_content.dart';
export 'views/management_home_view.dart';

class ManagementDashboard extends StatefulWidget {
  final UserProfile profile;
  final AuthService? authService;
  final DivisionNameLoader? divisionNameLoader;

  const ManagementDashboard({
    super.key,
    required this.profile,
    this.authService,
    this.divisionNameLoader,
  });

  @override
  State<ManagementDashboard> createState() => _ManagementDashboardState();
}

class _ManagementDashboardState extends State<ManagementDashboard> {
  int _selectedIndex = 0;

  /// Hanya Ketua, Wakil Ketua, Bendahara, dan Sekretaris yang memiliki akses ke fitur Keuangan/Kas.
  /// Kepala Divisi (Kadiv) tidak memiliki akses.
  bool get _canAccessKas =>
      widget.profile.role == UserRole.ketua ||
      widget.profile.role == UserRole.wakilKetua ||
      widget.profile.role == UserRole.bendahara ||
      widget.profile.role == UserRole.sekretaris;

  /// Hanya Sekretaris yang memiliki tab pendaftaran pengguna baru (Tambah User).
  bool get _isSekretaris => widget.profile.role == UserRole.sekretaris;

  List<ManagementNavItem> get _navItems {
    final items = <ManagementNavItem>[
      const ManagementNavItem(label: 'Beranda', icon: Icons.dashboard_outlined),
      const ManagementNavItem(label: 'Tugas', icon: Icons.assignment_outlined),
      const ManagementNavItem(label: 'Agenda', icon: Icons.event_available_outlined),
    ];

    if (_canAccessKas) {
      items.add(
        const ManagementNavItem(
          label: 'Kas',
          icon: Icons.account_balance_wallet_outlined,
        ),
      );
    }

    if (_isSekretaris) {
      items.add(
        const ManagementNavItem(
          label: 'Tambah User',
          icon: Icons.person_add_alt_1_outlined,
        ),
      );
    }

    return items;
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Konfirmasi Keluar',
      message:
          'Apakah Anda yakin ingin keluar dari akun ${widget.profile.nama}?',
      confirmText: 'Keluar',
      cancelText: 'Batal',
      isDestructive: true,
    );

    if (confirmed == true && context.mounted) {
      final service = widget.authService ?? AuthService();
      await service.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final navItems = _navItems;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Row(
          children: [
            SizedBox(width: 10),
            Text(
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
            tooltip: 'Notifikasi',
            icon: const Icon(
              Icons.notifications_outlined,
              color: AppTheme.textPrimary,
            ),
            onPressed: () {
              // TODO: aksi notifikasi
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.lightBlue,
              backgroundImage: widget.profile.fotoUrl?.isNotEmpty == true
                  ? NetworkImage(widget.profile.fotoUrl!)
                  : null,
              child: widget.profile.fotoUrl?.isNotEmpty == true
                  ? null
                  : const Icon(
                      Icons.person_rounded,
                      color: AppTheme.primaryBlue,
                      size: 18,
                    ),
            ),
          ),
        ],
      ),
      body: _buildCurrentTab(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex.clamp(0, navItems.length - 1),
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppTheme.surface,
        selectedItemColor: AppTheme.primaryBlue,
        unselectedItemColor: AppTheme.textSecondary,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: navItems
            .map(
              (page) => BottomNavigationBarItem(
                icon: Icon(page.icon),
                label: page.label,
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildCurrentTab() {
    final navItems = _navItems;
    final currentLabel =
        navItems[_selectedIndex.clamp(0, navItems.length - 1)].label;

    switch (currentLabel) {
      case 'Beranda':
        return ManagementHomeView(
          profile: widget.profile,
          divisionNameLoader: widget.divisionNameLoader,
          onLogout: () => _handleLogout(context),
        );
      case 'Tugas':
        // Routing Halaman Tugas Sesuai Role
        if (widget.profile.role == UserRole.ketua) {
          return const KetuaTugasPage();
        } else if (widget.profile.role == UserRole.wakilKetua) {
          return const WakilKetuaTugasPage();
        } else if (widget.profile.role == UserRole.bendahara) {
          return const BendaharaTugasPage();
        } else if (widget.profile.role == UserRole.sekretaris) {
          return const SekretarisTugasPage();
        }
        return _buildPlaceholderPage('Tugas');
      case 'Agenda':
        return const AgendaPage();
      case 'Kas':
        if (_canAccessKas) {
          return FinancePage(userRole: widget.profile.role);
        }
        return _buildPlaceholderPage('Akses Ditolak');
      case 'Tambah User':
        return const AddUserPage();
      default:
        return _buildPlaceholderPage(currentLabel);
    }
  }

  Widget _buildPlaceholderPage(String label) {
    return Center(
      child: Text(
        'Ini halaman $label',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }
}
