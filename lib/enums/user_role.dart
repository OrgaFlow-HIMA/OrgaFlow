/// Definisi enam role resmi dalam organisasi OrgaFlow (HIMA TI).
/// Tidak ada role ketujuh bernama Admin.
enum UserRole {
  ketua,
  wakilKetua,
  sekretaris,
  bendahara,
  kepalaDivisi,
  anggota;

  /// Nilai string yang tersimpan di Cloud Firestore
  String get firestoreValue {
    switch (this) {
      case UserRole.ketua:
        return 'ketua';
      case UserRole.wakilKetua:
        return 'wakil_ketua';
      case UserRole.sekretaris:
        return 'sekretaris';
      case UserRole.bendahara:
        return 'bendahara';
      case UserRole.kepalaDivisi:
        return 'kepala_divisi';
      case UserRole.anggota:
        return 'anggota';
    }
  }

  /// Label resmi dalam Bahasa Indonesia untuk tampilan antarmuka
  String get label {
    switch (this) {
      case UserRole.ketua:
        return 'Ketua';
      case UserRole.wakilKetua:
        return 'Wakil Ketua';
      case UserRole.sekretaris:
        return 'Sekretaris';
      case UserRole.bendahara:
        return 'Bendahara';
      case UserRole.kepalaDivisi:
        return 'Kepala Divisi';
      case UserRole.anggota:
        return 'Anggota';
    }
  }

  /// Menentukan apakah role ini termasuk dalam kelompok Pengurus
  bool get isPengurus => this != UserRole.anggota;

  /// Menentukan apakah role ini adalah Anggota biasa
  bool get isAnggota => this == UserRole.anggota;

  /// Label kelompok pengguna untuk badge header
  String get groupBadgeLabel => isPengurus ? 'PENGURUS' : 'ANGGOTA';

  /// Parsing nilai dari Firestore menjadi [UserRole].
  /// Mengembalikan `null` jika nilai tidak cocok dengan enam role resmi.
  /// CATATAN PENTING: Role tidak dikenal TIDAK BOLEH dialihkan menjadi anggota atau diberikan akses default.
  static UserRole? fromFirestore(String? value) {
    if (value == null) return null;
    final normalized = value.trim().toLowerCase();
    switch (normalized) {
      case 'ketua':
        return UserRole.ketua;
      case 'wakil_ketua':
      case 'wakil ketua':
      case 'wakil-ketua':
      case 'wakilketua':
        return UserRole.wakilKetua;
      case 'sekretaris':
        return UserRole.sekretaris;
      case 'bendahara':
        return UserRole.bendahara;
      case 'kepala_divisi':
      case 'kepala divisi':
      case 'kepala-divisi':
      case 'kepaladivisi':
      case 'kadiv':
        return UserRole.kepalaDivisi;
      case 'anggota':
        return UserRole.anggota;
      default:
        return null;
    }
  }
}
