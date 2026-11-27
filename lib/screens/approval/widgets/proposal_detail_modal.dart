import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../enums/user_role.dart';
import '../../../models/proposal.dart';
import '../../../services/proposal_service.dart';

class ProposalDetailModal extends StatefulWidget {
  final Proposal proposal;
  final UserRole userRole;
  final String currentUid;
  final String currentUserName;
  final VoidCallback? onUpdated;

  const ProposalDetailModal({
    super.key,
    required this.proposal,
    required this.userRole,
    required this.currentUid,
    required this.currentUserName,
    this.onUpdated,
  });

  static Future<void> show(
    BuildContext context, {
    required Proposal proposal,
    required UserRole userRole,
    required String currentUid,
    required String currentUserName,
    VoidCallback? onUpdated,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ProposalDetailModal(
        proposal: proposal,
        userRole: userRole,
        currentUid: currentUid,
        currentUserName: currentUserName,
        onUpdated: onUpdated,
      ),
    );
  }

  @override
  State<ProposalDetailModal> createState() => _ProposalDetailModalState();
}

class _ProposalDetailModalState extends State<ProposalDetailModal> {
  final ProposalService _proposalService = ProposalService();
  bool _isProcessing = false;
  bool _isDownloading = false;

  // ===== Style Seragam =====
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

  Proposal get proposal => widget.proposal;
  bool get _isKetua =>
      widget.userRole == UserRole.ketua ||
      widget.userRole == UserRole.wakilKetua;
  bool get _isDekan => widget.userRole == UserRole.dekan;

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
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  bool _isPdfUrl(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.pdf') || lower.contains('.pdf?');
  }

