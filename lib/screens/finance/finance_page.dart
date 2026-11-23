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

class _FinancePageState extends State<FinancePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final FinanceService _service;
  String _currentUid = '';
  String _currentNama = '';
  bool _isGeneratingPdf = false;

  bool get _isBendahara => widget.userRole == UserRole.bendahara;
  bool get _isLeader =>
      widget.userRole == UserRole.ketua ||
      widget.userRole == UserRole.wakilKetua;

  /// Role yang berhak mencetak laporan PDF keuangan:
  /// Ketua, Wakil Ketua, Bendahara, dan Dekan (Dosen)
  bool get _canExportPdf =>
      widget.userRole == UserRole.ketua ||
      widget.userRole == UserRole.wakilKetua ||
      widget.userRole == UserRole.bendahara ||
      widget.userRole == UserRole.dekan;

  @override
  void initState() {
    super.initState();
    _service = widget.financeService ?? FinanceService();
    _tabController = TabController(length: 2, vsync: this);
    final user = FirebaseAuth.instance.currentUser;
    _currentUid = user?.uid ?? 'anon';
    _currentNama =
        widget.userName ?? user?.displayName ?? widget.userRole.label;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatRupiah(int number) {
    return 'Rp ${number.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  /// Menampilkan pilihan periode sebelum generate PDF
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
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
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
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: true,
      bottom: false,
      child: Container(
        color: AppTheme.background,
        child: StreamBuilder<List<FinanceTransaction>>(
          stream: _service.watchTransactions(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final allTransactions = snapshot.data ?? [];

            // Hitung saldo dan arus kas realtime.
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

            return Stack(
              children: [
                NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) => [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeaderGreeting(allTransactions),
                            const SizedBox(height: 14),
                            _buildSummaryCard(
                              saldoAktif,
                              totalMasuk,
                              totalKeluar,
                            ),
                            const SizedBox(height: 14),
                            _buildTabBar(),
                          ],
                        ),
                      ),
                    ),
                  ],
                  body: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTagihanKasTab(tagihanKas),
                      _buildArusKasTab(arusKas),
                    ],
                  ),
                ),

                // Tombol tambah transaksi.
                if (_isBendahara)
                  Positioned(
                    right: 16,
                    bottom: 24,
                    child: FloatingActionButton.extended(
                      onPressed: () => AddFinanceModal.show(
                        context,
                        financeService: _service,
                      ),
                      backgroundColor: AppTheme.primaryBlue,
                      icon: const Icon(Icons.add_rounded, color: Colors.white),
                      label: const Text(
                        'Buat Kas / Transaksi',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderGreeting(List<FinanceTransaction> allTransactions) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Keuangan & Kas Organisasi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _isBendahara
                    ? 'Kelola arus kas & tagihan anggota'
                    : (_isLeader || widget.userRole == UserRole.dekan)
                    ? 'Pantau & unduh laporan buku kas'
                    : 'Cek kewajiban kas & pembayaran Anda',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (_canExportPdf) ...[
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: _isGeneratingPdf
                ? null
                : () => _showExportPdfOptions(allTransactions),
            icon: _isGeneratingPdf
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.picture_as_pdf_rounded, size: 16),
            label: const Text('PDF'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSummaryCard(int saldo, int masuk, int keluar) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryBlue, Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Saldo Kas HIMA TI',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatRupiah(saldo),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.arrow_downward_rounded,
                        size: 16,
                        color: Color(0xFF4ADE80),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pemasukan',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white70,
                              ),
                            ),
                            Text(
                              _formatRupiah(masuk),
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
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.arrow_upward_rounded,
                        size: 16,
                        color: Color(0xFFF87171),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pengeluaran',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white70,
                              ),
                            ),
                            Text(
                              _formatRupiah(keluar),
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
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
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
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        tabs: const [
          Tab(text: 'Tagihan Kas Anggota'),
          Tab(text: 'Laporan Buku Kas'),
        ],
      ),
    );
  }

  Widget _buildTagihanKasTab(List<FinanceTransaction> list) {
    if (list.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada tagihan kas yang dibuat.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final tx = list[index];
        return _buildTagihanKasCard(tx);
      },
    );
  }

  Widget _buildTagihanKasCard(FinanceTransaction tx) {
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
                  tx.judul,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.lightBlue,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _formatRupiah(tx.nominal),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
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
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
          if (tx.tenggatWaktu != null) ...[
            const SizedBox(height: 8),
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
          const SizedBox(height: 12),
          // Role-specific action
          if (_isBendahara)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => VerifyPaymentsModal.show(
                      context,
                      transaction: tx,
                      financeService: _service,
                    ),
                    icon: const Icon(Icons.checklist_rtl_rounded, size: 18),
                    label: const Text('Verifikasi Pembayar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryBlue,
                      side: const BorderSide(color: AppTheme.primaryBlue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _confirmDelete(tx.id),
                  icon: const Icon(Icons.delete_outline, color: AppTheme.error),
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
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isLunas
                            ? 'LUNAS'
                            : isMenunggu
                            ? 'MENUNGGU VERIFIKASI'
                            : 'BELUM DIBAYAR',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isLunas
                              ? AppTheme.success
                              : isMenunggu
                              ? AppTheme.warning
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    FilledButton.icon(
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
                      icon: const Icon(Icons.payment_rounded, size: 16),
                      label: Text(isMenunggu ? 'Lihat Bukti' : 'Bayar Kas'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
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

  Widget _buildArusKasTab(List<FinanceTransaction> list) {
    if (list.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada catatan buku kas.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    final itemCount = _canExportPdf ? list.length + 1 : list.length;

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        // Banner Unduh Laporan PDF di bagian paling atas Tab Buku Kas
        if (_canExportPdf && index == 0) {
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.lightBlue.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryBlue.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Laporan Pertanggungjawaban PDF',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Unduh atau bagikan rekap resmi buku kas HIMA TI',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _isGeneratingPdf
                      ? null
                      : () => _showExportPdfOptions(list),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Unduh',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          );
        }

        final tx = list[_canExportPdf ? index - 1 : index];
        final isIncome = tx.isIncome;
        final isConfirmed = tx.isDikonfirmasi;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderLight),
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
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isIncome
                          ? Icons.south_west_rounded
                          : Icons.north_east_rounded,
                      color: isIncome ? AppTheme.success : AppTheme.error,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tx.judul,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${tx.kategori.toUpperCase()} • ${tx.createdAt.day}/${tx.createdAt.month}/${tx.createdAt.year}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${isIncome ? '+' : '-'} ${_formatRupiah(tx.nominal)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isIncome ? AppTheme.success : AppTheme.error,
                    ),
                  ),
                ],
              ),
              if (tx.deskripsi.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  tx.deskripsi,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isConfirmed
                          ? AppTheme.successBg
                          : AppTheme.warningBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isConfirmed
                          ? 'Audit Ketua: Sah'
                          : 'Menunggu Konfirmasi Ketua',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isConfirmed
                            ? AppTheme.success
                            : AppTheme.warning,
                      ),
                    ),
                  ),
                  if (_isLeader && !isConfirmed)
                    FilledButton(
                      onPressed: () => _service.confirmTransaction(
                        txId: tx.id,
                        status: 'dikonfirmasi',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.success,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        minimumSize: const Size(0, 30),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Text(
                        'Konfirmasi Kas',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  if (_isBendahara)
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: AppTheme.error,
                      ),
                      onPressed: () => _confirmDelete(tx.id),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(String txId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Catatan Kas?'),
        content: const Text(
          'Data transaksi ini akan dihapus permanen dari Firestore.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _service.deleteTransaction(txId);
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
