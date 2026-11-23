import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _UserApprovalPageState extends State<UserApprovalPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final UserService _userService;

  @override
  void initState() {
    super.initState();
    _userService = widget.userService ?? UserService();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildStatusBadge(UserProfile user) {
    Color bgColor;
    Color textColor;
    IconData icon;
    String label;

    if (user.isActive) {
      bgColor = AppTheme.successBg;
      textColor = AppTheme.success;
      icon = Icons.check_circle_rounded;
      label = 'Aktif';
    } else if (user.isPending) {
      bgColor = AppTheme.warningBg;
      textColor = AppTheme.warning;
      icon = Icons.hourglass_top_rounded;
      label = 'Menunggu';
    } else if (user.isRejected) {
      bgColor = AppTheme.errorBg;
      textColor = AppTheme.error;
      icon = Icons.cancel_rounded;
      label = 'Ditolak';
    } else {
      bgColor = const Color(0xFFF1F5F9);
      textColor = AppTheme.textSecondary;
      icon = Icons.help_outline_rounded;
      label = 'Tidak Diketahui';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openOrDownloadDocument(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Format URL dokumen tidak valid.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        throw Exception('Tidak dapat membuka tautan');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka/mengunduh dokumen: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link berhasil disalin ke clipboard.'),
        backgroundColor: AppTheme.success,
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
              size: 26,
            ),
            const SizedBox(width: 8),
            Text(isApprove ? 'Setujui Akun' : 'Tolak Pendaftaran'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isApprove
                  ? 'Apakah Anda yakin ingin menyetujui akun ${user.nama} (${user.role.label})? Akun ini akan aktif dan dapat masuk ke aplikasi.'
                  : 'Berikan alasan penolakan pendaftaran untuk ${user.nama}:',
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: InputDecoration(
                hintText: isApprove
                    ? 'Catatan persetujuan (opsional)'
                    : 'Alasan penolakan (wajib)',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              maxLines: 2,
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
                  ),
                );
                return;
              }

              Navigator.pop(ctx);
              try {
                if (isApprove) {
                  await _userService.approveRegistration(
                    user.uid,
                    catatan: noteController.text.trim().isNotEmpty
                        ? noteController.text.trim()
                        : null,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Akun ${user.nama} berhasil disetujui.'),
                        backgroundColor: AppTheme.success,
                      ),
                    );
                  }
                } else {
                  await _userService.rejectRegistration(
                    user.uid,
                    alasan: noteController.text.trim(),
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Pendaftaran ${user.nama} ditolak.'),
                        backgroundColor: AppTheme.error,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal memproses permohonan: $e'),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: isApprove ? AppTheme.success : AppTheme.error,
            ),
            child: Text(isApprove ? 'Setujui (ACC)' : 'Tolak Pendaftaran'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Persetujuan & Manajemen Akun',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Verifikasi pendaftaran akun mandiri dan kelola anggota organisasi',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: AppTheme.primaryBlue,
                      unselectedLabelColor: AppTheme.textSecondary,
                      indicatorColor: AppTheme.primaryBlue,
                      dividerColor: Colors.transparent,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      tabs: const [
                        Tab(text: 'Perlu Verifikasi'),
                        Tab(text: 'Daftar Seluruh Akun'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [_buildPendingList(), _buildAllUsersList()],
        ),
      ),
    );
  }

  Widget _buildPendingList() {
    return StreamBuilder<List<UserProfile>>(
      stream: _userService.streamPendingRegistrations(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final list = snapshot.data ?? [];
        if (list.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: AppTheme.lightBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_read_outlined,
                    size: 40,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Tidak Ada Pendaftaran Tertunda',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Semua permohonan akun baru telah diproses.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final user = list[index];
            final isPengurus = user.role.isPengurus;

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          user.nama,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      RoleBadge(role: user.role),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Email: ${user.email} • NIM: ${user.nim ?? "-"}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  if (user.noWa?.isNotEmpty == true) ...[
                    const SizedBox(height: 2),
                    Text(
                      'No. WhatsApp: ${user.noWa}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                  if (user.divisiId?.isNotEmpty == true) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Divisi Diajukan: ${user.divisiId}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ],

                  if (isPengurus) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.file_present_rounded,
                                color: AppTheme.primaryBlue,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Dokumen Surat Tugas / SK Pengurus:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryBlue,
                                  ),
                                ),
                              ),
                              if (user.suratTugasUrl != null &&
                                  user.suratTugasUrl!.isNotEmpty)
                                IconButton(
                                  icon: const Icon(
                                    Icons.copy_rounded,
                                    size: 18,
                                    color: AppTheme.primaryBlue,
                                  ),
                                  tooltip: 'Salin Link',
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                  onPressed: () =>
                                      _copyToClipboard(user.suratTugasUrl!),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            user.suratTugasUrl ?? 'Tidak ada lampiran',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF1D4ED8),
                            ),
                          ),
                          if (user.suratTugasUrl != null &&
                              user.suratTugasUrl!.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _openOrDownloadDocument(
                                    user.suratTugasUrl!),
                                icon: const Icon(
                                  Icons.download_rounded,
                                  size: 18,
                                ),
                                label: const Text(
                                  'Unduh / Buka Dokumen',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryBlue,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              _showApprovalDialog(user, isApprove: false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.error,
                            side: const BorderSide(color: AppTheme.error),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Tolak'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: () =>
                              _showApprovalDialog(user, isApprove: true),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.success,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Setujui (ACC)'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAllUsersList() {
    return StreamBuilder<List<UserProfile>>(
      stream: _userService.streamUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data ?? [];
        if (users.isEmpty) {
          return const Center(
            child: Text(
              'Belum ada pengguna terdaftar.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final user = users[index];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.lightBlue,
                    child: Text(
                      user.nama.isNotEmpty ? user.nama[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
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
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${user.email} • ${user.role.label}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(user),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
