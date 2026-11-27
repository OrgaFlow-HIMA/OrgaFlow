import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../enums/task_status.dart';
import '../../../enums/user_role.dart';
import '../../../models/task.dart';

/// Modal detail lengkap tugas dengan preview & unduh berkas / buka link
class TaskDetailModal extends StatefulWidget {
  final Task task;
  final UserRole userRole;
  final VoidCallback? onDelegate;
  final VoidCallback? onSubmit;
  final VoidCallback? onConfirm;
  final bool isConfirming;

  const TaskDetailModal({
    super.key,
    required this.task,
    required this.userRole,
    this.onDelegate,
    this.onSubmit,
    this.onConfirm,
    this.isConfirming = false,
  });

  static Future<void> show(
    BuildContext context, {
    required Task task,
    required UserRole userRole,
    VoidCallback? onDelegate,
    VoidCallback? onSubmit,
    VoidCallback? onConfirm,
    bool isConfirming = false,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TaskDetailModal(
        task: task,
        userRole: userRole,
        onDelegate: onDelegate,
        onSubmit: onSubmit,
        onConfirm: onConfirm,
        isConfirming: isConfirming,
      ),
    );
  }

  @override
  State<TaskDetailModal> createState() => _TaskDetailModalState();
}

class _TaskDetailModalState extends State<TaskDetailModal> {
  bool _isDownloading = false;

  Task get task => widget.task;
  bool get _isKadiv => widget.userRole == UserRole.kepalaDivisi;
  bool get _isAnggota => widget.userRole == UserRole.anggota;
  bool get _isBendahara => widget.userRole == UserRole.bendahara;
  bool get _isSekretaris => widget.userRole == UserRole.sekretaris;

  bool get _isBendaharaTask =>
      task.targetRole == 'bendahara' || task.divisiId == 'bendahara';

  String _formatDate(DateTime dt) {
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
    final day = dt.day.toString().padLeft(2, '0');
    final month = months[dt.month - 1];
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day $month $year, $hour:$minute';
  }

  bool _isImageUrl(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp') ||
        lower.contains('/image/upload/');
  }

  bool _isPdfUrl(String url) {
    return url.toLowerCase().endsWith('.pdf') ||
        url.toLowerCase().contains('.pdf?');
  }

