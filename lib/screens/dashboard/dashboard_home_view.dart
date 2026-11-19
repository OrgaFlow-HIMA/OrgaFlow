import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../enums/user_role.dart';
import '../../models/agenda.dart';
import '../../models/task.dart';
import '../../models/user_profile.dart';
import '../../services/agenda_service.dart';
import '../../services/division_service.dart';
import '../../services/task_service.dart';
import '../../widgets/division_name_text.dart';

class DashboardCaptions {
  final String greetingSubtitle;
  final String taskSectionTitle;
  final String taskSectionSubtitle;
  final String noteFocus;

  const DashboardCaptions({
    required this.greetingSubtitle,
    required this.taskSectionTitle,
    required this.taskSectionSubtitle,
    required this.noteFocus,
  });
}

/// Tampilan Beranda Dashboard Universal untuk Seluruh Role (Pengurus & Anggota).
/// Menggunakan fungsi caption berbasis role dan mengambil data riil dari Firestore.
class DashboardHomeView extends StatefulWidget {
  final UserProfile profile;
  final DivisionNameLoader? divisionNameLoader;
  final VoidCallback? onNavigateToTasks;
  final VoidCallback? onNavigateToAgenda;

  const DashboardHomeView({
    super.key,
    required this.profile,
    this.divisionNameLoader,
    this.onNavigateToTasks,
    this.onNavigateToAgenda,
  });

  @override
  State<DashboardHomeView> createState() => _DashboardHomeViewState();
}

class _DashboardHomeViewState extends State<DashboardHomeView> {
  final TaskService _taskService = TaskService();
  final AgendaService _agendaService = AgendaService();

