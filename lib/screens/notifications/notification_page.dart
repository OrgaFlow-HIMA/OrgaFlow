import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../enums/user_role.dart';
import '../../models/app_notification.dart';
import '../../models/user_profile.dart';
import '../../services/notification_service.dart';
import '../../services/proposal_service.dart';
import '../../services/task_service.dart';
import '../../services/finance_service.dart';
import '../../services/user_service.dart';
import '../approval/approval_page.dart';
import '../approval/proposal_page.dart';
import '../approval/widgets/proposal_detail_modal.dart';
import '../finance/finance_page.dart';
import '../finance/widgets/qris_payment_sheet.dart';
import '../finance/widgets/verify_payments_modal.dart';
import '../tasks/widgets/task_detail_modal.dart';

class NotificationPage extends StatefulWidget {
  final String currentUserId;
  final UserRole userRole;
  final NotificationService? notificationService;

  const NotificationPage({
    super.key,
    required this.currentUserId,
    required this.userRole,
    this.notificationService,
  });

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  late final NotificationService _notificationService;
  final TaskService _taskService = TaskService();
  final FinanceService _financeService = FinanceService();
  final ProposalService _proposalService = ProposalService();
  final UserService _userService = UserService();

  UserProfile? _cachedProfile;
  bool _isSelecting = false;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _notificationService = widget.notificationService ?? NotificationService();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final profile = await _userService.getUserProfile(widget.currentUserId);
    if (mounted && profile != null) {
      setState(() {
        _cachedProfile = profile;
      });
    }
  }

  // =========================================================
  // LOGIKA WAKTU & GROUPING
  // =========================================================

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _getTimeGroup(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);
    final diffDays = today.difference(date).inDays;

    if (diffDays == 0) return 'Hari Ini';
    if (diffDays == 1) return 'Kemarin';
    if (diffDays < 7) return 'Minggu Ini';
    return 'Lebih Lama';
  }

  List<MapEntry<String, List<AppNotification>>> _groupNotifications(
    List<AppNotification> notifs,
  ) {
    final Map<String, List<AppNotification>> grouped = {};
    const order = ['Hari Ini', 'Kemarin', 'Minggu Ini', 'Lebih Lama'];

    for (final n in notifs) {
      final group = _getTimeGroup(n.createdAt);
      grouped.putIfAbsent(group, () => []).add(n);
    }

    final result = <MapEntry<String, List<AppNotification>>>[];
    for (final key in order) {
      if (grouped.containsKey(key)) {
        result.add(MapEntry(key, grouped[key]!));
      }
    }
    return result;
  }

  // =========================================================
  // LOGIKA SELEKSI
  // =========================================================

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
      if (_selectedIds.isEmpty) {
        _isSelecting = false;
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelecting = false;
      _selectedIds.clear();
    });
  }

  void _selectAll(List<AppNotification> notifs) {
    setState(() {
      if (_selectedIds.length == notifs.length) {
        _selectedIds.clear();
        _isSelecting = false;
      } else {
        _selectedIds.clear();
        _selectedIds.addAll(notifs.map((e) => e.id));
      }
    });
  }

  Future<void> _markSelectedAsRead() async {
    if (_selectedIds.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      for (final id in _selectedIds) {
        await _notificationService.markAsRead(
          notificationId: id,
          userId: widget.currentUserId,
        );
      }
      if (mounted) {
        _exitSelectionMode();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Ditandai telah dibaca.'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Notifikasi?'),
        content: Text('Hapus ${_selectedIds.length} notifikasi terpilih?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await _notificationService.deleteMultipleNotifications(
        _selectedIds.toList(),
      );
      if (mounted) {
        _exitSelectionMode();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Notifikasi dihapus.'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _showOptionsMenu(
    BuildContext buttonContext,
    List<AppNotification> allNotifs,
  ) {
    final RenderBox button = buttonContext.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Navigator.of(buttonContext).overlay!.context.findRenderObject()
            as RenderBox;

    // Hitung posisi menu agar muncul persis di bawah tombol
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    showMenu(
      context: buttonContext,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      elevation: 6,
      items: [
        PopupMenuItem(
          onTap: () async {
            final messenger = ScaffoldMessenger.of(context);
            await _notificationService.markAllAsRead(
              notifications: allNotifs,
              userId: widget.currentUserId,
            );
            messenger.showSnackBar(
              const SnackBar(
                content: Text('Semua ditandai dibaca.'),
                backgroundColor: AppTheme.success,
              ),
            );
          },
          child: const Row(
            children: [
              Icon(
                Icons.done_all_rounded,
                size: 18,
                color: AppTheme.primaryBlue,
              ),
              SizedBox(width: 10),
              Text(
                'Baca Semua',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          onTap: () {
            setState(() {
              _isSelecting = true;
              _selectedIds.clear();
            });
          },
          child: const Row(
            children: [
              Icon(
                Icons.checklist_rounded,
                size: 18,
                color: AppTheme.primaryBlue,
              ),
              SizedBox(width: 10),
              Text(
                'Pilih Notifikasi',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================
  // BUILD UI (REFERENSI LAYOUT BARU + ELEMEN LAMA)
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Background Gradient Aplikasi
          Container(
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
          ),

          SafeArea(
            bottom: false,
            child: StreamBuilder<List<AppNotification>>(
              stream: _notificationService.watchUserNotifications(
                userId: widget.currentUserId,
                role: widget.userRole,
              ),
              builder: (context, snapshot) {
                final allNotifs = snapshot.data ?? [];
                final unreadNotifs = allNotifs
                    .where((n) => !n.isReadBy(widget.currentUserId))
                    .toList();
                final isLoading =
                    snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData;

                final groupedNotifs = _groupNotifications(allNotifs);

                return Column(
                  children: [
                    _buildHeader(unreadNotifs.length, allNotifs),
                    const SizedBox(height: 16),

                    // Panel Putih List
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(28),
                          ),
                        ),
                        child: isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                ),
                              )
                            : allNotifs.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                padding: const EdgeInsets.only(
                                  bottom: 100,
                                  top: 24,
                                ),
                                itemCount: groupedNotifs.length,
                                itemBuilder: (context, index) {
                                  final group = groupedNotifs[index];
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          20,
                                          8,
                                          20,
                                          8,
                                        ),
                                        child: Text(
                                          group.key,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      ),
                                      ...group.value.map(
                                        (notif) => Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                            20,
                                            0,
                                            20,
                                            10,
                                          ),
                                          child: _buildNotificationCard(notif),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Bottom Action Bar Mode Pilih
          if (_isSelecting)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildSelectionActionBar(),
            ),
        ],
      ),
    );
  }

  // ============ HEADER ============

  Widget _buildHeader(int unreadCount, List<AppNotification> allNotifs) {
    if (_isSelecting) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(
                Icons.close_rounded,
                color: AppTheme.textPrimary,
              ),
              onPressed: _exitSelectionMode,
            ),
            const SizedBox(width: 8),
            Text(
              '${_selectedIds.length} Dipilih',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => _selectAll(allNotifs),
              child: Text(
                _selectedIds.length == allNotifs.length
                    ? 'Batal Pilih'
                    : 'Pilih Semua',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppTheme.textPrimary,
                size: 20,
              ),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Notifikasi',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                if (unreadCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.error,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Builder(
            builder: (buttonContext) {
              return GestureDetector(
                onTap: () => _showOptionsMenu(buttonContext, allNotifs),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: const Icon(
                    Icons.more_vert_rounded,
                    color: AppTheme.textPrimary,
                    size: 20,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ============ CARD NOTIFIKASI ============

  Widget _buildNotificationCard(AppNotification notif) {
    final isRead = notif.isReadBy(widget.currentUserId);
    final isSelected = _selectedIds.contains(notif.id);

    IconData icon;
    Color iconColor;
    Color iconBg;

    switch (notif.type) {
      case NotificationType.task:
        icon = Icons.assignment_outlined;
        iconColor = AppTheme.primaryBlue;
        iconBg = AppTheme.lightBlue;
        break;
      case NotificationType.agenda:
        icon = Icons.calendar_month_outlined;
        iconColor = const Color(0xFF15803D);
        iconBg = const Color(0xFFDCFCE7);
        break;
      case NotificationType.finance:
        icon = Icons.account_balance_wallet_outlined;
        iconColor = const Color(0xFFB45309);
        iconBg = const Color(0xFFFEF3C7);
        break;
      case NotificationType.proposal:
        icon = Icons.approval_outlined;
        iconColor = const Color(0xFF7C3AED);
        iconBg = const Color(0xFFF3E8FF);
        break;
      case NotificationType.general:
        icon = Icons.notifications_none_rounded;
        iconColor = const Color(0xFF6B7280);
        iconBg = const Color(0xFFF3F4F6);
        break;
    }

    return InkWell(
      onTap: () {
        if (_isSelecting) {
          _toggleSelection(notif.id);
        } else {
          if (!isRead) {
            _notificationService.markAsRead(
              notificationId: notif.id,
              userId: widget.currentUserId,
            );
          }
          _showNotificationDetailModal(notif);
        }
      },
      onLongPress: () {
        if (!_isSelecting) {
          setState(() {
            _isSelecting = true;
            _selectedIds.add(notif.id);
          });
        }
      },
      borderRadius: BorderRadius.circular(17),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.lightBlue.withOpacity(0.3)
              : (isRead ? Colors.white : AppTheme.lightBlue.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryBlue
                : (isRead
                      ? AppTheme.borderLight
                      : AppTheme.primaryBlue.withOpacity(0.3)),
            width: isSelected ? 1.4 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isSelecting)
              Padding(
                padding: const EdgeInsets.only(right: 12, top: 10),
                child: Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked,
                  color: isSelected
                      ? AppTheme.primaryBlue
                      : AppTheme.textSecondary,
                  size: 22,
                ),
              )
            else
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notif.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isRead
                                ? FontWeight.w600
                                : FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTimestamp(notif.createdAt),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: isRead
                          ? AppTheme.textSecondary
                          : const Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ),

            if (!isRead && !_isSelecting)
              Padding(
                padding: const EdgeInsets.only(left: 10, top: 14),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryBlue,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============ BOTTOM ACTION BAR ============

  Widget _buildSelectionActionBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 44,
              child: OutlinedButton.icon(
                onPressed: _selectedIds.isEmpty ? null : _markSelectedAsRead,
                icon: const Icon(Icons.done_all_rounded, size: 18),
                label: const Text('Baca'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryBlue,
                  side: const BorderSide(
                    color: AppTheme.primaryBlue,
                    width: 1.2,
                  ),
                  shape: const StadiumBorder(),
                  padding: EdgeInsets.zero,
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 44,
              child: FilledButton.icon(
                onPressed: _selectedIds.isEmpty ? null : _deleteSelected,
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('Hapus'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.error,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: EdgeInsets.zero,
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============ EMPTY STATE ============

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppTheme.lightBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_off_outlined,
                size: 30,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Tidak Ada Notifikasi',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Pemberitahuan baru akan muncul di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // MODAL DETAIL NOTIFIKASI & REDIRECT KE EVENT
  // =========================================================

  void _showNotificationDetailModal(AppNotification notif) {
    IconData icon;
    Color iconColor;
    Color iconBg;
    String typeLabel;

    switch (notif.type) {
      case NotificationType.task:
        icon = Icons.assignment_outlined;
        iconColor = AppTheme.primaryBlue;
        iconBg = AppTheme.lightBlue;
        typeLabel = 'Tugas Organisasi';
        break;
      case NotificationType.agenda:
        icon = Icons.calendar_month_outlined;
        iconColor = const Color(0xFF15803D);
        iconBg = const Color(0xFFDCFCE7);
        typeLabel = 'Agenda & Kegiatan';
        break;
      case NotificationType.finance:
        icon = Icons.account_balance_wallet_outlined;
        iconColor = const Color(0xFFB45309);
        iconBg = const Color(0xFFFEF3C7);
        typeLabel = 'Keuangan & Kas';
        break;
      case NotificationType.proposal:
        icon = Icons.approval_outlined;
        iconColor = const Color(0xFF7C3AED);
        iconBg = const Color(0xFFF3E8FF);
        typeLabel = 'Pengajuan & Persetujuan';
        break;
      case NotificationType.general:
        icon = Icons.notifications_none_rounded;
        iconColor = const Color(0xFF6B7280);
        iconBg = const Color(0xFFF3F4F6);
        typeLabel = 'Pemberitahuan';
        break;
    }

    final hasReference =
        notif.referenceId != null && notif.referenceId!.isNotEmpty;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 20,
                offset: Offset(0, -6),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppTheme.borderLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                // Icon + Kategori
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: iconColor, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            typeLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: iconColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatTimestamp(notif.createdAt),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.background,
                        foregroundColor: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Judul Notifikasi
                Text(
                  notif.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 10),

                // Pesan lengkap notifikasi
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Text(
                    notif.message,
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.5,
                      color: Color(0xFF334155),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                // Tombol Aksi: Lihat Selengkapnya / Redirect
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.borderLight),
                          foregroundColor: AppTheme.textSecondary,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('Tutup'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _handleNotificationRedirect(notif);
                        },
                        icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                        label: Text(
                          hasReference
                              ? 'Buka Detail Acara'
                              : 'Lihat Halaman Terkait',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: iconColor,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =========================================================
  // LOGIKA NAVIGASI / REDIRECT KE EVENT ASLI
  // =========================================================

  Future<void> _handleNotificationRedirect(AppNotification notif) async {
    final refId = notif.referenceId;
    final messenger = ScaffoldMessenger.of(context);

    // 1. TUGAS
    if (notif.type == NotificationType.task) {
      if (refId != null && refId.isNotEmpty) {
        // Tampilkan loading dialog singkat saat mengambil data
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryBlue),
          ),
        );

        final task = await _taskService.getTaskById(refId);
        if (mounted) Navigator.pop(context); // Tutup loading

        if (!mounted) return;

        if (task != null) {
          TaskDetailModal.show(context, task: task, userRole: widget.userRole);
          return;
        }
      }

      // Fallback jika task tidak ditemukan atau refId kosong: buka dashboard / infokan
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Membuka menu Tugas organisasi.'),
          backgroundColor: AppTheme.primaryBlue,
        ),
      );
      Navigator.maybePop(context);
      return;
    }

    // 2. KEUANGAN / KAS
    if (notif.type == NotificationType.finance) {
      if (refId != null && refId.isNotEmpty) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryBlue),
          ),
        );

        final tx = await _financeService.getTransactionById(refId);
        if (mounted) Navigator.pop(context);

        if (!mounted) return;

        if (tx != null) {
          // Jika pengguna adalah Bendahara, buka modal verifikasi / detail tagihan
          if (widget.userRole == UserRole.bendahara) {
            VerifyPaymentsModal.show(context, transaction: tx);
            return;
          }

          // Jika anggota/kadiv dan ada tagihan kas, buka modal pembayaran QRIS
          if (tx.isTagihanAnggota) {
            final existingPayment = await _financeService.getUserPayment(
              refId,
              widget.currentUserId,
            );
            if (!mounted) return;

            QrisPaymentSheet.show(
              context,
              transaction: tx,
              existingPayment: existingPayment,
              currentUid: widget.currentUserId,
              currentNama: _cachedProfile?.nama ?? 'Anggota',
              currentNim: _cachedProfile?.nim,
              currentDivisiId: _cachedProfile?.divisiId,
            );
            return;
          }
        }
      }

      // Fallback: Arahkan ke halaman keuangan
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FinancePage(
            userRole: widget.userRole,
            userName: _cachedProfile?.nama ?? 'Pengurus',
          ),
        ),
      );
      return;
    }

    // 3. PENGAJUAN / PERSETUJUAN (PROPOSAL / SURAT / LPJ)
    if (notif.type == NotificationType.proposal) {
      final isReviewer =
          widget.userRole == UserRole.dekan ||
          widget.userRole == UserRole.ketua ||
          widget.userRole == UserRole.wakilKetua;

      if (refId != null && refId.isNotEmpty) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryBlue),
          ),
        );

        final proposal = await _proposalService.getProposalById(refId);
        if (mounted) Navigator.pop(context);

        if (!mounted) return;

        if (proposal != null) {
          ProposalDetailModal.show(
            context,
            proposal: proposal,
            userRole: widget.userRole,
            currentUid: widget.currentUserId,
            currentUserName: _cachedProfile?.nama ?? 'Pimpinan',
          );
          return;
        }
      }

      // Fallback: Navigasi ke halaman Persetujuan (Dekan/Ketua) atau Pengajuan (Pengurus)
      if (isReviewer) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ApprovalPage(
              userProfile: _cachedProfile,
              role: widget.userRole,
            ),
          ),
        );
      } else {
        if (_cachedProfile != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProposalPage(
                role: widget.userRole,
                userProfile: _cachedProfile!,
              ),
            ),
          );
        }
      }
      return;
    }

    // 4. AGENDA / UMUM
    if (notif.type == NotificationType.agenda) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Membuka detail Agenda organisasi.'),
          backgroundColor: Color(0xFF15803D),
        ),
      );
      Navigator.maybePop(context);
      return;
    }

    // GENERAL NOTIFICATION
    messenger.showSnackBar(
      SnackBar(
        content: Text(notif.title),
        backgroundColor: AppTheme.primaryBlue,
      ),
    );
  }
}
