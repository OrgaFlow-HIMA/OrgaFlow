import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/division_service.dart';
import '../../widgets/confirmation_dialog.dart';
import '../agenda/agenda_page.dart';
import '../tasks/member_tugas_page.dart';
import 'views/member_home_view.dart';

export '../agenda/agenda_page.dart';
export '../tasks/member_tugas_page.dart';
export 'views/member_home_view.dart';

class MemberDashboard extends StatefulWidget {
  final UserProfile profile;
  final AuthService? authService;
  final DivisionNameLoader? divisionNameLoader;

  const MemberDashboard({
    super.key,
    required this.profile,
    this.authService,
    this.divisionNameLoader,
  });

  @override
  State<MemberDashboard> createState() => _MemberDashboardState();
}

class _MemberDashboardState extends State<MemberDashboard> {
  int _selectedIndex = 0;

  static const List<_MemberNavItem> _memberPages = [
    _MemberNavItem(label: 'Beranda', icon: Icons.grid_view_rounded),
    _MemberNavItem(label: 'Tugas', icon: Icons.assignment_outlined),
    _MemberNavItem(label: 'Agenda', icon: Icons.event_available_outlined),
  ];

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
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Row(
          children: [
            // Container(
            //   padding: const EdgeInsets.all(6),
            //   decoration: BoxDecoration(
            //     color: AppTheme.primaryBlue,
            //     borderRadius: BorderRadius.circular(8),
            //   ),
            //   child: const Icon(
            //     Icons.hub_rounded,
            //     color: Colors.white,
            //     size: 18,
            //   ),
            // ),
            // const SizedBox(width: 10),
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
            tooltip: 'Notifikasi',
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.lightBlue,
              child: const Icon(
                Icons.person_rounded,
                color: AppTheme.anggotaPrimary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
      body: _buildCurrentTab(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: AppTheme.anggotaPrimary,
        unselectedItemColor: AppTheme.textSecondary,
        backgroundColor: AppTheme.surface,
        showUnselectedLabels: true,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: _memberPages
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
    switch (_selectedIndex) {
      case 0:
        return MemberHomeView(
          profile: widget.profile,
          divisionNameLoader: widget.divisionNameLoader,
          onLogout: () => _handleLogout(context),
        );
      case 1:
        return const MemberTugasPage();
      case 2:
        return const AgendaPage();
      default:
        return _buildPlaceholderPage(_memberPages[_selectedIndex].label);
    }
  }

  Widget _buildPlaceholderPage(String label) {
    return Center(
      child: Text(
        'Ini halaman $label',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }
}

class _MemberNavItem {
  final String label;
  final IconData icon;
  const _MemberNavItem({required this.label, required this.icon});
}
