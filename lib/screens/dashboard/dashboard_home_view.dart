import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../enums/user_role.dart';
import '../../models/agenda.dart';
import '../../models/task.dart';
import '../../models/user_profile.dart';
import '../../models/proposal.dart';
import '../../services/division_monitoring_service.dart';
import '../../services/proposal_service.dart';
import '../../services/agenda_service.dart';
import '../../services/auth_service.dart';
import '../../services/division_service.dart';
import '../../services/task_service.dart';
import '../../widgets/division_name_text.dart';
import '../announcement/announcement_page.dart';
import '../approval/approval_page.dart';
import '../approval/proposal_page.dart';
import '../attendance/attendance_page.dart';
import '../monitoring/division_monitoring_page.dart';
import '../notifications/notification_page.dart';
import '../profile/profile_page.dart';
import '../../services/notification_service.dart';

class DashboardCaptions {
  final String greetingSubtitle;
  final String taskSectionTitle;
  final String noteFocus;

  const DashboardCaptions({
    required this.greetingSubtitle,
    required this.taskSectionTitle,
    required this.noteFocus,
  });
}

class DashboardHomeView extends StatefulWidget {
  final UserProfile profile;
  final AuthService? authService;
  final DivisionNameLoader? divisionNameLoader;
  final VoidCallback? onNavigateToTasks;
  final VoidCallback? onNavigateToMonitoring;
  final VoidCallback? onNavigateToApproval;
  final VoidCallback? onNavigateToAgenda;
  final VoidCallback? onNavigateToFinance;
  final VoidCallback? onNavigateToAdministration;

  const DashboardHomeView({
    super.key,
    required this.profile,
    this.authService,
    this.divisionNameLoader,
    this.onNavigateToTasks,
    this.onNavigateToMonitoring,
    this.onNavigateToApproval,
    this.onNavigateToAgenda,
    this.onNavigateToFinance,
    this.onNavigateToAdministration,
  });

  @override
  State<DashboardHomeView> createState() => _DashboardHomeViewState();
}

class _DashboardHomeViewState extends State<DashboardHomeView> {
  final TaskService _taskService = TaskService();
  final AgendaService _agendaService = AgendaService();
  final ProposalService _proposalService = ProposalService();
  final DivisionMonitoringService _monitoringService =
      DivisionMonitoringService();

