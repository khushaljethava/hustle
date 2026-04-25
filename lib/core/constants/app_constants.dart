class AppConstants {
  // App Info
  static const String appName = 'Hustle';
  static const String appTagline = 'Your work. Your time. Your money.';

  // Database
  static const String dbName = 'hustle.db';
  static const int dbVersion = 2;

  // Table Names
  static const String clientsTable = 'clients';
  static const String projectsTable = 'projects';
  static const String tasksTable = 'tasks';
  static const String timeEntriesTable = 'time_entries';
  static const String invoicesTable = 'invoices';
  static const String invoiceItemsTable = 'invoice_items';

  // Shared Prefs Keys
  static const String keyOnboarded = 'onboarded';
  static const String keyDefaultRate = 'default_rate';
  static const String keyCurrency = 'currency';
  static const String keyThemeMode = 'theme_mode';
  static const String keyUserName = 'user_name';
  static const String keyBusinessName = 'business_name';
  static const String keyUserEmail = 'user_email';
  static const String keyOverdueNotifications = 'overdue_notifications';
  static const String keyDefaultTemplate = 'default_invoice_template';

  // Default Values
  static const double defaultHourlyRate = 50.0;
  static const String defaultCurrency = 'USD';

  // Currency Symbols
  static const Map<String, String> currencySymbols = {
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'CAD': 'CA\$',
    'AUD': 'A\$',
    'JPY': '¥',
    'INR': '₹',
    'BRL': 'R\$',
    'MXN': 'MX\$',
    'SGD': 'S\$',
  };

  // Invoice Status
  static const String invoiceDraft = 'draft';
  static const String invoiceSent = 'sent';
  static const String invoicePaid = 'paid';
  static const String invoiceOverdue = 'overdue';

  // Invoice Templates
  static const String templateClassic = 'classic';
  static const String templateModern = 'modern';
  static const String templateMinimal = 'minimal';

  // Recurring Intervals
  static const String recurringWeekly = 'weekly';
  static const String recurringMonthly = 'monthly';
  static const String recurringQuarterly = 'quarterly';

  // Task Status
  static const String taskPending = 'pending';
  static const String taskInProgress = 'in_progress';
  static const String taskCompleted = 'completed';

  // Task Priority
  static const String priorityLow = 'low';
  static const String priorityMedium = 'medium';
  static const String priorityHigh = 'high';
  static const String priorityUrgent = 'urgent';

  // Notification IDs
  static const int timerNotificationId = 1001;
  static const int taskReminderNotificationId = 1002;
  static const int invoiceDueNotificationId = 1003;
  static const int invoiceOverdueBaseId = 2000; // +index per invoice
  static const String notificationChannelId = 'hustle_invoices';
  static const String notificationChannelName = 'Invoice Reminders';

  // In-App Purchase product IDs (must match Google Play Console exactly)
  static const String proMonthlyProductId = 'hustle_pro_monthly';
  static const String proAnnualProductId  = 'hustle_pro_annual';

  // RevenueCat identifiers
  static const String proEntitlementId = 'pro';
  static const String defaultOfferingId = 'default';

  // Pro status persistence key
  static const String keyIsPro = 'is_pro_user';

  // Free tier limits
  static const int freeClientLimit = 3;

  // Support / Developer links
  // TODO: replace with your actual Buy Me a Coffee handle
  static const String buyMeACoffeeUrl = 'https://buymeacoffee.com/yourhandle';

  // Legal
  // TODO: host and replace with your actual URLs
  static const String privacyPolicyUrl = 'https://hustle.app/privacy';
  static const String termsOfServiceUrl = 'https://hustle.app/terms';

  // Share copy
  static const String shareAppMessage =
      'I track my freelance work with Hustle — try it: https://hustle.app';

  // SharedPreferences keys (new)
  static const String keyBiometricLock = 'biometric_lock_enabled';
  static const String keyLogoBase64 = 'invoice_logo_base64';
}
