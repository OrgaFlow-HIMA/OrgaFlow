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
      useSafeArea: true,
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
  late final TextEditingController _linkAbsensiController;

  late String _tipe;
  late DateTime _tanggalWaktu;
  DateTime? _selesaiWaktu;
  bool _isLoading = false;

  bool get _isEdit => widget.agenda != null;

  // Style input seragam — dipakai di semua TextFormField
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
    final a = widget.agenda;
    _judulController = TextEditingController(text: a?.judul ?? '');
    _deskripsiController = TextEditingController(text: a?.deskripsi ?? '');
    _kategoriController = TextEditingController(
      text: a?.kategori ?? 'BPH & BPO',
    );
    _tipe = a?.tipe.toLowerCase() == 'online' ? 'online' : 'offline';
    _lokasiController = TextEditingController(
      text:
          a?.lokasi ??
          (_tipe == 'online' ? 'Google Meet' : 'Ruang Rapat Gedung B'),
    );
    _linkMeetingController = TextEditingController(text: a?.linkMeeting ?? '');
    _linkAbsensiController = TextEditingController(text: a?.linkAbsensi ?? '');
    _tanggalWaktu =
        a?.tanggalWaktu ?? DateTime.now().add(const Duration(days: 1));
    _selesaiWaktu = a?.selesaiWaktu;
  }

  @override
  void dispose() {
    _judulController.dispose();
    _deskripsiController.dispose();
    _kategoriController.dispose();
    _lokasiController.dispose();
    _linkMeetingController.dispose();
    _linkAbsensiController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final initial = isStart
        ? _tanggalWaktu
        : (_selesaiWaktu ?? _tanggalWaktu.add(const Duration(hours: 2)));

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
          content: Text(
            'Agenda online wajib menyertakan link Zoom atau Google Meet!',
          ),
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
          linkAbsensi: _tipe == 'online' ? _linkAbsensiController.text : null,
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
          linkAbsensi: _tipe == 'online' ? _linkAbsensiController.text : null,
          tanggalWaktu: _tanggalWaktu,
          selesaiWaktu: _selesaiWaktu,
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEdit
                  ? 'Agenda berhasil diperbarui!'
                  : 'Agenda berhasil ditambahkan!',
            ),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Form(
              key: _formKey,
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
                        child: Icon(
                          _isEdit
                              ? Icons.edit_calendar_rounded
                              : Icons.event_available_rounded,
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
                              _isEdit ? 'Edit Agenda' : 'Tambah Agenda Baru',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isEdit
                                  ? 'Perbarui detail jadwal agenda'
                                  : 'Lengkapi detail jadwal kegiatan',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
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

                  // Tipe
                  const Text('Tipe Agenda', style: _labelStyle),
                  const SizedBox(height: 8),
                  _buildTypeSwitcher(),
                  const SizedBox(height: 16),

                  // Judul
                  const Text('Judul Agenda', style: _labelStyle),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _judulController,
                    style: _inputTextStyle,
                    decoration: _inputDecoration(
                      'Contoh: Rapat Evaluasi Triwulan BPH',
                    ),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Judul agenda wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 14),

                  // Kategori
                  const Text('Kategori / Penanggung Jawab', style: _labelStyle),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _kategoriController,
                    style: _inputTextStyle,
                    decoration: _inputDecoration(
                      'Contoh: BPH & BPO, Divisi Acara',
                    ),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Kategori wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 14),

                  // Lokasi
                  Text(
                    _tipe == 'online' ? 'Platform Online' : 'Lokasi / Ruangan',
                    style: _labelStyle,
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _lokasiController,
                    style: _inputTextStyle,
                    decoration: _inputDecoration(
                      _tipe == 'online'
                          ? 'Contoh: Google Meet / Zoom'
                          : 'Contoh: Ruang Seminar Gedung D',
                    ),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Lokasi/Platform wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 14),

                  // Tautan online (animated)
                  AnimatedSize(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    child: _tipe == 'online'
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildOnlineLinksCard(),
                              const SizedBox(height: 14),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),

                  // Waktu
                  const Text('Waktu Pelaksanaan', style: _labelStyle),
                  const SizedBox(height: 6),
                  _buildDateTimeCard(
                    start: _tanggalWaktu,
                    onTap: () => _pickDateTime(isStart: true),
                  ),
                  const SizedBox(height: 14),

                  // Deskripsi
                  const Text('Deskripsi / Catatan Agenda', style: _labelStyle),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _deskripsiController,
                    maxLines: 3,
                    style: _inputTextStyle,
                    decoration: _inputDecoration(
                      'Rincian pembahasan atau dresscode...',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit
                  SizedBox(
                    width: double.infinity,
                    height: 46,
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
                          onTap: _isLoading ? null : _handleSubmit,
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
                                      Icon(
                                        _isEdit
                                            ? Icons.save_rounded
                                            : Icons.send_rounded,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _isEdit
                                            ? 'Simpan Perubahan'
                                            : 'Publikasikan',
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
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============ HELPERS ============

  Widget _buildTypeSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.lightBlue.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TypeChip(
              label: 'Tatap Muka',
              icon: Icons.place_rounded,
              selected: _tipe == 'offline',
              onTap: () {
                setState(() {
                  _tipe = 'offline';
                  if (_lokasiController.text == 'Google Meet' ||
                      _lokasiController.text == 'Zoom Meeting') {
                    _lokasiController.text = 'Ruang Seminar Gedung D';
                  }
                });
              },
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _TypeChip(
              label: 'Daring',
              icon: Icons.videocam_rounded,
              selected: _tipe == 'online',
              onTap: () {
                setState(() {
                  _tipe = 'online';
                  if (_lokasiController.text.contains('Ruang') ||
                      _lokasiController.text.isEmpty) {
                    _lokasiController.text = 'Google Meet';
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineLinksCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.lightBlue.withOpacity(0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.accentBlue.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.link_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Tautan Agenda Online',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text('Link Meeting (Zoom / Google Meet)', style: _labelStyle),
          const SizedBox(height: 6),
          TextFormField(
            controller: _linkMeetingController,
            style: _inputTextStyle,
            decoration: _inputDecoration(
              'https://meet.google.com/xyz-abcd-efg',
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Link Absensi (Google Form) — Opsional',
            style: _labelStyle,
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _linkAbsensiController,
            style: _inputTextStyle,
            decoration: _inputDecoration('https://forms.gle/xxxxxxxxxx'),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeCard({
    required DateTime start,
    required VoidCallback onTap,
  }) {
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
    final time =
        '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    final dateLabel =
        '${start.day} ${months[start.month - 1]} ${start.year} • $time WIB';

    return Material(
      color: Colors.transparent,
      child: InkWell(
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
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppTheme.lightBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mulai',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      dateLabel,
                      style: _inputTextStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Atur',
                  style: TextStyle(
                    fontSize: 11,
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

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: _hintStyle,
      filled: true,
      fillColor: AppTheme.background,
      isDense: true,
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

/// Chip tipe agenda — satu baris, teks singkat agar compact.
class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: selected ? Colors.white : AppTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
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
}
