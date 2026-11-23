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
      useSafeArea: true,
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

  // ===== Style seragam =====
  static const TextStyle _inputTextStyle = TextStyle(
    fontSize: 12,
    color: AppTheme.textPrimary,
    height: 1.35,
  );
  static const TextStyle _hintStyle = TextStyle(
    fontSize: 12,
    color: AppTheme.textSecondary,
    height: 1.35,
  );
  static const TextStyle _labelStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppTheme.textPrimary,
  );

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

  String _formatRupiah(int number) {
    return 'Rp ${number.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
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
            content: Text(
              'Konfirmasi pembayaran berhasil dikirim ke Bendahara!',
            ),
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

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Grabber
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
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.lightBlue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.qr_code_2_rounded,
                          color: AppTheme.primaryBlue,
                          size: 22,
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
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Nominal: ${_formatRupiah(tx.nominal)}',
                              style: const TextStyle(
                                fontSize: 13,
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
                  const SizedBox(height: 18),

                  if (isLunas) ...[
                    // ===== STATUS LUNAS =====
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.successBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppTheme.success.withOpacity(0.3),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: AppTheme.success,
                            size: 22,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Tagihan ini sudah LUNAS dan terverifikasi oleh Bendahara.',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.success,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // ===== INFO PEMBAYARAN =====
                    _buildPaymentInfoCard(tx),

                    const SizedBox(height: 14),

                    // ===== PERINGATAN MENUNGGU =====
                    if (isMenunggu) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.warningBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Bukti pembayaran Anda sedang menunggu verifikasi Bendahara.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.warning,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // ===== FORM =====
                    const Text('Metode Pembayaran', style: _labelStyle),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _metodeBayar,
                      isExpanded: true,
                      itemHeight: null,
                      style: _inputTextStyle,
                      isDense: true, // <--- TAMBAHKAN INI (Kunci agar tingginya sama)
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppTheme.textSecondary,
                        size: 20,
                      ),
                      decoration: _inputDecoration(null).copyWith(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12, // Samakan dengan TextField
                        ),
                        // Trik tambahan agar border & hint pas di tengah
                        prefixIconConstraints: const BoxConstraints(
                          minHeight: 0,
                          minWidth: 0,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'qris', child: Text('QRIS')),
                        DropdownMenuItem(
                          value: 'transfer_bank',
                          child: Text('Transfer Bank'),
                        ),
                        DropdownMenuItem(
                          value: 'tunai',
                          child: Text('Tunai / Cash'),
                        ),
                      ],
                      onChanged: (v) =>
                          setState(() => _metodeBayar = v ?? 'qris'),
                    ),
                    const SizedBox(height: 12),

                    const Text(
                      'Link Bukti Transfer (Opsional)',
                      style: _labelStyle,
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _buktiUrlController,
                      style: _inputTextStyle,
                      keyboardType: TextInputType.url,
                      decoration: _inputDecoration('https://...'),
                    ),
                    const SizedBox(height: 12),

                    const Text('Catatan (Opsional)', style: _labelStyle),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _catatanController,
                      style: _inputTextStyle,
                      maxLines: 2,
                      decoration: _inputDecoration(
                        'Contoh: Sudah bayar via ShopeePay atas nama Budi',
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ===== SUBMIT =====
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue,
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryBlue.withOpacity(0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(50),
                            onTap: _isLoading ? null : _submitPayment,
                            child: Center(
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          isMenunggu
                                              ? 'Kirim Ulang Bukti Bayar'
                                              : 'Konfirmasi Sudah Bayar',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentInfoCard(FinanceTransaction tx) {
    return Container(
      padding: const EdgeInsets.all(14),
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
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Image.network(
                  tx.qrisUrl!,
                  width: 170,
                  height: 170,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    width: 140,
                    height: 140,
                    color: AppTheme.lightBlue,
                    child: const Icon(
                      Icons.qr_code_2_rounded,
                      size: 70,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ),
              ),
            ),
            if (tx.nomorRekening?.isNotEmpty == true)
              const SizedBox(height: 12),
          ],
          if (tx.nomorRekening?.isNotEmpty == true)
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: tx.nomorRekening!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Nomor rekening disalin!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.account_balance_rounded,
                      size: 14,
                      color: AppTheme.primaryBlue,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tx.nomorRekening!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.copy_rounded,
                      size: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String? hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: _hintStyle,
      filled: true,
      fillColor: AppTheme.background,
      isDense: true,
      // Vertikal 12, horizontal 14 → tinggi field seragam
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.4),
      ),
      errorStyle: const TextStyle(fontSize: 11),
    );
  }
}
