/// Status siklus hidup tugas pada koleksi `tasks`.
enum TaskStatus {
  todo,
  done;

  /// Nilai string yang tersimpan di Cloud Firestore
  String get firestoreValue {
    switch (this) {
      case TaskStatus.todo:
        return 'todo';
      case TaskStatus.done:
        return 'done';
    }
  }

  /// Label Bahasa Indonesia untuk tampilan antarmuka
  String get label {
    switch (this) {
      case TaskStatus.todo:
        return 'Belum Selesai';
      case TaskStatus.done:
        return 'Selesai';
    }
  }

  /// Parsing nilai Firestore menjadi [TaskStatus].
  /// Mengembalikan `null` jika nilai tidak dikenali.
  static TaskStatus? fromFirestore(String? value) {
    if (value == null) return null;
    switch (value.trim().toLowerCase()) {
      case 'todo':
        return TaskStatus.todo;
      case 'done':
        return TaskStatus.done;
      default:
        return null;
    }
  }
}