  DashboardCaptions _getCaptions(UserRole role) {
    switch (role) {
      case UserRole.dekan:
        return const DashboardCaptions(
          greetingSubtitle: 'Kelola kebijakan dan persetujuan tingkat dekanat',
          taskSectionTitle: 'Daftar Persetujuan Terbaru',
          noteFocus: 'Fokus: Persetujuan proposal berkas dan pengawasan capaian strategis himpunan.',
        );
      case UserRole.ketua:
        return const DashboardCaptions(
          greetingSubtitle: 'Koordinasi dan pantau seluruh alur organisasi',
          taskSectionTitle: 'Daftar Persetujuan Terbaru',
          noteFocus: 'Fokus: Koordinasi internal pengurus inti dan pengawasan berkala program kerja.',
        );
      case UserRole.wakilKetua:
        return const DashboardCaptions(
          greetingSubtitle: 'Pantau kinerja divisi dan progres operasional',
          taskSectionTitle: 'Monitoring Performa Divisi',
          noteFocus: 'Fokus: Evaluasi kinerja divisi dan asistensi ketua dalam pelaksanaan proker.',
        );
      case UserRole.sekretaris:
        return const DashboardCaptions(
          greetingSubtitle: 'Kelola administrasi, tugas, dan agenda organisasi',
          taskSectionTitle: 'Tugas yang Dibuat / Berjalan',
          noteFocus: 'Fokus: Pendelegasian tugas antar-divisi dan pencatatan jadwal agenda rapat.',
        );
      case UserRole.bendahara:
        return const DashboardCaptions(
          greetingSubtitle:
              'Pantau arus kas dan verifikasi keuangan organisasi',
          taskSectionTitle: 'Tugas Keuangan & Verifikasi',
          noteFocus: 'Fokus: Pencatatan kas berkala dan verifikasi pembayaran iuran anggota.',
        );
      case UserRole.kepalaDivisi:
        return const DashboardCaptions(
          greetingSubtitle: 'Kelola koordinasi dan progres anggota divisi Anda',
          taskSectionTitle: 'Tugas Divisi',
          noteFocus: 'Fokus: Penyelesaian program kerja divisi bersama seluruh anggota.',
        );
      case UserRole.anggota:
        return const DashboardCaptions(
          greetingSubtitle:
              'Aktivitas dan tugas Anda di HIMA Teknik Informatika',
          taskSectionTitle: 'Tugas Saya',
          noteFocus: 'Fokus: Partisipasi aktif dalam kegiatan divisi dan kehadiran rapat organisasi.',
        );
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;

    if (hour >= 4 && hour < 11) return 'Selamat pagi';
    if (hour >= 11 && hour < 15) return 'Selamat siang';
    if (hour >= 15 && hour < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  @override
  Widget build(BuildContext context) {
    final captions = _getCaptions(widget.profile.role);
    final role = widget.profile.role;
    final isDekan = role == UserRole.dekan;
    final isKetua = role == UserRole.ketua;
    final isWakilKetua = role == UserRole.wakilKetua;
    final isSekretaris = role == UserRole.sekretaris;
    final isBendahara = role == UserRole.bendahara;
    final isKadiv = role == UserRole.kepalaDivisi;
    final divisionId = widget.profile.divisiId;

    final tasksStream = isSekretaris
        ? _taskService.watchAllTasks()
        : isBendahara
        ? _taskService.watchTasksForBendahara(widget.profile.uid)
        : (isKadiv && divisionId != null && divisionId.isNotEmpty)
        ? _taskService.watchTasksForDivision(divisionId)
        : _taskService.watchTasksForMember(widget.profile.uid);

    final agendaStream = _agendaService.watchAgendas();

    return Container(
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
          // Abstract flowing wave background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 550,
            child: CustomPaint(
              painter: DashboardBackgroundPainter(),
              size: Size.infinite,
            ),
          ),

          // Konten dashboard
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 16, bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER, GREETING, DAN RINGKASAN
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBrandHeader(),
                        const SizedBox(height: 25),
                        _buildWelcomeCard(captions),
                        const SizedBox(height: 24),

                        // Ringkasan real-time Firestore
                        if (isDekan || isKetua)
                          StreamBuilder<List<Proposal>>(
                            stream: _proposalService.watchAllProposals(),
                            builder: (context, propSnap) {
                              final proposals = propSnap.data ?? [];
                              final pendingProposals = proposals
                                  .where(
                                    (p) => p.status == ProposalStatus.menunggu,
                                  )
                                  .toList();

                              return StreamBuilder<List<Agenda>>(
                                stream: agendaStream,
                                builder: (context, agendaSnap) {
                                  final agendas = agendaSnap.data ?? [];
                                  final upcomingAgendas = agendas
                                      .where((agenda) => !agenda.isPast)
                                      .toList();

                                  return Row(
                                    children: [
                                      Expanded(
                                        child: _buildSummaryCard(
                                          title: 'Perlu Persetujuan',
                                          value: '${pendingProposals.length}',
                                          subtitle: pendingProposals.isEmpty
                                              ? 'Semua telah ditinjau'
                                              : 'Menunggu respon Anda',
                                          icon: Icons.approval_outlined,
                                          gradient: const [
                                            AppTheme.primaryBlue,
                                            AppTheme.accentBlue,
                                          ],
                                          onTap:
                                              widget.onNavigateToApproval ??
                                              () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        ApprovalPage(
                                                          userProfile:
                                                              widget.profile,
                                                          role: widget
                                                              .profile
                                                              .role,
                                                        ),
                                                  ),
                                                );
                                              },
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildSummaryCard(
                                          title: 'Agenda Mendatang',
                                          value: '${upcomingAgendas.length}',
                                          subtitle: upcomingAgendas.isEmpty
                                              ? 'Tidak ada jadwal'
                                              : 'Jadwal aktif himpunan',
                                          icon: Icons.event_available_outlined,
                                          gradient: const [
                                            AppTheme.primaryBlue,
                                            AppTheme.accentBlue,
                                          ],
                                          onTap: widget.onNavigateToAgenda,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          )
                        else if (isWakilKetua)
                          StreamBuilder<List<DivisionPerformance>>(
                            stream: _monitoringService
                                .watchAllDivisionsPerformance(),
                            builder: (context, monSnap) {
                              final divisions = monSnap.data ?? [];
                              int totalTasks = 0;
                              int completedTasks = 0;
                              for (final d in divisions) {
                                totalTasks += d.totalTasks;
                                completedTasks += d.completedTasks;
                              }
                              final rate = totalTasks > 0
                                  ? ((completedTasks / totalTasks) * 100)
                                        .round()
                                  : 0;

                              return StreamBuilder<List<Agenda>>(
                                stream: agendaStream,
                                builder: (context, agendaSnap) {
                                  final agendas = agendaSnap.data ?? [];
                                  final upcomingAgendas = agendas
                                      .where((agenda) => !agenda.isPast)
                                      .toList();

                                  return Row(
                                    children: [
                                      Expanded(
                                        child: _buildSummaryCard(
                                          title: 'Kinerja Divisi',
                                          value: '$rate%',
                                          subtitle:
                                              '${divisions.length} Divisi terpantau',
                                          icon: Icons.analytics_outlined,
                                          gradient: const [
                                            AppTheme.primaryBlue,
                                            AppTheme.accentBlue,
                                          ],
                                          onTap:
                                              widget.onNavigateToMonitoring ??
                                              () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        DivisionMonitoringPage(
                                                          userProfile:
                                                              widget.profile,
                                                          role: widget
                                                              .profile
                                                              .role,
                                                        ),
                                                  ),
                                                );
                                              },
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildSummaryCard(
                                          title: 'Agenda Mendatang',
                                          value: '${upcomingAgendas.length}',
                                          subtitle: upcomingAgendas.isEmpty
                                              ? 'Tidak ada jadwal'
                                              : 'Jadwal aktif himpunan',
                                          icon: Icons.event_available_outlined,
                                          gradient: const [
                                            AppTheme.primaryBlue,
                                            AppTheme.accentBlue,
                                          ],
                                          onTap: widget.onNavigateToAgenda,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          )
                        else
                          StreamBuilder<List<Task>>(
                            stream: tasksStream,
                            builder: (context, taskSnap) {
                              final tasks = taskSnap.data ?? [];
                              final todoTasks = tasks
                                  .where((task) => !task.isDone)
                                  .toList();

                              return StreamBuilder<List<Agenda>>(
                                stream: agendaStream,
                                builder: (context, agendaSnap) {
                                  final agendas = agendaSnap.data ?? [];
                                  final upcomingAgendas = agendas
                                      .where((agenda) => !agenda.isPast)
                                      .toList();

                                  return Row(
                                    children: [
                                      Expanded(
                                        child: _buildSummaryCard(
                                          title: isSekretaris
                                              ? 'Tugas Dibuat'
                                              : 'Tugas Menunggu',
                                          value: isSekretaris
                                              ? '${tasks.length}'
                                              : '${todoTasks.length}',
                                          subtitle: isSekretaris
                                              ? '${todoTasks.length} belum diselesaikan'
                                              : (todoTasks.isEmpty
                                                    ? 'Semua terselesaikan'
                                                    : 'Perlu dikerjakan'),
                                          icon: Icons.assignment_outlined,
                                          gradient: const [
                                            AppTheme.primaryBlue,
                                            AppTheme.accentBlue,
                                          ],
                                          onTap: widget.onNavigateToTasks,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildSummaryCard(
                                          title: 'Agenda Mendatang',
                                          value: '${upcomingAgendas.length}',
                                          subtitle: upcomingAgendas.isEmpty
                                              ? 'Tidak ada jadwal'
                                              : 'Jadwal aktif himpunan',
                                          icon: Icons.event_available_outlined,
                                          gradient: const [
                                            AppTheme.primaryBlue,
                                            AppTheme.accentBlue,
                                          ],
                                          onTap: widget.onNavigateToAgenda,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // PANEL PUTIH: LAYANAN SAMPAI AGENDA
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 30),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Layanan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildCategories(),

                        const SizedBox(height: 28),

                        // BAGIAN TUGAS / APPROVAL / MONITORING SESUAI ROLE
                        if (isDekan || isKetua)
                          StreamBuilder<List<Proposal>>(
                            stream: _proposalService.watchAllProposals(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                      ConnectionState.waiting &&
                                  !snapshot.hasData) {
                                return _buildLoading();
                              }

                              final all = snapshot.data ?? [];
                              final pending = all
                                  .where(
                                    (p) => p.status == ProposalStatus.menunggu,
                                  )
                                  .toList();

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionHeader(
                                    'Persetujuan Terbaru',
                                    actionLabel: 'Lihat Semua',
                                    onAction:
                                        widget.onNavigateToApproval ??
                                        () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => ApprovalPage(
                                                userProfile: widget.profile,
                                                role: widget.profile.role,
                                              ),
                                            ),
                                          );
                                        },
                                  ),
                                  const SizedBox(height: 14),
                                  if (pending.isEmpty)
                                    _buildEmptyApprovalCard()
                                  else
                                    ...pending
                                        .take(3)
                                        .map(_buildDashboardProposalCard),
                                ],
                              );
                            },
                          )
                        else if (isWakilKetua)
                          StreamBuilder<List<DivisionPerformance>>(
                            stream: _monitoringService
                                .watchAllDivisionsPerformance(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                      ConnectionState.waiting &&
                                  !snapshot.hasData) {
                                return _buildLoading();
                              }

                              final divisions = snapshot.data ?? [];

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionHeader(
                                    'Monitoring Divisi',
                                    actionLabel: 'Lihat Semua',
                                    onAction:
                                        widget.onNavigateToMonitoring ??
                                        () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  DivisionMonitoringPage(
                                                    userProfile: widget.profile,
                                                    role: widget.profile.role,
                                                  ),
                                            ),
                                          );
                                        },
                                  ),
                                  const SizedBox(height: 14),
                                  if (divisions.isEmpty)
                                    _buildEmptyTaskCard()
                                  else
                                    ...divisions
                                        .take(3)
                                        .map(_buildDashboardMonitoringCard),
                                ],
                              );
                            },
                          )
                        else
                          StreamBuilder<List<Task>>(
                            stream: tasksStream,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                      ConnectionState.waiting &&
                                  !snapshot.hasData) {
                                return _buildLoading();
                              }

                              final allTasks = snapshot.data ?? [];
                              final pendingTasks = allTasks
                                  .where((task) => !task.isDone)
                                  .toList();

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionHeader(
                                    captions.taskSectionTitle,
                                    actionLabel:
                                        widget.onNavigateToTasks != null
                                        ? 'Lihat Semua'
                                        : null,
                                    onAction: widget.onNavigateToTasks,
                                  ),
                                  const SizedBox(height: 14),
                                  if (pendingTasks.isEmpty)
                                    _buildEmptyTaskCard()
                                  else
                                    ...pendingTasks
                                        .take(3)
                                        .map(_buildDashboardTaskCard),
                                ],
                              );
                            },
                          ),

                        const SizedBox(height: 28),

                        // Agenda berikutnya dari Firestore
                        StreamBuilder<List<Agenda>>(
                          stream: agendaStream,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                    ConnectionState.waiting &&
                                !snapshot.hasData) {
                              return _buildLoading();
                            }

                            final agendas = snapshot.data ?? [];
                            final upcomingAgendas = agendas
                                .where((agenda) => !agenda.isPast)
                                .toList();

                            final nextAgenda = upcomingAgendas.isNotEmpty
                                ? upcomingAgendas.first
                                : null;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionHeader(
                                  'Agenda Berikutnya',
                                  actionLabel: widget.onNavigateToAgenda != null
                                      ? 'Lihat Semua'
                                      : null,
                                  onAction: widget.onNavigateToAgenda,
                                ),
                                const SizedBox(height: 14),
                                if (nextAgenda == null)
                                  _buildEmptyAgendaCard()
                                else
                                  _buildUpcomingAgendaCard(nextAgenda),
                              ],
                            );
                          },
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
    );
  }

  Widget _buildBrandHeader() {
    return Row(
      children: [
        Image.asset(
          'assets/images/logo-ogf.png',
          width: 32,
          height: 32,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Transform.translate(
              offset: const Offset(0, 3),
              child: const Image(
                image: AssetImage('assets/images/logo-textogf.png'),
                height: 20,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.45),
                shape: BoxShape.circle,
              ),
              child: StreamBuilder<int>(
                stream: NotificationService().watchUnreadCount(
                  userId: widget.profile.uid,
                  role: widget.profile.role,
                ),
                builder: (context, snapshot) {
                  final unreadCount = snapshot.data ?? 0;

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => NotificationPage(
                                currentUserId: widget.profile.uid,
                                userRole: widget.profile.role,
                              ),
                            ),
                          );
                        },
                        tooltip: 'Notifikasi',
                        icon: const Icon(
                          Icons.notifications_none_rounded,
                          color: AppTheme.primaryBlue,
                          size: 22,
                        ),
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(3.5),
                            decoration: const BoxDecoration(
                              color: AppTheme.error,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 8,
                              minHeight: 8,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.45),
                shape: BoxShape.circle,
              ),
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
                child: CircleAvatar(
                  radius: 21,
                  backgroundColor: Colors.transparent,
                  backgroundImage: widget.profile.fotoUrl?.isNotEmpty == true
                      ? NetworkImage(widget.profile.fotoUrl!)
                      : null,
                  child: widget.profile.fotoUrl?.isNotEmpty == true
                      ? null
                      : const Icon(
                          Icons.person_rounded,
                          color: AppTheme.primaryBlue,
                          size: 22,
                        ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeCard(DashboardCaptions captions) {
    final role = widget.profile.role;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_getGreeting()}, ${widget.profile.nama}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 2),
          if (role == UserRole.kepalaDivisi)
            DivisionNameText(
              divisionId: widget.profile.divisiId,
              prefix: role.label,
              divisionNameLoader: widget.divisionNameLoader,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            )
          else
            Text(
              '${role.label} • HIMA Teknik Informatika',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        // Tinggi dipastikan konsisten
        height: 135,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        // Masking agar dekorasi tidak keluar dari sudut melengkung
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // ===== DEKORASI LINGKARAN =====
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.12),
                  ),
                ),
              ),
              Positioned(
                right: 20,
                bottom: -30,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),

              // ===== KONTEN UTAMA =====
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ===== BARIS ATAS: JUDUL & IKON =====
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Teks Judul (di kiri)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(
                              top: 2,
                              right: 8,
                            ), // Beri jarak kanan
                            child: Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13.5, // Ukuran yang sudah diperbesar
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ),
                        // 2. Ikon (di kanan)
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          child: Icon(icon, color: Colors.white, size: 18),
                        ),
                      ],
                    ),

                    const Spacer(), // Mendorong konten bawah ke dasar
                    // Baris Bawah: Angka & Subtitle
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                value,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Ikon panah kecil
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.white,
                            size: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    final role = widget.profile.role;
    final isDekan = role == UserRole.dekan;
    final isKetua = role == UserRole.ketua;
    final isWakilKetua = role == UserRole.wakilKetua;

    // Persetujuan: Hanya Dekan dan Ketua
    final canAccessApproval = isDekan || isKetua;

    // Pengajuan: Khusus Manajemen/Pengurus kecuali Dekan dan Ketua (yaitu Wakahim, Sekretaris, Bendahara, Kadiv)
    final canAccessProposal =
        role.isPengurus && role != UserRole.dekan && role != UserRole.ketua;

    final categories = [
      if (isWakilKetua)
        _CategoryItem(
          title: 'Monitoring',
          icon: Icons.analytics_outlined,
          color: AppTheme.lightBlue,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DivisionMonitoringPage(
                  userProfile: widget.profile,
                  role: widget.profile.role,
                ),
              ),
            );
          },
        )
      else
        _CategoryItem(
          title: 'Tugas',
          icon: Icons.assignment_outlined,
          color: AppTheme.lightBlue,
          onTap: widget.onNavigateToTasks,
        ),
      if (canAccessApproval)
        _CategoryItem(
          title: 'Persetujuan',
          icon: Icons.approval_outlined,
          color: AppTheme.lightBlue,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ApprovalPage(
                  userProfile: widget.profile,
                  role: widget.profile.role,
                ),
              ),
            );
          },
        )
      else if (canAccessProposal)
        _CategoryItem(
          title: 'Pengajuan',
          icon: Icons.approval_outlined,
          color: AppTheme.lightBlue,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProposalPage(
                  role: widget.profile.role,
                  userProfile: widget.profile,
                ),
              ),
            );
          },
        ),
      _CategoryItem(
        title: 'Pengumuman',
        icon: Icons.campaign_outlined,
        color: AppTheme.lightBlue,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PengumumanPage(
                userRole: widget.profile.role,
                userName: widget.profile.nama,
              ),
            ),
          );
        },
      ),
      if (!isDekan)
        _CategoryItem(
          title: 'Presensi',
          icon: Icons.how_to_reg_outlined,
          color: AppTheme.lightBlue,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AttendancePage(
                  userName: widget.profile.nama,
                  divisionName: widget.profile.divisiId,
                  userRoleLabel: widget.profile.role.label,
                ),
              ),
            );
          },
        )
      else
        _CategoryItem(
          title: 'Administrasi',
          icon: Icons.folder_open_outlined,
          color: AppTheme.lightBlue,
          onTap: widget.onNavigateToAdministration,
        ),
    ];

    return Row(
      children: [
        for (int i = 0; i < categories.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: _buildCategoryItem(categories[i])),
        ],
      ],
    );
  }

  Widget _buildCategoryItem(_CategoryItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(15),
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AppTheme.accentBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(17),
              ),
              child: Icon(item.icon, size: 27, color: AppTheme.primaryBlue),
            ),
            const SizedBox(height: 9),
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  actionLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.accentBlue,
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppTheme.accentBlue,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildLoading() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 25),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
    );
  }

  Widget _buildDashboardTaskCard(Task task) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: task.isOverdue
              ? AppTheme.error.withOpacity(0.3)
              : AppTheme.borderLight,
        ),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  task.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: task.isOverdue ? AppTheme.errorBg : AppTheme.warningBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  task.isOverdue ? 'Terlambat' : task.status.label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: task.isOverdue ? AppTheme.error : AppTheme.warning,
                  ),
                ),
              ),
            ],
          ),
          if (widget.profile.role == UserRole.sekretaris) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.business_center_outlined,
                  size: 13,
                  color: AppTheme.primaryBlue,
                ),
                const SizedBox(width: 4),
                Text(
                  task.targetRole == 'bendahara'
                      ? 'Target: Bendahara'
                      : 'Divisi: ${task.divisiNama ?? task.divisiId}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                if (task.assignedToNama != null &&
                    task.assignedToNama!.isNotEmpty) ...[
                  const Text(
                    ' • ',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                  Flexible(
                    child: Text(
                      'Penerima: ${task.assignedToNama}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
          if (task.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              task.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ],
          if (task.dueAt != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  task.isOverdue
                      ? Icons.warning_amber_rounded
                      : Icons.access_time_rounded,
                  size: 14,
                  color: task.isOverdue ? AppTheme.error : AppTheme.textMuted,
                ),
                const SizedBox(width: 5),
                Text(
                  'Tenggat: ${task.dueAt!.day}/${task.dueAt!.month}/${task.dueAt!.year}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: task.isOverdue
                        ? AppTheme.error
                        : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyTaskCard() {
    return _buildEmptyCard(
      icon: Icons.task_alt_rounded,
      title: 'Tidak Ada Tugas Menunggu',
      subtitle: widget.profile.role == UserRole.sekretaris
          ? 'Belum ada tugas organisasi yang aktif.'
          : 'Semua tugas untuk ${widget.profile.role.label} saat ini telah terselesaikan.',
      color: AppTheme.success,
      background: AppTheme.successBg,
    );
  }

  Widget _buildUpcomingAgendaCard(Agenda agenda) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 53,
            height: 53,
            decoration: BoxDecoration(
              color: AppTheme.lightBlue,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              agenda.isOnline
                  ? Icons.videocam_outlined
                  : Icons.calendar_month_outlined,
              color: AppTheme.primaryBlue,
              size: 25,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: agenda.isStatusDanger
                              ? AppTheme.errorBg
                              : AppTheme.lightBlue,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          agenda.statusTag,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: agenda.isStatusDanger
                                ? AppTheme.error
                                : AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        agenda.kategori,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  agenda.judul,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${agenda.formattedDateTime} (${agenda.isOnline ? 'Online' : 'Offline'})',
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
        ],
      ),
    );
  }

  Widget _buildEmptyAgendaCard() {
    return _buildEmptyCard(
      icon: Icons.event_busy_outlined,
      title: 'Belum Ada Agenda Mendatang',
      subtitle: 'Jadwal kegiatan atau rapat baru akan tampil di sini.',
      color: AppTheme.textMuted,
      background: AppTheme.lightBlue,
    );
  }

  Widget _buildEmptyApprovalCard() {
    return _buildEmptyCard(
      icon: Icons.assignment_turned_in_outlined,
      title: 'Tidak Ada Persetujuan Tertunda',
      subtitle: 'Seluruh proposal dan usulan pengajuan telah selesai ditinjau.',
      color: AppTheme.primaryBlue,
      background: AppTheme.lightBlue,
    );
  }

  Widget _buildDashboardProposalCard(Proposal p) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(17),
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
              Expanded(
                child: Text(
                  p.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.warningBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Menunggu',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${p.applicantName} • ${p.type.label}',
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardMonitoringCard(DivisionPerformance d) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(17),
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
              Expanded(
                child: Text(
                  d.divisionName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${d.progressPercentage}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Kadiv: ${d.kadivName ?? '-'} • ${d.completedTasks}/${d.totalTasks} tugas tuntas',
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: d.totalTasks > 0 ? d.completedTasks / d.totalTasks : 0.0,
              minHeight: 5,
              backgroundColor: AppTheme.lightBlue,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.primaryBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color background,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 23, horizontal: 17),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: background,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 25, color: color),
          ),
          const SizedBox(height: 11),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class DashboardBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Lapisan gelombang utama
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
        colors: [Color(0xFFB8CCFF), Color(0xFFD5E1FF), Color(0xFFEAF0FF)],
      ).createShader(Rect.fromLTWH(0, 0, width, height));

    canvas.drawPath(wave1, paint1);

    // Gelombang kedua
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
        colors: [Color(0x5586A8FF), Color(0x3386A8FF), Color(0x00FFFFFF)],
      ).createShader(Rect.fromLTWH(0, 0, width, height));

    canvas.drawPath(wave2, paint2);

    // Aksen gelombang transparan
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

    final paint3 = Paint()..color = const Color(0x2286A8FF);

    canvas.drawPath(wave3, paint3);
  }

  @override
  bool shouldRepaint(covariant DashboardBackgroundPainter oldDelegate) {
    return false;
  }
}

class _CategoryItem {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _CategoryItem({
    required this.title,
    required this.icon,
    required this.color,
    this.onTap,
  });
}