  bool _isDirectFile(String url) {
    return _isPdfUrl(url) || _isImageUrl(url);
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tautan berhasil disalin ke papan klip!'),
          backgroundColor: AppTheme.success,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  bool _isImageUrl(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp');
  }

  Future<void> _handleDownloadOrOpen(String url, String? fileName) async {
    final cleanUrl = url.trim();
    if (cleanUrl.isEmpty) return;

    setState(() => _isDownloading = true);
    try {
      if (_isPdfUrl(cleanUrl) || _isImageUrl(cleanUrl)) {
        final response = await http.get(Uri.parse(cleanUrl));
        if (response.statusCode >= 200 && response.statusCode < 300) {
          final bytes = response.bodyBytes;
          final fallbackName = _isPdfUrl(cleanUrl)
              ? 'Proposal_${proposal.title}.pdf'
              : 'Lampiran_${proposal.title}.png';
          final sanitized = (fileName ?? fallbackName).replaceAll(
            RegExp(r'[^a-zA-Z0-9._\-]'),
            '_',
          );

          await Printing.sharePdf(bytes: bytes, filename: sanitized);
          return;
        }
      }

      final uri = Uri.tryParse(cleanUrl);
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka berkas: $e'),
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
      if (uri != null) launchUrl(uri, mode: LaunchMode.externalApplication);
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
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
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
                                    ? 'Pratinjau Proposal PDF'
                                    : 'Pratinjau Berkas'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
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
                        )
                      : InteractiveViewer(
                          child: Center(
                            child: Image.network(cleanUrl, fit: BoxFit.contain),
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

  Future<void> _handleApprove() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Setujui Pengajuan?'),
        content: Text(
          'Anda akan menyetujui pengajuan "${proposal.title}". Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
            ),
            child: const Text('Ya, Setujui'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    setState(() => _isProcessing = true);

    try {
      if (_isKetua) {
        await _proposalService.approveByKetua(
          proposalId: proposal.id,
          ketuaUid: widget.currentUid,
          ketuaName: widget.currentUserName,
        );
      } else if (_isDekan) {
        await _proposalService.approveByDekan(
          proposalId: proposal.id,
          dekanUid: widget.currentUid,
          dekanName: widget.currentUserName,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengajuan berhasil disetujui!'),
            backgroundColor: AppTheme.success,
          ),
        );
        widget.onUpdated?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyetujui: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleRejectOrRevision(bool isRevision) async {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isRevision ? 'Minta Revisi Pengajuan' : 'Tolak Pengajuan'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isRevision
                    ? 'Masukkan catatan revisi yang perlu diperbaiki oleh pengaju:'
                    : 'Berikan alasan penolakan pengajuan ini:',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: reasonController,
                style: _inputTextStyle,
                maxLines: 3,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: 'Tuliskan alasan / catatan...',
                  hintStyle: _hintStyle,
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
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppTheme.borderLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: AppTheme.primaryBlue,
                      width: 1.4,
                    ),
                  ),
                ),
                validator: (val) => (val == null || val.trim().isEmpty)
                    ? 'Alasan wajib diisi'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            },
            style: FilledButton.styleFrom(
              backgroundColor: isRevision ? AppTheme.warning : AppTheme.error,
              shape: const StadiumBorder(),
            ),
            child: Text(isRevision ? 'Kirim Revisi' : 'Tolak'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    setState(() => _isProcessing = true);

    try {
      await _proposalService.rejectOrRequestRevision(
        proposalId: proposal.id,
        role: _isKetua ? 'ketua' : 'dekan',
        reviewerUid: widget.currentUid,
        status: isRevision ? ProposalStatus.revisi : ProposalStatus.ditolak,
        reason: reasonController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isRevision
                  ? 'Permintaan revisi berhasil dikirim ke pengaju.'
                  : 'Pengajuan telah ditolak.',
            ),
            backgroundColor: isRevision ? AppTheme.warning : AppTheme.error,
          ),
        );
        widget.onUpdated?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memproses: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasDocument =
        proposal.documentUrl != null && proposal.documentUrl!.isNotEmpty;
    final canApproveAsKetua =
        _isKetua &&
        !proposal.approvedByKetua &&
        proposal.status != ProposalStatus.ditolak;
    final canApproveAsDekan =
        _isDekan &&
        !proposal.approvedByDekan &&
        proposal.status != ProposalStatus.ditolak;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
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
                        Icons.approval_outlined,
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
                            'Detail Pengajuan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${proposal.type.label} • ${proposal.divisionName ?? proposal.divisionId.toUpperCase()}',
                            style: const TextStyle(
                              fontSize: 11,
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

              // Konten
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Badge & Validasi Keduanya
                      Row(
                        children: [
                          _buildStatusBadge(proposal.status),
                          const SizedBox(width: 8),
                          _buildTypeBadge(proposal.type),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Text(
                        proposal.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Kotak Deskripsi
                      const Text('Deskripsi Pengajuan', style: _labelStyle),
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
                          proposal.description,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Informasi Pengaju
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.borderLight),
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow(
                              icon: Icons.person_outline_rounded,
                              label: 'Pengaju',
                              value:
                                  '${proposal.applicantName} (${proposal.applicantRole})',
                            ),
                            const Divider(
                              height: 18,
                              color: AppTheme.borderLight,
                            ),
                            _buildInfoRow(
                              icon: Icons.business_outlined,
                              label: 'Divisi',
                              value:
                                  proposal.divisionName ??
                                  proposal.divisionId.toUpperCase(),
                            ),
                            if (proposal.createdAt != null) ...[
                              const Divider(
                                height: 18,
                                color: AppTheme.borderLight,
                              ),
                              _buildInfoRow(
                                icon: Icons.access_time_rounded,
                                label: 'Tanggal Diajukan',
                                value: _formatDate(proposal.createdAt!),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ===== STATUS PERSETUJUAN GANDA (KETUA & DEKAN) =====
                      const Text(
                        'Persetujuan Ketua & Dekan',
                        style: _labelStyle,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.borderLight),
                        ),
                        child: Column(
                          children: [
                            _buildApprovalStatusTile(
                              title: 'Ketua Himpunan',
                              isApproved: proposal.approvedByKetua,
                              approverName: proposal.ketuaName,
                              approvedAt: proposal.ketuaApprovedAt,
                            ),
                            const Divider(
                              height: 18,
                              color: AppTheme.borderLight,
                            ),
                            _buildApprovalStatusTile(
                              title: 'Dekanat / Dekan',
                              isApproved: proposal.approvedByDekan,
                              approverName: proposal.dekanName,
                              approvedAt: proposal.dekanApprovedAt,
                            ),
                          ],
                        ),
                      ),

                      // Catatan Revisi / Penolakan
                      if (proposal.rejectionReason != null &&
                          proposal.rejectionReason!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: proposal.status == ProposalStatus.revisi
                                ? AppTheme.warningBg
                                : AppTheme.errorBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: proposal.status == ProposalStatus.revisi
                                  ? AppTheme.warning.withOpacity(0.3)
                                  : AppTheme.error.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    proposal.status == ProposalStatus.revisi
                                        ? Icons.edit_note_rounded
                                        : Icons.cancel_outlined,
                                    color:
                                        proposal.status == ProposalStatus.revisi
                                        ? AppTheme.warning
                                        : AppTheme.error,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      proposal.status == ProposalStatus.revisi
                                          ? 'Catatan Revisi (${proposal.rejectedByRole?.toUpperCase() ?? 'Reviewer'}):'
                                          : 'Alasan Penolakan (${proposal.rejectedByRole?.toUpperCase() ?? 'Reviewer'}):',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                        color:
                                            proposal.status ==
                                                ProposalStatus.revisi
                                            ? AppTheme.warning
                                            : AppTheme.error,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                proposal.rejectionReason!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textPrimary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Lampiran Dokumen
                      if (hasDocument) ...[
                        const SizedBox(height: 18),
                        Text(
                          _isDirectFile(proposal.documentUrl!)
                              ? 'Dokumen Pendukung'
                              : 'Tautan / Link Pendukung',
                          style: _labelStyle,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.borderLight),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: AppTheme.lightBlue,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      _isDirectFile(proposal.documentUrl!)
                                          ? (_isPdfUrl(proposal.documentUrl!)
                                                ? Icons.picture_as_pdf_rounded
                                                : Icons
                                                      .insert_drive_file_outlined)
                                          : Icons.link_rounded,
                                      color: AppTheme.primaryBlue,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          proposal.documentFileName ??
                                              (_isDirectFile(
                                                    proposal.documentUrl!,
                                                  )
                                                  ? 'Dokumen Pengajuan'
                                                  : 'Tautan Dokumen'),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _isDirectFile(proposal.documentUrl!)
                                              ? 'Lampiran berkas'
                                              : proposal.documentUrl!,
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
                              const SizedBox(height: 12),
                              // Jika berupa file langsung (PDF/Gambar): Muncul tombol Pratinjau & Unduh
                              // Jika berupa link eksternal (Drive, Docs, dll): Muncul tombol Salin Link & Buka Link
                              if (_isDirectFile(proposal.documentUrl!))
                                Row(
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        height: 38,
                                        child: OutlinedButton.icon(
                                          onPressed: () {
                                            _openFilePreviewDialog(
                                              proposal.documentUrl!,
                                              proposal.title,
                                              proposal.documentFileName,
                                            );
                                          },
                                          icon: const Icon(
                                            Icons.visibility_rounded,
                                            size: 15,
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
                                                  .withValues(alpha: 0.4),
                                              width: 1.2,
                                            ),
                                            shape: const StadiumBorder(),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: SizedBox(
                                        height: 38,
                                        child: FilledButton.icon(
                                          onPressed: _isDownloading
                                              ? null
                                              : () => _handleDownloadOrOpen(
                                                  proposal.documentUrl!,
                                                  proposal.documentFileName,
                                                ),
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
                                              : const Icon(
                                                  Icons.download_rounded,
                                                  size: 15,
                                                ),
                                          label: const Text(
                                            'Unduh',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          style: FilledButton.styleFrom(
                                            backgroundColor:
                                                AppTheme.primaryBlue,
                                            foregroundColor: Colors.white,
                                            shape: const StadiumBorder(),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Row(
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        height: 38,
                                        child: OutlinedButton.icon(
                                          onPressed: () => _copyToClipboard(
                                            proposal.documentUrl!,
                                          ),
                                          icon: const Icon(
                                            Icons.copy_rounded,
                                            size: 15,
                                          ),
                                          label: const Text(
                                            'Salin Tautan',
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
                                                  .withValues(alpha: 0.4),
                                              width: 1.2,
                                            ),
                                            shape: const StadiumBorder(),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: SizedBox(
                                        height: 38,
                                        child: FilledButton.icon(
                                          onPressed: () =>
                                              _handleDownloadOrOpen(
                                                proposal.documentUrl!,
                                                proposal.documentFileName,
                                              ),
                                          icon: const Icon(
                                            Icons.open_in_new_rounded,
                                            size: 15,
                                          ),
                                          label: const Text(
                                            'Buka Tautan',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          style: FilledButton.styleFrom(
                                            backgroundColor:
                                                AppTheme.primaryBlue,
                                            foregroundColor: Colors.white,
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
                      ],

                      // ===== TOMBOL AKSI UNTUK KETUA & DEKAN =====
                      if (canApproveAsKetua || canApproveAsDekan) ...[
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 42,
                                child: OutlinedButton.icon(
                                  onPressed: _isProcessing
                                      ? null
                                      : () => _handleRejectOrRevision(true),
                                  icon: const Icon(
                                    Icons.edit_note_rounded,
                                    size: 16,
                                  ),
                                  label: const Text('Revisi'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.warning,
                                    side: BorderSide(
                                      color: AppTheme.warning.withOpacity(0.5),
                                      width: 1.2,
                                    ),
                                    padding: EdgeInsets.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    shape: const StadiumBorder(),
                                    textStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SizedBox(
                                height: 42,
                                child: OutlinedButton.icon(
                                  onPressed: _isProcessing
                                      ? null
                                      : () => _handleRejectOrRevision(false),
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 16,
                                  ),
                                  label: const Text('Tolak'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.error,
                                    side: BorderSide(
                                      color: AppTheme.error.withOpacity(0.5),
                                      width: 1.2,
                                    ),
                                    padding: EdgeInsets.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    shape: const StadiumBorder(),
                                    textStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton.icon(
                            onPressed: _isProcessing ? null : _handleApprove,
                            label: Text(
                              _isKetua ? 'Setujui (Ketua)' : 'Setujui (Dekan)',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.primaryBlue,
                              foregroundColor: Colors.white,
                              shape: const StadiumBorder(),
                            ),
                          ),
                        ),
                      ],
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

  // ============ HELPER WIDGETS ============

  Widget _buildApprovalStatusTile({
    required String title,
    required bool isApproved,
    String? approverName,
    DateTime? approvedAt,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isApproved ? AppTheme.successBg : AppTheme.warningBg,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isApproved ? Icons.check_circle_rounded : Icons.pending_rounded,
            color: isApproved ? AppTheme.success : AppTheme.warning,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isApproved
                    ? 'Disetujui ${approverName ?? ''}'
                    : 'Menunggu Persetujuan',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: isApproved ? AppTheme.success : AppTheme.textSecondary,
                  fontWeight: isApproved ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              if (isApproved && approvedAt != null)
                Text(
                  _formatDate(approvedAt),
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.primaryBlue),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
        ),
        const Spacer(),
        Expanded(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeBadge(ProposalType type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.lightBlue,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        type.label,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: AppTheme.primaryBlue,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ProposalStatus status) {
    Color bg;
    Color fg;
    switch (status) {
      case ProposalStatus.disetujui:
        bg = AppTheme.successBg;
        fg = AppTheme.success;
        break;
      case ProposalStatus.menunggu:
        bg = AppTheme.warningBg;
        fg = AppTheme.warning;
        break;
      case ProposalStatus.revisi:
        bg = const Color(0xFFEDE9FE);
        fg = const Color(0xFF6D28D9);
        break;
      case ProposalStatus.ditolak:
        bg = AppTheme.errorBg;
        fg = AppTheme.error;
        break;
      case ProposalStatus.draft:
        bg = const Color(0xFFF1F5F9);
        fg = AppTheme.textSecondary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}
