import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../enums/user_role.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/division_service.dart';
import '../agenda/agenda_page.dart';
import '../approval/dekan_approval_page.dart';
import '../finance/finance_page.dart';
import '../profile/profile_page.dart';
import '../tasks/tasks_page.dart';
import '../users/user_approval_page.dart';
import 'dashboard_home_view.dart';

class DashboardNavItem {
  final String label;
  final IconData icon;

  const DashboardNavItem({required this.label, required this.icon});
}

/// Halaman Kerangka Dashboard Utama untuk Seluruh Role di OrgaFlow.
/// Mengatur navigasi tab bawah (Bottom Navigation Bar) secara dinamis sesuai role.
class DashboardPage extends StatefulWidget {
  final UserProfile profile;
  final AuthService? authService;
  final DivisionNameLoader? divisionNameLoader;

  const DashboardPage({
    super.key,
    required this.profile,
    this.authService,
    this.divisionNameLoader,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  List<DashboardNavItem> get _navItems {
    final role = widget.profile.role;
    final items = <DashboardNavItem>[
      const DashboardNavItem(label: 'Beranda', icon: Icons.dashboard_outlined),
      const DashboardNavItem(
        label: 'Agenda',
        icon: Icons.event_available_outlined,
      ),
      const DashboardNavItem(label: 'Tugas', icon: Icons.assignment_outlined),
    ];

    if (role == UserRole.dekan) {
      items.add(
        const DashboardNavItem(
          label: 'Persetujuan',
          icon: Icons.approval_outlined,
        ),
      );
    }

    // Semua role memiliki akses tab Keuangan
    items.add(
      const DashboardNavItem(
        label: 'Keuangan',
        icon: Icons.account_balance_wallet_outlined,
      ),
    );

    if (role == UserRole.sekretaris) {
      items.add(
        const DashboardNavItem(
          label: 'Pengguna',
          icon: Icons.person_add_alt_1_outlined,
        ),
      );
    }

    return items;
  }

  void _navigateToLabel(String label) {
    final idx = _navItems.indexWhere((item) => item.label == label);
    if (idx != -1) {
      setState(() => _selectedIndex = idx);
    }
  }

  @override
  Widget build(BuildContext context) {
    final navItems = _navItems;
    final clampedIndex = _selectedIndex.clamp(0, navItems.length - 1);
    final currentLabel = navItems[clampedIndex].label;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          AppConstants.appName,
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.3),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ProfilePage(
                      profile: widget.profile,
                      authService: widget.authService,
                      divisionNameLoader: widget.divisionNameLoader,
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(20),
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
          ),
        ],
      ),
      body: _buildCurrentTab(currentLabel),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: clampedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppTheme.surface,
        selectedItemColor: AppTheme.primaryBlue,
        unselectedItemColor: AppTheme.textSecondary,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: navItems
            .map(
              (item) => BottomNavigationBarItem(
                icon: Icon(item.icon),
                label: item.label,
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildCurrentTab(String currentLabel) {
    switch (currentLabel) {
      case 'Beranda':
        return DashboardHomeView(
          profile: widget.profile,
          divisionNameLoader: widget.divisionNameLoader,
          onNavigateToTasks: () => _navigateToLabel('Tugas'),
          onNavigateToAgenda: () => _navigateToLabel('Agenda'),
        );
      case 'Tugas':
        return TasksPage(role: widget.profile.role);
      case 'Agenda':
        return AgendaPage(
          userName: widget.profile.nama,
          role: widget.profile.role,
        );
      case 'Persetujuan':
        return DekanApprovalPage();
      case 'Keuangan':
        return FinancePage(
          userRole: widget.profile.role,
          userName: widget.profile.nama,
        );
      case 'Pengguna':
        return const UserApprovalPage();
      default:
        return Center(
          child: Text(
            'Halaman $currentLabel',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        );
    }
  }
}

/// Backward compatibility untuk pengujian atau import lama
class ManagementDashboard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return DashboardPage(
      profile: profile,
      authService: authService,
      divisionNameLoader: divisionNameLoader,
    );
  }
}

/// Backward compatibility untuk pengujian atau import lama
class MemberDashboard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return DashboardPage(
      profile: profile,
      authService: authService,
      divisionNameLoader: divisionNameLoader,
    );
  }
}