  DashboardCaptions _getCaptions(UserRole role) {
    switch (role) {
      case UserRole.dekan:
        return const DashboardCaptions(
          greetingSubtitle: 'Kelola kebijakan dan persetujuan tingkat dekanat',
          taskSectionTitle: 'Persetujuan & Tugas Dekanat',
          taskSectionSubtitle:
              'Tugas dan berkas yang memerlukan peninjauan Anda',
          noteFocus: 'Fokus: Persetujuan proposal berkas dan pengawasan capaian strategis himpunan.',
        );
      case UserRole.ketua:
        return const DashboardCaptions(
          greetingSubtitle: 'Koordinasi dan pantau seluruh alur organisasi',
          taskSectionTitle: 'Tugas & Persetujuan',
          taskSectionSubtitle:
              'Prioritas organisasi yang perlu ditindaklanjuti',
          noteFocus: 'Fokus: Koordinasi internal pengurus inti dan pengawasan berkala program kerja.',
        );
      case UserRole.wakilKetua:
        return const DashboardCaptions(
          greetingSubtitle: 'Pantau kinerja divisi dan progres operasional',
          taskSectionTitle: 'Tugas & Pemantauan Organisasi',
          taskSectionSubtitle: 'Progres operasional yang perlu dievaluasi',
          noteFocus: 'Fokus: Evaluasi kinerja divisi dan asistensi ketua dalam pelaksanaan proker.',
        );
      case UserRole.sekretaris:
        return const DashboardCaptions(
          greetingSubtitle: 'Kelola administrasi, tugas, dan agenda organisasi',
          taskSectionTitle: 'Tugas Organisasi Berjalan',
          taskSectionSubtitle: 'Seluruh tugas yang sedang aktif didelegasikan',
          noteFocus: 'Fokus: Pendelegasian tugas antar-divisi dan pencatatan jadwal agenda rapat.',
        );
      case UserRole.bendahara:
        return const DashboardCaptions(
          greetingSubtitle:
              'Pantau arus kas dan verifikasi keuangan organisasi',
          taskSectionTitle: 'Tugas Keuangan & Verifikasi',
          taskSectionSubtitle: 'Tugas dan verifikasi keuangan yang aktif',
          noteFocus: 'Fokus: Pencatatan kas berkala dan verifikasi pembayaran iuran anggota.',
        );
      case UserRole.kepalaDivisi:
        return const DashboardCaptions(
          greetingSubtitle: 'Kelola koordinasi dan progres anggota divisi Anda',
          taskSectionTitle: 'Tugas Divisi',
          taskSectionSubtitle: 'Tanggung jawab divisi yang sedang berjalan',
          noteFocus: 'Fokus: Penyelesaian program kerja divisi bersama seluruh anggota.',
        );
      case UserRole.anggota:
        return const DashboardCaptions(
          greetingSubtitle:
              'Aktivitas dan tugas Anda di HIMA Teknik Informatika',
          taskSectionTitle: 'Tugas Saya',
          taskSectionSubtitle: 'Penugasan aktif yang didelegasikan kepada Anda',
          noteFocus: 'Fokus: Partisipasi aktif dalam kegiatan divisi dan kehadiran rapat organisasi.',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final captions = _getCaptions(widget.profile.role);
    final isSekretaris = widget.profile.role == UserRole.sekretaris;

    // Stream tugas: Sekretaris memantau semua tugas; role lain memantau tugas miliknya
    final tasksStream = isSekretaris
        ? _taskService.watchAllTasks()
        : _taskService.watchTasksForRole(widget.profile.role);

    final agendaStream = _agendaService.watchAgendas();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Welcome Card
          _buildWelcomeCard(captions),
          const SizedBox(height: 20),

          // 2. Summary Cards (Real-time Tasks & Agendas)
          StreamBuilder<List<Task>>(
            stream: tasksStream,
            builder: (context, taskSnap) {
              final tasks = taskSnap.data ?? [];
              final todoTasks = tasks.where((t) => !t.isDone).toList();

              return StreamBuilder<List<Agenda>>(
                stream: agendaStream,
                builder: (context, agendaSnap) {
                  final agendas = agendaSnap.data ?? [];
                  final upcomingAgendas = agendas
                      .where((a) => !a.isPast)
                      .toList();

                  return Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          title: 'Tugas Menunggu',
                          value: '${todoTasks.length} Tugas',
                          subtitle: todoTasks.isEmpty
                              ? 'Semua terselesaikan'
                              : '${todoTasks.length} perlu dikerjakan',
                          icon: Icons.assignment_turned_in_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryCard(
                          title: 'Agenda Mendatang',
                          value: '${upcomingAgendas.length} Agenda',
                          subtitle: upcomingAgendas.isEmpty
                              ? 'Tidak ada jadwal'
                              : 'Jadwal aktif himpunan',
                          icon: Icons.event_available_outlined,
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 24),

          // 3. Bagian Persetujuan / Tugas (Real-time dari Firestore Tasks)
          StreamBuilder<List<Task>>(
            stream: tasksStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final allTasks = snapshot.data ?? [];
              final pendingTasks = allTasks.where((t) => !t.isDone).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    title: captions.taskSectionTitle,
                    isBadgeDanger: pendingTasks.isNotEmpty,
                    actionLabel: widget.onNavigateToTasks != null
                        ? 'Lihat Semua'
                        : null,
                    onAction: widget.onNavigateToTasks,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    captions.taskSectionSubtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Handling Kosong vs Ada Tugas
                  if (pendingTasks.isEmpty)
                    _buildEmptyTaskCard()
                  else
                    ...pendingTasks
                        .take(3)
                        .map((task) => _buildDashboardTaskCard(task)),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // 4. Bagian Agenda Berikutnya (Real-time dari Firestore Agenda)
          StreamBuilder<List<Agenda>>(
            stream: agendaStream,
            builder: (context, snapshot) {
              final agendas = snapshot.data ?? [];
              final upcomingAgendas = agendas.where((a) => !a.isPast).toList();
              final nextAgenda = upcomingAgendas.isNotEmpty
                  ? upcomingAgendas.first
                  : null;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    title: 'Agenda Berikutnya',
                    actionLabel: widget.onNavigateToAgenda != null
                        ? 'Semua Agenda →'
                        : null,
                    onAction: widget.onNavigateToAgenda,
                  ),
                  const SizedBox(height: 12),
                  if (nextAgenda == null)
                    _buildEmptyAgendaCard()
                  else
                    _buildUpcomingAgendaCard(nextAgenda),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ---------- Widgets ----------

  Widget _buildWelcomeCard(DashboardCaptions captions) {
    final role = widget.profile.role;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, ${widget.profile.nama} 👋',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                if (role == UserRole.kepalaDivisi)
                  DivisionNameText(
                    divisionId: widget.profile.divisiId,
                    prefix: role.label,
                    divisionNameLoader: widget.divisionNameLoader,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  )
                else
                  Text(
                    '${role.label} • HIMA TI',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  captions.greetingSubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: widget.profile.isActive
                  ? AppTheme.successBg
                  : AppTheme.warningBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.profile.isActive ? 'Aktif' : 'Nonaktif',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: widget.profile.isActive
                    ? AppTheme.success
                    : AppTheme.warning,
              ),
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
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 110),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.lightBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: AppTheme.primaryBlue),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    String? badgeText,
    bool isBadgeDanger = false,
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
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        if (badgeText != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isBadgeDanger ? AppTheme.errorBg : AppTheme.lightBlue,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isBadgeDanger ? AppTheme.error : AppTheme.primaryBlue,
              ),
            ),
          ),
        if (actionLabel != null) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryBlue,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDashboardTaskCard(Task task) {
    final isSekretaris = widget.profile.role == UserRole.sekretaris;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: task.isOverdue
              ? AppTheme.error.withOpacity(0.3)
              : AppTheme.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isSekretaris) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.lightBlue,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    task.targetRole.label,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: task.isOverdue ? AppTheme.errorBg : AppTheme.warningBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  task.isOverdue ? 'Terlambat' : 'Belum Selesai',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: task.isOverdue ? AppTheme.error : AppTheme.warning,
                  ),
                ),
              ),
            ],
          ),
          if (task.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              task.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
                height: 1.3,
              ),
            ),
          ],
          if (task.dueAt != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  task.isOverdue
                      ? Icons.warning_amber_rounded
                      : Icons.access_time_rounded,
                  size: 13,
                  color: task.isOverdue ? AppTheme.error : AppTheme.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  'Tenggat: ${task.dueAt!.day}/${task.dueAt!.month}/${task.dueAt!.year}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.successBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              size: 28,
              color: AppTheme.success,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Tidak Ada Tugas Menunggu',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            widget.profile.role == UserRole.sekretaris
                ? 'Belum ada tugas organisasi yang aktif.'
                : 'Semua tugas untuk ${widget.profile.role.label} saat ini telah terselesaikan.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingAgendaCard(Agenda agenda) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppTheme.lightBlue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              agenda.isOnline
                  ? Icons.videocam_rounded
                  : Icons.calendar_month_rounded,
              color: AppTheme.primaryBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: agenda.isStatusDanger
                            ? AppTheme.errorBg
                            : AppTheme.lightBlue,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        agenda.statusTag,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: agenda.isStatusDanger
                              ? AppTheme.error
                              : AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      agenda.kategori,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
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
                const SizedBox(height: 2),
                Text(
                  '${agenda.formattedDateTime} (${agenda.isOnline ? 'Online' : 'Offline'})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: const Row(
        children: [
          Icon(Icons.event_busy_outlined, color: AppTheme.textMuted, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Belum Ada Agenda Mendatang',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Jadwal kegiatan atau rapat baru akan tampil di sini.',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
