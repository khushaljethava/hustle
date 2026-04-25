class PurchasesConfig {
  static String get androidApiKey => const String.fromEnvironment(
        'REVENUECAT_ANDROID_KEY',
        defaultValue: 'goog_bxILNJbDdfTLgnhoedChbNJfsCl',
      );

  static String get iosApiKey => const String.fromEnvironment(
        'REVENUECAT_IOS_KEY',
        defaultValue: 'YOUR_IOS_KEY_HERE',
      );
}
