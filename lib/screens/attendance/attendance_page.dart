import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/agenda.dart';
import '../../models/attendance_record.dart';
import '../../services/agenda_service.dart';
import '../../services/attendance_service.dart';

class AttendancePage extends StatefulWidget {
  final String userName;
  final String? divisionName;
  final String? userRoleLabel;

  const AttendancePage({
    super.key,
    this.userName = 'Pengguna',
    this.divisionName,
    this.userRoleLabel,
  });

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final AttendanceService _attendanceService = AttendanceService();
  final AgendaService _agendaService = AgendaService();

  String get _currentUserId => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    final userId = _currentUserId;

    // Gunakan Scaffold agar layout tidak overflow saat scroll / keyboard muncul
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Container(
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
                  painter: _AttendanceSoftBackgroundPainter(),
                  size: Size.infinite,
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: StreamBuilder<List<AttendanceRecord>>(
                stream: _attendanceService.streamUserAttendance(userId),
                builder: (context, attendanceSnap) {
                  final userRecords = attendanceSnap.data ?? [];
                  final recordByAgendaId = {
                    for (final r in userRecords) r.agendaId: r,
                  };

                  int hadir = 0, izin = 0, sakit = 0, alpha = 0;
                  for (final r in userRecords) {
                    switch (r.status) {
                      case AttendanceStatus.hadir:
                        hadir++;
                        break;
                      case AttendanceStatus.izin:
                        izin++;
                        break;
                      case AttendanceStatus.sakit:
                        sakit++;
                        break;
                      case AttendanceStatus.alpha:
                        alpha++;
                        break;
                    }
                  }

                  final totalSesi = hadir + izin + sakit + alpha;
                  final persentaseHadir = totalSesi > 0
                      ? ((hadir / totalSesi) * 100).round()
                      : 0;

                  return StreamBuilder<List<Agenda>>(
                    stream: _agendaService.watchAgendas(),
                    builder: (context, agendaSnap) {
                      final isLoading =
                          agendaSnap.connectionState ==
                              ConnectionState.waiting &&
                          !agendaSnap.hasData;

                      final allAgendas = agendaSnap.data ?? [];
                      allAgendas.sort(
                        (a, b) => b.tanggalWaktu.compareTo(a.tanggalWaktu),
                      );

                      return RefreshIndicator(
                        onRefresh: () async => await Future<void>.delayed(
                          const Duration(milliseconds: 300),
                        ),
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          children: [
                            // Bagian atas
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                20,
                                20,
                                20,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildHeader(context),
                                  const SizedBox(height: 20),
                                  _buildStatCard(
                                    hadir: hadir,
                                    izin: izin,
                                    sakit: sakit,
                                    alpha: alpha,
                                    persentase: persentaseHadir,
                                  ),
                                ],
                              ),
                            ),

                            // Panel putih list agenda
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                24,
                                20,
                                120,
                              ),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(28),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionHeader(allAgendas.length),
                                  const SizedBox(height: 16),
                                  if (isLoading)
                                    _buildLoading()
                                  else if (allAgendas.isEmpty)
                                    _buildEmptyAgendaState()
                                  else
                                    ...allAgendas.map((agenda) {
                                      final record =
                                          recordByAgendaId[agenda.id];
                                      final status =
                                          record?.status ??
                                          AttendanceStatus.alpha;
                                      final hasBeenRecorded = record != null;
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: _buildAgendaAttendanceCard(
                                          agenda: agenda,
                                          status: status,
                                          hasBeenRecorded: hasBeenRecorded,
                                        ),
                                      );
                                    }),
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
      ),
    );
  }

  // ============ HEADER ============

  Widget _buildHeader(BuildContext context) {
    return Row(
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
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Presensi Saya',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Rekap kehadiran rapat & kegiatan',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============ STAT CARD ============

  Widget _buildStatCard({
    required int hadir,
    required int izin,
    required int sakit,
    required int alpha,
    required int persentase,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
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
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppTheme.lightBlue,
                child: Text(
                  widget.userName.isNotEmpty
                      ? widget.userName[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryBlue,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.userName,
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
                      widget.divisionName != null
                          ? '${widget.userRoleLabel ?? 'Anggota'} • ${widget.divisionName}'
                          : widget.userRoleLabel ?? 'Anggota',
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
              const SizedBox(width: 8), // Tambahkan jarak agar chip tidak mepet
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.lightBlue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$persentase% Hadir',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryBlue,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppTheme.borderLight),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Hadir',
                  '$hadir',
                  const Color(0xFF15803D),
                  const Color(0xFFDCFCE7),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatItem(
                  'Izin',
                  '$izin',
                  const Color(0xFF1D4ED8),
                  const Color(0xFFDBEAFE),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatItem(
                  'Sakit',
                  '$sakit',
                  const Color(0xFFB45309),
                  const Color(0xFFFEF3C7),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatItem(
                  'Alpha',
                  '$alpha',
                  const Color(0xFFB91C1C),
                  const Color(0xFFFEE2E2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    Color textColor,
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: textColor.withOpacity(0.8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ============ SECTION HEADER ============

  Widget _buildSectionHeader(int total) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Riwayat Agenda',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Daftar agenda & status kehadiran Anda',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppTheme.lightBlue,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '$total Agenda',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryBlue,
            ),
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

  // ============ AGENDA CARD ============

  Widget _buildAgendaAttendanceCard({
    required Agenda agenda,
    required AttendanceStatus status,
    required bool hasBeenRecorded,
  }) {
    Color badgeText;
    Color badgeBg;
    IconData statusIcon;

    if (!hasBeenRecorded) {
      badgeText = const Color(0xFF64748B);
      badgeBg = const Color(0xFFF1F5F9);
      statusIcon = Icons.hourglass_empty_rounded;
    } else {
      switch (status) {
        case AttendanceStatus.hadir:
          badgeText = const Color(0xFF15803D);
          badgeBg = const Color(0xFFDCFCE7);
          statusIcon = Icons.check_circle_rounded;
          break;
        case AttendanceStatus.izin:
          badgeText = const Color(0xFF1D4ED8);
          badgeBg = const Color(0xFFDBEAFE);
          statusIcon = Icons.info_outline_rounded;
          break;
        case AttendanceStatus.sakit:
          badgeText = const Color(0xFFB45309);
          badgeBg = const Color(0xFFFEF3C7);
          statusIcon = Icons.healing_rounded;
          break;
        case AttendanceStatus.alpha:
          badgeText = const Color(0xFFB91C1C);
          badgeBg = const Color(0xFFFEE2E2);
          statusIcon = Icons.cancel_outlined;
          break;
      }
    }

    final label = !hasBeenRecorded ? 'Belum Diabsen' : status.label;

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
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.center, // Ubah dari start ke center
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(statusIcon, color: badgeText, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize:
                  MainAxisSize.min, // Penting: agar tidak memaksa tinggi
              children: [
                Text(
                  agenda.judul,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 12,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        agenda.formattedDateTime,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: badgeText,
              ),
              maxLines: 1, // Pastikan tidak wrap ke bawah
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ============ EMPTY STATE ============

  Widget _buildEmptyAgendaState() {
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
            'Belum ada agenda kegiatan',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Riwayat agenda akan muncul di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ============ SOFT BACKGROUND PAINTER ============

class _AttendanceSoftBackgroundPainter extends CustomPainter {
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
