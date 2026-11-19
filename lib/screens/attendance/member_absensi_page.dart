import 'package:flutter/material.dart';

class MemberAbsensiPage extends StatefulWidget {
  final String userName;
  final String divisionName;

  const MemberAbsensiPage({
    super.key,
    this.userName = 'John Doe',
    this.divisionName = 'Divisi PSDM',
  });

  @override
  State<MemberAbsensiPage> createState() => _MemberAbsensiPageState();
}

class _MemberAbsensiPageState extends State<MemberAbsensiPage> {
  int _hadirCount = 11;
  final int _izinCount = 1;
  final int _alpaCount = 0;
  bool _isSessionCheckedIn = false;

  final List _riwayatList = [
    {
      'title': 'Workshop UI/UX Design...',
      'date': '24 Mei 2024',
      'statusDetail': 'Hadir (19:15 WIB)',
      'statusColor': const Color(0xFF15803D),
      'badgeText': 'Terverifikasi',
      'badgeColor': const Color(0xFF15803D),
      'badgeBg': const Color(0xFFDCFCE7),
      'icon': Icons.co_present_outlined,
      'hasSurat': false,
    },
    {
      'title': 'Briefing Panitia TI Fest...',
      'date': '18 Mei 2024',
      'statusDetail': 'Hadir (16:02 WIB)',
      'statusColor': const Color(0xFF15803D),
      'badgeText': 'Terverifikasi',
      'badgeColor': const Color(0xFF15803D),
      'badgeBg': const Color(0xFFDCFCE7),
      'icon': Icons.groups_outlined,
      'hasSurat': false,
    },
    {
      'title': 'Rapat Koordinasi Divisi...',
      'date': '10 Mei 2024',
      'statusDetail': 'Izin (Sakit)',
      'statusColor': const Color(0xFF1D4ED8),
      'badgeText': 'Disetujui',
      'badgeColor': const Color(0xFF1D4ED8),
      'badgeBg': const Color(0xFFDBEAFE),
      'icon': Icons.assignment_late_outlined,
      'hasSurat': true,
    },
  ];

