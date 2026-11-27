import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../enums/user_role.dart';
import '../../models/proposal.dart';
import '../../models/user_profile.dart';
import '../../services/proposal_service.dart';
import 'widgets/create_proposal_modal.dart';
import 'widgets/proposal_detail_modal.dart';

class ProposalPage extends StatefulWidget {
  final UserRole role;
  final UserProfile userProfile;

  const ProposalPage({
    super.key,
    required this.role,
    required this.userProfile,
  });

  @override
  State<ProposalPage> createState() => _ProposalPageState();
}

class _ProposalPageState extends State<ProposalPage> {
  final ProposalService _proposalService = ProposalService();
  int _selectedFilterIndex =
      0; // 0: Semua, 1: Menunggu, 2: Disetujui, 3: Revisi/Ditolak

  String get _currentUid =>
      FirebaseAuth.instance.currentUser?.uid ?? widget.userProfile.uid;

  bool get _isReviewer =>
      widget.role == UserRole.ketua ||
      widget.role == UserRole.wakilKetua ||
      widget.role == UserRole.dekan;

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
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final stream = _isReviewer
        ? _proposalService.watchAllProposals()
        : _proposalService.watchProposalsByApplicant(_currentUid);

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
                  painter: _ProposalSoftBackgroundPainter(),
                  size: Size.infinite,
                ),
              ),
            ),

            SafeArea(
              bottom: false,
              child: StreamBuilder<List<Proposal>>(
                stream: stream,
                builder: (context, snapshot) {
                  final all = snapshot.data ?? [];
                  final isLoading =
                      snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData;

                  final filtered = all.where((p) {
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
                      // ===== BAGIAN ATAS (HEADER + TAB) =====
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(),
                            const SizedBox(height: 20),
                            _buildFilterTabs(
                              allCount: all.length,
                              menungguCount: all
                                  .where(
                                    (x) => x.status == ProposalStatus.menunggu,
                                  )
                                  .length,
                              disetujuiCount: all
                                  .where(
                                    (x) => x.status == ProposalStatus.disetujui,
                                  )
                                  .length,
                              revisiCount: all
                                  .where(
                                    (x) =>
                                        x.status == ProposalStatus.revisi ||
                                        x.status == ProposalStatus.ditolak,
                                  )
                                  .length,
                            ),
                          ],
                        ),
                      ),

                      // ===== PANEL PUTIH (LIST) =====
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(28),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(),
                            const SizedBox(height: 16),
                            if (isLoading)
                              _buildLoading()
                            else if (filtered.isEmpty)
                              _buildEmptyState()
                            else
                              ...filtered.map(
                                (p) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
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

            // ===== FAB Bulat (+) Buat Pengajuan =====
            Positioned(
              right: 20,
              bottom: 40,
              child: GestureDetector(
                onTap: () {
                  CreateProposalModal.show(
                    context,
                    userProfile: widget.userProfile,
                    onCreated: () => setState(() {}),
                  );
                },
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
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

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pengajuan',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _isReviewer
                    ? 'Verifikasi pengajuan kegiatan & berkas'
                    : 'Ajukan proposal, dana, atau surat',
                style: const TextStyle(
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

  // =========================================================
  // FILTER TABS (SLIDING)
  // =========================================================

  Widget _buildFilterTabs({
    required int allCount,
    required int menungguCount,
    required int disetujuiCount,
    required int revisiCount,
  }) {
    // Label disederhanakan agar tidak overflow
    final labels = ['Semua', 'Menunggu', 'Setuju', 'Revisi'];
    final counts = [allCount, menungguCount, disetujuiCount, revisiCount];

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
                left: (_selectedFilterIndex * tabWidth) + 4,
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
                  final isSelected = _selectedFilterIndex == i;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _selectedFilterIndex = i),
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: 11,
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
                            textAlign: TextAlign.center,
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

  String get _sectionSubtitle {
    switch (_selectedFilterIndex) {
      case 1:
        return 'Pengajuan yang menunggu tinjauan';
      case 2:
        return 'Pengajuan yang telah disetujui';
      case 3:
        return 'Pengajuan dengan status revisi atau ditolak';
      default:
        return 'Seluruh riwayat pengajuan organisasi';
    }
  }

  Widget _buildSectionHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _sectionTitle,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _sectionSubtitle,
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
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

  // =========================================================
  // CARD PENGAJUAN
  // =========================================================

  Widget _buildProposalCard(Proposal p) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          ProposalDetailModal.show(
            context,
            proposal: p,
            userRole: widget.role,
            currentUid: _currentUid,
            currentUserName: widget.userProfile.nama,
            onUpdated: () => setState(() {}),
          );
        },
        borderRadius: BorderRadius.circular(17),
        child: Container(
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
              // ===== HEADER CHIP =====
              Row(
                children: [
                  // Chip Tipe
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.lightBlue,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        p.type.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Chip Status
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusBg(p.status),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        p.status.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: _getStatusFg(p.status),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),

                  // Tanggal
                  if (p.createdAt != null)
                    Text(
                      _formatDate(p.createdAt!),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // ===== JUDUL =====
              Text(
                p.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  height: 1.3,
                ),
              ),

              // ===== DESKRIPSI =====
              if (p.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  p.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],

              const SizedBox(height: 10),
              const Divider(height: 1, color: AppTheme.borderLight),
              const SizedBox(height: 10),

              // ===== FOOTER: APPLICANT & BADGE =====
              Row(
                children: [
                  const Icon(
                    Icons.person_outline_rounded,
                    size: 13,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${p.applicantName} • ${p.divisionName ?? p.divisionId.toUpperCase()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildMiniApprovalBadge('Ketua', p.approvedByKetua),
                  const SizedBox(width: 4),
                  _buildMiniApprovalBadge('Dekan', p.approvedByDekan),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniApprovalBadge(String roleLabel, bool isApproved) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: isApproved ? AppTheme.successBg : AppTheme.warningBg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isApproved ? Icons.check_circle_rounded : Icons.pending_rounded,
            size: 9,
            color: isApproved ? AppTheme.success : AppTheme.warning,
          ),
          const SizedBox(width: 3),
          Text(
            roleLabel,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: isApproved ? AppTheme.success : AppTheme.warning,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // HELPERS
  // =========================================================

  Color _getStatusBg(ProposalStatus s) {
    switch (s) {
      case ProposalStatus.disetujui:
        return AppTheme.successBg;
      case ProposalStatus.menunggu:
        return AppTheme.warningBg;
      case ProposalStatus.revisi:
        return const Color(0xFFEDE9FE);
      case ProposalStatus.ditolak:
        return AppTheme.errorBg;
      case ProposalStatus.draft:
        return const Color(0xFFF1F5F9);
    }
  }

  Color _getStatusFg(ProposalStatus s) {
    switch (s) {
      case ProposalStatus.disetujui:
        return AppTheme.success;
      case ProposalStatus.menunggu:
        return AppTheme.warning;
      case ProposalStatus.revisi:
        return const Color(0xFF6D28D9);
      case ProposalStatus.ditolak:
        return AppTheme.error;
      case ProposalStatus.draft:
        return AppTheme.textSecondary;
    }
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
                Icons.description_outlined,
                size: 25,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 11),
            const Text(
              'Belum Ada Pengajuan',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _isReviewer
                  ? 'Saat ini belum ada pengajuan yang memerlukan persetujuan.'
                  : 'Buat pengajuan baru dengan menekan tombol di kanan bawah.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
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

class _ProposalSoftBackgroundPainter extends CustomPainter {
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
