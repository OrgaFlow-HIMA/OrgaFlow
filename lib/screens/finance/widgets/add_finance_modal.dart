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

  // ===== Style seragam =====
  static const TextStyle _inputTextStyle = TextStyle(
    fontSize: 13,
    color: AppTheme.textPrimary,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle _hintStyle = TextStyle(
    fontSize: 13,
    color: AppTheme.textSecondary,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle _labelStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppTheme.textPrimary,
  );

  @override
  void dispose() {
    _judulController.dispose();
    _deskripsiController.dispose();
    _nominalController.dispose();
    _nomorRekeningController.dispose();
    _qrisUrlController.dispose();
    super.dispose();
  }

  // ============ HELPERS ============

  InputDecoration _inputDecoration({
    required String hint,
    IconData? icon,
    String? prefixText,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: _hintStyle,
      prefixText: prefixText,
      prefixStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary,
      ),
      prefixIcon: icon != null
          ? Icon(icon, size: 20, color: AppTheme.primaryBlue)
          : null,
      // HAPUS prefixIconConstraints agar Flutter menggunakan ukuran default (48px)
      filled: true,
      fillColor: AppTheme.background,
      isDense: false,
      // KUNCI UTAMA: contentPadding kiri 0 agar teks nempel ke kotak ikon
      contentPadding: const EdgeInsets.only(
        left: 0, // Teks menempel ke batas kanan ikon
        right: 16,
        top: 16,
        bottom: 16,
      ),
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.error, width: 1.4),
      ),
      errorStyle: const TextStyle(fontSize: 11),
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.error : AppTheme.success,
      ),
    );
  }

  String _formatDate(DateTime date) {
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
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // ============ DATE PICKER ============

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

    setState(() => _tenggatWaktu = picked);
  }

  // ============ SUBMIT ============

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

    setState(() => _isLoading = true);
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
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('GAGAL MENYIMPAN DATA KAS: $e');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      _showMessage('Gagal menyimpan: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ============ UI COMPONENTS ============

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.lightBlue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.account_balance_wallet_outlined,
            color: AppTheme.primaryBlue,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Buat Data Kas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Tagihan anggota atau catatan transaksi',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: _labelStyle),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
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
        const SizedBox(height: 8),
        Container(
          height: 44,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppTheme.lightBlue.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildTypeChip(
                  label: 'Tagihan Anggota',
                  icon: Icons.people_alt_outlined,
                  selected: _isTagihanAnggota,
                  onTap: () => setState(() {
                    _isTagihanAnggota = true;
                    _jenis = 'masuk';
                    _kategori = 'iuran';
                  }),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildTypeChip(
                  label: 'Laporan Kas',
                  icon: Icons.receipt_long_outlined,
                  selected: !_isTagihanAnggota,
                  onTap: () => setState(() => _isTagihanAnggota = false),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTypeChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: selected ? Colors.white : AppTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionType() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Jenis transaksi'),
        const SizedBox(height: 8),
        Container(
          height: 44,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppTheme.lightBlue.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildTypeChip(
                  label: 'Pemasukan',
                  icon: Icons.south_west_rounded,
                  selected: _jenis == 'masuk',
                  onTap: () => setState(() => _jenis = 'masuk'),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildTypeChip(
                  label: 'Pengeluaran',
                  icon: Icons.north_east_rounded,
                  selected: _jenis == 'keluar',
                  onTap: () => setState(() => _jenis = 'keluar'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Kategori transaksi', style: _labelStyle),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _kategori,
          isExpanded: true,
          isDense: false,
          itemHeight: null,
          style: _inputTextStyle,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppTheme.textSecondary,
            size: 20,
          ),
          decoration: _inputDecoration(hint: 'Pilih kategori').copyWith(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
          ),
          items: const [
            DropdownMenuItem(value: 'iuran', child: Text('Iuran')),
            DropdownMenuItem(value: 'operasional', child: Text('Operasional')),
            DropdownMenuItem(value: 'kegiatan', child: Text('Kegiatan')),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() => _kategori = value);
          },
        ),
      ],
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

        // --- Judul ---
        TextFormField(
          controller: _judulController,
          textCapitalization: TextCapitalization.sentences,
          style: _inputTextStyle,
          decoration: _inputDecoration(
            hint: _isTagihanAnggota ? 'Nama tagihan kas' : 'Judul transaksi',
            icon: Icons.edit_note_rounded,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Judul wajib diisi.';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),

        // --- Nominal ---
        TextFormField(
          controller: _nominalController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: _inputTextStyle,
          decoration: _inputDecoration(
            hint: _isTagihanAnggota ? 'Nominal per anggota' : 'Total nominal',
            icon: Icons.payments_outlined,
            prefixText: 'Rp ',
          ),
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

        // --- Keterangan (MULTILINE) ---
        Container(
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ikon
              Padding(
                // left 12 dan top 15 agar sejajar dengan baris pertama teks
                padding: const EdgeInsets.only(left: 12, top: 15),
                child: Icon(
                  Icons.notes_rounded,
                  size: 20,
                  color: AppTheme.primaryBlue,
                ),
              ),
              // TextField
              Expanded(
                child: TextFormField(
                  controller: _deskripsiController,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 3,
                  minLines: 2,
                  style: _inputTextStyle,
                  decoration: InputDecoration(
                    hintText: 'Keterangan (opsional)',
                    hintStyle: _hintStyle,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    filled: false,
                    // KUNCI UTAMA: left 10 agar dekat dengan ikon, top 14 agar sejajar
                    contentPadding: const EdgeInsets.only(
                      left: 10,
                      right: 16,
                      top: 14,
                      bottom: 14,
                    ),
                  ),
                ),
              ),
            ],
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
          subtitle: 'Panduan pembayaran untuk anggota.',
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _nomorRekeningController,
          textCapitalization: TextCapitalization.sentences,
          style: _inputTextStyle,
          decoration: _inputDecoration(
            hint: 'Rekening / Bank transfer',
            icon: Icons.account_balance_outlined,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _qrisUrlController,
          keyboardType: TextInputType.url,
          style: _inputTextStyle,
          decoration: _inputDecoration(
            hint: 'URL gambar QRIS (opsional)',
            icon: Icons.qr_code_rounded,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) return null;
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isLoading ? null : _pickDate,
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.lightBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.calendar_today_rounded,
                  size: 18,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tenggat pembayaran',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasDate
                          ? _formatDate(_tenggatWaktu!)
                          : 'Belum ditentukan',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Atur',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton.icon(
        onPressed: _isLoading ? null : _submit,
        label: Text(
          _isLoading ? 'Menyimpan...' : 'Simpan Data Kas',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
        ),
      ),
    );
  }

  // ============ BUILD ============

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.9),
          child: Container(
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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

                    _buildHeader(),
                    const SizedBox(height: 20),

                    _buildEntryType(),

                    if (!_isTagihanAnggota) ...[
                      const SizedBox(height: 16),
                      _buildTransactionType(),
                      const SizedBox(height: 14),
                      _buildCategoryField(),
                    ],

                    const SizedBox(height: 20),
                    _buildBasicInformation(),

                    if (_isTagihanAnggota) ...[
                      const SizedBox(height: 20),
                      const Divider(height: 1, color: AppTheme.borderLight),
                      const SizedBox(height: 18),
                      _buildPaymentInformation(),
                    ],

                    const SizedBox(height: 24),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
