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

/// Halaman Tugas Terpadu untuk Seluruh Role di OrgaFlow.
/// Menggunakan fungsi konfigurasi teks header sesuai role (KISS principle).
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

  /// Konfigurasi judul dan subjudul berdasarkan role pengguna
  (String title, String subtitle) _getHeader(UserRole role) {
    switch (role) {
      case UserRole.dekan:
        return (
          'Daftar Tugas & Persetujuan Dekan',
          'Kelola persetujuan berkas dan tugas tingkat dekanat',
        );
      case UserRole.ketua:
        return (
          'Daftar Tugas & Persetujuan',
          'Kelola persetujuan berkas dan progres tugas organisasi',
        );
      case UserRole.wakilKetua:
        return (
          'Tugas Wakil Ketua',
          'Memantau progres dan tugas operasional wakil ketua',
        );
      case UserRole.sekretaris:
        return (
          'Kelola Tugas Organisasi',
          'Buat dan delegasikan tugas ke seluruh role organisasi',
        );
      case UserRole.bendahara:
        return (
          'Tugas Bendahara',
          'Kelola verifikasi transaksi dan tugas keuangan organisasi',
        );
      case UserRole.kepalaDivisi:
        return (
          'Tugas Kepala Divisi',
          'Kelola koordinasi dan tugas divisi organisasi',
        );
      case UserRole.anggota:
        return (
          'Tugas Saya',
          'Pantau dan selesaikan tugas yang didelegasikan kepada Anda',
        );
    }
  }

  Future<void> _handleMarkDone(Task task) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
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
    final isSekretaris = widget.role == UserRole.sekretaris;
    final (title, subtitle) = _getHeader(widget.role);

    // Sekretaris memantau semua tugas; role lain memantau tugas miliknya
    final stream = isSekretaris
        ? _taskService.watchAllTasks()
        : _taskService.watchTasksForRole(widget.role);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: StreamBuilder<List<Task>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
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

          final tasks = snapshot.data ?? <Task>[];
          final todoTasks = tasks.where((t) => !t.isDone).toList();
          final doneTasks = tasks.where((t) => t.isDone).toList();
          final visibleTasks = _selectedTab == 0 ? todoTasks : doneTasks;

          return RefreshIndicator(
            onRefresh: () async =>
                await Future<void>.delayed(const Duration(milliseconds: 300)),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              children: [
                // Header (dengan tombol Buat Tugas khusus Sekretaris)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSekretaris)
                      FilledButton.icon(
                        onPressed: () => CreateTaskModal.show(
                          context,
                          taskService: _taskService,
                        ),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Buat Tugas'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Switcher Tab
                TaskTabSwitcher(
                  selectedIndex: _selectedTab,
                  onTabChanged: (index) => setState(() => _selectedTab = index),
                  todoCount: todoTasks.length,
                  doneCount: doneTasks.length,
                  todoLabel: isSekretaris ? 'Berjalan' : 'Perlu Dikerjakan',
                ),
                const SizedBox(height: 16),

                // Daftar Tugas
                if (visibleTasks.isEmpty)
                  TaskEmptyState(
                    title: _selectedTab == 0
                        ? 'Tidak ada tugas yang menunggu'
                        : 'Belum ada tugas selesai',
                    subtitle: isSekretaris && _selectedTab == 0
                        ? 'Tekan tombol "Buat Tugas" di atas untuk mendelegasikan tugas.'
                        : 'Daftar tugas akan muncul di sini.',
                  )
                else
                  ...visibleTasks.map(
                    (task) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TaskCard(
                        task: task,
                        showRoleBadge:
                            isSekretaris, // Sekretaris melihat role target
                        showActionButton:
                            !isSekretaris, // Penerima yang menandai selesai
                        isMarkingDone: _markingTaskId == task.id,
                        onMarkDone: () => _handleMarkDone(task),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
