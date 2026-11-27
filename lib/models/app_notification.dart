import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  task('task', 'Tugas'),
  agenda('agenda', 'Agenda'),
  finance('finance', 'Keuangan'),
  proposal('proposal', 'Pengajuan & Persetujuan'),
  general('general', 'Umum');

  final String value;
  final String label;

  const NotificationType(this.value, this.label);

  static NotificationType fromString(String? val) {
    switch (val?.trim().toLowerCase()) {
      case 'task':
        return NotificationType.task;
      case 'agenda':
        return NotificationType.agenda;
      case 'finance':
        return NotificationType.finance;
      case 'proposal':
        return NotificationType.proposal;
      default:
        return NotificationType.general;
    }
  }
}

enum NotificationTargetType {
  broadcast('broadcast'),
  role('role'),
  user('user');

  final String value;
  const NotificationTargetType(this.value);

  static NotificationTargetType fromString(String? val) {
    switch (val?.trim().toLowerCase()) {
      case 'role':
        return NotificationTargetType.role;
      case 'user':
        return NotificationTargetType.user;
      default:
        return NotificationTargetType.broadcast;
    }
  }
}

class AppNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final NotificationTargetType targetType;
  final String? targetRole;
  final String? targetUserId;
  final String? referenceId; // ID tugas, ID transaksi, ID proposal, ID agenda
  final String createdBy;
  final DateTime createdAt;
  final List<String> readBy;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    this.type = NotificationType.general,
    this.targetType = NotificationTargetType.broadcast,
    this.targetRole,
    this.targetUserId,
    this.referenceId,
    required this.createdBy,
    required this.createdAt,
    this.readBy = const [],
  });

  bool isReadBy(String userId) => readBy.contains(userId);

  factory AppNotification.fromMap(Map<String, dynamic> data, String documentId) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    final readByList = (data['read_by'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        <String>[];

    return AppNotification(
      id: documentId,
      title: (data['title'] as String?)?.trim() ?? 'Pemberitahuan',
      message: (data['message'] as String?)?.trim() ?? '',
      type: NotificationType.fromString(data['type'] as String?),
      targetType: NotificationTargetType.fromString(data['target_type'] as String?),
      targetRole: (data['target_role'] as String?)?.trim(),
      targetUserId: (data['target_user_id'] as String?)?.trim(),
      referenceId: (data['reference_id'] as String?)?.trim(),
      createdBy: (data['created_by'] as String?)?.trim() ?? '',
      createdAt: parseDate(data['created_at']),
      readBy: readByList,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'type': type.value,
      'target_type': targetType.value,
      if (targetRole != null) 'target_role': targetRole,
      if (targetUserId != null) 'target_user_id': targetUserId,
      if (referenceId != null) 'reference_id': referenceId,
      'created_by': createdBy,
      'created_at': Timestamp.fromDate(createdAt),
      'read_by': readBy,
    };
  }
}
