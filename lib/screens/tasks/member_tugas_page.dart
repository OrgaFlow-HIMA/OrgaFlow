import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class MemberTugasPage extends StatefulWidget {
  const MemberTugasPage({super.key});

  @override
  State<MemberTugasPage> createState() => _MemberTugasPageState();
}

class _MemberTugasPageState extends State<MemberTugasPage> {
  int _selectedFilter = 0; // 0: Semua, 1: Berjalan, 2: Selesai

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tugas Saya',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Pantau dan selesaikan tugas yang didelegasikan kepada Anda',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 18),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Semua Tugas', 0),
                const SizedBox(width: 8),
                _buildFilterChip('Sedang Berjalan', 1),
                const SizedBox(width: 8),
                _buildFilterChip('Selesai', 2),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Tugas List
          _buildTaskCard(
            title: 'Mempersiapkan Materi Workshop Flutter',
            divisi: 'Divisi Riset & Teknologi',
            tenggat: 'Besok, 18:00 WIB',
            status: 'Sedang Berjalan',
            statusColor: AppTheme.primaryBlue,
            statusBg: AppTheme.lightBlue,
            priority: 'Prioritas Tinggi',
          ),
          const SizedBox(height: 12),
          _buildTaskCard(
            title: 'Membuat Desain Banner Penyambutan Maba',
            divisi: 'Divisi Media & Informasi',
            tenggat: '3 Hari lagi',
            status: 'Sedang Berjalan',
            statusColor: AppTheme.warning,
            statusBg: AppTheme.warningBg,
            priority: 'Prioritas Sedang',
          ),
          const SizedBox(height: 12),
          _buildTaskCard(
            title: 'Notulensi Rapat Pleno 1',
            divisi: 'Sekretariat',
            tenggat: 'Selesai 25 Mei',
            status: 'Selesai',
            statusColor: AppTheme.success,
            statusBg: AppTheme.successBg,
            priority: 'Selesai',
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int index) {
    final isSelected = _selectedFilter == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.anggotaPrimary : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.anggotaPrimary : AppTheme.borderLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard({
    required String title,
    required String divisi,
    required String tenggat,
    required String status,
    required Color statusColor,
    required Color statusBg,
    required String priority,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            divisi,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: AppTheme.textMuted,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    tenggat,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              Text(
                priority,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

