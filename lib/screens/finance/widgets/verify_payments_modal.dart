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
      backgroundColor: Colors.transparent,
      builder: (context) => VerifyPaymentsModal(
        transaction: transaction,
        financeService: financeService,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = financeService ?? FinanceService();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
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
          const SizedBox(height: 16),
          Text(
            'Verifikasi Pembayaran: ${transaction.judul}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Nominal: Rp ${transaction.nominal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
            style: const TextStyle(fontSize: 13, color: AppTheme.primaryBlue, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<FinancePayment>>(
              stream: service.watchAllPaymentsForTransaction(transaction.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final payments = snapshot.data ?? [];
                if (payments.isEmpty) {
                  return const Center(
                    child: Text(
                      'Belum ada anggota yang mengirim konfirmasi pembayaran.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: payments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = payments[index];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item.userNama,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              _buildStatusBadge(item.status),
                            ],
                          ),
                          if (item.catatanAnggota?.isNotEmpty == true) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Catatan: ${item.catatanAnggota}',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                          ],
                          if (item.buktiTransferUrl?.isNotEmpty == true) ...[
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => Dialog(
                                    child: Image.network(
                                      item.buktiTransferUrl!,
                                      errorBuilder: (_, __, ___) => const Padding(
                                        padding: EdgeInsets.all(20),
                                        child: Text('Gagal memuat gambar bukti transfer.'),
                                      ),
                                    ),
                                  ),
                                );
                              },
                              child: const Row(
                                children: [
                                  Icon(Icons.image_outlined, size: 14, color: AppTheme.primaryBlue),
                                  SizedBox(width: 4),
                                  Text(
                                    'Lihat Bukti Transfer',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.primaryBlue,
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          if (item.isMenungguVerifikasi)
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => service.verifyPayment(
                                      txId: transaction.id,
                                      userUid: item.userUid,
                                      status: 'ditolak',
                                      catatanBendahara: 'Bukti tidak valid / dana belum masuk',
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.error,
                                      side: const BorderSide(color: AppTheme.error),
                                      minimumSize: const Size.fromHeight(36),
                                    ),
                                    child: const Text('Tolak'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: FilledButton(
                                    onPressed: () => service.verifyPayment(
                                      txId: transaction.id,
                                      userUid: item.userUid,
                                      status: 'lunas',
                                      catatanBendahara: 'Dikonfirmasi Bendahara',
                                    ),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppTheme.success,
                                      minimumSize: const Size.fromHeight(36),
                                    ),
                                    child: const Text('Terima (Lunas)'),
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
            ),
          ),
        ],
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
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
