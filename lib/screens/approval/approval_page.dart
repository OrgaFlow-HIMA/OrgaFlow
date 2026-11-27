import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../enums/user_role.dart';
import '../../models/proposal.dart';
import '../../models/user_profile.dart';
import '../../services/proposal_service.dart';
import 'widgets/proposal_detail_modal.dart';

class ApprovalPage extends StatefulWidget {
  final UserProfile? userProfile;
  final UserRole? role;

  const ApprovalPage({super.key, this.userProfile, this.role});

  @override
  State<ApprovalPage> createState() => _ApprovalPageState();
}

class _ApprovalPageState extends State<ApprovalPage> {
  final ProposalService _proposalService = ProposalService();
  int _selectedFilterIndex = 0;

  String get _currentUid =>
      FirebaseAuth.instance.currentUser?.uid ?? widget.userProfile?.uid ?? '';

  String get _currentUserName =>
      widget.userProfile?.nama ??
      FirebaseAuth.instance.currentUser?.displayName ??
      'Pimpinan';

  UserRole get _userRole =>
      widget.role ?? widget.userProfile?.role ?? UserRole.dekan;

  String _formatDate(DateTime? dt) {
    if (dt == null) return '-';
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
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);

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
                  painter: _ApprovalSoftBackgroundPainter(),
                  size: Size.infinite,
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: StreamBuilder<List<Proposal>>(
                stream: _proposalService.watchAllProposals(),
                builder: (context, snapshot) {
                  final allProposals = snapshot.data ?? [];
                  final isLoading =
                      snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData;

                  final pendingCount = allProposals
                      .where((p) => p.status == ProposalStatus.menunggu)
                      .length;
                  final approvedCount = allProposals
                      .where((p) => p.status == ProposalStatus.disetujui)
                      .length;
                  final otherCount = allProposals
                      .where(
                        (p) =>
                            p.status == ProposalStatus.revisi ||
                            p.status == ProposalStatus.ditolak,
                      )
                      .length;

                  final filteredProposals = allProposals.where((p) {
                    switch (_selectedFilterIndex) {
                      case 1:
                        return p.status == ProposalStatus.menunggu;
                      case 2:
                        return p.status == ProposalStatus.disetujui;
                      case 3:
                        return p.status == ProposalStatus.revisi ||
                            p.status == ProposalStatus.ditolak;
                      default:
                        return true;
                    }
                  }).toList();

                  return ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      // Bagian Atas
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(canPop),
                            const SizedBox(height: 16),
                            _buildFilterTabs(
                              totalCount: allProposals.length,
                              menungguCount: pendingCount,
                              disetujuiCount: approvedCount,
                              revisiCount: otherCount,
                            ),
                          ],
                        ),
                      ),

                      // Panel Putih
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(28),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(totalPending: pendingCount),
                            const SizedBox(height: 14),
                            if (isLoading)
                              _buildLoading()
                            else if (filteredProposals.isEmpty)
                              _buildEmptyState()
                            else
                              ...filteredProposals.map(
                                (p) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _buildProposalCard(p),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // HEADER
  // =========================================================

  Widget _buildHeader(bool canPop) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (canPop) ...[
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppTheme.textPrimary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _userRole == UserRole.dekan
                    ? 'Persetujuan Dekan'
                    : 'Persetujuan Ketua',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Kelola persetujuan berkas & pengajuan',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================
  // FILTER TABS (SLIDING)
  // =========================================================

  Widget _buildFilterTabs({
    required int totalCount,
    required int menungguCount,
    required int disetujuiCount,
    required int revisiCount,
  }) {
    final labels = ['Semua', 'Menunggu', 'Disetujui', 'Revisi'];
    final counts = [totalCount, menungguCount, disetujuiCount, revisiCount];

    return LayoutBuilder(
      builder: (context, constraints) {
        final tabWidth = constraints.maxWidth / labels.length;

        return Container(
          height: 42, // Lebih proporsional
          decoration: BoxDecoration(
            color: AppTheme.lightBlue.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                left: (_selectedFilterIndex * tabWidth) + 4,
                top: 4,
                bottom: 4,
                width: tabWidth - 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withOpacity(0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: List.generate(labels.length, (i) {
                  final isSelected = _selectedFilterIndex == i;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _selectedFilterIndex = i),
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: 10.5, // Lebih proporsional
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

  // =========================================================
  // SECTION HEADER
  // =========================================================

  String get _sectionTitle {
    switch (_selectedFilterIndex) {
      case 1:
        return 'Menunggu Persetujuan';
      case 2:
        return 'Pengajuan Disetujui';
      case 3:
        return 'Perlu Revisi / Ditolak';
      default:
        return 'Semua Pengajuan';
    }
  }

  Widget _buildSectionHeader({required int totalPending}) {
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
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _selectedFilterIndex == 0
                    ? 'Seluruh riwayat pengajuan organisasi'
                    : _selectedFilterIndex == 1
                    ? 'Pengajuan yang menunggu tinjauan Anda'
                    : _selectedFilterIndex == 2
                    ? 'Pengajuan yang telah disetujui'
                    : 'Pengajuan dengan status revisi atau ditolak',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (totalPending > 0 && _selectedFilterIndex == 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.warningBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$totalPending Menunggu',
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppTheme.warning,
              ),
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

  // =========================================================
  // CARD PROPOSAL
  // =========================================================

  Widget _buildProposalCard(Proposal proposal) {
    Color badgeBg;
    Color badgeColor;
    String badgeText;

    switch (proposal.status) {
      case ProposalStatus.menunggu:
        badgeBg = AppTheme.warningBg;
        badgeColor = AppTheme.warning;
        badgeText = 'MENUNGGU';
        break;
      case ProposalStatus.disetujui:
        badgeBg = AppTheme.successBg;
        badgeColor = AppTheme.success;
        badgeText = 'DISETUJUI';
        break;
      case ProposalStatus.revisi:
        badgeBg = AppTheme.warningBg;
        badgeColor = const Color(0xFFD97706);
        badgeText = 'REVISI';
        break;
      case ProposalStatus.ditolak:
        badgeBg = AppTheme.errorBg;
        badgeColor = AppTheme.error;
        badgeText = 'DITOLAK';
        break;
      default:
        badgeBg = AppTheme.lightBlue;
        badgeColor = AppTheme.primaryBlue;
        badgeText = proposal.status.label.toUpperCase();
    }

    final divisionDisplay =
        (proposal.divisionName != null && proposal.divisionName!.isNotEmpty)
        ? proposal.divisionName!
        : (proposal.divisionId.isNotEmpty
              ? proposal.divisionId.toUpperCase()
              : 'PENGURUS');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14), // Lebih proporsional
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Divisi & Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  divisionDisplay,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 2.5,
                ),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Judul
          Text(
            proposal.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),

          // Kotak Info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pengaju & Jenis',
                        style: TextStyle(
                          fontSize: 9,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '${proposal.applicantName} • ${proposal.type.label}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Tanggal',
                      style: TextStyle(
                        fontSize: 9,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 10,
                          color: AppTheme.primaryBlue,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          _formatDate(proposal.createdAt),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Tombol Aksi
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: () {
                ProposalDetailModal.show(
                  context,
                  proposal: proposal,
                  userRole: _userRole,
                  currentUid: _currentUid,
                  currentUserName: _currentUserName,
                );
              },
              label: Text(
                _userRole == UserRole.dekan ||
                        _userRole == UserRole.ketua ||
                        _userRole == UserRole.wakilKetua
                    ? 'Tinjau Pengajuan'
                    : 'Lihat Detail',
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
      ),
    );
  }

  // =========================================================
  // EMPTY STATE
  // =========================================================

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Container(
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
                Icons.assignment_turned_in_outlined,
                size: 25,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 11),
            const Text(
              'Tidak Ada Pengajuan',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Belum ada berkas atau proposal pada kategori ini.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================
// SOFT BACKGROUND PAINTER
// =========================================================

class _ApprovalSoftBackgroundPainter extends CustomPainter {
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
