import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/announcement.dart';
import '../../../services/announcement_service.dart';
import '../../../services/cloudinary_service.dart';

class CreateAnnouncementModal extends StatefulWidget {
  final AnnouncementService? announcementService;
  final CloudinaryService? cloudinaryService;

  const CreateAnnouncementModal({
    super.key,
    this.announcementService,
    this.cloudinaryService,
  });

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreateAnnouncementModal(),
    );
  }

  @override
  State<CreateAnnouncementModal> createState() =>
      _CreateAnnouncementModalState();
}

class _CreateAnnouncementModalState extends State<CreateAnnouncementModal> {
  final _formKey = GlobalKey<FormState>();
  final _judulController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _lokasiController = TextEditingController();
  final _linkController = TextEditingController();

  late final AnnouncementService _announcementService;
  late final CloudinaryService _cloudinaryService;

  String _selectedCategory = AnnouncementCategory.allCategories.first.name;
  String _selectedTipe = 'offline'; // 'offline' | 'online'
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);

  PlatformFile? _pickedFile;
  bool _isUploadingPoster = false;
  bool _isSaving = false;
  String? _uploadedPosterUrl;

  // ===== Style Seragam =====
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
    _announcementService = widget.announcementService ?? AnnouncementService();
    _cloudinaryService = widget.cloudinaryService ?? CloudinaryService();
  }

  @override
  void dispose() {
    _judulController.dispose();
    _deskripsiController.dispose();
    _lokasiController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _pickedFile = result.files.first;
          _uploadedPosterUrl = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih file gambar: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesi pengguna tidak valid. Silakan login kembali.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      String? posterUrl = _uploadedPosterUrl;

      if (_pickedFile != null &&
          _pickedFile!.bytes != null &&
          posterUrl == null) {
        setState(() => _isUploadingPoster = true);
        posterUrl = await _cloudinaryService.uploadFile(
          fileBytes: _pickedFile!.bytes!,
          fileName: _pickedFile!.name,
          folder: 'announcements',
        );
        setState(() {
          _isUploadingPoster = false;
          _uploadedPosterUrl = posterUrl;
        });
      }

      final tanggalWaktu = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      await _announcementService.createAnnouncement(
        createdBy: user.uid,
        authorName: user.displayName ?? 'Sekretaris HIMA TI',
        judul: _judulController.text.trim(),
        deskripsi: _deskripsiController.text.trim(),
        kategori: _selectedCategory,
        tipe: _selectedTipe,
        lokasi: _selectedTipe == 'offline'
            ? _lokasiController.text.trim()
            : null,
        linkKegiatan: _selectedTipe == 'online'
            ? _linkController.text.trim()
            : null,
        posterUrl: posterUrl,
        tanggalWaktu: tanggalWaktu,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengumuman berhasil dipublikasikan!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mempublikasikan: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isUploadingPoster = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final categoryObj = AnnouncementCategory.getByName(_selectedCategory);

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      // Menggunakan constraints agar tinggi maksimal 90% dan bisa menyesuaikan keyboard
      constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.9),
      child: Column(
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
                    Icons.campaign_outlined,
                    color: AppTheme.primaryBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Buat Pengumuman',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Disampaikan ke seluruh anggota',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppTheme.borderLight),

          // Form fields
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                // Padding bawah ditambah (32) agar tidak tertutup tombol home indicator
                // Padding bawah juga merespon keyboard (viewInsets)
                padding: EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  24 + mediaQuery.viewInsets.bottom + mediaQuery.padding.bottom,
                ),
                children: [
                  // ... (isi field Judul hingga Deskripsi persis sama seperti sebelumnya) ...

                  // Judul
                  const Text('Judul Pengumuman *', style: _labelStyle),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _judulController,
                    style: _inputTextStyle,
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Judul wajib diisi'
                        : null,
                    decoration: _inputDecoration(
                      'Contoh: Workshop Flutter 2026',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Kategori
                  const Text('Kategori *', style: _labelStyle),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    isDense: true,
                    itemHeight: null,
                    style: _inputTextStyle,
                    decoration: _inputDecoration('Pilih kategori').copyWith(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4, // Kunci dropdown agar sama tinggi
                      ),
                    ),
                    items: AnnouncementCategory.allCategories
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.name,
                            child: Row(
                              children: [
                                Icon(
                                  c.icon,
                                  size: 16,
                                  color: c.gradientColors.first,
                                ),
                                const SizedBox(width: 8),
                                Text(c.name, style: _inputTextStyle),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Banner Preview
                  const Text('Pratinjau Banner Utama', style: _labelStyle),
                  const SizedBox(height: 6),
                  _buildBannerPreview(categoryObj),
                  const SizedBox(height: 16),

                  // Tipe Pelaksanaan
                  const Text('Bentuk Pelaksanaan *', style: _labelStyle),
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
                            label: 'Offline',
                            icon: Icons.location_on_outlined,
                            selected: _selectedTipe == 'offline',
                            onTap: () =>
                                setState(() => _selectedTipe = 'offline'),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _buildTypeChip(
                            label: 'Online',
                            icon: Icons.videocam_outlined,
                            selected: _selectedTipe == 'online',
                            onTap: () =>
                                setState(() => _selectedTipe = 'online'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Lokasi atau Link
                  if (_selectedTipe == 'offline') ...[
                    const Text('Lokasi Pelaksanaan *', style: _labelStyle),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _lokasiController,
                      style: _inputTextStyle,
                      validator: (val) =>
                          _selectedTipe == 'offline' &&
                              (val == null || val.trim().isEmpty)
                          ? 'Lokasi wajib diisi'
                          : null,
                      decoration: _inputDecoration(
                        'Contoh: Ruang Seminar Lt. 4',
                      ),
                    ),
                  ] else ...[
                    const Text('Tautan Kegiatan *', style: _labelStyle),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _linkController,
                      style: _inputTextStyle,
                      keyboardType: TextInputType.url,
                      validator: (val) =>
                          _selectedTipe == 'online' &&
                              (val == null || val.trim().isEmpty)
                          ? 'Tautan wajib diisi'
                          : null,
                      decoration: _inputDecoration(
                        'https://meet.google.com/...',
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Waktu Pelaksanaan
                  const Text('Waktu Pelaksanaan *', style: _labelStyle),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime.now().subtract(
                                const Duration(days: 7),
                              ),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (picked != null)
                              setState(() => _selectedDate = picked);
                          },
                          icon: const Icon(
                            Icons.calendar_today_rounded,
                            size: 14,
                          ),
                          label: Text(
                            '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: _pickerButtonStyle(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: _selectedTime,
                            );
                            if (picked != null)
                              setState(() => _selectedTime = picked);
                          },
                          icon: const Icon(Icons.access_time_rounded, size: 14),
                          label: Text(
                            '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')} WIB',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: _pickerButtonStyle(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Deskripsi
                  const Text('Deskripsi Lengkap *', style: _labelStyle),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _deskripsiController,
                    style: _inputTextStyle,
                    maxLines: 4,
                    minLines: 3,
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Deskripsi wajib diisi'
                        : null,
                    decoration: _inputDecoration(
                      'Tuliskan rincian kegiatan atau info penting...',
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Tombol Publikasikan
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: _isSaving ? null : _submit,
                      label: Text(
                        _isUploadingPoster
                            ? 'Mengunggah...'
                            : _isSaving
                            ? 'Menyimpan...'
                            : 'Publikasikan Pengumuman',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============ HELPER WIDGETS ============

  Widget _buildBannerPreview(AnnouncementCategory category) {
    final primaryColor = category.gradientColors.first;

    return Container(
      width: double.infinity,
      height: 140,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor,
            category.gradientColors.length > 1
                ? category.gradientColors.last
                : primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        children: [
          // Dekorasi Lingkaran
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            right: 40,
            bottom: -30,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          // Konten
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (_pickedFile != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: Colors.white,
                              size: 12,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Pamflet Siap',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        category.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: primaryColor,
                        ),
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _pickFile,
                      icon: Icon(
                        _pickedFile != null
                            ? Icons.edit_rounded
                            : Icons.upload_file_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      label: Text(
                        _pickedFile != null ? 'Ganti Pamflet' : 'Pilih Pamflet',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    if (_pickedFile != null) ...[
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => setState(() => _pickedFile = null),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
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

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: _hintStyle,
      filled: true,
      fillColor: AppTheme.background,
      isDense: false, // <--- UBAH KE FALSE
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14, // <--- Vertikal 14 agar total tinggi ±48px
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
      errorStyle: const TextStyle(fontSize: 11),
    );
  }

  ButtonStyle _pickerButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: AppTheme.textPrimary,
      side: const BorderSide(color: AppTheme.borderLight),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ), // Radius 12 disamakan
      padding: const EdgeInsets.symmetric(vertical: 14), // Samakan vertikalnya
      minimumSize: const Size(0, 44),
    );
  }
}
