import 'package:flutter/material.dart';

class MemberPengumumanPage extends StatefulWidget {
  final String userName;
  final String divisionName;

  const MemberPengumumanPage({
    super.key,
    this.userName = 'John Doe',
    this.divisionName = 'Divisi PSDM',
  });

  @override
  State<MemberPengumumanPage> createState() => _MemberPengumumanPageState();
}

class _MemberPengumumanPageState extends State<MemberPengumumanPage> {
  int _selectedFilter = 0; // 0: Semua, 1: Penting / Mendesak, 2: Divisi
  String _searchQuery = '';
  bool _isPlenoConfirmed = false;

  final List _otherAnnouncements = [
    {
      'category': 'Divisi PSDM',
      'categoryColor': const Color(0xFF0284C7),
      'categoryBg': const Color(0xFFE0F2FE),
      'time': 'Kemarin, 20:15 WIB',
      'title': 'Pendaftaran Panitia Pelatihan Softskill & Kaderisasi Maba',
      'author': 'Oleh: Kadiv PSDM (Kak Reza)',
      'summary': 'Open recruitment panitia kaderisasi telah dibuka sampai tanggal 30 Mei 2024. Posisi terbuka: Acara, Humas, Perlengkapan, dan PDD.',
      'fullContent': 'Open recruitment panitia Pelatihan Softskill & Kaderisasi Mahasiswa Baru 2024 resmi dibuka hingga 30 Mei 2024 pukul 23:59 WIB. Posisi yang dibuka meliputi Divisi Acara, Humas, Perlengkapan, Konsumsi, dan PDD. Segera daftarkan diri melalui koordinator PSDM.',
      'footerType': 'avatars',
      'isImportant': false,
      'isDivision': true,
    },
    {
      'category': 'Umum & Dana',
      'categoryColor': const Color(0xFF1D4ED8),
      'categoryBg': const Color(0xFFDBEAFE),
      'time': '22 Mei 2024',
      'title': 'Batas Akhir Pembayaran Iuran Kas Periode Mei 2024',
      'author': 'Oleh: Bendahara Umum',
      'summary': 'Mengingatkan kembali bagi anggota yang belum menyelesaikan iuran kas bulanan sebesar Rp20.000 sebelum akhir bulan.',
      'fullContent': 'Mengingatkan kembali kepada seluruh pengurus dan anggota aktif HIMA TI yang belum menyelesaikan pembayaran iuran kas bulanan periode Mei 2024 sebesar Rp20.000 agar segera melakukan pembayaran melalui menu Kas sebelum tanggal 31 Mei 2024.',
      'footerType': 'nominal',
      'footerText': 'Nominal: Rp20.000',
      'isImportant': false,
      'isDivision': false,
    },
    {
      'category': 'Akademik',
      'categoryColor': const Color(0xFF475569),
      'categoryBg': const Color(0xFFF1F5F9),
      'time': '18 Mei 2024',
      'title': 'Jadwal Ujian Akhir Semester & Dispensasi Kegiatan HIMA',
      'author': 'Oleh: Humas & Advokasi',
      'summary': 'Formulir permohonan surat izin dispensasi untuk anggota panitia kegiatan HIMA TI dapat diakses melalui tautan resmi.',
      'fullContent': 'Sehubungan dengan dimulainya pekan Ujian Akhir Semester (UAS), seluruh kegiatan internal HIMA TI akan disesuaikan jadwalnya. Bagi panitia yang membutuhkan surat dispensasi kuliah, silakan mengisi formulir permohonan maksimal H-3 kegiatan.',
      'footerType': 'link',
      'footerText': 'Formulir Online',
      'isImportant': false,
      'isDivision': false,
    },
  ];

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'JD';
  }

  List get _filteredAnnouncements {
    return _otherAnnouncements.where((item) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          item['title'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          item['summary'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );

      if (!matchesSearch) return false;
      if (_selectedFilter == 1) return item['isImportant'] == true;
      if (_selectedFilter == 2) return item['isDivision'] == true;
      return true;
    }).toList();
  }

  void _showDetailModal({
    required String badge,
    required String title,
    required String author,
    required String time,
    required String content,
    bool showConfirmButton = false,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDBEAFE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D4ED8),
                      ),
                    ),
                  ),
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                author,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0284C7),
                ),
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 14),
              Text(
                content,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF334155),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: showConfirmButton && !_isPlenoConfirmed
                        ? const Color(0xFF0A2463)
                        : const Color(0xFF15803D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    if (showConfirmButton) {
                      setState(() => _isPlenoConfirmed = true);
                    }
                    Navigator.pop(context);
                    if (showConfirmButton) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Konfirmasi kehadiran rapat tercatat!'),
                          backgroundColor: Color(0xFF15803D),
                        ),
                      );
                    }
                  },
                  child: Text(
                    showConfirmButton
                        ? (_isPlenoConfirmed
                              ? 'Sudah Dikonfirmasi ✓'
                              : 'Konfirmasi Membaca & Hadir')
                        : 'Tutup Edaran',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool showFeaturedCard =
        (_selectedFilter == 0 || _selectedFilter == 1) &&
        (_searchQuery.isEmpty ||
            'pelaksanaan rapat pleno semester genap & laporan progres divisi'
                .contains(_searchQuery.toLowerCase()));

    final filteredList = _filteredAnnouncements;

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
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
              child: Text(
                _getInitials(widget.userName),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0284C7),
                ),
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
            // Sub-header Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.campaign_outlined,
                    size: 14,
                    color: Color(0xFF1D4ED8),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'HIMA TI • Periode 2024/2025',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1D4ED8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pengumuman',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Informasi & edaran resmi pengurus organisasi.',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 18),

            // 1. Kartu Profil & Ringkasan Edaran (Semua / Penting / Divisi)
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
                      CircleAvatar(
                        radius: 21,
                        backgroundColor: const Color(0xFFE0F2FE),
                        child: Text(
                          _getInitials(widget.userName),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0284C7),
                          ),
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
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.circle,
                              size: 6,
                              color: Color(0xFF0284C7),
                            ),
                            SizedBox(width: 5),
                            Text(
                              '3 Edaran Baru',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0284C7),
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
                      _buildCounterBox(
                        '4',
                        'Semua',
                        const Color(0xFF0F172A),
                        const Color(0xFFF8FAFC),
                      ),
                      const SizedBox(width: 10),
                      _buildCounterBox(
                        '1',
                        'Penting',
                        const Color(0xFFDC2626),
                        const Color(0xFFFEF2F2),
                      ),
                      const SizedBox(width: 10),
                      _buildCounterBox(
                        '2',
                        'Divisi',
                        const Color(0xFF0284C7),
                        const Color(0xFFF0F9FF),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Search Bar
            TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Cari edaran atau topik...',
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF94A3B8),
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF64748B),
                  size: 20,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 3. Filter Pills (Semua | Penting / Mendesak | Divisi PSDM)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterPill('Semua', 0),
                  const SizedBox(width: 8),
                  _buildFilterPill('Penting / Mendesak', 1, hasDot: true),
                  const SizedBox(width: 8),
                  _buildFilterPill(widget.divisionName, 2),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 4. Featured Card: Penting dari BPH
            if (showFeaturedCard) ...[
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Garis gradien merah-biru di atas kartu
                    Container(
                      height: 4,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFDC2626), Color(0xFF0A2463)],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.priority_high_rounded,
                                      size: 12,
                                      color: Color(0xFFDC2626),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'PENTING • DARI BPH',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFFDC2626),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Row(
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 13,
                                    color: Color(0xFF64748B),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Hari ini, 14:00 WIB',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Pelaksanaan Rapat Pleno Semester Genap & Laporan Progres Divisi',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Oleh: Sekretaris Umum • HIMA TI',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0284C7),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Diberitahukan kepada seluruh anggota aktif HIMA TI untuk menghadiri Rapat Pleno evaluasi tengah semester yang akan dilaksanakan pada Aula...',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF475569),
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 14),
                          // Kotak Lampiran PDF
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEE2E2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.description_outlined,
                                    color: Color(0xFFDC2626),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Surat_Edaran_Pleno.pdf',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        '1.2 MB • Surat Keputusan',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.download_rounded,
                                    color: Color(0xFF1D4ED8),
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Mengunduh Surat_Edaran_Pleno.pdf...',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isPlenoConfirmed
                                    ? const Color(0xFF15803D)
                                    : const Color(0xFF0A2463),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => _showDetailModal(
                                badge: 'PENTING • DARI BPH',
                                title: 'Pelaksanaan Rapat Pleno Semester Genap & Laporan Progres Divisi',
                                author: 'Oleh: Sekretaris Umum • HIMA TI',
                                time: 'Hari ini, 14:00 WIB',
                                content: 'Diberitahukan kepada seluruh anggota aktif HIMA TI untuk menghadiri Rapat Pleno evaluasi tengah semester yang akan dilaksanakan pada Aula Gedung Teknik Lt. 3 pukul 19:00 WIB. Setiap divisi wajib menyiapkan laporan progres program kerja.',
                                showConfirmButton: true,
                              ),
                              icon: Icon(
                                _isPlenoConfirmed
                                    ? Icons.check_circle_rounded
                                    : Icons.arrow_forward_rounded,
                                size: 18,
                              ),
                              label: Text(
                                _isPlenoConfirmed
                                    ? 'Edaran Sudah Dikonfirmasi'
                                    : 'Baca Selengkapnya & Konfirmasi',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
            ],

            // 5. Header Edaran Terbaru
            if (filteredList.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Edaran Terbaru',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    '${filteredList.length} pengumuman aktif',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...filteredList.map((item) => _buildAnnouncementCard(item)),
            ],

            const SizedBox(height: 8),

            // 6. Banner Ketentuan & Informasi Pengumuman
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                          'Ketentuan & Informasi Pengumuman',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Pengumuman resmi diterbitkan langsung oleh BPH dan Pengurus HIMA TI. Seluruh anggota wajib membaca dan menindaklanjuti instruksi edaran divisi masing-masing.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF475569),
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCounterBox(
    String count,
    String label,
    Color textColor,
    Color bgColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              count,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textColor == const Color(0xFF0F172A)
                    ? const Color(0xFF64748B)
                    : textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill(String label, int index, {bool hasDot = false}) {
    final bool isSelected = _selectedFilter == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0A2463) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0A2463)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            if (hasDot) ...[
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Color(0xFFDC2626),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementCard(Map item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
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
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: item['categoryBg'],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  item['category'],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: item['categoryColor'],
                  ),
                ),
              ),
              Text(
                item['time'],
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item['title'],
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item['author'],
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0284C7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item['summary'],
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF475569),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (item['footerType'] == 'avatars')
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 12,
                      backgroundColor: Color(0xFFDBEAFE),
                      child: Icon(
                        Icons.person,
                        size: 14,
                        color: Color(0xFF1D4ED8),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '+8',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Icon(
                      item['footerType'] == 'nominal'
                          ? Icons.payments_outlined
                          : Icons.link_rounded,
                      size: 15,
                      color: const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item['footerText'] ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              GestureDetector(
                onTap: () => _showDetailModal(
                  badge: item['category'],
                  title: item['title'],
                  author: item['author'],
                  time: item['time'],
                  content: item['fullContent'],
                ),
                child: const Row(
                  children: [
                    Text(
                      'Lihat Detail',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D4ED8),
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: Color(0xFF1D4ED8),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
