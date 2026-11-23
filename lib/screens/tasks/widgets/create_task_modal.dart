import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../enums/user_role.dart';
import '../../../services/task_service.dart';

class CreateTaskModal extends StatefulWidget {
  final TaskService taskService;
  final VoidCallback? onTaskCreated;

  const CreateTaskModal({
    super.key,
    required this.taskService,
    this.onTaskCreated,
  });

  static Future<void> show(
    BuildContext context, {
    TaskService? taskService,
    VoidCallback? onTaskCreated,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => CreateTaskModal(
        taskService: taskService ?? TaskService(),
        onTaskCreated: onTaskCreated,
      ),
    );
  }

  @override
  State<CreateTaskModal> createState() => _CreateTaskModalState();
}

class _CreateTaskModalState extends State<CreateTaskModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  UserRole _selectedRole = UserRole.anggota;
  DateTime? _selectedDueDate;
  bool _isLoading = false;

  // Style seragam
  static const TextStyle _inputTextStyle = TextStyle(
    fontSize: 12,
    color: AppTheme.textPrimary,
    height: 1.35,
  );
  static const TextStyle _hintStyle = TextStyle(
    fontSize: 12,
    color: AppTheme.textSecondary,
    height: 1.35,
  );
  static const TextStyle _labelStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppTheme.textPrimary,
  );

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: _selectedDueDate != null
            ? TimeOfDay.fromDateTime(_selectedDueDate!)
            : const TimeOfDay(hour: 23, minute: 59),
      );

      if (time != null && mounted) {
        setState(() {
          _selectedDueDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesi login tidak ditemukan. Silakan login kembali.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await widget.taskService.createTask(
        createdBy: uid,
        title: _titleController.text,
        description: _descriptionController.text,
        targetRole: _selectedRole,
        dueAt: _selectedDueDate,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tugas berhasil dibuat!'),
            backgroundColor: AppTheme.success,
          ),
        );
        widget.onTaskCreated?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat tugas: $e'),
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
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
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
                  const SizedBox(height: 14),

                  // Header
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.lightBlue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.assignment_add,
                          color: AppTheme.primaryBlue,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Buat Tugas Baru',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Delegasikan tugas ke role organisasi',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppTheme.textSecondary,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Judul
                  const Text('Judul Tugas', style: _labelStyle),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _titleController,
                    style: _inputTextStyle,
                    textInputAction: TextInputAction.next,
                    decoration: _inputDecoration(
                      'Misal: Rekap Data Keuangan LPJ',
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Judul tugas wajib diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Deskripsi
                  const Text('Deskripsi / Catatan', style: _labelStyle),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    style: _inputTextStyle,
                    textInputAction: TextInputAction.newline,
                    decoration: _inputDecoration(
                      'Jelaskan rincian atau instruksi tugas...',
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Target Role
                  const Text('Target Role Penerima', style: _labelStyle),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<UserRole>(
                    value: _selectedRole,
                    isExpanded: true,
                    itemHeight: null,
                    style: _inputTextStyle,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppTheme.textSecondary,
                      size: 20,
                    ),
                    items: UserRole.values.map((role) {
                      return DropdownMenuItem<UserRole>(
                        value: role,
                        child: Text(
                          role.label,
                          style: _inputTextStyle,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (role) {
                      if (role != null) {
                        setState(() => _selectedRole = role);
                      }
                    },
                    decoration: _inputDecoration(null).copyWith(
                      hintText: null,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Tenggat Waktu
                  const Text('Tenggat Waktu (Opsional)', style: _labelStyle),
                  const SizedBox(height: 6),
                  _buildDateTimeCard(
                    date: _selectedDueDate,
                    onTap: _pickDueDate,
                    onClear: _selectedDueDate == null
                        ? null
                        : () => setState(() => _selectedDueDate = null),
                  ),
                  const SizedBox(height: 24),

                  // Submit
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue,
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryBlue.withOpacity(0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(50),
                          onTap: _isLoading ? null : _handleSubmit,
                          child: Center(
                            child: _isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Text(
                                        'Publikasikan Tugas',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============ HELPERS ============

  Widget _buildDateTimeCard({
    required DateTime? date,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    String label;
    Color labelColor;
    if (date != null) {
      final time =
          '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      label = '${date.day} ${months[date.month - 1]} ${date.year} • $time WIB';
      labelColor = AppTheme.textPrimary;
    } else {
      label = 'Belum ditentukan';
      labelColor = AppTheme.textSecondary;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppTheme.lightBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _inputTextStyle.copyWith(color: labelColor),
                ),
              ),
              const SizedBox(width: 8),
              if (onClear != null) ...[
                InkWell(
                  onTap: onClear,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.errorBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: AppTheme.error,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Atur',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String? hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: _hintStyle,
      filled: true,
      fillColor: AppTheme.background,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.4),
      ),
      errorStyle: const TextStyle(fontSize: 11),
    );
  }
}
