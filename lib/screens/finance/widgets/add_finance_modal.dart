import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../services/finance_service.dart';

class AddFinanceModal extends StatefulWidget {
  final FinanceService? financeService;

  const AddFinanceModal({super.key, this.financeService});

  static Future<void> show(BuildContext context, {FinanceService? financeService}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
  final _nomorRekeningController = TextEditingController(text: 'BCA 1234567890 a.n HIMA TI');
  final _qrisUrlController = TextEditingController();

  String _jenis = 'masuk'; // 'masuk' or 'keluar'
  String _kategori = 'iuran'; // 'iuran', 'operasional', 'kegiatan'
  bool _isTagihanAnggota = true;
  DateTime? _tenggatWaktu;
  bool _isLoading = false;

  @override
  void dispose() {
    _judulController.dispose();
    _deskripsiController.dispose();
    _nominalController.dispose();
    _nomorRekeningController.dispose();
    _qrisUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _tenggatWaktu ?? now.add(const Duration(days: 14)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _tenggatWaktu = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final nominal = int.tryParse(_nominalController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (nominal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal harus lebih dari 0')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final service = widget.financeService ?? FinanceService();

    try {
      await service.createTransaction(
        judul: _judulController.text,
        deskripsi: _deskripsiController.text,
        kategori: _kategori,
        jenis: _jenis,
        nominal: nominal,
        isTagihanAnggota: _isTagihanAnggota,
        nomorRekening: _isTagihanAnggota ? _nomorRekeningController.text : null,
        qrisUrl: _isTagihanAnggota ? _qrisUrlController.text : null,
        tenggatWaktu: _isTagihanAnggota ? _tenggatWaktu : null,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaksi / Kas berhasil dibuat!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat transaksi: $e'),
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
        child: Form(
          key: _formKey,
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
              const Text(
                'Buat Kas / Transaksi Baru',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              // Tipe Entri
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment<bool>(
                    value: true,
                    label: Text('Tagihan Kas Anggota'),
                    icon: Icon(Icons.people_alt_outlined),
                  ),
                  ButtonSegment<bool>(
                    value: false,
                    label: Text('Laporan Kas'),
                    icon: Icon(Icons.receipt_long_outlined),
                  ),
                ],
                selected: {_isTagihanAnggota},
                onSelectionChanged: (val) {
                  setState(() {
                    _isTagihanAnggota = val.first;
                    if (_isTagihanAnggota) {
                      _jenis = 'masuk';
                      _kategori = 'iuran';
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
              if (!_isTagihanAnggota) ...[
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Pemasukan'),
                        value: 'masuk',
                        groupValue: _jenis,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (v) => setState(() => _jenis = v ?? 'masuk'),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Pengeluaran'),
                        value: 'keluar',
                        groupValue: _jenis,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (v) => setState(() => _jenis = v ?? 'keluar'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              TextFormField(
                controller: _judulController,
                decoration: InputDecoration(
                  labelText: _isTagihanAnggota ? 'Nama Kas (cth: Kas Bulan Maret 2026)' : 'Judul Transaksi',
                  filled: true,
                  fillColor: AppTheme.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Judul wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nominalController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: _isTagihanAnggota ? 'Nominal per Anggota (Rp)' : 'Total Nominal (Rp)',
                  hintText: 'Contoh: 20000',
                  filled: true,
                  fillColor: AppTheme.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Nominal wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _deskripsiController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Keterangan / Catatan',
                  filled: true,
                  fillColor: AppTheme.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              if (_isTagihanAnggota) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nomorRekeningController,
                  decoration: InputDecoration(
                    labelText: 'Info Rekening / Bank Transfer',
                    filled: true,
                    fillColor: AppTheme.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _qrisUrlController,
                  decoration: InputDecoration(
                    labelText: 'URL Gambar QRIS (Opsional)',
                    hintText: 'https://...',
                    filled: true,
                    fillColor: AppTheme.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _tenggatWaktu == null
                              ? 'Pilih Tenggat Waktu Bayar'
                              : 'Tenggat: ${_tenggatWaktu!.day}/${_tenggatWaktu!.month}/${_tenggatWaktu!.year}',
                          style: TextStyle(
                            fontSize: 13,
                            color: _tenggatWaktu == null ? AppTheme.textSecondary : AppTheme.textPrimary,
                          ),
                        ),
                        const Icon(Icons.calendar_today_rounded, size: 18, color: AppTheme.primaryBlue),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : _submit,
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
                      : const Text('Simpan Transaksi Kas'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
