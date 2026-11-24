import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../enums/user_role.dart';
import '../../models/finance_transaction.dart';
import '../../services/finance_pdf_service.dart';
import '../../services/finance_service.dart';
import 'widgets/add_finance_modal.dart';
import 'widgets/qris_payment_sheet.dart';
import 'widgets/verify_payments_modal.dart';

class FinancePage extends StatefulWidget {
  final UserRole userRole;
  final String? userName;
  final FinanceService? financeService;

  const FinancePage({
    super.key,
    required this.userRole,
    this.userName,
    this.financeService,
  });

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  late final FinanceService _service;
  int _selectedTab = 0; // 0: Tagihan Kas, 1: Buku Kas
  String _currentUid = '';
  String _currentNama = '';
  bool _isGeneratingPdf = false;

  bool get _isBendahara => widget.userRole == UserRole.bendahara;
  bool get _isLeader =>
      widget.userRole == UserRole.ketua ||
      widget.userRole == UserRole.wakilKetua;

  bool get _canExportPdf =>
      widget.userRole == UserRole.ketua ||
      widget.userRole == UserRole.wakilKetua ||
      widget.userRole == UserRole.bendahara ||
      widget.userRole == UserRole.dekan;

  @override
  void initState() {
    super.initState();
    _service = widget.financeService ?? FinanceService();
    final user = FirebaseAuth.instance.currentUser;
    _currentUid = user?.uid ?? 'anon';
    _currentNama =
        widget.userName ?? user?.displayName ?? widget.userRole.label;
  }

