class AppConstants {
  static const String appName = 'Pockify';
  static const String appSlogan = 'Favori İçeriklerini Yönet';
  static const String appVersion = '1.0.0';

  // Storage Keys
  static const String boxSettings = 'settings';
  static const String boxDownloads = 'downloads';

  // API Limits
  static const int dailyDownloadLimitFree = 3;
  static const int maxVideoQualityFree = 720;
  static const int maxVideoQualityPremium = 1080;

  // URLs
  static const String privacyPolicyUrl = 'https://pockify.app/privacy';
  static const String termsOfServiceUrl = 'https://pockify.app/terms';
  static const String supportUrl = 'https://pockify.app/support';
  static const String websiteUrl = 'https://pockify.app';
  static const String supportEmail = 'support@pockify.app';

  // App Store URLs
  static const String playStoreUrl = 'https://play.google.com/store/apps/details?id=app.pockify';
  static const String appStoreUrl = 'https://apps.apple.com/app/pockify/id0000000000';

  // Ad Intervals
  static const int adsPerDownloads = 2;
}
