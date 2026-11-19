import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/agenda.dart';
import '../../../services/agenda_service.dart';

class AddEditAgendaModal extends StatefulWidget {
  final Agenda? agenda;
  final AgendaService agendaService;
  final VoidCallback? onSuccess;

  const AddEditAgendaModal({
    super.key,
    this.agenda,
    required this.agendaService,
    this.onSuccess,
  });

  static Future<void> show(
    BuildContext context, {
    Agenda? agenda,
    AgendaService? agendaService,
    VoidCallback? onSuccess,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => AddEditAgendaModal(
        agenda: agenda,
        agendaService: agendaService ?? AgendaService(),
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  State<AddEditAgendaModal> createState() => _AddEditAgendaModalState();
}

class _AddEditAgendaModalState extends State<AddEditAgendaModal> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _judulController;
  late final TextEditingController _deskripsiController;
  late final TextEditingController _kategoriController;
  late final TextEditingController _lokasiController;
  late final TextEditingController _linkMeetingController;

  late String _tipe; // 'online' atau 'offline'
  late DateTime _tanggalWaktu;
  DateTime? _selesaiWaktu;
  bool _isLoading = false;

  bool get _isEdit => widget.agenda != null;

  @override
  void initState() {
    super.initState();
    final a = widget.agenda;
    _judulController = TextEditingController(text: a?.judul ?? '');
    _deskripsiController = TextEditingController(text: a?.deskripsi ?? '');
    _kategoriController = TextEditingController(text: a?.kategori ?? 'BPH & BPO');
    _tipe = a?.tipe.toLowerCase() == 'online' ? 'online' : 'offline';
    _lokasiController = TextEditingController(
      text: a?.lokasi ?? (_tipe == 'online' ? 'Google Meet' : 'Ruang Rapat Gedung B'),
    );
    _linkMeetingController = TextEditingController(text: a?.linkMeeting ?? '');
    _tanggalWaktu = a?.tanggalWaktu ?? DateTime.now().add(const Duration(days: 1));
    _selesaiWaktu = a?.selesaiWaktu;
  }

  @override
  void dispose() {
    _judulController.dispose();
    _deskripsiController.dispose();
    _kategoriController.dispose();
    _lokasiController.dispose();
    _linkMeetingController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final initial = isStart ? _tanggalWaktu : (_selesaiWaktu ?? _tanggalWaktu.add(const Duration(hours: 2)));
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initial),
      );

      if (time != null && mounted) {
        setState(() {
          final result = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
          if (isStart) {
            _tanggalWaktu = result;
          } else {
            _selesaiWaktu = result;
          }
        });
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_tipe == 'online' && _linkMeetingController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agenda online wajib menyertakan link Zoom atau Google Meet!'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesi login tidak ditemukan. Silakan login kembali.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isEdit) {
        await widget.agendaService.updateAgenda(
          agendaId: widget.agenda!.id,
          judul: _judulController.text,
          deskripsi: _deskripsiController.text,
          kategori: _kategoriController.text,
          tipe: _tipe,
          lokasi: _lokasiController.text,
          linkMeeting: _tipe == 'online' ? _linkMeetingController.text : null,
          tanggalWaktu: _tanggalWaktu,
          selesaiWaktu: _selesaiWaktu,
        );
      } else {
        await widget.agendaService.createAgenda(
          createdBy: uid,
          judul: _judulController.text,
          deskripsi: _deskripsiController.text,
          kategori: _kategoriController.text,
          tipe: _tipe,
          lokasi: _lokasiController.text,
          linkMeeting: _tipe == 'online' ? _linkMeetingController.text : null,
          tanggalWaktu: _tanggalWaktu,
          selesaiWaktu: _selesaiWaktu,
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? 'Agenda berhasil diperbarui!' : 'Agenda berhasil ditambahkan!'),
            backgroundColor: AppTheme.success,
          ),
        );
        widget.onSuccess?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan agenda: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
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
                const SizedBox(height: 12),
                // Header Modal
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isEdit ? 'Edit Agenda' : 'Tambah Agenda Baru',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

              // Pilihan Tipe: Offline vs Online
              const Text(
                'Tipe Agenda',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.lightBlue.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _tipe = 'offline';
                            if (_lokasiController.text == 'Google Meet' ||
                                _lokasiController.text == 'Zoom Meeting') {
                              _lokasiController.text = 'Ruang Seminar Gedung D';
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: _tipe == 'offline' ? AppTheme.primaryBlue : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.place_rounded,
                                size: 16,
                                color: _tipe == 'offline' ? Colors.white : AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Offline (Tatap Muka)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _tipe == 'offline' ? Colors.white : AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _tipe = 'online';
                            if (_lokasiController.text.contains('Ruang') ||
                                _lokasiController.text.isEmpty) {
                              _lokasiController.text = 'Google Meet';
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: _tipe == 'online' ? AppTheme.primaryBlue : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.videocam_rounded,
                                size: 16,
                                color: _tipe == 'online' ? Colors.white : AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Online (Daring)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _tipe == 'online' ? Colors.white : AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Judul Agenda
              const Text(
                'Judul Agenda',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _judulController,
                decoration: _inputDecoration('Contoh: Rapat Evaluasi Triwulan BPH'),
                validator: (val) => val == null || val.trim().isEmpty ? 'Judul agenda wajib diisi' : null,
              ),
              const SizedBox(height: 14),

              // Kategori
              const Text(
                'Kategori / Penanggung Jawab',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _kategoriController,
                decoration: _inputDecoration('Contoh: BPH & BPO, Divisi Acara, dll.'),
                validator: (val) => val == null || val.trim().isEmpty ? 'Kategori wajib diisi' : null,
              ),
              const SizedBox(height: 14),

              // Lokasi / Platform
              Text(
                _tipe == 'online' ? 'Platform Online' : 'Lokasi / Ruangan',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _lokasiController,
                decoration: _inputDecoration(
                  _tipe == 'online' ? 'Contoh: Google Meet / Zoom' : 'Contoh: Ruang Seminar Gedung D Lt. 2',
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Lokasi/Platform wajib diisi' : null,
              ),
              const SizedBox(height: 14),

              // Link Meeting (Khusus Online)
              if (_tipe == 'online') ...[
                const Text(
                  'Tautan Link Meeting (Zoom / Google Meet)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _linkMeetingController,
                  decoration: _inputDecoration('https://meet.google.com/xyz-abcd-efg'),
                ),
                const SizedBox(height: 14),
              ],

              // Tanggal & Waktu Pelaksanaan
              const Text(
                'Waktu Pelaksanaan',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Text(
                        '${_tanggalWaktu.day}/${_tanggalWaktu.month}/${_tanggalWaktu.year} • ${_tanggalWaktu.hour.toString().padLeft(2, '0')}:${_tanggalWaktu.minute.toString().padLeft(2, '0')} WIB',
                        style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _pickDateTime(isStart: true),
                    icon: const Icon(Icons.calendar_today_rounded, size: 16),
                    label: const Text('Atur'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Deskripsi
              const Text(
                'Deskripsi / Catatan Agenda',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _deskripsiController,
                maxLines: 3,
                decoration: _inputDecoration('Rincian pembahasan atau dresscode...'),
              ),
              const SizedBox(height: 24),

              // Submit Button
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _handleSubmit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            _isEdit ? 'Simpan Perubahan' : 'Publikasikan Agenda',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppTheme.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.borderLight),
      ),
    );
  }
}