  void _showPinDialog() {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Masukkan 6-Digit Kode PIN',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: pinController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 6,
          ),
          decoration: InputDecoration(
            hintText: '••••••',
            filled: true,
            fillColor: const Color(0xFFF1F5F9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A2463),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              if (pinController.text.length == 6) {
                Navigator.pop(context);
                _markPresensiBerhasil();
              }
            },
            child: const Text(
              'Verifikasi',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _markPresensiBerhasil() {
    if (_isSessionCheckedIn) return;
    setState(() {
      _isSessionCheckedIn = true;
      _hadirCount += 1;
      _riwayatList.insert(0, {
        'title': 'Rapat Pleno & Evaluasi Bulanan...',
        'date': 'Hari Ini',
        'statusDetail': 'Hadir (19:35 WIB)',
        'statusColor': const Color(0xFF15803D),
        'badgeText': 'Terverifikasi',
        'badgeColor': const Color(0xFF15803D),
        'badgeBg': const Color(0xFFDCFCE7),
        'icon': Icons.check_circle_outline_rounded,
        'hasSurat': false,
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Presensi berhasil dicatat!'),
        backgroundColor: Color(0xFF15803D),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int totalSesi = _hadirCount + _izinCount + _alpaCount;
    final int persenHadir = totalSesi > 0
        ? ((_hadirCount / totalSesi) * 100).round()
        : 100;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFF0A2463),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.radio_button_unchecked_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'OrgaFlow',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0A2463),
                    height: 1.1,
                  ),
                ),
                Text(
                  'HIMA TI',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: Color(0xFF1E293B),
                ),
                onPressed: () {},
              ),
              Positioned(
                right: 12,
                top: 14,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDC2626),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFFE0F2FE),
              child: const Icon(
                Icons.person_outline_rounded,
                color: Color(0xFF0284C7),
                size: 18,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sub-header Periode
            Row(
              children: const [
                Icon(
                  Icons.how_to_reg_outlined,
                  size: 15,
                  color: Color(0xFF1D4ED8),
                ),
                SizedBox(width: 6),
                Text(
                  'HIMA TI • Periode 2024/2025',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D4ED8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Absensi & Kehadiran',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0A2463),
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Pencatatan presensi rapat & kegiatan organisasi.',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 18),

            // 1. Kartu Profil & Statistik Kehadiran (Hadir / Izin / Alpa)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEFF6FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_outline_rounded,
                          color: Color(0xFF1D4ED8),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.userName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${widget.divisionName} • Anggota Aktif',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF15803D),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '$persenHadir% Hadir',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF15803D),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildStatBox(
                        'Hadir',
                        '$_hadirCount',
                        const Color(0xFF15803D),
                      ),
                      const SizedBox(width: 10),
                      _buildStatBox(
                        'Izin',
                        '$_izinCount',
                        const Color(0xFF0284C7),
                      ),
                      const SizedBox(width: 10),
                      _buildStatBox(
                        'Alpa',
                        '$_alpaCount',
                        const Color(0xFF64748B),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 2. Kartu Sesi Presensi Aktif
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF16A34A),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'PRESENSI SEDANG BERLANGSUNG',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF15803D),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Sesi Aktif',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Rapat Pleno & Evaluasi Bulanan PSDM',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: const [
                      Icon(
                        Icons.access_time_rounded,
                        size: 15,
                        color: Color(0xFF1D4ED8),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Hari Ini, 19:30 - 21:00 WIB',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: const [
                      Icon(
                        Icons.apartment_rounded,
                        size: 15,
                        color: Color(0xFF1D4ED8),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Ruang Sidang HIMA / Hybrid Meeting',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isSessionCheckedIn
                            ? const Color(0xFF15803D)
                            : const Color(0xFF0A2463),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isSessionCheckedIn
                          ? null
                          : _markPresensiBerhasil,
                      icon: Icon(
                        _isSessionCheckedIn
                            ? Icons.check_circle_rounded
                            : Icons.qr_code_scanner_rounded,
                        size: 18,
                      ),
                      label: Text(
                        _isSessionCheckedIn
                            ? 'Presensi Sudah Tercatat'
                            : 'Scan QR / Isi Presensi Sekarang',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEFF6FF),
                        foregroundColor: const Color(0xFF1D4ED8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isSessionCheckedIn ? null : _showPinDialog,
                      icon: const Icon(Icons.dialpad_rounded, size: 18),
                      label: const Text(
                        'Gunakan 6-Digit Kode PIN',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // 3. Riwayat Presensi Terbaru
            const Text(
              'Riwayat Presensi Terbaru',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            ..._riwayatList.map((item) => _buildRiwayatCard(item)),
            const SizedBox(height: 8),

            // 4. Banner Ketentuan Presensi Digital
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFF1D4ED8),
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ketentuan Presensi Digital',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Presensi hanya dapat diisi saat sesi dibuka oleh sekretaris divisi atau panitia acara. Pastikan izin lokasi (GPS) dan koneksi internet Anda aktif selama sesi verifikasi.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF475569),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String label, String value, Color valueColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: valueColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiwayatCard(Map item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item['icon'], color: const Color(0xFF1D4ED8), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'],
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      item['date'],
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const Text(
                      '  •  ',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    Text(
                      item['statusDetail'],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: item['statusColor'],
                      ),
                    ),
                  ],
                ),
                if (item['hasSurat'] == true) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: const [
                      Icon(
                        Icons.description_outlined,
                        size: 13,
                        color: Color(0xFF1D4ED8),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Lihat Surat Izin',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1D4ED8),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: item['badgeBg'],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              item['badgeText'],
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: item['badgeColor'],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
