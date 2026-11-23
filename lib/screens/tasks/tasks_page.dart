import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../enums/user_role.dart';
import '../../models/task.dart';
import '../../services/task_service.dart';
import 'widgets/create_task_modal.dart';
import 'widgets/task_card.dart';
import 'widgets/task_empty_state.dart';
import 'widgets/task_tab_switcher.dart';

class TasksPage extends StatefulWidget {
  final UserRole role;

  const TasksPage({super.key, required this.role});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  final TaskService _taskService = TaskService();
  int _selectedTab = 0; // 0: Perlu Dikerjakan / Berjalan, 1: Selesai
  String? _markingTaskId;

  bool get _isSekretaris => widget.role == UserRole.sekretaris;

  (String title, String subtitle) _getHeader(UserRole role) {
    switch (role) {
      case UserRole.dekan:
        return (
          'Daftar Tugas & Persetujuan Dekan',
          'Kelola persetujuan dan tugas dekanat',
        );
      case UserRole.ketua:
        return (
          'Daftar Tugas & Persetujuan',
          'Kelola persetujuan dan progres organisasi',
        );
      case UserRole.wakilKetua:
        return ('Tugas Wakil Ketua', 'Pantau progres tugas operasional');
      case UserRole.sekretaris:
        return (
          'Kelola Tugas Organisasi',
          'Buat dan delegasikan tugas organisasi',
        );
      case UserRole.bendahara:
        return ('Tugas Bendahara', 'Kelola verifikasi dan tugas keuangan');
      case UserRole.kepalaDivisi:
        return (
          'Tugas Kepala Divisi',
          'Koordinasikan tugas dan progres divisi',
        );
      case UserRole.anggota:
        return ('Tugas Saya', 'Pantau dan selesaikan tugas Anda');
    }
  }

  Future<void> _handleMarkDone(Task task) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Selesaikan Tugas?'),
        content: Text('Tandai tugas "${task.title}" sebagai selesai?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
            ),
            child: const Text('Ya, Selesai'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    setState(() => _markingTaskId = task.id);

    try {
      await _taskService.markTaskDone(taskId: task.id, completedBy: user.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tugas berhasil diselesaikan!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyelesaikan tugas: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _markingTaskId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final (title, subtitle) = _getHeader(widget.role);

    final stream = _isSekretaris
        ? _taskService.watchAllTasks()
        : _taskService.watchTasksForRole(widget.role);

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
          // Wave dekoratif (samar)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 420,
            child: IgnorePointer(
              child: CustomPaint(
                painter: _TasksSoftBackgroundPainter(),
                size: Size.infinite,
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: StreamBuilder<List<Task>>(
              stream: stream,
              builder: (context, snapshot) {
                final allTasks = snapshot.data ?? <Task>[];
                final todoTasks = allTasks.where((t) => !t.isDone).toList();
                final doneTasks = allTasks.where((t) => t.isDone).toList();
                final visibleTasks = _selectedTab == 0 ? todoTasks : doneTasks;

                final isLoading =
                    snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData;

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Gagal memuat tugas: ${snapshot.error}',
                        style: const TextStyle(color: AppTheme.error),
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => await Future<void>.delayed(
                    const Duration(milliseconds: 300),
                  ),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    children: [
                      // Bagian atas (judul + tab)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTitleBlock(title, subtitle),
                            const SizedBox(height: 20),
                            TaskTabSwitcher(
                              selectedIndex: _selectedTab,
                              onTabChanged: (index) =>
                                  setState(() => _selectedTab = index),
                              todoCount: todoTasks.length,
                              doneCount: doneTasks.length,
                              todoLabel: _isSekretaris
                                  ? 'Berjalan'
                                  : 'Perlu Dikerjakan',
                            ),
                          ],
                        ),
                      ),

                      // Panel putih berisi daftar tugas
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(28),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(),
                            const SizedBox(height: 16),

                            if (isLoading)
                              _buildLoading()
                            else if (visibleTasks.isEmpty)
                              TaskEmptyState(
                                title: _selectedTab == 0
                                    ? 'Tidak ada tugas yang menunggu'
                                    : 'Belum ada tugas selesai',
                                subtitle: _isSekretaris && _selectedTab == 0
                                    ? 'Tekan tombol "+" di kanan atas untuk mendelegasikan tugas.'
                                    : 'Daftar tugas akan muncul di sini.',
                              )
                            else
                              ...visibleTasks.map(
                                (task) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: TaskCard(
                                    task: task,
                                    showRoleBadge: _isSekretaris,
                                    showActionButton: !_isSekretaris,
                                    isMarkingDone: _markingTaskId == task.id,
                                    onMarkDone: () => _handleMarkDone(task),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============ TITLE + ADD BUTTON ============

  Widget _buildTitleBlock(String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (_isSekretaris) ...[const SizedBox(width: 12), _buildAddButton()],
      ],
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: () => CreateTaskModal.show(context, taskService: _taskService),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppTheme.primaryBlue,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
      ),
    );
  }

  // ============ SECTION HEADER ============

  String get _sectionTitle =>
      _selectedTab == 0 ? 'Tugas Berjalan' : 'Tugas Selesai';

  String get _sectionSubtitle => _selectedTab == 0
      ? 'Tugas yang perlu ditindaklanjuti'
      : 'Riwayat tugas yang sudah diselesaikan';

  Widget _buildSectionHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _sectionTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _sectionSubtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (_isSekretaris && _selectedTab == 0) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () =>
                CreateTaskModal.show(context, taskService: _taskService),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Buat',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.accentBlue,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppTheme.accentBlue,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLoading() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 30),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
    );
  }
}

// ============ SOFT BACKGROUND PAINTER ============

class _TasksSoftBackgroundPainter extends CustomPainter {
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
  bool shouldRepaint(covariant _TasksSoftBackgroundPainter oldDelegate) =>
      false;
}
