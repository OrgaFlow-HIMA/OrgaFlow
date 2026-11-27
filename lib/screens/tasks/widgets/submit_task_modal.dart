import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/task.dart';
import '../../../services/cloudinary_service.dart';
import '../../../services/task_service.dart';

class SubmitTaskModal extends StatefulWidget {
  final Task task;
  final TaskService taskService;
  final CloudinaryService? cloudinaryService;
  final VoidCallback? onSubmitted;

  const SubmitTaskModal({
    super.key,
    required this.task,
    required this.taskService,
    this.cloudinaryService,
    this.onSubmitted,
  });

  static Future<void> show(
    BuildContext context, {
    required Task task,
    TaskService? taskService,
    CloudinaryService? cloudinaryService,
    VoidCallback? onSubmitted,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SubmitTaskModal(
        task: task,
        taskService: taskService ?? TaskService(),
        cloudinaryService: cloudinaryService ?? CloudinaryService(),
        onSubmitted: onSubmitted,
      ),
    );
  }

  @override
  State<SubmitTaskModal> createState() => _SubmitTaskModalState();
}

class _SubmitTaskModalState extends State<SubmitTaskModal> {
  final _linkController = TextEditingController();
  final _noteController = TextEditingController();
  String _submissionType = 'file'; // 'file' atau 'link'
  PlatformFile? _pickedFile;
  bool _isUploading = false;

  @override
  void dispose() {
    _linkController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'doc',
          'docx',
          'ppt',
          'pptx',
          'xls',
          'xlsx',
          'png',
          'jpg',
          'jpeg',
          'zip',
        ],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _pickedFile = result.files.first;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih file: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _handleSubmit() async {
    final memberUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    String submissionUrl = '';
    String? fileName;

    if (_submissionType == 'file') {
      if (_pickedFile == null || _pickedFile!.bytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Silakan pilih berkas hasil tugas terlebih dahulu.'),
            backgroundColor: AppTheme.error,
          ),
        );
        return;
      }

      setState(() => _isUploading = true);
      try {
        final cloudinary = widget.cloudinaryService ?? CloudinaryService();
        submissionUrl = await cloudinary.uploadFile(
          fileBytes: _pickedFile!.bytes!,
          fileName: _pickedFile!.name,
          folder: 'task_submissions',
        );
        fileName = _pickedFile!.name;
      } catch (e) {
        if (mounted) {
          setState(() => _isUploading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal mengunggah berkas: $e'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
        return;
      }
    } else {
      submissionUrl = _linkController.text.trim();
      if (submissionUrl.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tautan hasil pengerjaan wajib diisi.'),
            backgroundColor: AppTheme.error,
          ),
        );
        return;
      }
    }

    setState(() => _isUploading = true);

    try {
      await widget.taskService.submitTaskResult(
        taskId: widget.task.id,
        submissionType: _submissionType,
        submissionUrl: submissionUrl,
        submissionFileName: fileName,
        submissionNote: _noteController.text.trim(),
        memberUid: memberUid,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Hasil tugas berhasil dikumpulkan! Menunggu konfirmasi Kadiv.',
            ),
            backgroundColor: AppTheme.success,
          ),
        );
        widget.onSubmitted?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyerahkan tugas: $e'),
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
        child: SingleChildScrollView(
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
                      Icons.upload_file_rounded,
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
                          'Kumpulkan Hasil Tugas',
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

              // Pilihan Tipe Lampiran (File vs Link)
              const Text(
                'Bentuk Lampiran Hasil *',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildTypeOption(
                      label: 'Unggah Berkas',
                      sublabel: 'PDF, DOCX, PPTX, XLS',
                      icon: Icons.attach_file_rounded,
                      isSelected: _submissionType == 'file',
                      onTap: () => setState(() => _submissionType = 'file'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTypeOption(
                      label: 'Tautan / Link',
                      sublabel: 'Google Drive, Figma, dll',
                      icon: Icons.link_rounded,
                      isSelected: _submissionType == 'link',
                      onTap: () => setState(() => _submissionType = 'link'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_submissionType == 'file') ...[
                // File Picker Box
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _pickedFile != null
                            ? Icons.insert_drive_file_rounded
                            : Icons.cloud_upload_outlined,
                        size: 36,
                        color: AppTheme.primaryBlue,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _pickedFile != null
                            ? _pickedFile!.name
                            : 'Pilih file PDF, Word, PPT, Excel, atau Gambar',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: _pickedFile != null
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _pickFile,
                        icon: const Icon(Icons.folder_open_rounded, size: 16),
                        label: Text(
                          _pickedFile != null
                              ? 'Ganti File'
                              : 'Pilih dari Perangkat',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryBlue,
                          side: const BorderSide(color: AppTheme.primaryBlue),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Input Link
                const Text(
                  'Tautan Hasil Pengerjaan *',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _linkController,
                  decoration: InputDecoration(
                    hintText: 'https://drive.google.com/... atau https://figma.com/...',
                    hintStyle: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
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
              ],
              const SizedBox(height: 16),

              // Catatan Opsional
              const Text(
                'Catatan Tambahan (Opsional)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _noteController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Tuliskan catatan singkat jika ada...',
                  hintStyle: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                  filled: true,
                  fillColor: AppTheme.background,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppTheme.borderLight),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Tombol Serahkan
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: _isUploading ? null : _handleSubmit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  child: _isUploading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Mengirim hasil...',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        )
                      : const Text(
                          'Serahkan Tugas ke Kadiv',
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

  Widget _buildTypeOption({
    required String label,
    required String sublabel,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.lightBlue : AppTheme.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : AppTheme.borderLight,
            width: isSelected ? 1.4 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppTheme.primaryBlue : AppTheme.textSecondary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? AppTheme.primaryBlue : AppTheme.textPrimary,
              ),
            ),
            Text(
              sublabel,
              style: TextStyle(
                fontSize: 9,
                color: isSelected
                    ? AppTheme.primaryBlue
                    : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
