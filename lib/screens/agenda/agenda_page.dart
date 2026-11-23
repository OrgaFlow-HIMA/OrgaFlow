import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../enums/user_role.dart';
import '../../models/agenda.dart';
import '../../services/agenda_service.dart';
import 'widgets/add_edit_agenda_modal.dart';
import 'widgets/online_meeting_box.dart';

class AgendaPage extends StatefulWidget {
  final String userName;
  final UserRole? role;

  const AgendaPage({super.key, this.userName = 'Pengurus', this.role});

  @override
  State<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends State<AgendaPage> {
  final AgendaService _agendaService = AgendaService();
  int _selectedFilter = 0; // 0: Mendatang, 1: Selesai, 2: Semua

  bool get _isSekretaris => widget.role == UserRole.sekretaris;

  void _selectFilter(int index) {
    if (_selectedFilter == index) return;
    setState(() => _selectedFilter = index);
  }

  void _showAddEditModal({Agenda? agenda}) {
    AddEditAgendaModal.show(
      context,
      agenda: agenda,
      agendaService: _agendaService,
    );
  }

  Future<void> _handleDelete(Agenda agenda) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Agenda?'),
        content: Text('Yakin ingin menghapus agenda "${agenda.judul}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _agendaService.deleteAgenda(agenda.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Agenda berhasil dihapus.'),
              backgroundColor: AppTheme.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menghapus: $e'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    }
  }

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
          // Wave background (lebih samar dibanding dashboard)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 420,
            child: IgnorePointer(
              child: CustomPaint(
                painter: _AgendaSoftBackgroundPainter(),
                size: Size.infinite,
              ),
            ),
          ),

          // Konten
          SafeArea(
            bottom: false,
            child: StreamBuilder<List<Agenda>>(
              stream: _agendaService.watchAgendas(),
              builder: (context, snapshot) {
                final allAgendas = snapshot.data ?? const <Agenda>[];
                final upcomingAgendas = allAgendas
                    .where((a) => !a.isPast)
                    .toList();
                final pastAgendas = allAgendas.where((a) => a.isPast).toList();

                final isLoading =
                    snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData;

                List<Agenda> visibleAgendas;
                if (_selectedFilter == 0) {
                  visibleAgendas = upcomingAgendas;
                } else if (_selectedFilter == 1) {
                  visibleAgendas = pastAgendas;
                } else {
                  visibleAgendas = allAgendas;
                }

                return RefreshIndicator(
                  onRefresh: () async => await Future<void>.delayed(
                    const Duration(milliseconds: 300),
                  ),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    children: [
                      // Bagian atas (judul + tabs) di atas background
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTitleBlock(),
                            const SizedBox(height: 20),
                            _buildFilterTabs(
                              counts: [
                                upcomingAgendas.length,
                                pastAgendas.length,
                                allAgendas.length,
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Panel putih berisi list agenda
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
                            // Section header dinamis
                            _buildSectionHeader(),

                            const SizedBox(height: 16),

                            if (isLoading)
                              _buildLoading()
                            else if (visibleAgendas.isEmpty)
                              _buildEmptyState()
                            else
                              ...visibleAgendas.map(
                                (agenda) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildAgendaCard(agenda),
                                ),
                              ),

                            const SizedBox(height: 8),
                            _buildReminderCard(),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============ TITLE + ADD BUTTON ============

  Widget _buildTitleBlock() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Agenda & Acara',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Pengingat jadwal dan kegiatan organisasi',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (_isSekretaris) ...[const SizedBox(width: 12), _buildAddButton()],
      ],
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: () => _showAddEditModal(),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppTheme.primaryBlue,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
      ),
    );
  }

  // ============ FILTER TABS (sliding) ============

  Widget _buildFilterTabs({required List<int> counts}) {
    const labels = ['Mendatang', 'Selesai', 'Semua'];

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final tabWidth = totalWidth / labels.length;

        return Container(
          height: 46,
          decoration: BoxDecoration(
            color: AppTheme.lightBlue.withOpacity(0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Stack(
            children: [
              // Sliding indicator
              AnimatedPositioned(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                left: (_selectedFilter * tabWidth) + 4,
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
              // Labels
              Row(
                children: List.generate(labels.length, (i) {
                  final isSelected = _selectedFilter == i;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _selectFilter(i),
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

  // ============ SECTION HEADER DINAMIS ============

  String get _sectionTitle {
    switch (_selectedFilter) {
      case 0:
        return 'Agenda Mendatang';
      case 1:
        return 'Agenda Selesai';
      default:
        return 'Semua Agenda';
    }
  }

  String get _sectionSubtitle {
    switch (_selectedFilter) {
      case 0:
        return 'Jadwal kegiatan dan rapat yang akan datang';
      case 1:
        return 'Riwayat agenda yang sudah terlaksana';
      default:
        return 'Seluruh jadwal kegiatan organisasi';
    }
  }

  Widget _buildSectionHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _sectionTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _sectionSubtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (_isSekretaris) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _showAddEditModal(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Tambah',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.accentBlue,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppTheme.accentBlue,
                ),
              ],
            ),
          ),
        ],
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

  // ============ AGENDA CARD ============

  Widget _buildAgendaCard(Agenda agenda) {
    final isDanger = agenda.isStatusDanger;
    final isOnline = agenda.isOnline;

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
          // Header Row
          // Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Kategori chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.lightBlue,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  agenda.kategori,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
              const Spacer(),

              // Status tag
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDanger ? AppTheme.errorBg : AppTheme.lightBlue,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  agenda.statusTag,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDanger ? AppTheme.error : AppTheme.primaryBlue,
                  ),
                ),
              ),

              // Menu titik tiga
              if (_isSekretaris) ...[
                const SizedBox(width: 4),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: PopupMenuButton<String>(
                    tooltip: '',
                    padding: EdgeInsets.zero,
                    iconSize: 20,
                    splashRadius: 16,
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                    position: PopupMenuPosition.under,
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      size: 20,
                      color: AppTheme.textSecondary,
                    ),
                    onSelected: (val) {
                      if (val == 'edit') {
                        _showAddEditModal(agenda: agenda);
                      } else if (val == 'delete') {
                        _handleDelete(agenda);
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Edit Agenda'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: AppTheme.error,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Hapus',
                              style: TextStyle(color: AppTheme.error),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),

          // Judul
          Text(
            agenda.judul,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
              height: 1.3,
            ),
          ),

          if (agenda.deskripsi.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              agenda.deskripsi,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 12),

          // Info waktu & lokasi
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 15,
                      color: AppTheme.primaryBlue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        agenda.formattedDateTime,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      isOnline
                          ? Icons.videocam_outlined
                          : Icons.location_on_outlined,
                      size: 15,
                      color: AppTheme.primaryBlue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isOnline ? '${agenda.lokasi} (Online)' : agenda.lokasi,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (isOnline &&
              agenda.linkMeeting != null &&
              agenda.linkMeeting!.isNotEmpty) ...[
            const SizedBox(height: 12),
            OnlineMeetingBox(
              meetUrl: agenda.linkMeeting!,
              platform: agenda.lokasi,
            ),
          ],

          if (isOnline &&
              agenda.linkAbsensi != null &&
              agenda.linkAbsensi!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildAttendanceBox(agenda.linkAbsensi!),
          ],
        ],
      ),
    );
  }

  // ============ ATTENDANCE BOX ============

  Widget _buildAttendanceBox(String absensiUrl) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.lightBlue.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accentBlue.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.assignment_turned_in_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Absensi Kehadiran',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  absensiUrl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: absensiUrl));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tautan absensi berhasil disalin!'),
                  backgroundColor: AppTheme.success,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 14),
            label: const Text('Salin'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(0, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============ EMPTY STATE ============

  Widget _buildEmptyState() {
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
            child: const Icon(
              Icons.event_busy_outlined,
              size: 25,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 11),
          const Text(
            'Tidak ada agenda pada kategori ini',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _isSekretaris
                ? 'Tekan tombol "+" di kanan atas untuk membuat jadwal baru.'
                : 'Agenda baru akan muncul di sini saat ditambahkan.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  // ============ REMINDER CARD ============

  Widget _buildReminderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppTheme.lightBlue.withOpacity(0.45),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppTheme.accentBlue.withOpacity(0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Catatan Pengingat',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Pastikan hadir 15 menit sebelum acara dimulai untuk presensi kehadiran.',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.4,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============ SOFT BACKGROUND PAINTER ============
// Sama seperti DashboardBackgroundPainter, tapi opacity diturunkan
// (~50% lebih samar) agar tidak menyala di halaman Agenda.

class _AgendaSoftBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Wave 1 — versi dashboard, dipudarkan
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
        colors: [
          Color(0x80B8CCFF), // 50% opacity (semula solid)
          Color(0x66D5E1FF), // 40%
          Color(0x33EAF0FF), // 20%
        ],
      ).createShader(Rect.fromLTWH(0, 0, width, height));

    canvas.drawPath(wave1, paint1);

    // Wave 2 — versi dashboard, dipudarkan
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
        colors: [
          Color(0x3386A8FF), // 20% (semula 0x55 = 33%)
          Color(0x1F86A8FF), // 12% (semula 0x33 = 20%)
          Color(0x00FFFFFF), // transparan
        ],
      ).createShader(Rect.fromLTWH(0, 0, width, height));

    canvas.drawPath(wave2, paint2);

    // Wave 3 — aksen transparan, dipudarkan
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

    final paint3 = Paint()
      ..color = const Color(0x1486A8FF); // 8% (semula 0x22 = 13%)

    canvas.drawPath(wave3, paint3);
  }

  @override
  bool shouldRepaint(covariant _AgendaSoftBackgroundPainter oldDelegate) =>
      false;
}
