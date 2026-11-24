import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../models/user_profile.dart';
import '../../services/user_service.dart';
import '../../widgets/role_badge.dart';

typedef AddUserPage = UserApprovalPage;
typedef AddUserScreen = UserApprovalPage;

class UserApprovalPage extends StatefulWidget {
  final UserService? userService;

  const UserApprovalPage({super.key, this.userService});

  @override
  State<UserApprovalPage> createState() => _UserApprovalPageState();
}

class _UserApprovalPageState extends State<UserApprovalPage> {
  late final UserService _userService;
  int _selectedTab = 0; // 0: Perlu Verifikasi, 1: Seluruh Akun

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

  @override
  void initState() {
    super.initState();
    _userService = widget.userService ?? UserService();
  }

  // ============ BADGE STATUS ============

  Widget _buildStatusBadge(UserProfile user) {
    Color bgColor;
    Color textColor;
    String label;

    if (user.isActive) {
      bgColor = AppTheme.successBg;
      textColor = AppTheme.success;
      label = 'Aktif';
    } else if (user.isPending) {
      bgColor = AppTheme.warningBg;
      textColor = AppTheme.warning;
      label = 'Menunggu';
    } else if (user.isRejected) {
      bgColor = AppTheme.errorBg;
      textColor = AppTheme.error;
      label = 'Ditolak';
    } else {
      bgColor = const Color(0xFFF1F5F9);
      textColor = AppTheme.textSecondary;
      label = 'Tidak Diketahui';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  bool _isDownloadingDoc = false;

  void _previewDocument(String url, {required String candidateName}) {
    final cleanUrl = url.trim();
    if (cleanUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lampiran dokumen tidak tersedia.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    final isPdf = cleanUrl.toLowerCase().endsWith('.pdf');

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
                  border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
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
                        isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                        color: AppTheme.primaryBlue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pratinjau Surat Tugas',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            candidateName,
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
                    // Tombol Unduh / Share Cepat dari Header Preview
                    IconButton(
                      tooltip: 'Unduh / Simpan',
                      icon: const Icon(Icons.download_rounded, color: AppTheme.primaryBlue),
                      onPressed: () {
                        _openOrDownloadDocument(cleanUrl, candidateName: candidateName);
                      },
                    ),
                    IconButton(
                      tooltip: 'Tutup',
                      icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),

              // Isi Preview
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                  child: isPdf
                      ? PdfPreview(
                          build: (format) async {
                            final response = await http.get(Uri.parse(cleanUrl));
                            if (response.statusCode >= 200 && response.statusCode < 300) {
                              return response.bodyBytes;
                            }
                            throw Exception('Gagal memuat berkas PDF: ${response.statusCode}');
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
                                  const Icon(Icons.error_outline_rounded,
                                      color: AppTheme.error, size: 40),
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
                                  const SizedBox(height: 4),
                                  Text(
                                    '$error',
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  FilledButton.icon(
                                    onPressed: () => _openOrDownloadDocument(
                                      cleanUrl,
                                      candidateName: candidateName,
                                    ),
                                    icon: const Icon(Icons.download_rounded, size: 16),
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
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(
                                  child: CircularProgressIndicator(strokeWidth: 2.5),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) => Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.broken_image_rounded,
                                          color: AppTheme.error, size: 40),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Gagal memuat gambar',
                                        style: TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 12),
                                      FilledButton.icon(
                                        onPressed: () => _openOrDownloadDocument(
                                          cleanUrl,
                                          candidateName: candidateName,
                                        ),
                                        icon: const Icon(Icons.download_rounded, size: 16),
                                        label: const Text('Unduh Berkas'),
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

  Future<void> _openOrDownloadDocument(String url, {String? candidateName}) async {
    final cleanUrl = url.trim();
    if (cleanUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lampiran dokumen tidak tersedia.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    final isCloudinaryOrDirect = cleanUrl.contains('cloudinary.com') ||
        cleanUrl.toLowerCase().endsWith('.pdf') ||
        cleanUrl.toLowerCase().endsWith('.jpg') ||
        cleanUrl.toLowerCase().endsWith('.png') ||
        cleanUrl.toLowerCase().endsWith('.jpeg');

    setState(() => _isDownloadingDoc = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Text('Mengunduh dokumen surat tugas...'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      if (isCloudinaryOrDirect) {
        final response = await http.get(Uri.parse(cleanUrl));
        if (response.statusCode >= 200 && response.statusCode < 300) {
          final bytes = response.bodyBytes;
          final sanitizedName = (candidateName ?? 'surat_tugas')
              .replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
          final isPdf = cleanUrl.toLowerCase().endsWith('.pdf');
          final filename = isPdf
              ? 'Surat_Tugas_$sanitizedName.pdf'
              : 'Surat_Tugas_$sanitizedName.png';

          // Membuka sheet preview/unduh/simpan/cetak langsung di HP
          await Printing.sharePdf(
            bytes: bytes,
            filename: filename,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Dokumen berhasil diunduh ke aplikasi.'),
                backgroundColor: AppTheme.success,
              ),
            );
          }
          return;
        }
      }

      // Fallback jika berupa link Google Drive atau eksternal lainnya
      final uri = Uri.tryParse(cleanUrl);
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Format URL tidak valid');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengunduh berkas: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloadingDoc = false);
      }
    }
  }

  void _showApprovalDialog(UserProfile user, {required bool isApprove}) {
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isApprove
                  ? Icons.check_circle_outline_rounded
                  : Icons.cancel_outlined,
              color: isApprove ? AppTheme.success : AppTheme.error,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              isApprove ? 'Setujui Akun' : 'Tolak Pendaftaran',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isApprove
                  ? 'Yakin ingin menyetujui akun ${user.nama} (${user.role.label})? Akun akan aktif dan dapat masuk ke aplikasi.'
                  : 'Berikan alasan penolakan pendaftaran untuk ${user.nama}:',
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              style: _inputTextStyle,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: isApprove
                    ? 'Catatan persetujuan (opsional)'
                    : 'Alasan penolakan (wajib)',
                hintStyle: _hintStyle,
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
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              if (!isApprove && noteController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Alasan penolakan wajib diisi.'),
                    backgroundColor: AppTheme.error,
                  ),
                );
                return;
              }

              Navigator.pop(ctx);
              try {
                if (isApprove) {
                  debugPrint('[OrgaFlow UserApproval] Menekan Setujui untuk UID: ${user.uid} (${user.nama})');
                  await _userService.approveRegistration(
                    user.uid,
                    catatan: noteController.text.trim().isNotEmpty
                        ? noteController.text.trim()
                        : null,
                  );
                  debugPrint('[OrgaFlow UserApproval] Selesai memanggil approveRegistration');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Akun ${user.nama} berhasil disetujui.'),
                        backgroundColor: AppTheme.success,
                      ),
                    );
                  }
                } else {
                  debugPrint('[OrgaFlow UserApproval] Menekan Tolak untuk UID: ${user.uid} (${user.nama})');
                  await _userService.rejectRegistration(
                    user.uid,
                    alasan: noteController.text.trim(),
                  );
                  debugPrint('[OrgaFlow UserApproval] Selesai memanggil rejectRegistration');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Pendaftaran ${user.nama} ditolak.'),
                        backgroundColor: AppTheme.error,
                      ),
                    );
                  }
                }
              } catch (e, stack) {
                debugPrint('[OrgaFlow UserApproval ERROR] Gagal setujui/tolak akun: $e\n$stack');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal memproses permohonan: $e'),
                      backgroundColor: AppTheme.error,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: isApprove ? AppTheme.success : AppTheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Text(isApprove ? 'Setujui (ACC)' : 'Tolak Pendaftaran'),
          ),
        ],
      ),
    );
  }

  // ============ BUILD ============

  @override
  Widget build(BuildContext context) {
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
                painter: _UserApprovalSoftBackgroundPainter(),
                size: Size.infinite,
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: StreamBuilder<List<UserProfile>>(
              stream: _userService.streamPendingRegistrations(),
              builder: (context, pendingSnap) {
                final pendingList = pendingSnap.data ?? [];

                return StreamBuilder<List<UserProfile>>(
                  stream: _userService.streamUsers(),
                  builder: (context, allSnap) {
                    final allUsers = allSnap.data ?? [];

                    final isLoading =
                        (pendingSnap.connectionState ==
                                ConnectionState.waiting &&
                            !pendingSnap.hasData) ||
                        (allSnap.connectionState == ConnectionState.waiting &&
                            !allSnap.hasData);

                    return RefreshIndicator(
                      onRefresh: () async => await Future<void>.delayed(
                        const Duration(milliseconds: 300),
                      ),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildTitleBlock(),
                                const SizedBox(height: 16),
                                _buildTabSwitcher(
                                  pendingCount: pendingList.length,
                                  allCount: allUsers.length,
                                ),
                              ],
                            ),
                          ),
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
                                _buildSectionHeader(
                                  totalPending: pendingList.length,
                                ),
                                const SizedBox(height: 16),

                                // --- Logika List ---
                                if (isLoading)
                                  _buildLoading()
                                else if (_selectedTab == 0)
                                  // Jika list kosong, tampilkan empty state
                                  if (pendingList.isEmpty)
                                    _buildEmptyState(
                                      title: 'Tidak Ada Pendaftaran Tertunda',
                                      subtitle: 'Semua permohonan akun baru telah diproses.',
                                      icon: Icons.mark_email_read_outlined,
                                    )
                                  else
                                    // Jika list ada isinya, spread (sebarkan) card-card-nya
                                    ...pendingList.map(
                                      (user) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: _buildPendingCard(user),
                                      ),
                                    )
                                else
                                // Untuk Tab Semua Akun
                                if (allUsers.isEmpty)
                                  _buildEmptyState(
                                    title: 'Belum ada pengguna terdaftar',
                                    subtitle:
                                        'Data anggota akan muncul di sini.',
                                    icon: Icons.people_outline_rounded,
                                  )
                                else
                                  ...allUsers.map(
                                    (user) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 10,
                                      ),
                                      child: _buildUserCard(user),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============ TITLE ============

  Widget _buildTitleBlock() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Manajemen Akun',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Verifikasi akun & kelola anggota',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ============ TAB SWITCHER ============

  Widget _buildTabSwitcher({required int pendingCount, required int allCount}) {
    const labels = ['Perlu Verifikasi', 'Semua Akun'];
    final counts = [pendingCount, allCount];

    return LayoutBuilder(
      builder: (context, constraints) {
        final tabWidth = constraints.maxWidth / labels.length;

        return Container(
          height: 46,
          decoration: BoxDecoration(
            color: AppTheme.lightBlue.withOpacity(0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                left: (_selectedTab * tabWidth) + 4,
                top: 4,
                bottom: 4,
                width: tabWidth - 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: List.generate(labels.length, (i) {
                  final isSelected = _selectedTab == i;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _selectedTab = i),
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : AppTheme.textSecondary,
                          ),
                          child: Text(
                            '${labels[i]} (${counts[i]})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============ SECTION HEADER ============

  Widget _buildSectionHeader({required int totalPending}) {
    final isPending = _selectedTab == 0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isPending
                    ? 'Pendaftaran Perlu Verifikasi'
                    : 'Daftar Semua Akun',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isPending
                    ? (totalPending > 0
                          ? 'Terdapat $totalPending akun menunggu persetujuan'
                          : 'Tidak ada akun yang perlu diproses')
                    : 'Seluruh anggota & pengurus terdaftar',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
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

  // ============ PENDING CARD ============

  Widget _buildPendingCard(UserProfile user) {
    final isPengurus = user.role.isPengurus;
    final initial = user.nama.isNotEmpty ? user.nama[0].toUpperCase() : 'U';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== HEADER: Avatar, Nama, Email, Badge =====
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppTheme.lightBlue,
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.nama,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
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
              const SizedBox(width: 8),
              RoleBadge(role: user.role),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: AppTheme.borderLight),
          const SizedBox(height: 12),

          // ===== INFO GRID =====
          _buildInfoRow(
            icon: Icons.badge_outlined,
            label: 'NIM',
            value: user.nim?.isNotEmpty == true ? user.nim! : '-',
          ),
          if (user.noWa?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              icon: Icons.phone_outlined,
              label: 'WhatsApp',
              value: user.noWa!,
            ),
          ],
          if (user.divisiId?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              icon: Icons.groups_outlined,
              label: 'Divisi Diajukan',
              value: user.divisiId!,
              valueColor: AppTheme.primaryBlue,
              highlight: true,
            ),
          ],

          // ===== DOKUMEN =====
          if (isPengurus) ...[
            const SizedBox(height: 12),
            _buildDocumentSection(user),
          ],

          // ===== TOMBOL AKSI =====
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: OutlinedButton(
                    onPressed: () =>
                        _showApprovalDialog(user, isApprove: false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: BorderSide(color: AppTheme.error.withOpacity(0.4)),
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: const StadiumBorder(),
                      textStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Text('Tolak'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: FilledButton(
                    onPressed: () => _showApprovalDialog(user, isApprove: true),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: const StadiumBorder(),
                      textStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Text('Setujui'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============ INFO ROW ============

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool highlight = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: AppTheme.lightBlue.withOpacity(0.6),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, size: 14, color: AppTheme.primaryBlue),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
                  color: valueColor ?? AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentSection(UserProfile user) {
    final hasDoc = user.suratTugasUrl != null && user.suratTugasUrl!.isNotEmpty;
    final isPdf = user.suratTugasUrl?.toLowerCase().endsWith('.pdf') ?? false;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.lightBlue.withOpacity(0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isPdf ? Icons.picture_as_pdf_rounded : Icons.file_present_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Surat Tugas / SK Pengurus',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasDoc ? 'Berkas lampiran siap diunduh' : 'Tidak ada berkas terlampir',
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
          if (hasDoc) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                // Tombol Pratinjau / Lihat Dokumen (Utama)
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 38,
                    child: FilledButton.icon(
                      onPressed: () => _previewDocument(
                        user.suratTugasUrl!,
                        candidateName: user.nama,
                      ),
                      icon: const Icon(Icons.visibility_outlined, size: 16),
                      label: const Text(
                        'Lihat Dokumen',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Tombol Unduh / Share Cepat
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 38,
                    child: OutlinedButton.icon(
                      onPressed: _isDownloadingDoc
                          ? null
                          : () => _openOrDownloadDocument(
                                user.suratTugasUrl!,
                                candidateName: user.nama,
                              ),
                      icon: _isDownloadingDoc
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.primaryBlue,
                                ),
                              ),
                            )
                          : const Icon(Icons.download_rounded, size: 16),
                      label: Text(
                        _isDownloadingDoc ? 'Proses...' : 'Unduh',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryBlue,
                        side: const BorderSide(
                          color: AppTheme.primaryBlue,
                          width: 1.2,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ============ USER CARD (SEMUA AKUN) ============

  Widget _buildUserCard(UserProfile user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppTheme.lightBlue,
            child: Text(
              user.nama.isNotEmpty ? user.nama[0].toUpperCase() : 'U',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryBlue,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.nama,
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
                  '${user.email} • ${user.role.label}',
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
          const SizedBox(width: 8),
          _buildStatusBadge(user),
        ],
      ),
    );
  }

  // ============ EMPTY STATE ============

  Widget _buildEmptyState({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 23, horizontal: 17),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppTheme.lightBlue,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 25, color: AppTheme.primaryBlue),
          ),
          const SizedBox(height: 11),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ============ SOFT BACKGROUND PAINTER ============

class _UserApprovalSoftBackgroundPainter extends CustomPainter {
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
  bool shouldRepaint(
    covariant _UserApprovalSoftBackgroundPainter oldDelegate,
  ) => false;
}
