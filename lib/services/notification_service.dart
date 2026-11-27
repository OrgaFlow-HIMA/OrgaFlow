import 'package:cloud_firestore/cloud_firestore.dart';

import '../enums/user_role.dart';
import '../models/app_notification.dart';

class NotificationService {
  final FirebaseFirestore _firestore;

  NotificationService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String notificationCollection = 'notifications';

  CollectionReference<Map<String, dynamic>> get _notificationsRef =>
      _firestore.collection(notificationCollection);

  /// Aliran notifikasi yang relevan untuk pengguna tertentu
  Stream<List<AppNotification>> watchUserNotifications({
    required String userId,
    required UserRole role,
  }) {
    return _notificationsRef.snapshots().map((snapshot) {
      final allNotifs = snapshot.docs
          .map((doc) => AppNotification.fromMap(doc.data(), doc.id))
          .where((notif) {
            if (notif.targetType == NotificationTargetType.broadcast) {
              return true;
            }
            if (notif.targetType == NotificationTargetType.role) {
              if (notif.targetRole == role.firestoreValue) {
                return true;
              }
            }
            if (notif.targetType == NotificationTargetType.user &&
                notif.targetUserId == userId) {
              return true;
            }
            return false;
          })
          .toList();

      // Urutkan dari notifikasi paling baru
      allNotifs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return allNotifs;
    });
  }

  /// Menghitung jumlah notifikasi yang belum dibaca oleh pengguna
  Stream<int> watchUnreadCount({
    required String userId,
    required UserRole role,
  }) {
    return watchUserNotifications(
      userId: userId,
      role: role,
    ).map((notifs) => notifs.where((n) => !n.isReadBy(userId)).length);
  }

  /// Membuat notifikasi baru
  Future<String> createNotification({
    required String title,
    required String message,
    required NotificationType type,
    NotificationTargetType targetType = NotificationTargetType.broadcast,
    String? targetRole,
    String? targetUserId,
    String? referenceId,
    required String createdBy,
  }) async {
    final docRef = await _notificationsRef.add({
      'title': title.trim(),
      'message': message.trim(),
      'type': type.value,
      'target_type': targetType.value,
      if (targetRole != null) 'target_role': targetRole.trim(),
      if (targetUserId != null) 'target_user_id': targetUserId.trim(),
      if (referenceId != null) 'reference_id': referenceId.trim(),
      'created_by': createdBy.trim(),
      'created_at': FieldValue.serverTimestamp(),
      'read_by': <String>[],
    });
    return docRef.id;
  }

  /// Menandai sebuah notifikasi telah dibaca oleh pengguna
  Future<void> markAsRead({
    required String notificationId,
    required String userId,
  }) async {
    await _notificationsRef.doc(notificationId).update({
      'read_by': FieldValue.arrayUnion([userId]),
    });
  }

  /// Menandai seluruh notifikasi yang relevan sebagai sudah dibaca
  Future<void> markAllAsRead({
    required List<AppNotification> notifications,
    required String userId,
  }) async {
    final unread = notifications.where((n) => !n.isReadBy(userId));
    final batch = _firestore.batch();
    for (final notif in unread) {
      final docRef = _notificationsRef.doc(notif.id);
      batch.update(docRef, {
        'read_by': FieldValue.arrayUnion([userId]),
      });
    }
    await batch.commit();
  }

  // =========================================================
  // FITUR HAPUS NOTIFIKASI
  // =========================================================

  /// Menghapus satu notifikasi
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationsRef.doc(notificationId).delete();
    } catch (e) {
      throw Exception('Gagal menghapus notifikasi: $e');
    }
  }

  /// Menghapus banyak notifikasi sekaligus (menggunakan batch)
  Future<void> deleteMultipleNotifications(List<String> notificationIds) async {
    if (notificationIds.isEmpty) return;

    try {
      final batch = _firestore.batch();
      for (final id in notificationIds) {
        batch.delete(_notificationsRef.doc(id));
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Gagal menghapus notifikasi: $e');
    }
  }
}
