import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../services/finance_service.dart';

class AddFinanceModal extends StatefulWidget {
  final FinanceService? financeService;

  const AddFinanceModal({super.key, this.financeService});

  static Future<void> show(
    BuildContext context, {
    FinanceService? financeService,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddFinanceModal(financeService: financeService),
    );
  }

  @override
  State<AddFinanceModal> createState() => _AddFinanceModalState();
}

class _AddFinanceModalState extends State<AddFinanceModal> {
  final _formKey = GlobalKey<FormState>();

  final _judulController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _nominalController = TextEditingController();

  final _nomorRekeningController = TextEditingController(
    text: 'BCA 1234567890 a.n HIMA TI',
  );

  final _qrisUrlController = TextEditingController();

  String _jenis = 'masuk';
  String _kategori = 'iuran';

  bool _isTagihanAnggota = true;
  bool _isLoading = false;

  DateTime? _tenggatWaktu;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    _judulController.dispose();
    _deskripsiController.dispose();
    _nominalController.dispose();
    _nomorRekeningController.dispose();
    _qrisUrlController.dispose();

    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: AppTheme.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.error, width: 1.5),
      ),
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.error : AppTheme.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // ---------------------------------------------------------------------------
  // Date Picker
  // ---------------------------------------------------------------------------

  Future<void> _pickDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _tenggatWaktu ?? now.add(const Duration(days: 14)),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Pilih tenggat pembayaran',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );

    if (!mounted || picked == null) return;

    setState(() {
      _tenggatWaktu = picked;
    });
  }

  // ---------------------------------------------------------------------------
  // Form Submission
  // ---------------------------------------------------------------------------

  Future<void> _submit() async {
    if (_isLoading) return;

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final nominal =
        int.tryParse(
          _nominalController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        0;

    if (nominal <= 0) {
      _showMessage('Nominal harus lebih dari Rp0.', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final service = widget.financeService ?? FinanceService();

    try {
      await service.createTransaction(
        judul: _judulController.text.trim(),
        deskripsi: _deskripsiController.text.trim(),
        kategori: _kategori,
        jenis: _jenis,
        nominal: nominal,
        isTagihanAnggota: _isTagihanAnggota,
        nomorRekening: _isTagihanAnggota
            ? _nomorRekeningController.text.trim()
            : null,
        qrisUrl: _isTagihanAnggota ? _qrisUrlController.text.trim() : null,
        tenggatWaktu: _isTagihanAnggota ? _tenggatWaktu : null,
      );

      if (!mounted) return;

      final messenger = ScaffoldMessenger.of(context);

      Navigator.pop(context);

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Data kas berhasil disimpan.'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('GAGAL MENYIMPAN DATA KAS: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      _showMessage('Gagal menyimpan: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // UI Components
  // ---------------------------------------------------------------------------

  Widget _buildHeader() {
    return Column(
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
        const SizedBox(height: 24),
        const Text(
          'Buat Data Kas',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Tambahkan tagihan anggota atau catat transaksi kas organisasi.',
          style: TextStyle(
            fontSize: 13,
            height: 1.5,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ],
    );
  }

  Widget _buildEntryType() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Jenis pencatatan'),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment<bool>(
                value: true,
                label: Text('Tagihan Anggota', textAlign: TextAlign.center),
                icon: Icon(Icons.people_alt_outlined),
              ),
              ButtonSegment<bool>(
                value: false,
                label: Text('Laporan Kas', textAlign: TextAlign.center),
                icon: Icon(Icons.receipt_long_outlined),
              ),
            ],
            selected: {_isTagihanAnggota},
            onSelectionChanged: (value) {
              setState(() {
                _isTagihanAnggota = value.first;

                if (_isTagihanAnggota) {
                  _jenis = 'masuk';
                  _kategori = 'iuran';
                }
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionType() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Jenis transaksi'),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<String>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment<String>(
                value: 'masuk',
                label: Text('Pemasukan'),
                icon: Icon(Icons.south_west_rounded),
              ),
              ButtonSegment<String>(
                value: 'keluar',
                label: Text('Pengeluaran'),
                icon: Icon(Icons.north_east_rounded),
              ),
            ],
            selected: {_jenis},
            onSelectionChanged: (value) {
              setState(() {
                _jenis = value.first;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryField() {
    return DropdownButtonFormField<String>(
      value: _kategori,
      decoration: _inputDecoration(
        label: 'Kategori transaksi',
        prefixIcon: const Icon(Icons.category_outlined),
      ),
      items: const [
        DropdownMenuItem(value: 'iuran', child: Text('Iuran')),
        DropdownMenuItem(value: 'operasional', child: Text('Operasional')),
        DropdownMenuItem(value: 'kegiatan', child: Text('Kegiatan')),
      ],
      onChanged: (value) {
        if (value == null) return;

        setState(() {
          _kategori = value;
        });
      },
    );
  }

  Widget _buildBasicInformation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          'Informasi transaksi',
          subtitle: 'Lengkapi informasi utama pencatatan kas.',
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _judulController,
          textCapitalization: TextCapitalization.sentences,
          decoration: _inputDecoration(
            label: _isTagihanAnggota ? 'Nama tagihan kas' : 'Judul transaksi',
            hint: _isTagihanAnggota
                ? 'Contoh: Kas Bulan November 2026'
                : 'Contoh: Pembelian perlengkapan',
            prefixIcon: const Icon(Icons.edit_note_rounded),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Judul wajib diisi.';
            }

            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _nominalController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: _inputDecoration(
            label: _isTagihanAnggota ? 'Nominal per anggota' : 'Total nominal',
            hint: 'Contoh: 20000',
            prefixIcon: const Icon(Icons.payments_outlined),
          ).copyWith(prefixText: 'Rp '),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Nominal wajib diisi.';
            }

            final amount = int.tryParse(value);

            if (amount == null || amount <= 0) {
              return 'Masukkan nominal yang valid.';
            }

            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _deskripsiController,
          textCapitalization: TextCapitalization.sentences,
          maxLines: 3,
          minLines: 2,
          decoration: _inputDecoration(
            label: 'Keterangan',
            hint: 'Tambahkan catatan atau detail transaksi (opsional).',
            prefixIcon: const Icon(Icons.notes_rounded),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentInformation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          'Informasi pembayaran',
          subtitle: 'Informasi ini akan digunakan sebagai panduan pembayaran anggota.',
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _nomorRekeningController,
          textCapitalization: TextCapitalization.sentences,
          decoration: _inputDecoration(
            label: 'Rekening / Bank transfer',
            hint: 'Contoh: BCA 1234567890 a.n HIMA TI',
            prefixIcon: const Icon(Icons.account_balance_outlined),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _qrisUrlController,
          keyboardType: TextInputType.url,
          decoration: _inputDecoration(
            label: 'URL gambar QRIS',
            hint: 'https://example.com/qris.png',
            prefixIcon: const Icon(Icons.qr_code_rounded),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return null;
            }

            final uri = Uri.tryParse(value.trim());

            if (uri == null ||
                !uri.hasScheme ||
                (uri.scheme != 'http' && uri.scheme != 'https') ||
                uri.host.isEmpty) {
              return 'Masukkan URL gambar yang valid.';
            }

            return null;
          },
        ),
        const SizedBox(height: 12),
        _buildDeadlinePicker(),
      ],
    );
  }

  Widget _buildDeadlinePicker() {
    final hasDate = _tenggatWaktu != null;

    return InkWell(
      onTap: _isLoading ? null : _pickDate,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_month_outlined,
              color: AppTheme.primaryBlue,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tenggat pembayaran',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasDate
                        ? _formatDate(_tenggatWaktu!)
                        : 'Pilih tanggal pembayaran',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: hasDate ? FontWeight.w600 : FontWeight.w400,
                      color: hasDate
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              hasDate
                  ? Icons.edit_calendar_outlined
                  : Icons.chevron_right_rounded,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _isLoading ? null : _submit,
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.primaryBlue,
          disabledBackgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.5),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save_outlined, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Simpan Data Kas',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Main Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.9),
        child: Container(
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),

                  _buildEntryType(),

                  if (!_isTagihanAnggota) ...[
                    const SizedBox(height: 20),
                    _buildTransactionType(),
                    const SizedBox(height: 16),
                    _buildCategoryField(),
                  ],

                  const SizedBox(height: 24),
                  _buildBasicInformation(),

                  if (_isTagihanAnggota) ...[
                    const SizedBox(height: 24),
                    const Divider(color: AppTheme.borderLight),
                    const SizedBox(height: 20),
                    _buildPaymentInformation(),
                  ],

                  const SizedBox(height: 28),
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
