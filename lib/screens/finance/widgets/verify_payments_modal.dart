import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/finance_transaction.dart';
import '../../../services/finance_service.dart';

class VerifyPaymentsModal extends StatelessWidget {
  final FinanceTransaction transaction;
  final FinanceService? financeService;

  const VerifyPaymentsModal({
    super.key,
    required this.transaction,
    this.financeService,
  });

  static Future<void> show(
    BuildContext context, {
    required FinanceTransaction transaction,
    FinanceService? financeService,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VerifyPaymentsModal(
        transaction: transaction,
        financeService: financeService,
      ),
    );
  }

  String _formatRupiah(int number) {
    return 'Rp ${number.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    final service = financeService ?? FinanceService();

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Grabber
            const SizedBox(height: 12),
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

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
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
                      Icons.fact_check_outlined,
                      color: AppTheme.primaryBlue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.judul,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Nominal: ${_formatRupiah(transaction.nominal)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryBlue,
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
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1, color: AppTheme.borderLight),

            // Body
            Expanded(
              child: StreamBuilder<List<FinancePayment>>(
                stream: service.watchAllPaymentsForTransaction(transaction.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final payments = snapshot.data ?? [];
                  if (payments.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: payments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _buildPaymentCard(
                        context,
                        service,
                        payments[index],
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppTheme.lightBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inbox_outlined,
                size: 30,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Belum ada konfirmasi pembayaran',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Anggota belum mengirimkan bukti transfer untuk tagihan ini.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(
    BuildContext context,
    FinanceService service,
    FinancePayment item,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
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
          // Header: Nama + Status
          Row(
            children: [
              Expanded(
                child: Text(
                  item.userNama,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildStatusBadge(item.status),
            ],
          ),

          // Catatan anggota
          if (item.catatanAnggota?.isNotEmpty == true) ...[
            const SizedBox(height: 6),
            Text(
              'Catatan: ${item.catatanAnggota}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ],

          // Link bukti transfer
          if (item.buktiTransferUrl?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _showBuktiDialog(context, item.buktiTransferUrl!),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.lightBlue.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.primaryBlue.withOpacity(0.15),
                  ),
                ),
                child: Row(
                  children: const [
                    Icon(
                      Icons.image_outlined,
                      size: 14,
                      color: AppTheme.primaryBlue,
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Lihat Bukti Transfer',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: AppTheme.primaryBlue,
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Tombol aksi
          if (item.isMenungguVerifikasi) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                // ----- Tombol Tolak -----
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: OutlinedButton(
                      onPressed: () => service.verifyPayment(
                        txId: transaction.id,
                        userUid: item.userUid,
                        status: 'ditolak',
                        catatanBendahara:
                            'Bukti tidak valid / dana belum masuk',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.error,
                        side: BorderSide(
                          color: AppTheme.error.withOpacity(0.4),
                          width: 1.2,
                        ),
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

                // ----- Tombol Terima (Lunas) -----
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: FilledButton(
                      onPressed: () => service.verifyPayment(
                        txId: transaction.id,
                        userUid: item.userUid,
                        status: 'lunas',
                        catatanBendahara: 'Dikonfirmasi Bendahara',
                      ),
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
                      child: const Text('Terima (Lunas)'),
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

  void _showBuktiDialog(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Padding(
                  padding: EdgeInsets.all(30),
                  child: Text(
                    'Gagal memuat gambar bukti transfer.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, size: 16),
                label: const Text(
                  'Tutup',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case 'lunas':
        bg = AppTheme.successBg;
        fg = AppTheme.success;
        label = 'LUNAS';
        break;
      case 'menunggu_verifikasi':
        bg = AppTheme.warningBg;
        fg = AppTheme.warning;
        label = 'VERIFIKASI';
        break;
      case 'ditolak':
        bg = AppTheme.errorBg;
        fg = AppTheme.error;
        label = 'DITOLAK';
        break;
      default:
        bg = Colors.grey.shade200;
        fg = Colors.grey.shade700;
        label = 'BELUM BAYAR';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}
