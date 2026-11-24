import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AnnouncementCategory {
  final String name;
  final IconData icon;
  final List<Color> gradientColors;

  const AnnouncementCategory({
    required this.name,
    required this.icon,
    required this.gradientColors,
  });

  static const List<AnnouncementCategory> allCategories = [
    AnnouncementCategory(
      name: 'Workshop & Pelatihan',
      icon: Icons.build_circle_outlined,
      gradientColors: [Color(0xFF0284C7), Color(0xFF06B6D4)],
    ),
    AnnouncementCategory(
      name: 'Seminar & Webinar',
      icon: Icons.co_present_outlined,
      gradientColors: [Color(0xFF4F46E5), Color(0xFF3B82F6)],
    ),
    AnnouncementCategory(
      name: 'Kompetisi & Prestasi',
      icon: Icons.emoji_events_outlined,
      gradientColors: [Color(0xFFD97706), Color(0xFFF59E0B)],
    ),
    AnnouncementCategory(
      name: 'Akademik',
      icon: Icons.school_outlined,
      gradientColors: [Color(0xFF059669), Color(0xFF10B981)],
    ),
    AnnouncementCategory(
      name: 'Kegiatan Himpunan',
      icon: Icons.groups_outlined,
      gradientColors: [Color(0xFFEA580C), Color(0xFFF97316)],
    ),
    AnnouncementCategory(
      name: 'Open Recruitment',
      icon: Icons.person_add_alt_1_outlined,
      gradientColors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
    ),
    AnnouncementCategory(
      name: 'Kepanitiaan',
      icon: Icons.assignment_ind_outlined,
      gradientColors: [Color(0xFFE11D48), Color(0xFFF43F5E)],
    ),
    AnnouncementCategory(
      name: 'Pengabdian Masyarakat',
      icon: Icons.volunteer_activism_outlined,
      gradientColors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
    ),
    AnnouncementCategory(
      name: 'Administrasi & Pendataan',
      icon: Icons.folder_shared_outlined,
      gradientColors: [Color(0xFF475569), Color(0xFF64748B)],
    ),
    AnnouncementCategory(
      name: 'Informasi Umum',
      icon: Icons.info_outline_rounded,
      gradientColors: [Color(0xFF0A2463), Color(0xFF3E92CC)],
    ),
  ];

  static AnnouncementCategory getByName(String? name) {
    return allCategories.firstWhere(
      (c) => c.name.toLowerCase() == (name ?? '').trim().toLowerCase(),
      orElse: () => allCategories.last,
    );
  }
}

class Announcement {
  final String id;
  final String judul;
  final String deskripsi;
  final String kategori;
  final String tipe; // 'online' atau 'offline'
  final String? lokasi;
  final String? linkKegiatan;
  final String? posterUrl;
  final DateTime tanggalWaktu;
  final String createdBy;
  final String? authorName;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Announcement({
    required this.id,
    required this.judul,
    required this.deskripsi,
    required this.kategori,
    required this.tipe,
    this.lokasi,
    this.linkKegiatan,
    this.posterUrl,
    required this.tanggalWaktu,
    required this.createdBy,
    this.authorName,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isOnline => tipe.trim().toLowerCase() == 'online';
  bool get hasPoster => posterUrl != null && posterUrl!.trim().isNotEmpty;

  AnnouncementCategory get categoryDetails =>
      AnnouncementCategory.getByName(kategori);

  String get formattedDateTime {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final day = tanggalWaktu.day;
    final month = months[tanggalWaktu.month - 1];
    final year = tanggalWaktu.year;
    final hour = tanggalWaktu.hour.toString().padLeft(2, '0');
    final minute = tanggalWaktu.minute.toString().padLeft(2, '0');

    return '$day $month $year • $hour:$minute WIB';
  }

  factory Announcement.fromMap(Map<String, dynamic> data, String documentId) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return Announcement(
      id: documentId,
      judul: (data['judul'] as String?)?.trim() ?? 'Pengumuman Tanpa Judul',
      deskripsi: (data['deskripsi'] as String?)?.trim() ?? '',
      kategori: (data['kategori'] as String?)?.trim() ?? 'Informasi Umum',
      tipe: (data['tipe'] as String?)?.trim().toLowerCase() ?? 'offline',
      lokasi: (data['lokasi'] as String?)?.trim(),
      linkKegiatan: (data['link_kegiatan'] as String?)?.trim(),
      posterUrl: (data['poster_url'] as String?)?.trim(),
      tanggalWaktu: parseDate(data['tanggal_waktu']),
      createdBy: (data['created_by'] as String?)?.trim() ?? '',
      authorName: (data['author_name'] as String?)?.trim(),
      createdAt: parseDate(data['created_at']),
      updatedAt: data['updated_at'] != null ? parseDate(data['updated_at']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'judul': judul,
      'deskripsi': deskripsi,
      'kategori': kategori,
      'tipe': tipe,
      if (lokasi != null) 'lokasi': lokasi,
      if (linkKegiatan != null) 'link_kegiatan': linkKegiatan,
      if (posterUrl != null) 'poster_url': posterUrl,
      'tanggal_waktu': Timestamp.fromDate(tanggalWaktu),
      'created_by': createdBy,
      if (authorName != null) 'author_name': authorName,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': FieldValue.serverTimestamp(),
    };
  }
}
