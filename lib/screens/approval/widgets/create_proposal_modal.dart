import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../enums/user_role.dart';
import '../../../models/proposal.dart';
import '../../../models/user_profile.dart';
import '../../../services/cloudinary_service.dart';
import '../../../services/proposal_service.dart';
import '../../../services/task_service.dart';

class CreateProposalModal extends StatefulWidget {
  final UserProfile userProfile;
  final VoidCallback? onCreated;

  const CreateProposalModal({
    super.key,
    required this.userProfile,
    this.onCreated,
  });

  static Future<void> show(
    BuildContext context, {
    required UserProfile userProfile,
    VoidCallback? onCreated,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) =>
          CreateProposalModal(userProfile: userProfile, onCreated: onCreated),
    );
  }

  @override
  State<CreateProposalModal> createState() => _CreateProposalModalState();
}

class _CreateProposalModalState extends State<CreateProposalModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _urlController = TextEditingController();

  ProposalType _selectedType = ProposalType.kegiatan;
  String? _selectedDivisionId;
  String? _selectedDivisionName;
  List<Map<String, String>> _divisions = [];
  bool _isLoadingDivisions = true;

  // File Upload State
  int _documentMethod = 0; // 0: Unggah Berkas, 1: Masukkan Link
  PlatformFile? _pickedFile;
  bool _isUploadingFile = false;
  bool _isSubmitting = false;

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

  // Cek role pengaju
  bool get _isKadiv => widget.userProfile.role == UserRole.kepalaDivisi;
  bool get _isBphNonDivisi =>
      widget.userProfile.role == UserRole.sekretaris ||
      widget.userProfile.role == UserRole.bendahara;

  @override
  void initState() {
    super.initState();
    if (_isBphNonDivisi) {
      // Sekretaris & Bendahara tidak terikat divisi tertentu
      _selectedDivisionId = widget.userProfile.role == UserRole.sekretaris
          ? 'sekretaris'
          : 'bendahara';
      _selectedDivisionName = widget.userProfile.role == UserRole.sekretaris
          ? 'Sekretariat'
          : 'Keuangan (Bendahara)';
      _isLoadingDivisions = false;
    } else if (_isKadiv) {
      // Kadiv otomatis menggunakan divisi miliknya
      _selectedDivisionId = widget.userProfile.divisiId ?? 'umum';
      _loadKadivDivisionName();
    } else {
      _selectedDivisionId =
          (widget.userProfile.divisiId != null &&
              widget.userProfile.divisiId!.isNotEmpty)
          ? widget.userProfile.divisiId!
          : 'umum';
      _loadDivisions();
    }
  }

  Future<void> _loadKadivDivisionName() async {
    try {
      final taskService = TaskService();
      final list = await taskService.getAllDivisions();
      if (mounted) {
        final match = list.firstWhere(
          (d) => d['id'] == _selectedDivisionId,
          orElse: () => {
            'id': _selectedDivisionId ?? 'umum',
            'nama': widget.userProfile.divisiId?.toUpperCase() ?? 'Divisi',
          },
        );
        setState(() {
          _selectedDivisionName = match['nama'];
          _isLoadingDivisions = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _selectedDivisionName =
              widget.userProfile.divisiId?.toUpperCase() ?? 'Divisi';
          _isLoadingDivisions = false;
        });
      }
    }
  }

  Future<void> _loadDivisions() async {
    try {
      final taskService = TaskService();
      final list = await taskService.getAllDivisions();
      if (mounted) {
        setState(() {
          _divisions = list;
          if (_divisions.isEmpty) {
            _divisions = [
              {'id': 'umum', 'nama': 'Umum / Himpunan'},
              {'id': 'bph', 'nama': 'BPH (Badan Pengurus Harian)'},
              {'id': 'medkom', 'nama': 'Media & Komunikasi'},
              {'id': 'psdm', 'nama': 'Pengembangan SDM'},
              {'id': 'litbang', 'nama': 'Penelitian & Pengembangan'},
            ];
          }
          final match = _divisions.firstWhere(
            (d) => d['id'] == _selectedDivisionId,
            orElse: () => _divisions.first,
          );
          _selectedDivisionId = match['id'];
          _selectedDivisionName = match['nama'];
          _isLoadingDivisions = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _divisions = [
            {'id': 'umum', 'nama': 'Umum / Himpunan'},
            {'id': 'bph', 'nama': 'BPH (Badan Pengurus Harian)'},
          ];
          _selectedDivisionId = _divisions.first['id'];
          _selectedDivisionName = _divisions.first['nama'];
          _isLoadingDivisions = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'doc',
          'docx',
          'ppt',
          'pptx',
          'xls',
          'xlsx',
          'png',
          'jpg',
          'jpeg',
        ],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal membaca berkas. Coba pilih berkas lain.'),
              backgroundColor: AppTheme.error,
            ),
          );
          return;
        }

        if (file.size > 15 * 1024 * 1024) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ukuran berkas maksimal 15 MB.'),
              backgroundColor: AppTheme.error,
            ),
          );
          return;
        }

        setState(() => _pickedFile = file);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memilih berkas: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    String? documentUrl;
    String? documentFileName;

    if (_documentMethod == 1) {
      final url = _urlController.text.trim();
      if (url.isNotEmpty) {
        documentUrl = url;
        documentFileName = 'Dokumen Pengajuan (Tautan)';
      }
    }

    setState(() => _isSubmitting = true);

    try {
      if (_documentMethod == 0 && _pickedFile != null) {
        setState(() => _isUploadingFile = true);
        final cloudinary = CloudinaryService();
        final uploaded = await cloudinary.uploadFile(
          fileBytes: _pickedFile!.bytes!,
          fileName: _pickedFile!.name,
          folder: 'orgaflow/proposals',
        );
        documentUrl = uploaded;
        documentFileName = _pickedFile!.name;
        setState(() => _isUploadingFile = false);
      }

      final proposalService = ProposalService();
      await proposalService.createProposal(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        type: _selectedType,
        applicantUid: widget.userProfile.uid,
        applicantName: widget.userProfile.nama,
        applicantRole: widget.userProfile.role.label,
        divisionId: _selectedDivisionId ?? 'umum',
        divisionName: _selectedDivisionName,
        documentUrl: documentUrl,
        documentFileName: documentFileName,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengajuan berhasil dibuat & dikirimkan!'),
            backgroundColor: AppTheme.success,
          ),
        );
        widget.onCreated?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengajukan: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isUploadingFile = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.9),
      child: Padding(
        padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                      Icons.note_add_outlined,
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
                          'Buat Pengajuan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Ajukan kegiatan, dana, atau surat',
                          style: TextStyle(
                            fontSize: 11,
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
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppTheme.borderLight),

            // Form
            Expanded(
              child: SingleChildScrollView(
                // Padding bawah dinamis: 24 standar + safe area iPhone
                padding: EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  24 + mediaQuery.padding.bottom,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Jenis Pengajuan
                      const Text('Jenis Pengajuan *', style: _labelStyle),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<ProposalType>(
                        value: _selectedType,
                        isExpanded: true,
                        isDense: true,
                        itemHeight: null,
                        style: _inputTextStyle,
                        decoration: _inputDecoration('Pilih jenis pengajuan')
                            .copyWith(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 4,
                              ),
                            ),
                        items: ProposalType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type.label, style: _inputTextStyle),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedType = val);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Field Divisi Pengaju:
                      // - Sembunyikan untuk Sekretaris & Bendahara (karena ranah BPH/keuangan/sekretariat umum)
                      // - Untuk Kadiv: Ditampilkan otomatis terkunci (read-only) sesuai divisinya
                      // - Untuk role lain: Pilihan dropdown
                      if (!_isBphNonDivisi) ...[
                        const Text('Divisi Pengaju *', style: _labelStyle),
                        const SizedBox(height: 6),
                        if (_isKadiv)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 13,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.borderLight),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.business_rounded,
                                  size: 16,
                                  color: AppTheme.primaryBlue,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _isLoadingDivisions
                                        ? 'Memuat divisi...'
                                        : (_selectedDivisionName ??
                                              widget.userProfile.divisiId
                                                  ?.toUpperCase() ??
                                              'Divisi Anda'),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.lightBlue,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Otomatis',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.primaryBlue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (_isLoadingDivisions)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: LinearProgressIndicator(minHeight: 2),
                          )
                        else
                          DropdownButtonFormField<String>(
                            value: _selectedDivisionId,
                            isExpanded: true,
                            isDense: true,
                            itemHeight: null,
                            style: _inputTextStyle,
                            decoration: _inputDecoration('Pilih divisi')
                                .copyWith(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 4,
                                  ),
                                ),
                            items: _divisions.map((d) {
                              return DropdownMenuItem(
                                value: d['id'],
                                child: Text(d['nama']!, style: _inputTextStyle),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                final d = _divisions.firstWhere(
                                  (x) => x['id'] == val,
                                );
                                setState(() {
                                  _selectedDivisionId = val;
                                  _selectedDivisionName = d['nama'];
                                });
                              }
                            },
                          ),
                        const SizedBox(height: 16),
                      ],

                      // Judul Pengajuan
                      const Text('Judul Pengajuan *', style: _labelStyle),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _titleController,
                        style: _inputTextStyle,
                        decoration: _inputDecoration(
                          'Misal: Proposal TI Festival 2026',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Judul pengajuan wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Deskripsi
                      const Text('Deskripsi / Catatan *', style: _labelStyle),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _descController,
                        style: _inputTextStyle,
                        maxLines: 5,
                        minLines: 4,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: _inputDecoration(
                          'Jelaskan tujuan, ruang lingkup, atau detail pengajuan...',
                        ).copyWith(alignLabelWithHint: true),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Deskripsi pengajuan wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Dokumen Lampiran
                      const Text('Dokumen Pendukung', style: _labelStyle),
                      const SizedBox(height: 8),

                      // Custom Segmented Tab (Unggah vs Link)
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
                              child: _buildMethodChip(
                                label: 'Unggah Berkas',
                                icon: Icons.upload_file_rounded,
                                selected: _documentMethod == 0,
                                onTap: () =>
                                    setState(() => _documentMethod = 0),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: _buildMethodChip(
                                label: 'Tautan Link',
                                icon: Icons.link_rounded,
                                selected: _documentMethod == 1,
                                onTap: () =>
                                    setState(() => _documentMethod = 1),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Konten Dokumen
                      if (_documentMethod == 0) ...[
                        InkWell(
                          onTap: _pickFile,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: 18,
                              horizontal: 16,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _pickedFile != null
                                    ? AppTheme.success.withOpacity(0.5)
                                    : AppTheme.primaryBlue.withOpacity(0.3),
                                width: 1.2,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  _pickedFile != null
                                      ? Icons.check_circle_rounded
                                      : Icons.cloud_upload_outlined,
                                  size: 32,
                                  color: _pickedFile != null
                                      ? AppTheme.success
                                      : AppTheme.primaryBlue,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _pickedFile != null
                                      ? _pickedFile!.name
                                      : 'Pilih berkas proposal/surat',
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _pickedFile != null
                                        ? AppTheme.textPrimary
                                        : AppTheme.primaryBlue,
                                  ),
                                ),
                                if (_pickedFile != null)
                                  Text(
                                    '${(_pickedFile!.size / (1024 * 1024)).toStringAsFixed(2)} MB',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ] else ...[
                        TextFormField(
                          controller: _urlController,
                          style: _inputTextStyle,
                          keyboardType: TextInputType.url,
                          decoration:
                              _inputDecoration(
                                'https://docs.google.com/document/d/...',
                              ).copyWith(
                                prefixIcon: const Icon(
                                  Icons.link_rounded,
                                  size: 20,
                                  color: AppTheme.primaryBlue,
                                ),
                                prefixIconConstraints: const BoxConstraints(
                                  minWidth: 44,
                                  minHeight: 44,
                                ),
                              ),
                        ),
                      ],

                      const SizedBox(height: 28),

                      // Tombol Submit
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton.icon(
                          onPressed: _isSubmitting ? null : _handleSubmit,
                          label: Text(
                            _isUploadingFile
                                ? 'Mengunggah Berkas...'
                                : _isSubmitting
                                ? 'Mengirimkan...'
                                : 'Kirim Pengajuan',
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
            ),
          ],
        ),
      ),
    );
  }

  // ============ HELPER WIDGETS ============

  Widget _buildMethodChip({
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
      isDense: false, // Kunci tinggi field
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
