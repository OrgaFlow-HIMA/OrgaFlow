import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/agenda.dart';
import '../../../models/attendance_record.dart';
import '../../../models/user_profile.dart';
import '../../../services/attendance_service.dart';

class ManageAttendanceSheet extends StatefulWidget {
  final Agenda agenda;
  final AttendanceService? attendanceService;

  const ManageAttendanceSheet({
    super.key,
    required this.agenda,
    this.attendanceService,
  });

  @override
  State<ManageAttendanceSheet> createState() => _ManageAttendanceSheetState();
}

class _ManageAttendanceSheetState extends State<ManageAttendanceSheet> {
  late final AttendanceService _attendanceService;
  final TextEditingController _searchController = TextEditingController();

  List<UserProfile> _allUsers = [];
  bool _isLoadingUsers = true;
  String _searchQuery = '';
  final Set<String> _savingUserIds = {};

  @override
  void initState() {
    super.initState();
    _attendanceService = widget.attendanceService ?? AttendanceService();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await _attendanceService.getAttendanceEligibleUsers();
      if (mounted) {
        setState(() {
          _allUsers = users;
          _isLoadingUsers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingUsers = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat daftar peserta: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _changeStatus({
    required UserProfile user,
    required AttendanceStatus newStatus,
  }) async {
    final secretaryUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    setState(() => _savingUserIds.add(user.uid));

    try {
      await _attendanceService.setAttendanceStatus(
        agendaId: widget.agenda.id,
        agendaJudul: widget.agenda.judul,
        user: user,
        status: newStatus,
        secretaryUid: secretaryUid,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengubah absensi ${user.nama}: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _savingUserIds.remove(user.uid));
      }
    }
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          child: Column(
            children: [
              // ===== GRABBER =====
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 14),

              // ===== HEADER =====
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
                        Icons.fact_check_outlined,
                        color: AppTheme.primaryBlue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Kelola Kehadiran',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.agenda.judul,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
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

              // ===== SEARCH =====
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) =>
                      setState(() => _searchQuery = val.trim().toLowerCase()),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Cari nama atau NIM...',
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: AppTheme.textSecondary,
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppTheme.background,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
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
                      borderSide: const BorderSide(
                        color: AppTheme.primaryBlue,
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
              ),

              // ===== LEGEND =====
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 4,
                ),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildLegendItem(
                      'H',
                      'Hadir',
                      const Color(0xFF15803D),
                      const Color(0xFFDCFCE7),
                    ),
                    _buildLegendItem(
                      'I',
                      'Izin',
                      const Color(0xFF1D4ED8),
                      const Color(0xFFDBEAFE),
                    ),
                    _buildLegendItem(
                      'S',
                      'Sakit',
                      const Color(0xFFB45309),
                      const Color(0xFFFEF3C7),
                    ),
                    _buildLegendItem(
                      'A',
                      'Alpha',
                      const Color(0xFFB91C1C),
                      const Color(0xFFFEE2E2),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              // ===== LIST PESERTA =====
              Expanded(
                child: _isLoadingUsers
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 30),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                        ),
                      )
                    : StreamBuilder<List<AttendanceRecord>>(
                        stream: _attendanceService.streamAttendanceForAgenda(
                          widget.agenda.id,
                        ),
                        builder: (context, snapshot) {
                          final records = snapshot.data ?? [];
                          final recordMap = {
                            for (final r in records) r.userId: r.status,
                          };

                          final filteredUsers = _allUsers.where((u) {
                            if (_searchQuery.isEmpty) return true;
                            final matchesName = u.nama.toLowerCase().contains(
                              _searchQuery,
                            );
                            final matchesNim =
                                u.nim?.toLowerCase().contains(_searchQuery) ??
                                false;
                            return matchesName || matchesNim;
                          }).toList();

                          if (filteredUsers.isEmpty) {
                            return _buildEmptyState();
                          }

                          return ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                            itemCount: filteredUsers.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final user = filteredUsers[index];
                              final currentStatus =
                                  recordMap[user.uid] ?? AttendanceStatus.alpha;
                              final isSaving = _savingUserIds.contains(
                                user.uid,
                              );

                              return _buildUserAttendanceRow(
                                user: user,
                                status: currentStatus,
                                isSaving: isSaving,
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // WIDGET HELPERS
  // =========================================================

  Widget _buildLegendItem(
    String code,
    String label,
    Color textColor,
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$code: $label',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppTheme.lightBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 30,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Tidak ada peserta yang cocok',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Coba ubah kata kunci pencarian Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserAttendanceRow({
    required UserProfile user,
    required AttendanceStatus status,
    required bool isSaving,
  }) {
    final initial = user.nama.isNotEmpty ? user.nama[0].toUpperCase() : 'U';
    final subtitle =
        '${user.nim?.isNotEmpty == true ? '${user.nim} • ' : ''}'
        '${user.role.label}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.lightBlue,
            child: Text(
              initial,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryBlue,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Nama & subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.nama,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Tombol status H/I/S/A
          if (isSaving)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatusButton(
                  code: 'H',
                  isSelected: status == AttendanceStatus.hadir,
                  activeColor: const Color(0xFF15803D),
                  activeBg: const Color(0xFFDCFCE7),
                  onTap: () => _changeStatus(
                    user: user,
                    newStatus: AttendanceStatus.hadir,
                  ),
                ),
                const SizedBox(width: 4),
                _buildStatusButton(
                  code: 'I',
                  isSelected: status == AttendanceStatus.izin,
                  activeColor: const Color(0xFF1D4ED8),
                  activeBg: const Color(0xFFDBEAFE),
                  onTap: () => _changeStatus(
                    user: user,
                    newStatus: AttendanceStatus.izin,
                  ),
                ),
                const SizedBox(width: 4),
                _buildStatusButton(
                  code: 'S',
                  isSelected: status == AttendanceStatus.sakit,
                  activeColor: const Color(0xFFB45309),
                  activeBg: const Color(0xFFFEF3C7),
                  onTap: () => _changeStatus(
                    user: user,
                    newStatus: AttendanceStatus.sakit,
                  ),
                ),
                const SizedBox(width: 4),
                _buildStatusButton(
                  code: 'A',
                  isSelected: status == AttendanceStatus.alpha,
                  activeColor: const Color(0xFFB91C1C),
                  activeBg: const Color(0xFFFEE2E2),
                  onTap: () => _changeStatus(
                    user: user,
                    newStatus: AttendanceStatus.alpha,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatusButton({
    required String code,
    required bool isSelected,
    required Color activeColor,
    required Color activeBg,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.white,
          borderRadius: BorderRadius.circular(50), // rounded 50 → kapsul
          border: Border.all(
            color: isSelected ? activeColor : AppTheme.borderLight,
            width: isSelected ? 1.6 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withOpacity(0.18),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          code,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: isSelected ? activeColor : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
