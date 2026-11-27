/// Status siklus hidup tugas pada koleksi `tasks`.
enum TaskStatus {
  pendingDelegation, // Baru dibuat Sekretaris, belum didelegasikan Kadiv
  todo,              // Sudah ditugaskan ke anggota tertentu, dalam pengerjaan
  submitted,         // Anggota sudah mengunggah hasil tugas (menunggu konfirmasi Kadiv)
  done;              // Kadiv telah menyetujui hasil tugas (selesai tuntas)

  /// Nilai string yang tersimpan di Cloud Firestore
  String get firestoreValue {
    switch (this) {
      case TaskStatus.pendingDelegation:
        return 'pending_delegation';
      case TaskStatus.todo:
        return 'todo';
      case TaskStatus.submitted:
        return 'submitted';
      case TaskStatus.done:
        return 'done';
    }
  }

  /// Label Bahasa Indonesia untuk tampilan antarmuka
  String get label {
    switch (this) {
      case TaskStatus.pendingDelegation:
        return 'Perlu Didelegasikan';
      case TaskStatus.todo:
        return 'Dalam Pengerjaan';
      case TaskStatus.submitted:
        return 'Menunggu Konfirmasi';
      case TaskStatus.done:
        return 'Selesai';
    }
  }

  /// Parsing nilai Firestore menjadi [TaskStatus].
  static TaskStatus? fromFirestore(String? value) {
    if (value == null) return null;
    switch (value.trim().toLowerCase()) {
      case 'pending_delegation':
      case 'draft':
        return TaskStatus.pendingDelegation;
      case 'todo':
        return TaskStatus.todo;
      case 'submitted':
        return TaskStatus.submitted;
      case 'done':
        return TaskStatus.done;
      default:
        return null;
    }
  }
}
