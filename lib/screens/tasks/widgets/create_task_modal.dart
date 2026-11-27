import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
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

  List<Map<String, String>> _divisions = [];
  String? _selectedDivisiId;
  String? _selectedDivisiNama;
  DateTime? _selectedDueDate;
  bool _isLoadingDivisions = true;
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
  void initState() {
    super.initState();
    _loadDivisions();
  }

  Future<void> _loadDivisions() async {
    try {
      final list = await widget.taskService.getAllDivisions();
      // Tambahkan opsi Bendahara (Keuangan) agar Sekretaris bisa memberi tugas ke Bendahara
      final allTargets = [
        ...list,
        {'id': 'bendahara', 'nama': 'Bendahara (Keuangan)'},
      ];
      if (mounted) {
        setState(() {
          _divisions = allTargets;
          if (allTargets.isNotEmpty) {
            _selectedDivisiId = allTargets.first['id'];
            _selectedDivisiNama = allTargets.first['nama'];
          }
          _isLoadingDivisions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingDivisions = false);
      }
    }
  }

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

    if (_selectedDivisiId == null || _selectedDivisiId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih divisi tujuan tugas.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

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

    final isBendahara = _selectedDivisiId == 'bendahara';

    try {
      await widget.taskService.createTask(
        createdBy: uid,
        title: _titleController.text,
        description: _descriptionController.text,
        divisiId: _selectedDivisiId!,
        divisiNama: _selectedDivisiNama,
        targetRole: isBendahara ? 'bendahara' : null,
        dueAt: _selectedDueDate,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isBendahara
                  ? 'Tugas berhasil dibuat untuk Bendahara!'
                  : 'Tugas berhasil dilimpahkan ke ${_selectedDivisiNama ?? 'Divisi'}!',
            ),
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
                              'Distribusikan tugas organisasi',
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
                  const Text('Judul Tugas *', style: _labelStyle),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _titleController,
                    style: _inputTextStyle,
                    textInputAction: TextInputAction.next,
                    decoration: _inputDecoration(
                      'Misal: Pembuatan Banner & Poster Workshop',
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Judul tugas wajib diisi.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Divisi Tujuan
                  const Text('Divisi Tujuan *', style: _labelStyle),
                  const SizedBox(height: 6),
                  if (_isLoadingDivisions)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  else if (_divisions.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Belum ada divisi terdaftar di sistem.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    )
                  else
                    DropdownButtonFormField<String>(
                      value: _selectedDivisiId,
                      items: _divisions.map((d) {
                        return DropdownMenuItem(
                          value: d['id'],
                          child: Text(
                            d['nama'] ?? d['id']!,
                            style: _inputTextStyle,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedDivisiId = val;
                            _selectedDivisiNama = _divisions.firstWhere(
                              (e) => e['id'] == val,
                            )['nama'];
                          });
                        }
                      },
                      decoration: _inputDecoration('Pilih Divisi Tujuan'),
                    ),
                  const SizedBox(height: 14),

                  // Deskripsi
                  const Text('Deskripsi & Rincian Tugas', style: _labelStyle),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _descriptionController,
                    style: _inputTextStyle,
                    maxLines: 4,
                    decoration: _inputDecoration(
                      'Tuliskan instruksi atau format yang diharapkan dari tugas ini...',
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Tenggat Waktu
                  const Text('Batas Waktu (Tenggat)', style: _labelStyle),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: _pickDueDate,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_month_outlined,
                            size: 18,
                            color: _selectedDueDate != null
                                ? AppTheme.primaryBlue
                                : AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _selectedDueDate != null
                                  ? '${_selectedDueDate!.day}/${_selectedDueDate!.month}/${_selectedDueDate!.year} pukul ${_selectedDueDate!.hour.toString().padLeft(2, '0')}:${_selectedDueDate!.minute.toString().padLeft(2, '0')} WIB'
                                  : 'Pilih batas waktu pengerjaan (opsional)',
                              style: _selectedDueDate != null
                                  ? _inputTextStyle
                                  : _hintStyle,
                            ),
                          ),
                          if (_selectedDueDate != null)
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 16),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () =>
                                  setState(() => _selectedDueDate = null),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tombol Kirim
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _handleSubmit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Buat Tugas',
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
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: _hintStyle,
      filled: true,
      fillColor: AppTheme.background,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.4),
      ),
    );
  }
}