  String _formatRupiah(int number) {
    return 'Rp${number.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  // ============ PDF EXPORT ============

  void _showExportPdfOptions(List<FinanceTransaction> allTransactions) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final now = DateTime.now();
        final thisMonthTx = allTransactions
            .where(
              (tx) =>
                  tx.createdAt.month == now.month &&
                  tx.createdAt.year == now.year,
            )
            .toList();
        final verifiedTx = allTransactions
            .where((tx) => tx.isDikonfirmasi)
            .toList();

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                const SizedBox(height: 14),
                const Text(
                  'Cetak Laporan Keuangan (PDF)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Pilih cakupan data buku kas yang ingin dicetak:',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 16),
                _buildPdfOptionTile(
                  icon: Icons.all_inbox_rounded,
                  title: 'Semua Riwayat Buku Kas',
                  subtitle:
                      '${allTransactions.length} total transaksi tercatat',
                  onTap: () {
                    Navigator.pop(ctx);
                    _runPdfExport(
                      allTransactions,
                      'Semua Riwayat Kepengurusan',
                    );
                  },
                ),
                const SizedBox(height: 10),
                _buildPdfOptionTile(
                  icon: Icons.calendar_month_rounded,
                  title: 'Laporan Bulan Ini (${now.month}/${now.year})',
                  subtitle: '${thisMonthTx.length} transaksi bulan berjalan',
                  onTap: () {
                    Navigator.pop(ctx);
                    _runPdfExport(
                      thisMonthTx,
                      'Bulan ${now.month}/${now.year}',
                    );
                  },
                ),
                const SizedBox(height: 10),
                _buildPdfOptionTile(
                  icon: Icons.verified_rounded,
                  title: 'Hanya Transaksi Terverifikasi (Sah)',
                  subtitle:
                      '${verifiedTx.length} transaksi sudah diaudit Ketua',
                  onTap: () {
                    Navigator.pop(ctx);
                    _runPdfExport(
                      verifiedTx,
                      'Transaksi Terverifikasi (Audit Sah)',
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPdfOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.lightBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.primaryBlue, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runPdfExport(
    List<FinanceTransaction> transactions,
    String periodeLabel,
  ) async {
    if (_isGeneratingPdf) return;
    setState(() => _isGeneratingPdf = true);

    try {
      await FinancePdfService.generateAndPreviewReport(
        transactions: transactions,
        dicetakOleh: _currentNama,
        rolePencetak: widget.userRole.label,
        periodeLabel: periodeLabel,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat PDF: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPdf = false);
      }
    }
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
                painter: _FinanceSoftBackgroundPainter(),
                size: Size.infinite,
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: StreamBuilder<List<FinanceTransaction>>(
              stream: _service.watchTransactions(),
              builder: (context, snapshot) {
                final allTransactions = snapshot.data ?? [];

                int totalMasuk = 0;
                int totalKeluar = 0;
                for (final tx in allTransactions) {
                  if (tx.isIncome) {
                    totalMasuk += tx.nominal;
                  } else {
                    totalKeluar += tx.nominal;
                  }
                }
                final saldoAktif = totalMasuk - totalKeluar;

                final tagihanKas = allTransactions
                    .where((tx) => tx.isTagihanAnggota)
                    .toList();
                final arusKas = allTransactions;

                final isLoading =
                    snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData;

                final visibleList = _selectedTab == 0 ? tagihanKas : arusKas;

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
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTitleBlock(allTransactions), // ← pass list
                            const SizedBox(height: 16),
                            _buildSummaryCard(
                              saldoAktif,
                              totalMasuk,
                              totalKeluar,
                            ),
                            const SizedBox(height: 16),
                            _buildTabSwitcher(
                              tagihanCount: tagihanKas.length,
                              arusCount: arusKas.length,
                            ),
                          ],
                        ),
                      ),

                      // Panel putih
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
                            _buildSectionHeader(allTransactions: arusKas),
                            const SizedBox(height: 16),
                            if (isLoading)
                              _buildLoading()
                            else if (visibleList.isEmpty)
                              _buildEmptyState()
                            else
                              ..._selectedTab == 0
                                  ? tagihanKas.map(
                                      (tx) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: _buildTagihanKasCard(tx),
                                      ),
                                    )
                                  : _buildArusKasListItems(arusKas),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Tombol Tambah Kas di Kanan Bawah (FAB di atas Bottom Nav Bar)
          if (_isBendahara)
            Positioned(
              right: 20,
              bottom: 115,
              child: _buildAddButton(),
            ),
        ],
      ),
    );
  }

  // ============ TITLE + ADD BUTTON ============

  Widget _buildTitleBlock(List<FinanceTransaction> allTransactions) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Keuangan & Kas',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _isBendahara
                    ? 'Kelola arus kas & tagihan anggota'
                    : (_isLeader || widget.userRole == UserRole.dekan)
                    ? 'Pantau & unduh laporan buku kas'
                    : 'Cek kewajiban kas & pembayaran Anda',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (_canExportPdf) ...[
          const SizedBox(width: 8),
          _buildPdfButton(allTransactions), // ← pass list
        ],
      ],
    );
  }

  Widget _buildAddButton() {
    return FloatingActionButton(
      heroTag: 'fab_create_finance',
      onPressed: () => AddFinanceModal.show(context, financeService: _service),
      backgroundColor: AppTheme.primaryBlue,
      elevation: 6,
      shape: const CircleBorder(),
      child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
    );
  }

  Widget _buildPdfButton(List<FinanceTransaction> allTransactions) {
    return GestureDetector(
      onTap: _isGeneratingPdf
          ? null
          : () => _showExportPdfOptions(allTransactions),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withOpacity(0.10),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: _isGeneratingPdf
            ? const SizedBox(width: 18, height: 18)
            : const Icon(
                Icons.picture_as_pdf_rounded,
                color: AppTheme.primaryBlue,
                size: 22,
              ),
      ),
    );
  }

  // ============ SUMMARY CARD ============

  Widget _buildSummaryCard(int saldo, int masuk, int keluar) {
    const baseColor = Color(0xFF1E3A8A);

    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ===== FOLDER BELAKANG =====
          Positioned(
            top: 18,
            left: 6,
            right: 6,
            bottom: 20,
            child: Container(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 22, 43, 99),
                borderRadius: BorderRadius.circular(22),
              ),
            ),
          ),

          // ===== FOLDER UTAMA =====
          CustomPaint(
            painter: _FolderCardPainter(color: baseColor),
            child: Padding(
              // padding kiri diperkecil → menempel ke tepi lengkungan folder
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== Total Saldo =====
                  const Text(
                    'Total Saldo Kas',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    _formatRupiah(saldo),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ===== Mini Stat =====
                  Row(
                    children: [
                      Expanded(
                        child: _buildMiniStat(
                          icon: Icons.arrow_downward_rounded,
                          iconColor: const Color(0xFF4ADE80),
                          label: 'Pemasukan',
                          value: _formatRupiah(masuk),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMiniStat(
                          icon: Icons.arrow_upward_rounded,
                          iconColor: const Color(0xFFF87171),
                          label: 'Pengeluaran',
                          value: _formatRupiah(keluar),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 10, color: Colors.white70),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============ TAB SWITCHER (sliding) ============

  Widget _buildTabSwitcher({
    required int tagihanCount,
    required int arusCount,
  }) {
    const labels = ['Tagihan Kas', 'Buku Kas'];
    final counts = [tagihanCount, arusCount];

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

  Widget _buildSectionHeader({
    required List<FinanceTransaction> allTransactions,
  }) {
    final isTagihan = _selectedTab == 0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isTagihan ? 'Tagihan Kas Anggota' : 'Laporan Buku Kas',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isTagihan
                    ? 'Daftar kewajiban kas yang harus dibayar'
                    : 'Riwayat seluruh arus kas organisasi',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (_canExportPdf && !isTagihan) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isGeneratingPdf
                ? null
                : () => _showExportPdfOptions(allTransactions),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'PDF',
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

  // ============ TAGIHAN KAS CARD ============

  Widget _buildTagihanKasCard(FinanceTransaction tx) {
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
          // ===== JUDUL + NOMINAL =====
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  tx.judul,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.lightBlue,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _formatRupiah(tx.nominal),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          if (tx.deskripsi.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              tx.deskripsi,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ],
          if (tx.tenggatWaktu != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.timer_outlined,
                  size: 14,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Tenggat: ${tx.tenggatWaktu!.day}/${tx.tenggatWaktu!.month}/${tx.tenggatWaktu!.year}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],

          // ===== TOMBOL AKSI =====
          const SizedBox(height: 12),

          if (_isBendahara)
            Row(
              children: [
                // ----- Tombol Verifikasi (primary blue solid) -----
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: FilledButton.icon(
                      onPressed: () => VerifyPaymentsModal.show(
                        context,
                        transaction: tx,
                        financeService: _service,
                      ),
                      label: const Text('Verifikasi'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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

                // ----- Tombol Hapus (outline merah) -----
                SizedBox(
                  width: 38,
                  height: 38,
                  child: OutlinedButton(
                    onPressed: () => _confirmDelete(tx.id),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: BorderSide(
                        color: AppTheme.error.withOpacity(0.4),
                        width: 1.2,
                      ),
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: const StadiumBorder(),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      size: 17,
                      color: AppTheme.error,
                    ),
                  ),
                ),
              ],
            )
          else
            StreamBuilder<FinancePayment?>(
              stream: _service.watchUserPayment(tx.id, _currentUid),
              builder: (context, paymentSnapshot) {
                final payment = paymentSnapshot.data;
                final isLunas = payment?.isLunas == true;
                final isMenunggu = payment?.isMenungguVerifikasi == true;

                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isLunas
                            ? AppTheme.successBg
                            : isMenunggu
                            ? AppTheme.warningBg
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isLunas
                            ? 'LUNAS'
                            : isMenunggu
                            ? 'MENUNGGU VERIFIKASI'
                            : 'BELUM DIBAYAR',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: isLunas
                              ? AppTheme.success
                              : isMenunggu
                              ? AppTheme.warning
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      height: 38,
                      child: FilledButton.icon(
                        onPressed: isLunas
                            ? null
                            : () => QrisPaymentSheet.show(
                                context,
                                transaction: tx,
                                existingPayment: payment,
                                currentUid: _currentUid,
                                currentNama: _currentNama,
                                financeService: _service,
                              ),
                        icon: const Icon(Icons.payment_rounded, size: 14),
                        label: Text(isMenunggu ? 'Lihat Bukti' : 'Bayar Kas'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          minimumSize: const Size(0, 38),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: const StadiumBorder(),
                          textStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  // ============ ARUS KAS LIST ============

  List<Widget> _buildArusKasListItems(List<FinanceTransaction> list) {
    return list.map((tx) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _buildArusKasCard(tx),
      );
    }).toList();
  }

  Widget _buildArusKasCard(FinanceTransaction tx) {
    final isIncome = tx.isIncome;
    final isConfirmed = tx.isDikonfirmasi;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isIncome ? AppTheme.successBg : AppTheme.errorBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isIncome
                      ? Icons.south_west_rounded
                      : Icons.north_east_rounded,
                  color: isIncome ? AppTheme.success : AppTheme.error,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.judul,
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
                      '${tx.kategori.toUpperCase()} • ${tx.createdAt.day}/${tx.createdAt.month}/${tx.createdAt.year}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${isIncome ? '+' : '-'} ${_formatRupiah(tx.nominal)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isIncome ? AppTheme.success : AppTheme.error,
                ),
              ),
            ],
          ),
          if (tx.deskripsi.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              tx.deskripsi,
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isConfirmed ? AppTheme.successBg : AppTheme.warningBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isConfirmed
                      ? 'Audit Ketua: Sah'
                      : 'Menunggu Konfirmasi Ketua',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: isConfirmed ? AppTheme.success : AppTheme.warning,
                  ),
                ),
              ),
              const Spacer(),
              if (_isLeader && !isConfirmed)
                FilledButton(
                  onPressed: () => _service.confirmTransaction(
                    txId: tx.id,
                    status: 'dikonfirmasi',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    minimumSize: const Size(0, 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('Konfirmasi'),
                ),
              if (_isBendahara)
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: AppTheme.error,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  onPressed: () => _confirmDelete(tx.id),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ============ EMPTY STATE ============

  Widget _buildEmptyState() {
    final isTagihan = _selectedTab == 0;
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
            child: Icon(
              isTagihan
                  ? Icons.receipt_long_outlined
                  : Icons.account_balance_wallet_outlined,
              size: 25,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 11),
          Text(
            isTagihan ? 'Belum ada tagihan kas' : 'Belum ada catatan buku kas',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _isBendahara
                ? 'Tekan tombol "+" di kanan atas untuk membuat catatan baru.'
                : 'Data akan muncul di sini saat ditambahkan bendahara.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String txId) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: AppTheme.surface,
          surfaceTintColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ===== HEADER =====
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.errorBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: AppTheme.error,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hapus Catatan Kas?',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                              height: 1.3,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Data transaksi ini akan dihapus permanen dari Firestore dan tidak dapat dikembalikan.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ===== TOMBOL AKSI =====
                Row(
                  children: [
                    // Batal
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textSecondary,
                            side: BorderSide(
                              color: AppTheme.borderLight,
                              width: 1.2,
                            ),
                            padding: EdgeInsets.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: const StadiumBorder(),
                            textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: const Text('Batal'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Hapus
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: FilledButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            _service.deleteTransaction(txId);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.error,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: const StadiumBorder(),
                            textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: const Text('Hapus'),
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
}

// ============ SOFT BACKGROUND PAINTER ============

class _FinanceSoftBackgroundPainter extends CustomPainter {
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
  bool shouldRepaint(covariant _FinanceSoftBackgroundPainter oldDelegate) =>
      false;
}

class _FolderCardPainter extends CustomPainter {
  final Color color;
  _FolderCardPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    const tabWidth = 116.0; // Lebar tab
    const tabHeight = 20.0; // Tinggi tab
    const radius = 22.0; // Radius body

    // Mulai dari kiri bawah tab
    path.moveTo(0, tabHeight);
    path.lineTo(0, 16); // Sisi kiri tab
    path.quadraticBezierTo(0, 0, 16, 0); // Sudut kiri atas tab

    // Garis atas tab
    path.lineTo(tabWidth - 16, 0);

    // Lengkungan landai turun ke body (S-Curve halus)
    path.quadraticBezierTo(
      tabWidth + 15,
      0, // Titik kontrol menarik ke kanan
      tabWidth + 30,
      tabHeight + 5, // Titik akhir turun
    );

    // Garis lurus di atas body
    path.lineTo(size.width - radius, tabHeight + 5);

    // Sudut kanan atas body
    path.quadraticBezierTo(
      size.width,
      tabHeight + 5,
      size.width,
      tabHeight + 5 + radius,
    );

    // Sisi kanan body
    path.lineTo(size.width, size.height - radius);
    path.quadraticBezierTo(
      size.width,
      size.height,
      size.width - radius,
      size.height,
    );

    // Sisi bawah body
    path.lineTo(radius, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - radius);

    path.close();

    // Gambar dengan gradient
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF2647B5), Color(0xFF1E3A8A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
