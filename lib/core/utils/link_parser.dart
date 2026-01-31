enum SocialPlatform { tiktok, instagram, unknown }

class LinkParser {
  static SocialPlatform parse(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return SocialPlatform.unknown;
    
    final host = uri.host.toLowerCase();
    
    if (host.contains('tiktok.com')) {
      return SocialPlatform.tiktok;
    } else if (host.contains('instagram.com')) {
      return SocialPlatform.instagram;
    }
    
    return SocialPlatform.unknown;
  }
  
  static bool isValidUrl(String url) {
    return parse(url) != SocialPlatform.unknown;
  }
}
