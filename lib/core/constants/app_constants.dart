class AppConstants {
  AppConstants._();

  static const String appName = 'OrgaFlow';
  static const String appTagline = 'Kelola Organisasi, Satu Alur.';
  static const String organizationName = 'HIMA Teknik Informatika';

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String divisionsCollection = 'divisi';
  static const String tasksCollection = 'tasks';
  static const String agendasCollection = 'agenda';
  static const String financeCollection = 'finance_transactions';
  static const String financePaymentsSubcollection = 'payments';

  // Account Statuses
  static const String statusActive = 'aktif';
  static const String statusInactive = 'nonaktif';
}