  Future<void> _handleDownloadOrOpen(String url, String? fileName) async {
    final cleanUrl = url.trim();
    if (cleanUrl.isEmpty) return;

    final isCloudinaryOrDirect =
        cleanUrl.startsWith('http://') || cleanUrl.startsWith('https://');

    setState(() => _isDownloading = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Menyiapkan berkas...'),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      if (isCloudinaryOrDirect &&
          (_isPdfUrl(cleanUrl) || _isImageUrl(cleanUrl))) {
        final response = await http.get(Uri.parse(cleanUrl));
        if (response.statusCode >= 200 && response.statusCode < 300) {
          final bytes = response.bodyBytes;
          final fallbackName = _isPdfUrl(cleanUrl)
              ? 'Tugas_${task.title}.pdf'
              : 'Tugas_${task.title}.png';
          final sanitizedFilename = (fileName ?? fallbackName).replaceAll(
            RegExp(r'[^a-zA-Z0-9._\-]'),
            '_',
          );

          await Printing.sharePdf(bytes: bytes, filename: sanitizedFilename);

          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Berkas berhasil dibuka / diunduh.'),
                backgroundColor: AppTheme.success,
              ),
            );
          }
          return;
        }
      }

      // Fallback eksternal browser / Google Drive
      final uri = Uri.tryParse(cleanUrl);
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Format URL tidak valid');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengunduh berkas: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  void _openFilePreviewDialog(String url, String title, String? fileName) {
    final cleanUrl = url.trim();
    final isPdf = _isPdfUrl(cleanUrl);
    final isImage = _isImageUrl(cleanUrl);

    if (!isPdf && !isImage) {
      final uri = Uri.tryParse(cleanUrl);
      if (uri != null) {
        launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(ctx).size.height * 0.85,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header Pratinjau
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                decoration: const BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  border: Border(
                    bottom: BorderSide(color: AppTheme.borderLight),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.lightBlue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isPdf
                            ? Icons.picture_as_pdf_rounded
                            : Icons.image_rounded,
                        color: AppTheme.primaryBlue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fileName ??
                                (isPdf
                                    ? 'Pratinjau Dokumen PDF'
                                    : 'Pratinjau Berkas'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            title,
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
                    IconButton(
                      tooltip: 'Unduh / Simpan',
                      icon: const Icon(
                        Icons.download_rounded,
                        color: AppTheme.primaryBlue,
                      ),
                      onPressed: () =>
                          _handleDownloadOrOpen(cleanUrl, fileName),
                    ),
                    IconButton(
                      tooltip: 'Tutup',
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppTheme.textSecondary,
                      ),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),

              // Konten Pratinjau
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(20),
                  ),
                  child: isPdf
                      ? PdfPreview(
                          build: (format) async {
                            final response = await http.get(
                              Uri.parse(cleanUrl),
                            );
                            if (response.statusCode >= 200 &&
                                response.statusCode < 300) {
                              return response.bodyBytes;
                            }
                            throw Exception(
                              'Gagal memuat berkas PDF: ${response.statusCode}',
                            );
                          },
                          canChangeOrientation: false,
                          canChangePageFormat: false,
                          canDebug: false,
                          allowPrinting: true,
                          allowSharing: true,
                          maxPageWidth: 700,
                          loadingWidget: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(strokeWidth: 2.5),
                                SizedBox(height: 12),
                                Text(
                                  'Memuat pratinjau dokumen...',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          onError: (context, error) => Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    color: AppTheme.error,
                                    size: 40,
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Gagal menampilkan pratinjau dokumen',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textPrimary,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  FilledButton.icon(
                                    onPressed: () => _handleDownloadOrOpen(
                                      cleanUrl,
                                      fileName,
                                    ),
                                    icon: const Icon(
                                      Icons.download_rounded,
                                      size: 16,
                                    ),
                                    label: const Text('Buka / Unduh Dokumen'),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppTheme.primaryBlue,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : InteractiveViewer(
                          panEnabled: true,
                          minScale: 0.5,
                          maxScale: 4.0,
                          child: Center(
                            child: Image.network(
                              cleanUrl,
                              fit: BoxFit.contain,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                      ),
                                    );
                                  },
                              errorBuilder: (context, error, stackTrace) =>
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.broken_image_rounded,
                                            color: AppTheme.error,
                                            size: 40,
                                          ),
                                          const SizedBox(height: 8),
                                          const Text(
                                            'Gagal memuat gambar',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          FilledButton.icon(
                                            onPressed: () =>
                                                _handleDownloadOrOpen(
                                                  cleanUrl,
                                                  fileName,
                                                ),
                                            icon: const Icon(
                                              Icons.download_rounded,
                                              size: 16,
                                            ),
                                            label: const Text('Buka Gambar'),
                                          ),
                                        ],
                                      ),
                                    ),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasSubmission =
        task.submissionUrl != null && task.submissionUrl!.isNotEmpty;
    final isDone = task.isDone;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Grabber
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 12, 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.lightBlue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.assignment_rounded,
                        color: AppTheme.primaryBlue,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Detail Tugas',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isBendaharaTask
                                ? 'Tugas Divisi Keuangan (Bendahara)'
                                : 'Divisi: ${task.divisiNama ?? task.divisiId.toUpperCase()}',
                            style: const TextStyle(
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
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppTheme.borderLight),

              // Content Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge Status & Sasaran
                      Row(
                        children: [
                          _buildStatusBadge(
                            task.status,
                            isOverdue: task.isOverdue,
                          ),
                          const SizedBox(width: 8),
                          _buildTargetBadge(),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Judul Tugas
                      Text(
                        task.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Deskripsi
                      if (task.description.isNotEmpty) ...[
                        const Text(
                          'Deskripsi / Arahan Tugas',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.borderLight),
                          ),
                          child: Text(
                            task.description,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textPrimary,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Informasi Penugasan
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.borderLight),
                        ),
                        child: Column(
                          children: [
                            _buildInfoItem(
                              icon: Icons.person_outline_rounded,
                              label: 'Penanggung Jawab',
                              value: _isBendaharaTask
                                  ? 'Bendahara Organisasi'
                                  : (task.assignedToNama ??
                                        'Belum didelegasikan Kadiv'),
                            ),
                            if (task.createdAt != null) ...[
                              const Divider(
                                height: 18,
                                color: AppTheme.borderLight,
                              ),
                              _buildInfoItem(
                                icon: Icons.calendar_today_rounded,
                                label: 'Dibuat Pada',
                                value: _formatDate(task.createdAt!),
                              ),
                            ],
                            if (task.dueAt != null) ...[
                              const Divider(
                                height: 18,
                                color: AppTheme.borderLight,
                              ),
                              _buildInfoItem(
                                icon: Icons.access_time_rounded,
                                label: 'Tenggat Waktu',
                                value: _formatDate(task.dueAt!),
                                valueColor: task.isOverdue
                                    ? AppTheme.error
                                    : null,
                              ),
                            ],
                            if (isDone && task.completedAt != null) ...[
                              const Divider(
                                height: 18,
                                color: AppTheme.borderLight,
                              ),
                              _buildInfoItem(
                                icon: Icons.check_circle_outline_rounded,
                                label: 'Diselesaikan Pada',
                                value: _formatDate(task.completedAt!),
                                valueColor: AppTheme.success,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Section Hasil Pengerjaan (Submission)
                      if (hasSubmission) ...[
                        const Text(
                          'Hasil Pengerjaan Tugas',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.lightBlue,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      task.submissionType == 'link'
                                          ? Icons.link_rounded
                                          : Icons.file_present_rounded,
                                      color: AppTheme.primaryBlue,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          task.submissionFileName ??
                                              (task.submissionType == 'link'
                                                  ? 'Tautan Hasil Pengerjaan'
                                                  : 'Lampiran Berkas Tugas'),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                        if (task.submittedAt != null)
                                          Text(
                                            'Dikumpulkan: ${_formatDate(task.submittedAt!)}',
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
                              if (task.submissionNote != null &&
                                  task.submissionNote!.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(
                                  'Catatan Anggota: "${task.submissionNote}"',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              // Tombol Pratinjau & Unduh
                              Row(
                                children: [
                                  if (task.submissionType != 'link' &&
                                      (_isPdfUrl(task.submissionUrl!) ||
                                          _isImageUrl(
                                            task.submissionUrl!,
                                          ))) ...[
                                    Expanded(
                                      child: SizedBox(
                                        height: 40,
                                        child: OutlinedButton.icon(
                                          onPressed: () {
                                            _openFilePreviewDialog(
                                              task.submissionUrl!,
                                              task.title,
                                              task.submissionFileName,
                                            );
                                          },
                                          icon: const Icon(
                                            Icons.visibility_rounded,
                                            size: 16,
                                          ),
                                          label: const Text(
                                            'Pratinjau',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor:
                                                AppTheme.primaryBlue,
                                            side: BorderSide(
                                              color: AppTheme.primaryBlue
                                                  .withOpacity(0.4),
                                              width: 1.2,
                                            ),
                                            padding: EdgeInsets.zero,
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                            shape: const StadiumBorder(),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Expanded(
                                    child: SizedBox(
                                      height: 40,
                                      child: FilledButton.icon(
                                        onPressed: _isDownloading
                                            ? null
                                            : () {
                                                _handleDownloadOrOpen(
                                                  task.submissionUrl!,
                                                  task.submissionFileName,
                                                );
                                              },
                                        icon: _isDownloading
                                            ? const SizedBox(
                                                width: 14,
                                                height: 14,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                              )
                                            : Icon(
                                                task.submissionType == 'link'
                                                    ? Icons.open_in_new_rounded
                                                    : Icons.download_rounded,
                                                size: 16,
                                              ),
                                        label: Text(
                                          task.submissionType == 'link'
                                              ? 'Buka Tautan'
                                              : 'Unduh Berkas',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: AppTheme.primaryBlue,
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          shape: const StadiumBorder(),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],

                      // Tombol Aksi Utama di dalam modal
                      _buildActionButtons(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    // 1. Delegasi ke anggota (Kadiv)
    if (_isKadiv &&
        !_isBendaharaTask &&
        task.status == TaskStatus.pendingDelegation &&
        widget.onDelegate != null) {
      return SizedBox(
        width: double.infinity,
        height: 44,
        child: FilledButton.icon(
          onPressed: () {
            Navigator.pop(context);
            widget.onDelegate?.call();
          },
          icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
          label: const Text(
            'Tugaskan ke Anggota Divisi',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.primaryBlue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      );
    }

    // 2. Kumpulkan Hasil Tugas (Anggota / Bendahara)
    if (((_isAnggota && !_isBendaharaTask) ||
            (_isBendahara && _isBendaharaTask)) &&
        task.status == TaskStatus.todo &&
        widget.onSubmit != null) {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: FilledButton.icon(
          onPressed: () {
            Navigator.pop(context);
            widget.onSubmit?.call();
          },
          label: const Text(
            'Kumpulkan Hasil Tugas',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.primaryBlue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
          ),
        ),
      );
    }

    // 3. Konfirmasi Selesai (Kadiv untuk divisi, Sekretaris untuk Bendahara)
    if (((_isKadiv && !_isBendaharaTask) ||
            (_isSekretaris && _isBendaharaTask)) &&
        task.status == TaskStatus.submitted &&
        widget.onConfirm != null) {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: FilledButton.icon(
          onPressed: widget.isConfirming
              ? null
              : () {
                  Navigator.pop(context);
                  widget.onConfirm?.call();
                },
          label: Text(
            widget.isConfirming
                ? 'Menyetujui...'
                : 'Periksa & Setujui Tugas Selesai',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.primaryBlue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppTheme.primaryBlue),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTargetBadge() {
    final label = _isBendaharaTask
        ? 'Bendahara'
        : (task.divisiNama ?? 'Divisi ${task.divisiId.toUpperCase()}');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.lightBlue,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppTheme.primaryBlue,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(TaskStatus status, {required bool isOverdue}) {
    switch (status) {
      case TaskStatus.done:
        return _buildBadge(
          label: 'Selesai',
          bgColor: AppTheme.successBg,
          fgColor: AppTheme.success,
        );
      case TaskStatus.submitted:
        return _buildBadge(
          label: 'Menunggu Konfirmasi',
          bgColor: const Color(0xFFFEF3C7),
          fgColor: const Color(0xFFB45309),
        );
      case TaskStatus.todo:
        return _buildBadge(
          label: isOverdue ? 'Terlambat' : 'Sedang Dikerjakan',
          bgColor: isOverdue ? AppTheme.errorBg : const Color(0xFFE0E7FF),
          fgColor: isOverdue ? AppTheme.error : const Color(0xFF4338CA),
        );
      case TaskStatus.pendingDelegation:
        return _buildBadge(
          label: isOverdue ? 'Terlambat Delegasi' : 'Perlu Didelegasikan',
          bgColor: isOverdue ? AppTheme.errorBg : AppTheme.warningBg,
          fgColor: isOverdue ? AppTheme.error : AppTheme.warning,
        );
    }
  }

  Widget _buildBadge({
    required String label,
    required Color bgColor,
    required Color fgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fgColor,
        ),
      ),
    );
  }
}
