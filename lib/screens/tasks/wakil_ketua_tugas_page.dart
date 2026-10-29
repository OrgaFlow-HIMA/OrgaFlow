import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class WakilKetuaTugasPage extends StatefulWidget {
  const WakilKetuaTugasPage({super.key});

  @override
  State<WakilKetuaTugasPage> createState() => _WakilKetuaTugasPageState();
}

class _WakilKetuaTugasPageState extends State<WakilKetuaTugasPage> {
  int _selectedTab = 0; // 0: Monitoring Divisi, 1: Kendala Masuk

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Memantau progres dan kendala divisi',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 14),
          _buildTabSwitcher(),
          const SizedBox(height: 12),
          _buildFilterBadges(),
          const SizedBox(height: 18),
          _buildSummaryCard(),
          const SizedBox(height: 20),
          _buildDivisiCard(
            icon: Icons.palette_outlined,
            iconColor: const Color(0xFF9333EA),
            iconBg: const Color(0xFFF3E8FF),
            title: 'Kreatif & Multimedia',
            pic: 'Arya Wicaksana',
            statusTag: 'Aktif Berjalan',
            statusBg: const Color(0xFFDCFCE7),
            statusColor: const Color(0xFF16A34A),
            prokerTitle: 'Publikasi TI Fest 2026 & Feed Media Sosial',
            percentage: '82%',
            progressValue: 0.82,
            progressColor: AppTheme.primaryBlue,
          ),
          const SizedBox(height: 14),
          _buildDivisiCard(
            icon: Icons.campaign_outlined,
            iconColor: const Color(0xFFD97706),
            iconBg: const Color(0xFFFEF3C7),
            title: 'Acara & Humas',
            pic: 'Nabila Putri',
            statusTag: 'Perlu Koordinasi',
            statusBg: const Color(0xFFFEF3C7),
            statusColor: const Color(0xFFD97706),
            prokerTitle: 'Timeline Rundown & Sponsorship TI Fest',
            percentage: '65%',
            progressValue: 0.65,
            progressColor: const Color(0xFFD97706),
          ),
          const SizedBox(height: 14),
          _buildDivisiCard(
            icon: Icons.developer_board_rounded,
            iconColor: AppTheme.primaryBlue,
            iconBg: AppTheme.lightBlue,
            title: 'Riset & Teknologi',
            pic: 'Farhan Ramadhan',
            statusTag: 'Sesuai Jadwal',
            statusBg: const Color(0xFFDCFCE7),
            statusColor: const Color(0xFF16A34A),
            prokerTitle: 'Workshop Web Development & Sistem Pemilu HIMA',
            percentage: '90%',
            progressValue: 0.90,
            progressColor: const Color(0xFF16A34A),
          ),
          const SizedBox(height: 14),
          _buildDivisiCard(
            icon: Icons.groups_outlined,
            iconColor: const Color(0xFF0D9488),
            iconBg: const Color(0xFFCCFBF1),
            title: 'Kaderisasi & PSDM',
            pic: 'Dimas Pratama',
            statusTag: 'Tahap Evaluasi',
            statusBg: AppTheme.lightBlue,
            statusColor: AppTheme.primaryBlue,
            prokerTitle: 'LPJ Makrab Maba 2026 & Pelatihan Kepemimpinan',
            percentage: '92%',
            progressValue: 0.92,
            progressColor: AppTheme.primaryBlue,
          ),
          const SizedBox(height: 14),
          _buildDivisiCard(
            icon: Icons.storefront_outlined,
            iconColor: const Color(0xFFEA580C),
            iconBg: const Color(0xFFFFEDD5),
            title: 'Danus & Logistik',
            pic: 'Siti Nurhaliza',
            statusTag: 'Aktif Berjalan',
            statusBg: const Color(0xFFDCFCE7),
            statusColor: const Color(0xFF16A34A),
            prokerTitle: 'Pengadaan Merchandise & Pendanaan TI Fest',
            percentage: '70%',
            progressValue: 0.70,
            progressColor: AppTheme.primaryBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildTabSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.lightBlue.withOpacity(0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _selectedTab == 0
                      ? const Color(0xFF0F2C59)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Monitoring Divisi',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _selectedTab == 0
                            ? Colors.white
                            : AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _selectedTab == 0
                            ? Colors.white.withOpacity(0.2)
                            : AppTheme.surface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '5',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _selectedTab == 0
                              ? Colors.white
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _selectedTab == 1
                      ? const Color(0xFF0F2C59)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Kendala Masuk',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _selectedTab == 1
                            ? Colors.white
                            : AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '2',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _selectedTab == 1
                            ? Colors.white
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBadges() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0F2C59),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Semua Divisi (5)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.fiber_manual_record,
                  size: 8,
                  color: Color(0xFF16A34A),
                ),
                SizedBox(width: 6),
                Text(
                  '5 Aktif Berjalan',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF16A34A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.fiber_manual_record,
                  size: 8,
                  color: Color(0xFFD97706),
                ),
                SizedBox(width: 6),
                Text(
                  '2 Perlu Koordinasi',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFD97706),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0B2545),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RANGKUMAN PROGRES PERIODE INI',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withOpacity(0.7),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        const Text(
                          '78%',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Rata-rata 5 Divisi',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF00A8FF), width: 3),
                ),
                child: const Center(
                  child: Text(
                    '5 Div',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '14 Proker',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Terlaksana Baik',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.assignment_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '2 Laporan',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Perlu Review',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDivisiCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String pic,
    required String statusTag,
    required Color statusBg,
    required Color statusColor,
    required String prokerTitle,
    required String percentage,
    required double progressValue,
    required Color progressColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 20, color: iconColor),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline_rounded,
                            size: 12,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            pic,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.fiber_manual_record,
                      size: 8,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      statusTag,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PROKER AKTIF SAAT INI',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  prokerTitle,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progres Kerja',
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
              Text(
                percentage,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: 6,
              backgroundColor: AppTheme.lightBlue,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {},
              child: const Text(
                'Lihat Detail Progres →',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
