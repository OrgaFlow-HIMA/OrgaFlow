import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/task.dart';
import '../../../models/user_profile.dart';
import '../../../services/task_service.dart';

class DelegateTaskModal extends StatefulWidget {
  final Task task;
  final String divisionId;
  final TaskService taskService;
  final VoidCallback? onDelegated;

  const DelegateTaskModal({
    super.key,
    required this.task,
    required this.divisionId,
    required this.taskService,
    this.onDelegated,
  });

  static Future<void> show(
    BuildContext context, {
    required Task task,
    required String divisionId,
    TaskService? taskService,
    VoidCallback? onDelegated,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DelegateTaskModal(
        task: task,
        divisionId: divisionId,
        taskService: taskService ?? TaskService(),
        onDelegated: onDelegated,
      ),
    );
  }

  @override
  State<DelegateTaskModal> createState() => _DelegateTaskModalState();
}

class _DelegateTaskModalState extends State<DelegateTaskModal> {
  List<UserProfile> _members = [];
  bool _isLoading = true;
  String? _selectedMemberUid;
  String? _selectedMemberNama;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadDivisionMembers();
  }

  Future<void> _loadDivisionMembers() async {
    try {
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      final list = await widget.taskService.getMembersByDivision(
        widget.divisionId,
        excludeUid: currentUid,
      );
      if (mounted) {
        setState(() {
          _members = list;
          if (list.isNotEmpty) {
            _selectedMemberUid = list.first.uid;
            _selectedMemberNama = list.first.nama;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleDelegate() async {
    if (_selectedMemberUid == null) return;
    final kadivUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    setState(() => _isSubmitting = true);

    try {
      await widget.taskService.delegateTaskToMember(
        taskId: widget.task.id,
        memberUid: _selectedMemberUid!,
        memberNama: _selectedMemberNama ?? 'Anggota',
        kadivUid: kadivUid,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Tugas berhasil didelegasikan ke $_selectedMemberNama!',
            ),
            backgroundColor: AppTheme.success,
          ),
        );
        widget.onDelegated?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mendelegasikan tugas: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Grabber
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppTheme.lightBlue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.person_add_alt_1_rounded,
                      color: AppTheme.primaryBlue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Delegasikan ke Anggota',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          widget.task.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: AppTheme.borderLight),
              const SizedBox(height: 16),

              const Text(
                'Pilih Anggota Divisi yang Bertugas *',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),

              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (_members.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Tidak ditemukan anggota aktif di divisi ini.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  value: _selectedMemberUid,
                  items: _members.map((m) {
                    return DropdownMenuItem(
                      value: m.uid,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: AppTheme.lightBlue,
                            child: Text(
                              m.nama.isNotEmpty ? m.nama[0].toUpperCase() : 'U',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${m.nama} (${m.nim ?? m.role.label})',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedMemberUid = val;
                        _selectedMemberNama = _members
                            .firstWhere((e) => e.uid == val)
                            .nama;
                      });
                    }
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppTheme.background,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.borderLight),
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: (_isLoading || _members.isEmpty || _isSubmitting)
                      ? null
                      : _handleDelegate,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Tugaskan Anggota',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
