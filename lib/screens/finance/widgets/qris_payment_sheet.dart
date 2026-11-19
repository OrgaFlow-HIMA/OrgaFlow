import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/finance_transaction.dart';
import '../../../services/finance_service.dart';

class QrisPaymentSheet extends StatefulWidget {
  final FinanceTransaction transaction;
  final FinancePayment? existingPayment;
  final String currentUid;
  final String currentNama;
  final String? currentNim;
  final String? currentDivisiId;
  final FinanceService? financeService;

  const QrisPaymentSheet({
    super.key,
    required this.transaction,
    this.existingPayment,
    required this.currentUid,
    required this.currentNama,
    this.currentNim,
    this.currentDivisiId,
    this.financeService,
  });

  static Future<void> show(
    BuildContext context, {
    required FinanceTransaction transaction,
    FinancePayment? existingPayment,
    required String currentUid,
    required String currentNama,
    String? currentNim,
    String? currentDivisiId,
    FinanceService? financeService,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QrisPaymentSheet(
        transaction: transaction,
        existingPayment: existingPayment,
        currentUid: currentUid,
        currentNama: currentNama,
        currentNim: currentNim,
        currentDivisiId: currentDivisiId,
        financeService: financeService,
      ),
    );
  }

  @override
  State<QrisPaymentSheet> createState() => _QrisPaymentSheetState();
}

class _QrisPaymentSheetState extends State<QrisPaymentSheet> {
  final _buktiUrlController = TextEditingController();
  final _catatanController = TextEditingController();
  String _metodeBayar = 'qris';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingPayment != null) {
      _buktiUrlController.text = widget.existingPayment!.buktiTransferUrl ?? '';
      _catatanController.text = widget.existingPayment!.catatanAnggota ?? '';
      _metodeBayar = widget.existingPayment!.metodeBayar ?? 'qris';
    }
  }

  @override
  void dispose() {
    _buktiUrlController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  Future<void> _submitPayment() async {
    setState(() => _isLoading = true);
    final service = widget.financeService ?? FinanceService();

    try {
      await service.submitPayment(
        txId: widget.transaction.id,
        userUid: widget.currentUid,
        userNama: widget.currentNama,
        userNim: widget.currentNim,
        divisiId: widget.currentDivisiId,
        nominal: widget.transaction.nominal,
        metodeBayar: _metodeBayar,
        buktiTransferUrl: _buktiUrlController.text.trim().isNotEmpty
            ? _buktiUrlController.text.trim()
            : null,
        catatanAnggota: _catatanController.text.trim().isNotEmpty
            ? _catatanController.text.trim()
            : null,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Konfirmasi pembayaran berhasil dikirim ke Bendahara!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim konfirmasi: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tx = widget.transaction;
    final isLunas = widget.existingPayment?.isLunas == true;
    final isMenunggu = widget.existingPayment?.isMenungguVerifikasi == true;

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
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
            const SizedBox(height: 16),
            Text(
              tx.judul,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Nominal: Rp ${tx.nominal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 16),
            if (isLunas)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.successBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: AppTheme.success),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tagihan ini sudah LUNAS dan terverifikasi oleh Bendahara.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.success,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              // QRIS & Rekening Info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Column(
                  children: [
                    if (tx.qrisUrl?.isNotEmpty == true) ...[
                      const Text(
                        'Scan QRIS untuk Bayar',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          tx.qrisUrl!,
                          width: 180,
                          height: 180,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Container(
                            width: 140,
                            height: 140,
                            color: AppTheme.lightBlue,
                            child: const Icon(
                              Icons.qr_code_2_rounded,
                              size: 80,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (tx.nomorRekening?.isNotEmpty == true)
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: tx.nomorRekening!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Nomor rekening disalin!')),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.borderLight),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.account_balance_rounded, size: 16, color: AppTheme.primaryBlue),
                              const SizedBox(width: 8),
                              Text(
                                tx.nomorRekening!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.copy_rounded, size: 14, color: AppTheme.textSecondary),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (isMenunggu)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.warningBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Bukti pembayaran Anda sudah dikirim dan sedang menunggu verifikasi oleh Bendahara.',
                    style: TextStyle(fontSize: 12, color: AppTheme.warning, fontWeight: FontWeight.w600),
                  ),
                ),
              const SizedBox(height: 12),
              // Form Konfirmasi Pembayaran
              DropdownButtonFormField<String>(
                value: _metodeBayar,
                decoration: InputDecoration(
                  labelText: 'Metode Pembayaran',
                  filled: true,
                  fillColor: AppTheme.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: const [
                  DropdownMenuItem(value: 'qris', child: Text('QRIS')),
                  DropdownMenuItem(value: 'transfer_bank', child: Text('Transfer Bank')),
                  DropdownMenuItem(value: 'tunai', child: Text('Tunai / Cash')),
                ],
                onChanged: (v) => setState(() => _metodeBayar = v ?? 'qris'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _buktiUrlController,
                decoration: InputDecoration(
                  labelText: 'Link Bukti Transfer / Gambar (Opsional)',
                  hintText: 'https://...',
                  filled: true,
                  fillColor: AppTheme.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _catatanController,
                decoration: InputDecoration(
                  labelText: 'Catatan (Opsional)',
                  hintText: 'Contoh: Sudah bayar via ShopeePay atas nama Budi',
                  filled: true,
                  fillColor: AppTheme.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : _submitPayment,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(isMenunggu ? 'Kirim Ulang Bukti Bayar' : 'Konfirmasi Sudah Bayar'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
