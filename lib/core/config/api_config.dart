/// API Configuration for Pockify
/// 
/// To use the video download functionality, you need to:
/// 1. Create a free account at https://rapidapi.com
/// 2. Subscribe to "All in One Video Downloader" API (has free tier)
/// 3. Copy your API key and paste it below
/// 
/// Supported Platforms:
/// - TikTok (videos, no watermark)
/// - Instagram (reels, posts, stories)
/// - Facebook (videos, reels)
/// - Twitter/X (videos)
/// - YouTube (videos)
/// - Pinterest (videos, pins)
/// - Snapchat (stories)
/// - Reddit (videos)
/// - Vimeo (videos)
/// - Dailymotion (videos)

class ApiConfig {
  // ============================================
  // RapidAPI Configuration
  // ============================================
  
  /// Your RapidAPI key - Get it from https://rapidapi.com/developer
  /// Subscribe to "All in One Video Downloader" API (free tier available)
  static const String rapidApiKey = 'YOUR_RAPIDAPI_KEY';
  
  /// RapidAPI Host - Don't change unless using different API
  static const String rapidApiHost = 'all-in-one-video-downloader.p.rapidapi.com';
  
  /// Alternative API endpoints (fallback)
  static const List<Map<String, String>> alternativeApis = [
    {
      'host': 'tiktok-video-no-watermark2.p.rapidapi.com',
      'endpoint': '/video/data',
    },
    {
      'host': 'instagram-downloader-download-instagram-videos-stories.p.rapidapi.com',
      'endpoint': '/instagram',
    },
    {
      'host': 'facebook-reel-and-video-downloader.p.rapidapi.com',
      'endpoint': '/app/main.php',
    },
    {
      'host': 'twitter-downloader-download-twitter-videos-gifs-and-images.p.rapidapi.com', 
      'endpoint': '/twitter/',
    },
  ];
  
  // ============================================
  // App Configuration
  // ============================================
  
  /// Maximum concurrent downloads
  static const int maxConcurrentDownloads = 3;
  
  /// Download retry attempts
  static const int maxRetryAttempts = 3;
  
  /// Connection timeout in seconds
  static const int connectionTimeoutSeconds = 30;
  
  /// Receive timeout in minutes
  static const int receiveTimeoutMinutes = 5;
  
  // ============================================
  // Free User Limits
  // ============================================
  
  /// Maximum daily downloads for free users
  static const int freeUserDailyLimit = 5;
  
  /// Show ad after every N downloads (free users)
  static const int adFrequency = 2;
  
  // ============================================
  // Premium Features
  // ============================================
  
  /// Premium removes watermarks (when supported by API)
  static const bool premiumNoWatermark = true;
  
  /// Premium enables HD quality
  static const bool premiumHdQuality = true;
  
  /// Premium removes ads
  static const bool premiumNoAds = true;
  
  /// Premium unlimited downloads
  static const bool premiumUnlimitedDownloads = true;
  
  // ============================================
  // Check if API is configured
  // ============================================
  
  static bool get isApiConfigured {
    return rapidApiKey.isNotEmpty && 
           rapidApiKey != 'YOUR_RAPIDAPI_KEY' &&
           rapidApiKey.length > 20;
  }
  
  /// Get error message for unconfigured API
  static String get apiNotConfiguredMessage {
    return 'API yapılandırılmamış. Lütfen lib/core/config/api_config.dart dosyasındaki rapidApiKey değerini güncelleyin.';
  }
}
