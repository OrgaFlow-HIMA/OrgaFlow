import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../enums/user_role.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/division_service.dart';
import '../agenda/agenda_page.dart';
import '../approval/dekan_approval_page.dart';
import '../finance/finance_page.dart';
import '../tasks/tasks_page.dart';
import '../users/user_approval_page.dart';
import 'dashboard_home_view.dart';
import '../../widgets/custom_bottom_nav.dart';

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
      const DashboardNavItem(label: 'Beranda', icon: Icons.home_outlined),
      const DashboardNavItem(label: 'Tugas', icon: Icons.assignment_outlined),
      const DashboardNavItem(
        label: 'Agenda',
        icon: Icons.event_available_outlined,
      ),
      const DashboardNavItem(
        label: 'Keuangan',
        icon: Icons.account_balance_wallet_outlined,
      ),
    ];

    if (role == UserRole.dekan) {
      items.add(
        const DashboardNavItem(
          label: 'Persetujuan',
          icon: Icons.approval_outlined,
        ),
      );
    }

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
      extendBody: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: KeyedSubtree(
          key: ValueKey(currentLabel),
          child: _buildCurrentTab(currentLabel),
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: clampedIndex,
        onItemSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        items: navItems,
      ),
    );
  }

  Widget _buildCurrentTab(String currentLabel) {
    switch (currentLabel) {
      case 'Beranda':
        return DashboardHomeView(
          profile: widget.profile,
          authService: widget.authService,
          divisionNameLoader: widget.divisionNameLoader,
          onNavigateToTasks: () => _navigateToLabel('Tugas'),
          onNavigateToAgenda: () => _navigateToLabel('Agenda'),
          onNavigateToFinance: () => _navigateToLabel('Keuangan'),
        );
      case 'Tugas':
        return TasksPage(role: widget.profile.role);
      case 'Agenda':
        return AgendaPage(
          userName: widget.profile.nama,
          role: widget.profile.role,
        );
      case 'Persetujuan':
        return const DekanApprovalPage();
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
