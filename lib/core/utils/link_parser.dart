/// Supported social media platforms
enum SocialPlatform { 
  tiktok, 
  instagram, 
  facebook, 
  twitter, 
  youtube,
  pinterest,
  snapchat,
  reddit,
  vimeo,
  dailymotion,
  unknown 
}

class LinkParser {
  /// Platform patterns for URL detection
  static final Map<SocialPlatform, List<String>> _platformPatterns = {
    SocialPlatform.tiktok: ['tiktok.com', 'vm.tiktok.com'],
    SocialPlatform.instagram: ['instagram.com', 'instagr.am'],
    SocialPlatform.facebook: ['facebook.com', 'fb.watch', 'fb.com', 'm.facebook.com'],
    SocialPlatform.twitter: ['twitter.com', 'x.com', 'mobile.twitter.com'],
    SocialPlatform.youtube: ['youtube.com', 'youtu.be', 'm.youtube.com', 'youtube-nocookie.com'],
    SocialPlatform.pinterest: ['pinterest.com', 'pin.it'],
    SocialPlatform.snapchat: ['snapchat.com', 'story.snapchat.com'],
    SocialPlatform.reddit: ['reddit.com', 'redd.it'],
    SocialPlatform.vimeo: ['vimeo.com', 'player.vimeo.com'],
    SocialPlatform.dailymotion: ['dailymotion.com', 'dai.ly'],
  };

  /// Parse URL and detect platform
  static SocialPlatform parse(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return SocialPlatform.unknown;
    
    final host = uri.host.toLowerCase();
    
    for (final entry in _platformPatterns.entries) {
      for (final pattern in entry.value) {
        if (host.contains(pattern)) {
          return entry.key;
        }
      }
    }
    
    return SocialPlatform.unknown;
  }
  
  /// Check if URL is valid and supported
  static bool isValidUrl(String url) {
    return parse(url) != SocialPlatform.unknown;
  }
  
  /// Get platform display name
  static String getDisplayName(SocialPlatform platform) {
    switch (platform) {
      case SocialPlatform.tiktok:
        return 'TikTok';
      case SocialPlatform.instagram:
        return 'Instagram';
      case SocialPlatform.facebook:
        return 'Facebook';
      case SocialPlatform.twitter:
        return 'Twitter/X';
      case SocialPlatform.youtube:
        return 'YouTube';
      case SocialPlatform.pinterest:
        return 'Pinterest';
      case SocialPlatform.snapchat:
        return 'Snapchat';
      case SocialPlatform.reddit:
        return 'Reddit';
      case SocialPlatform.vimeo:
        return 'Vimeo';
      case SocialPlatform.dailymotion:
        return 'Dailymotion';
      case SocialPlatform.unknown:
        return 'Bilinmiyor';
    }
  }
  
  /// Get platform icon/emoji
  static String getIcon(SocialPlatform platform) {
    switch (platform) {
      case SocialPlatform.tiktok:
        return '🎵';
      case SocialPlatform.instagram:
        return '📸';
      case SocialPlatform.facebook:
        return '👤';
      case SocialPlatform.twitter:
        return '🐦';
      case SocialPlatform.youtube:
        return '▶️';
      case SocialPlatform.pinterest:
        return '📌';
      case SocialPlatform.snapchat:
        return '👻';
      case SocialPlatform.reddit:
        return '🔴';
      case SocialPlatform.vimeo:
        return '🎬';
      case SocialPlatform.dailymotion:
        return '📺';
      case SocialPlatform.unknown:
        return '🔗';
    }
  }
  
  /// Get all supported platforms
  static List<SocialPlatform> getSupportedPlatforms() {
    return SocialPlatform.values.where((p) => p != SocialPlatform.unknown).toList();
  }
  
  /// Get platform color (for UI)
  static int getColor(SocialPlatform platform) {
    switch (platform) {
      case SocialPlatform.tiktok:
        return 0xFF000000; // Black
      case SocialPlatform.instagram:
        return 0xFFE4405F; // Pink/Purple gradient
      case SocialPlatform.facebook:
        return 0xFF1877F2; // Facebook Blue
      case SocialPlatform.twitter:
        return 0xFF1DA1F2; // Twitter Blue
      case SocialPlatform.youtube:
        return 0xFFFF0000; // YouTube Red
      case SocialPlatform.pinterest:
        return 0xFFBD081C; // Pinterest Red
      case SocialPlatform.snapchat:
        return 0xFFFFFC00; // Snapchat Yellow
      case SocialPlatform.reddit:
        return 0xFFFF4500; // Reddit Orange
      case SocialPlatform.vimeo:
        return 0xFF1AB7EA; // Vimeo Blue
      case SocialPlatform.dailymotion:
        return 0xFF0066DC; // Dailymotion Blue
      case SocialPlatform.unknown:
        return 0xFF757575; // Grey
    }
  }
}
