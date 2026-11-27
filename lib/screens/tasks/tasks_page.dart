import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../enums/user_role.dart';
import '../../models/task.dart';
import '../../models/user_profile.dart';
import '../../services/task_service.dart';
import 'widgets/create_task_modal.dart';
import 'widgets/delegate_task_modal.dart';
import 'widgets/submit_task_modal.dart';
import 'widgets/task_card.dart';
import 'widgets/task_empty_state.dart';
import 'widgets/task_tab_switcher.dart';

class TasksPage extends StatefulWidget {
  final UserRole role;
  final UserProfile? userProfile;

  const TasksPage({super.key, required this.role, this.userProfile});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  final TaskService _taskService = TaskService();
  int _selectedTab = 0; // 0: Berjalan/Aktif, 1: Selesai
  String? _confirmingTaskId;

  bool get _isSekretaris => widget.role == UserRole.sekretaris;
  bool get _isKadiv => widget.role == UserRole.kepalaDivisi;

  String? get _divisionId => widget.userProfile?.divisiId;
  String get _currentUid => FirebaseAuth.instance.currentUser?.uid ?? '';

  (String title, String subtitle) _getHeader(UserRole role) {
    switch (role) {
      case UserRole.sekretaris:
        return (
          'Monitoring Tugas Organisasi',
          'Limpahkan tugas ke divisi & pantau penyelesaian',
        );
      case UserRole.kepalaDivisi:
        return (
          'Tugas Divisi Anda',
          'Delegasikan ke anggota & konfirmasi tugas selesai',
        );
      case UserRole.anggota:
        return ('Tugas Saya', 'Kerjakan dan kumpulkan hasil tugas Anda');
      case UserRole.bendahara:
        return ('Tugas Bendahara', 'Daftar tugas divisi keuangan');
      default:
        return ('Daftar Tugas', 'Pantau aktivitas tugas himpunan');
    }
  }

  Future<void> _handleConfirmDone(Task task) async {
    final isBendaharaTask =
        task.targetRole == 'bendahara' || task.divisiId == 'bendahara';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Setujui & Selesaikan Tugas?'),
        content: Text(
          isBendaharaTask
              ? 'Konfirmasi bahwa hasil pengerjaan tugas "${task.title}" oleh Bendahara sudah sesuai dan selesai tuntas?'
              : 'Konfirmasi bahwa hasil tugas "${task.title}" oleh ${task.assignedToNama ?? 'anggota'} sudah sesuai dan selesai tuntas?',
        ),
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
            child: const Text('Ya, Setujui Selesai'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    setState(() => _confirmingTaskId = task.id);

    try {
      if (isBendaharaTask && _isSekretaris) {
        await _taskService.confirmTaskBySecretary(
          taskId: task.id,
          secretaryUid: _currentUid,
        );
      } else {
        await _taskService.confirmTaskByKadiv(
          taskId: task.id,
          kadivUid: _currentUid,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tugas berhasil disetujui dan ditandai selesai!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyetujui tugas: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _confirmingTaskId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final (title, subtitle) = _getHeader(widget.role);

    // Stream yang sesuai dengan peran user
    Stream<List<Task>> taskStream;
    if (_isSekretaris) {
      taskStream = _taskService.watchAllTasks();
    } else if (widget.role == UserRole.bendahara) {
      taskStream = _taskService.watchTasksForBendahara(_currentUid);
    } else if (_isKadiv && _divisionId != null && _divisionId!.isNotEmpty) {
      taskStream = _taskService.watchTasksForDivision(_divisionId!);
    } else {
      taskStream = _taskService.watchTasksForMember(_currentUid);
    }

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
              stream: taskStream,
              builder: (context, snapshot) {
                final allTasks = snapshot.data ?? <Task>[];
                final activeTasks = allTasks.where((t) => !t.isDone).toList();
                final doneTasks = allTasks.where((t) => t.isDone).toList();
                final visibleTasks = _selectedTab == 0
                    ? activeTasks
                    : doneTasks;

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
                      // Header judul + switcher tab
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
                              todoCount: activeTasks.length,
                              doneCount: doneTasks.length,
                              todoLabel: _isSekretaris || _isKadiv
                                  ? 'Aktif / Berjalan'
                                  : 'Perlu Dikerjakan',
                            ),
                          ],
                        ),
                      ),

                      // Panel putih daftar tugas
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
                                    ? 'Tekan tombol "+" di kanan bawah untuk melimpahkan tugas ke divisi.'
                                    : 'Daftar tugas akan muncul di sini.',
                              )
                            else
                              ...visibleTasks.map(
                                (task) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: TaskCard(
                                    task: task,
                                    userRole: widget.role,
                                    onDelegate: () {
                                      DelegateTaskModal.show(
                                        context,
                                        task: task,
                                        divisionId:
                                            _divisionId ?? task.divisiId,
                                        taskService: _taskService,
                                      );
                                    },
                                    onSubmit: () {
                                      SubmitTaskModal.show(
                                        context,
                                        task: task,
                                        taskService: _taskService,
                                      );
                                    },
                                    onConfirm: () => _handleConfirmDone(task),
                                    isConfirming: _confirmingTaskId == task.id,
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

          // Tombol Tambah Tugas Khusus Sekretaris di Kanan Bawah
          if (_isSekretaris)
            Positioned(right: 20, bottom: 115, child: _buildAddButton()),
        ],
      ),
    );
  }

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
      ],
    );
  }

  Widget _buildAddButton() {
    return FloatingActionButton(
      heroTag: 'fab_create_task',
      onPressed: () => CreateTaskModal.show(context, taskService: _taskService),
      backgroundColor: AppTheme.primaryBlue,
      elevation: 6,
      shape: const CircleBorder(),
      child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
    );
  }

  String get _sectionTitle =>
      _selectedTab == 0 ? 'Tugas Aktif & Berjalan' : 'Tugas Selesai';

  String get _sectionSubtitle => _selectedTab == 0
      ? 'Daftar penugasan yang sedang diproses'
      : 'Riwayat tugas yang telah tuntas disetujui';

  Widget _buildSectionHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _sectionTitle,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _sectionSubtitle,
          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
        ),
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

class _TasksSoftBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC7D7FE).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height * 0.45)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.25,
        size.width * 0.7,
        size.height * 0.55,
      )
      ..quadraticBezierTo(
        size.width * 0.88,
        size.height * 0.7,
        size.width,
        size.height * 0.6,
      )
      ..lineTo(size.width, 0)
      ..lineTo(0, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
