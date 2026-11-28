/// Helper utilitas untuk standardisasi format penamaan divisi resmi di OrgaFlow.
/// Organisasi resmi hanya memiliki 3 divisi:
/// 1. PSDM (Pengembangan Sumber Daya Mahasiswa)
/// 2. Medkom (Media & Komunikasi)
/// 3. Ristek (Riset & Teknologi)
class DivisionHelper {
  const DivisionHelper._();

  /// Mendapatkan nama pendek divisi resmi ("PSDM", "Medkom", "Ristek")
  static String getShortName(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '-';
    final trimmed = raw.trim();
    final lower = trimmed.toLowerCase();

    if (lower == 'ristek' ||
        lower.contains('riset') ||
        lower.contains('teknologi') ||
        lower.contains('iptek')) {
      return 'Ristek';
    }
    if (lower == 'medkom' ||
        lower.contains('media') ||
        lower.contains('komunikasi') ||
        lower.contains('kreatif') ||
        lower.contains('multimedia')) {
      return 'Medkom';
    }
    if (lower == 'psdm' ||
        lower.contains('sumber daya') ||
        lower.contains('kaderisasi')) {
      return 'PSDM';
    }

    // Jika sudah format rapi kapital, kembalikan langsung
    if (trimmed.length <= 6) {
      return trimmed.toUpperCase();
    }
    return trimmed;
  }

  /// Mendapatkan nama panjang resmi divisi (Contoh: "Divisi Riset & Teknologi (Ristek)")
  static String getFullName(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'Divisi belum ditentukan';
    final trimmed = raw.trim();
    final lower = trimmed.toLowerCase();

    if (lower == 'ristek' ||
        lower.contains('riset') ||
        lower.contains('teknologi') ||
        lower.contains('iptek')) {
      return 'Divisi Riset & Teknologi (Ristek)';
    }
    if (lower == 'medkom' ||
        lower.contains('media') ||
        lower.contains('komunikasi') ||
        lower.contains('kreatif') ||
        lower.contains('multimedia')) {
      return 'Divisi Media & Komunikasi (Medkom)';
    }
    if (lower == 'psdm' ||
        lower.contains('sumber daya') ||
        lower.contains('kaderisasi')) {
      return 'Divisi Pengembangan Sumber Daya Mahasiswa (PSDM)';
    }

    if (!trimmed.toLowerCase().startsWith('divisi ')) {
      return 'Divisi $trimmed';
    }
    return trimmed;
  }
}
