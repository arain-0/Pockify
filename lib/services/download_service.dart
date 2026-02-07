import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/video_model.dart';
import '../models/download_model.dart';
import '../core/utils/link_parser.dart';
import '../core/config/api_config.dart';
import 'storage_service.dart';

typedef ProgressCallback = void Function(int received, int total);

class DownloadService {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: Duration(seconds: ApiConfig.connectionTimeoutSeconds),
    receiveTimeout: Duration(minutes: ApiConfig.receiveTimeoutMinutes),
    followRedirects: true,
    maxRedirects: 5,
    validateStatus: (status) => status != null && status < 500,
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    },
  ));

  final StorageService _storageService = StorageService();

  // Pockify Custom API (Google Cloud Run)
  static const String _pockifyApiUrl = 'https://pockify-api-643314832062.us-central1.run.app';

  // Fallback Cobalt API instances
  static const List<String> _cobaltInstances = [
    'https://api.cobalt.tools',
    'https://cobalt-api.kwiatekmiki.com',
  ];

  // Active downloads tracking
  final Map<String, CancelToken> _activeDownloads = {};

  /// Detect platform from URL
  String detectPlatform(String url) {
    final platform = LinkParser.parse(url);
    return platform.name;
  }

  /// Check if URL is supported
  bool isUrlSupported(String url) {
    return LinkParser.isValidUrl(url);
  }

  /// Add retry logic
  Future<T> _retryWithBackoff<T>(Future<T> Function() operation, {int maxAttempts = 3}) async {
    int attempts = 0;
    Exception? lastError;
    
    while (attempts < maxAttempts) {
      try {
        return await operation();
      } catch (e) {
        attempts++;
        lastError = e is Exception ? e : Exception(e.toString());
        print('DownloadService: Attempt $attempts failed: $e');
        if (attempts >= maxAttempts) break;
        await Future.delayed(Duration(seconds: attempts * 2));
      }
    }
    throw lastError ?? Exception('İçerik kaydedilemedi. Lütfen tekrar deneyin.');
  }

  /// Process a social media link and get video information
  /// Client-side approach: API calls from user's device (not blocked by platforms)
  Future<VideoModel?> processLink(String url) async {
    print('DownloadService: Processing link: $url');

    final platform = LinkParser.parse(url);
    if (platform == SocialPlatform.unknown) {
      throw Exception('Desteklenmeyen platform. YouTube, TikTok, Instagram veya Twitter linki girin.');
    }
    print('DownloadService: Platform detected: ${platform.name}');

    // Client-side API calls (user's IP - not blocked!)

    // TikTok - TikWM API (very reliable from client)
    if (platform == SocialPlatform.tiktok) {
      final tikTokResult = await _fetchTikTokVideo(url);
      if (tikTokResult != null) return tikTokResult;
    }

    // Instagram - Multiple APIs
    if (platform == SocialPlatform.instagram) {
      final instaResult = await _fetchInstagramVideo(url);
      if (instaResult != null) return instaResult;
    }

    // Facebook
    if (platform == SocialPlatform.facebook) {
      final fbResult = await _fetchFacebookVideo(url);
      if (fbResult != null) return fbResult;
    }

    // Twitter
    if (platform == SocialPlatform.twitter) {
      final twitterResult = await _fetchTwitterVideo(url);
      if (twitterResult != null) return twitterResult;
    }

    // YouTube - Try client-side APIs first (user's IP not blocked)
    if (platform == SocialPlatform.youtube) {
      final youtubeResult = await _fetchYouTubeVideo(url);
      if (youtubeResult != null) return youtubeResult;

      // Fallback to Pockify API
      final pockifyResult = await _fetchFromPockifyApi(url, platform.name);
      if (pockifyResult != null) return pockifyResult;
    }

    // Reddit/Vimeo - Use Cloud Run API
    if (platform == SocialPlatform.reddit ||
        platform == SocialPlatform.vimeo) {
      final pockifyResult = await _fetchFromPockifyApi(url, platform.name);
      if (pockifyResult != null) return pockifyResult;
    }

    // Fallback: try Cobalt for remaining platforms
    final cobaltResult = await _fetchFromCobalt(url, platform);
    if (cobaltResult != null) return cobaltResult;

    throw Exception('İçerik bilgisi alınamadı. Lütfen linki kontrol edin ve tekrar deneyin.');
  }

  /// Fetch video using Pockify Custom API (Google Cloud Run)
  Future<VideoModel?> _fetchFromPockifyApi(String url, String platform) async {
    try {
      print('DownloadService: Using Pockify API');

      final response = await _dio.get(
        '$_pockifyApiUrl/api/video',
        queryParameters: {'url': url},
        options: Options(
          headers: {
            'Accept': 'application/json',
          },
        ),
      );

      print('DownloadService: Pockify API Response: ${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;

        if (data['success'] == true) {
          final downloadUrl = data['download_url'] as String?;

          if (downloadUrl != null && downloadUrl.isNotEmpty) {
            print('DownloadService: Pockify API download URL found');
            return VideoModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              url: url,
              title: data['title'] ?? _generateTitle(platform),
              thumbnail: data['thumbnail'],
              downloadUrl: downloadUrl,
              dateAdded: DateTime.now(),
              platform: platform,
            );
          }
        } else {
          print('DownloadService: Pockify API error: ${data['error']}');
        }
      }
    } catch (e) {
      print('DownloadService: Pockify API error: $e');
    }

    return null;
  }

  /// Fetch TikTok video using TikWM API (most reliable for TikTok)
  Future<VideoModel?> _fetchTikTokVideo(String url) async {
    try {
      print('DownloadService: Using TikWM API for TikTok');
      
      final response = await _dio.post(
        'https://www.tikwm.com/api/',
        data: {'url': url, 'hd': 1},
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      print('DownloadService: TikWM Response code: ${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        print('DownloadService: TikWM data code: ${data['code']}');
        
        if (data['code'] == 0 && data['data'] != null) {
          final videoData = data['data'];
          
          // HD play first, fallback to normal play
          String? downloadUrl = videoData['hdplay'];
          if (downloadUrl == null || downloadUrl.isEmpty) {
            downloadUrl = videoData['play'];
          }
          
          if (downloadUrl != null && downloadUrl.isNotEmpty) {
            print('DownloadService: TikTok download URL found');
            return VideoModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              url: url,
              title: videoData['title'] ?? _generateTitle('tiktok'),
              thumbnail: videoData['cover'] ?? videoData['origin_cover'],
              downloadUrl: downloadUrl,
              dateAdded: DateTime.now(),
              platform: 'tiktok',
            );
          }
        }
      }
    } catch (e) {
      print('DownloadService: TikWM error: $e');
    }

    // Method 2: Try SSSTik API
    try {
      print('DownloadService: Using SSSTik API');

      final response = await _dio.post(
        'https://ssstik.io/abc',
        queryParameters: {'url': 'dl'},
        data: {'id': url, 'locale': 'en', 'tt': 'cXBRNkVo'},
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {
            'User-Agent': 'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36',
            'Origin': 'https://ssstik.io',
            'Referer': 'https://ssstik.io/',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final htmlData = response.data.toString();
        // Parse for download link
        final videoMatch = RegExp(r'href="(https://[^"]+)" class="pure-button[^"]*without_watermark').firstMatch(htmlData);
        if (videoMatch != null) {
          final downloadUrl = videoMatch.group(1);
          if (downloadUrl != null) {
            print('DownloadService: SSSTik URL found');
            return VideoModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              url: url,
              title: _generateTitle('tiktok'),
              thumbnail: null,
              downloadUrl: downloadUrl,
              dateAdded: DateTime.now(),
              platform: 'tiktok',
            );
          }
        }
      }
    } catch (e) {
      print('DownloadService: SSSTik error: $e');
    }

    // Method 3: Try SnapTik API
    try {
      print('DownloadService: Using SnapTik API');

      final response = await _dio.post(
        'https://snaptik.app/abc2.php',
        data: {'url': url, 'lang': 'en'},
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {
            'User-Agent': 'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36',
            'Origin': 'https://snaptik.app',
            'Referer': 'https://snaptik.app/',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final htmlData = response.data.toString();
        // Parse for download link
        final videoMatch = RegExp(r'"(https://[^"]*tikcdn[^"]*\.mp4[^"]*)"').firstMatch(htmlData);
        if (videoMatch != null) {
          var downloadUrl = videoMatch.group(1);
          if (downloadUrl != null) {
            downloadUrl = downloadUrl.replaceAll(r'\/', '/');
            print('DownloadService: SnapTik URL found');
            return VideoModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              url: url,
              title: _generateTitle('tiktok'),
              thumbnail: null,
              downloadUrl: downloadUrl,
              dateAdded: DateTime.now(),
              platform: 'tiktok',
            );
          }
        }
      }
    } catch (e) {
      print('DownloadService: SnapTik error: $e');
    }

    return null;
  }

  /// Fetch YouTube video using client-side APIs
  Future<VideoModel?> _fetchYouTubeVideo(String url) async {
    // Extract video ID from URL
    String? videoId;
    final uri = Uri.tryParse(url);
    if (uri != null) {
      if (uri.host.contains('youtu.be')) {
        videoId = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
      } else if (uri.host.contains('youtube.com')) {
        videoId = uri.queryParameters['v'];
        // Handle shorts
        if (videoId == null && uri.pathSegments.contains('shorts')) {
          final shortsIndex = uri.pathSegments.indexOf('shorts');
          if (shortsIndex + 1 < uri.pathSegments.length) {
            videoId = uri.pathSegments[shortsIndex + 1];
          }
        }
      }
    }

    if (videoId == null || videoId.isEmpty) {
      print('DownloadService: Could not extract YouTube video ID');
      return null;
    }

    print('DownloadService: YouTube video ID: $videoId');

    // Invidious public instances (open source YouTube frontend)
    final invidiousInstances = [
      'https://inv.nadeko.net',
      'https://invidious.nerdvpn.de',
      'https://invidious.privacyredirect.com',
      'https://vid.puffyan.us',
    ];

    // Method 1: Try Invidious API (most reliable for YouTube)
    for (final instance in invidiousInstances) {
      try {
        print('DownloadService: Trying Invidious instance: $instance');

        final response = await _dio.get(
          '$instance/api/v1/videos/$videoId',
          options: Options(
            headers: {
              'User-Agent': 'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36',
              'Accept': 'application/json',
            },
            validateStatus: (status) => status != null && status < 500,
          ),
        );

        if (response.statusCode == 200 && response.data != null) {
          final data = response.data;

          // Get format streams (combined audio+video)
          final formatStreams = data['formatStreams'] as List?;
          if (formatStreams != null && formatStreams.isNotEmpty) {
            // Sort by quality and get best MP4
            String? downloadUrl;
            String? quality;

            for (var fmt in formatStreams) {
              if (fmt['container'] == 'mp4' && fmt['url'] != null) {
                downloadUrl = fmt['url'];
                quality = fmt['qualityLabel'];
                break;
              }
            }

            if (downloadUrl != null) {
              print('DownloadService: Invidious URL found ($quality)');
              return VideoModel(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                url: url,
                title: data['title'] ?? _generateTitle('youtube'),
                thumbnail: 'https://i.ytimg.com/vi/$videoId/maxresdefault.jpg',
                downloadUrl: downloadUrl,
                dateAdded: DateTime.now(),
                platform: 'youtube',
              );
            }
          }
        }
      } catch (e) {
        print('DownloadService: Invidious error ($instance): $e');
        continue;
      }
    }

    // Method 2: Try Piped API (another open source YouTube frontend)
    final pipedInstances = [
      'https://pipedapi.kavin.rocks',
      'https://api.piped.privacydev.net',
      'https://pipedapi.r4fo.com',
    ];

    for (final instance in pipedInstances) {
      try {
        print('DownloadService: Trying Piped instance: $instance');

        final response = await _dio.get(
          '$instance/streams/$videoId',
          options: Options(
            headers: {
              'User-Agent': 'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36',
              'Accept': 'application/json',
            },
            validateStatus: (status) => status != null && status < 500,
          ),
        );

        if (response.statusCode == 200 && response.data != null) {
          final data = response.data;

          // Get video streams
          final videoStreams = data['videoStreams'] as List?;
          if (videoStreams != null && videoStreams.isNotEmpty) {
            // Find best quality with both audio and video
            String? downloadUrl;

            for (var stream in videoStreams) {
              if (stream['mimeType']?.contains('video/mp4') == true &&
                  stream['videoOnly'] != true &&
                  stream['url'] != null) {
                downloadUrl = stream['url'];
                break;
              }
            }

            // If no combined stream, try video only
            if (downloadUrl == null) {
              for (var stream in videoStreams) {
                if (stream['mimeType']?.contains('video/mp4') == true &&
                    stream['url'] != null) {
                  downloadUrl = stream['url'];
                  break;
                }
              }
            }

            if (downloadUrl != null) {
              print('DownloadService: Piped URL found');
              return VideoModel(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                url: url,
                title: data['title'] ?? _generateTitle('youtube'),
                thumbnail: data['thumbnailUrl'] ?? 'https://i.ytimg.com/vi/$videoId/maxresdefault.jpg',
                downloadUrl: downloadUrl,
                dateAdded: DateTime.now(),
                platform: 'youtube',
              );
            }
          }
        }
      } catch (e) {
        print('DownloadService: Piped error ($instance): $e');
        continue;
      }
    }

    return null;
  }

  /// Fetch video using RapidAPI (works for all platforms)
  Future<VideoModel?> _fetchFromRapidAPI(String url, String platform) async {
    if (!ApiConfig.isApiConfigured) {
      print('DownloadService: RapidAPI not configured');
      return null;
    }

    try {
      print('DownloadService: Using RapidAPI for $platform');

      final response = await _dio.get(
        'https://${ApiConfig.rapidApiHost}/download',
        queryParameters: {'url': url},
        options: Options(
          headers: {
            'X-RapidAPI-Key': ApiConfig.rapidApiKey,
            'X-RapidAPI-Host': ApiConfig.rapidApiHost,
          },
        ),
      );

      print('DownloadService: RapidAPI Response code: ${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        print('DownloadService: RapidAPI data: $data');

        // Extract download URL from response
        String? downloadUrl;
        String? title;
        String? thumbnail;

        // Handle different response formats
        if (data is Map) {
          // Try common fields
          downloadUrl = data['url'] ??
                       data['video'] ??
                       data['download_url'] ??
                       data['link'] ??
                       data['hd'] ??
                       data['sd'];

          // Try nested structures
          if (downloadUrl == null && data['medias'] != null) {
            final medias = data['medias'] as List?;
            if (medias != null && medias.isNotEmpty) {
              final media = medias.first;
              downloadUrl = media['url'] ?? media['video'];
            }
          }

          if (downloadUrl == null && data['links'] != null) {
            final links = data['links'];
            if (links is List && links.isNotEmpty) {
              downloadUrl = links.first['url'] ?? links.first['link'];
            } else if (links is Map) {
              downloadUrl = links['download_url'] ?? links['url'];
            }
          }

          title = data['title'] ?? data['name'] ?? data['caption'];
          thumbnail = data['thumbnail'] ?? data['cover'] ?? data['thumb'];
        }

        if (downloadUrl != null && downloadUrl.isNotEmpty) {
          print('DownloadService: RapidAPI download URL found');
          return VideoModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            url: url,
            title: title ?? _generateTitle(platform),
            thumbnail: thumbnail,
            downloadUrl: downloadUrl,
            dateAdded: DateTime.now(),
            platform: platform,
          );
        }
      }
    } catch (e) {
      print('DownloadService: RapidAPI error: $e');
    }

    return null;
  }

  /// Fetch Instagram video using multiple client-side APIs
  Future<VideoModel?> _fetchInstagramVideo(String url) async {
    // Clean URL - remove query params
    String cleanUrl = url.split('?').first;
    if (!cleanUrl.endsWith('/')) cleanUrl += '/';

    // Extract shortcode from URL
    String? shortcode;
    final reelMatch = RegExp(r'/reel/([^/]+)').firstMatch(cleanUrl);
    final pMatch = RegExp(r'/p/([^/]+)').firstMatch(cleanUrl);
    shortcode = reelMatch?.group(1) ?? pMatch?.group(1);

    // Method 1: Instagram Direct JSON API (flutter_insta method - works from user's device!)
    // This uses Instagram's hidden JSON endpoint that returns video_url
    try {
      print('DownloadService: Using Instagram Direct JSON API');

      // Build the JSON endpoint URL
      final jsonUrl = '${cleanUrl}?__a=1&__d=dis';

      final response = await _dio.get(
        jsonUrl,
        options: Options(
          validateStatus: (status) => status != null && status < 500,
          headers: {
            'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
            'Accept': 'application/json, text/plain, */*',
            'Accept-Language': 'en-US,en;q=0.9',
            'X-Requested-With': 'XMLHttpRequest',
            'Sec-Fetch-Site': 'same-origin',
            'Sec-Fetch-Mode': 'cors',
          },
          followRedirects: true,
        ),
      );

      print('DownloadService: Instagram JSON response status: ${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        dynamic data = response.data;

        // Parse JSON if string
        if (data is String) {
          try {
            data = jsonDecode(data);
          } catch (e) {
            print('DownloadService: Failed to parse JSON: $e');
          }
        }

        if (data is Map) {
          // Try graphql path (older format)
          String? videoUrl;
          String? thumbnail;
          String? title;

          // Path 1: graphql > shortcode_media > video_url
          if (data['graphql'] != null && data['graphql']['shortcode_media'] != null) {
            final media = data['graphql']['shortcode_media'];
            videoUrl = media['video_url'];
            thumbnail = media['thumbnail_src'] ?? media['display_url'];
            title = media['title'] ?? media['accessibility_caption'];
            print('DownloadService: Found video via graphql path');
          }

          // Path 2: items[0] > video_versions
          if (videoUrl == null && data['items'] != null && data['items'] is List) {
            final items = data['items'] as List;
            if (items.isNotEmpty) {
              final item = items[0];
              if (item['video_versions'] != null && item['video_versions'] is List) {
                final versions = item['video_versions'] as List;
                if (versions.isNotEmpty) {
                  videoUrl = versions[0]['url'];
                  print('DownloadService: Found video via items path');
                }
              }
              thumbnail = item['image_versions2']?['candidates']?[0]?['url'];
              title = item['caption']?['text'];
            }
          }

          // Path 3: Direct video_url in root
          if (videoUrl == null) {
            videoUrl = data['video_url'];
          }

          if (videoUrl != null && videoUrl.isNotEmpty) {
            print('DownloadService: Instagram JSON API success');
            return VideoModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              url: url,
              title: title ?? _generateTitle('instagram'),
              thumbnail: thumbnail,
              downloadUrl: videoUrl,
              dateAdded: DateTime.now(),
              platform: 'instagram',
            );
          }
        }
      }
    } catch (e) {
      print('DownloadService: Instagram JSON API error: $e');
    }

    // Method 2: DDInstagram (open source proxy)
    if (shortcode != null) {
      try {
        print('DownloadService: Using DDInstagram for $shortcode');

        final response = await _dio.get(
          'https://d.ddinstagram.com/reel/$shortcode',
          options: Options(
            followRedirects: true,
            validateStatus: (status) => status != null && status < 500,
            headers: {
              'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15',
              'Accept': 'text/html,*/*',
            },
          ),
        );

        if (response.statusCode == 200 && response.data != null) {
          final htmlData = response.data.toString();
          // Find video source tag
          final videoMatch = RegExp(r'<source[^>]+src="([^"]+)"[^>]+type="video').firstMatch(htmlData);
          if (videoMatch != null) {
            final downloadUrl = videoMatch.group(1);
            if (downloadUrl != null) {
              print('DownloadService: DDInstagram URL found');
              return VideoModel(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                url: url,
                title: _generateTitle('instagram'),
                thumbnail: null,
                downloadUrl: downloadUrl,
                dateAdded: DateTime.now(),
                platform: 'instagram',
              );
            }
          }
          // Try finding in video tag directly
          final videoSrcMatch = RegExp(r'<video[^>]+src="([^"]+)"').firstMatch(htmlData);
          if (videoSrcMatch != null) {
            final downloadUrl = videoSrcMatch.group(1);
            if (downloadUrl != null && downloadUrl.contains('.mp4')) {
              print('DownloadService: DDInstagram video src found');
              return VideoModel(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                url: url,
                title: _generateTitle('instagram'),
                thumbnail: null,
                downloadUrl: downloadUrl,
                dateAdded: DateTime.now(),
                platform: 'instagram',
              );
            }
          }
        }
      } catch (e) {
        print('DownloadService: DDInstagram error: $e');
      }
    }

    // Method 3: Try Pockify API (has yt-dlp fallback)
    print('DownloadService: Trying Pockify API for Instagram');
    final pockifyResult = await _fetchFromPockifyApi(url, 'instagram');
    if (pockifyResult != null) return pockifyResult;

    // Method 4: Try iGram.world API
    try {
      print('DownloadService: Using iGram API');

      final response = await _dio.post(
        'https://api.igram.world/api/convert',
        data: {'url': cleanUrl},
        options: Options(
          headers: {
            'User-Agent': 'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Origin': 'https://igram.world',
            'Referer': 'https://igram.world/',
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is List && data.isNotEmpty) {
          for (var item in data) {
            if (item['url'] != null) {
              final downloadUrl = item['url'] as String;
              if (downloadUrl.contains('.mp4') || item['type'] == 'video') {
                print('DownloadService: iGram URL found');
                return VideoModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  url: url,
                  title: _generateTitle('instagram'),
                  thumbnail: item['thumbnail'],
                  downloadUrl: downloadUrl,
                  dateAdded: DateTime.now(),
                  platform: 'instagram',
                );
              }
            }
          }
        }
      }
    } catch (e) {
      print('DownloadService: iGram error: $e');
    }

    // Method 4: Try SaveInsta API
    try {
      print('DownloadService: Using SaveInsta API');

      final response = await _dio.post(
        'https://v3.saveinsta.app/api/ajaxSearch',
        data: {'q': cleanUrl, 't': 'media', 'lang': 'en'},
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {
            'User-Agent': 'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36',
            'Origin': 'https://saveinsta.app',
            'Referer': 'https://saveinsta.app/',
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['status'] == 'ok' && data['data'] != null) {
          final htmlData = data['data'].toString();
          // Parse for video URL
          final videoMatch = RegExp(r'href="(https://[^"]+\.mp4[^"]*)"').firstMatch(htmlData);
          if (videoMatch != null) {
            var downloadUrl = videoMatch.group(1);
            if (downloadUrl != null) {
              downloadUrl = downloadUrl.replaceAll('&amp;', '&');
              print('DownloadService: SaveInsta URL found');
              return VideoModel(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                url: url,
                title: _generateTitle('instagram'),
                thumbnail: null,
                downloadUrl: downloadUrl,
                dateAdded: DateTime.now(),
                platform: 'instagram',
              );
            }
          }
        }
      }
    } catch (e) {
      print('DownloadService: SaveInsta error: $e');
    }

    // Method 3: Try DDInstagram (embeds)
    if (shortcode != null) {
      try {
        print('DownloadService: Using DDInstagram');

        final response = await _dio.get(
          'https://www.ddinstagram.com/videos/$shortcode/1',
          options: Options(
            followRedirects: false,
            validateStatus: (status) => status != null && status < 400,
            headers: {
              'User-Agent': 'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36',
            },
          ),
        );

        // Check for redirect URL
        if (response.statusCode == 302 || response.statusCode == 301) {
          final redirectUrl = response.headers['location']?.first;
          if (redirectUrl != null && redirectUrl.contains('.mp4')) {
            print('DownloadService: DDInstagram URL found');
            return VideoModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              url: url,
              title: _generateTitle('instagram'),
              thumbnail: null,
              downloadUrl: redirectUrl,
              dateAdded: DateTime.now(),
              platform: 'instagram',
            );
          }
        }
      } catch (e) {
        print('DownloadService: DDInstagram error: $e');
      }
    }

    // Method 4: Try SnapInsta API (backup)
    try {
      print('DownloadService: Using SnapInsta API');

      final response = await _dio.post(
        'https://snapinsta.app/action2.php',
        data: {'url': cleanUrl},
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {
            'User-Agent': 'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36',
            'Origin': 'https://snapinsta.app',
            'Referer': 'https://snapinsta.app/',
            'Accept': '*/*',
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final htmlData = response.data.toString();
        // Look for video download links
        final videoMatch = RegExp(r'href="(https://[^"]*scontent[^"]*\.mp4[^"]*)"').firstMatch(htmlData);
        if (videoMatch != null) {
          var downloadUrl = videoMatch.group(1);
          if (downloadUrl != null) {
            // Decode HTML entities
            downloadUrl = downloadUrl.replaceAll('&amp;', '&');
            print('DownloadService: SnapInsta URL found');
            return VideoModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              url: url,
              title: _generateTitle('instagram'),
              thumbnail: null,
              downloadUrl: downloadUrl,
              dateAdded: DateTime.now(),
              platform: 'instagram',
            );
          }
        }
      }
    } catch (e) {
      print('DownloadService: SnapInsta error: $e');
    }

    // Method 5: Try FastDl API
    try {
      print('DownloadService: Using FastDl API');

      final response = await _dio.post(
        'https://fastdl.app/api/convert',
        data: {'url': url},
        options: Options(
          headers: {
            'User-Agent': 'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36',
            'Accept': 'application/json',
            'Origin': 'https://fastdl.app',
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map && data['url'] != null) {
          final downloadUrl = data['url'] as String?;
          if (downloadUrl != null && downloadUrl.isNotEmpty) {
            print('DownloadService: FastDl URL found');
            return VideoModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              url: url,
              title: data['title'] ?? _generateTitle('instagram'),
              thumbnail: data['thumbnail'],
              downloadUrl: downloadUrl,
              dateAdded: DateTime.now(),
              platform: 'instagram',
            );
          }
        }
      }
    } catch (e) {
      print('DownloadService: FastDl error: $e');
    }

    // Method 6: Try older hosted API
    try {
      print('DownloadService: Using Instagram Reel API');

      final response = await _dio.get(
        'https://instagram-reel-api.onrender.com',
        queryParameters: {'url': url},
        options: Options(
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          },
        ),
      );

      print('DownloadService: Instagram Reel API Response: ${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        print('DownloadService: Instagram API data: $data');

        // Extract download_link from response
        String? downloadUrl = data['download_link'];
        String? title = data['title'] ?? data['description'];
        String? thumbnail = data['thumbnail'];

        if (downloadUrl != null && downloadUrl.isNotEmpty) {
          print('DownloadService: Instagram download URL found');
          return VideoModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            url: url,
            title: title ?? _generateTitle('instagram'),
            thumbnail: thumbnail,
            downloadUrl: downloadUrl,
            dateAdded: DateTime.now(),
            platform: 'instagram',
          );
        }
      }
    } catch (e) {
      print('DownloadService: Instagram Reel API error: $e');
    }

    // Last resort: RapidAPI
    return await _fetchFromRapidAPI(url, 'instagram');
  }

  /// Fetch Facebook video using client-side APIs
  Future<VideoModel?> _fetchFacebookVideo(String url) async {
    // Method 1: Try fbdown API
    try {
      print('DownloadService: Using FBDown API');

      final response = await _dio.post(
        'https://fbdown.net/download.php',
        data: {'URLz': url},
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {
            'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)',
            'Origin': 'https://fbdown.net',
            'Referer': 'https://fbdown.net/',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final htmlData = response.data.toString();
        // Parse for HD or SD video URL
        var videoMatch = RegExp(r'href="(https://[^"]+)" id="hdlink"').firstMatch(htmlData);
        videoMatch ??= RegExp(r'href="(https://[^"]+)" id="sdlink"').firstMatch(htmlData);

        if (videoMatch != null) {
          final downloadUrl = videoMatch.group(1);
          if (downloadUrl != null) {
            print('DownloadService: FBDown URL found');
            return VideoModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              url: url,
              title: _generateTitle('facebook'),
              thumbnail: null,
              downloadUrl: downloadUrl,
              dateAdded: DateTime.now(),
              platform: 'facebook',
            );
          }
        }
      }
    } catch (e) {
      print('DownloadService: FBDown error: $e');
    }

    // Fallback: Try Pockify API (yt-dlp for Facebook)
    print('DownloadService: Trying Pockify API for Facebook');
    final pockifyResult = await _fetchFromPockifyApi(url, 'facebook');
    if (pockifyResult != null) return pockifyResult;

    // Last resort: RapidAPI
    return await _fetchFromRapidAPI(url, 'facebook');
  }

  /// Fetch Twitter video using client-side APIs
  Future<VideoModel?> _fetchTwitterVideo(String url) async {
    // Method 1: Try twitsave API
    try {
      print('DownloadService: Using TwitSave API');

      final response = await _dio.post(
        'https://twitsave.com/info',
        data: {'id': url},
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {
            'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)',
            'Origin': 'https://twitsave.com',
            'Referer': 'https://twitsave.com/',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final htmlData = response.data.toString();
        // Parse for video URL
        final videoMatch = RegExp(r'href="(https://[^"]+\.mp4[^"]*)"').firstMatch(htmlData);
        if (videoMatch != null) {
          final downloadUrl = videoMatch.group(1);
          if (downloadUrl != null) {
            print('DownloadService: TwitSave URL found');
            return VideoModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              url: url,
              title: _generateTitle('twitter'),
              thumbnail: null,
              downloadUrl: downloadUrl,
              dateAdded: DateTime.now(),
              platform: 'twitter',
            );
          }
        }
      }
    } catch (e) {
      print('DownloadService: TwitSave error: $e');
    }

    // Method 2: Try ssstwitter API
    try {
      print('DownloadService: Using sssTwitter API');

      final response = await _dio.post(
        'https://ssstwitter.com/api/get-video',
        data: {'url': url},
        options: Options(
          headers: {
            'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        String? downloadUrl = data['url'] ?? data['video_url'] ?? data['download_url'];
        if (downloadUrl != null && downloadUrl.isNotEmpty) {
          print('DownloadService: sssTwitter URL found');
          return VideoModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            url: url,
            title: data['title'] ?? _generateTitle('twitter'),
            thumbnail: data['thumbnail'],
            downloadUrl: downloadUrl,
            dateAdded: DateTime.now(),
            platform: 'twitter',
          );
        }
      }
    } catch (e) {
      print('DownloadService: sssTwitter error: $e');
    }

    // Fallback: Try Pockify API (yt-dlp for Twitter)
    print('DownloadService: Trying Pockify API for Twitter');
    final pockifyResult = await _fetchFromPockifyApi(url, 'twitter');
    if (pockifyResult != null) return pockifyResult;

    // Last resort: RapidAPI
    return await _fetchFromRapidAPI(url, 'twitter');
  }

  /// Fetch video from Cobalt instances (works for multiple platforms)
  Future<VideoModel?> _fetchFromCobalt(String url, SocialPlatform platform) async {
    for (final instance in _cobaltInstances) {
      try {
        print('DownloadService: Trying Cobalt instance: $instance');

        final response = await _dio.post(
          '$instance/api/json',
          data: jsonEncode({'url': url}),
          options: Options(
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            validateStatus: (status) => status != null && status < 500,
          ),
        );

        print('DownloadService: Cobalt response status: ${response.statusCode}');

        if (response.statusCode == 200 && response.data != null) {
          final data = response.data;
          print('DownloadService: Cobalt response: ${data['status']}');

          // Handle stream/redirect response (new format)
          if (data['status'] == 'stream' || data['status'] == 'redirect' || data['status'] == 'tunnel') {
            final downloadUrl = data['url'] as String?;
            if (downloadUrl != null && downloadUrl.isNotEmpty) {
              print('DownloadService: Cobalt URL found');
              return VideoModel(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                url: url,
                title: data['filename'] ?? _generateTitle(platform.name),
                thumbnail: null,
                downloadUrl: downloadUrl,
                dateAdded: DateTime.now(),
                platform: platform.name,
              );
            }
          }

          // Handle picker response (multiple videos/images)
          if (data['status'] == 'picker' && data['picker'] is List) {
            final picker = data['picker'] as List;
            for (var item in picker) {
              if (item['type'] == 'video' || picker.length == 1) {
                final downloadUrl = item['url'] as String?;
                if (downloadUrl != null && downloadUrl.isNotEmpty) {
                  print('DownloadService: Cobalt picker URL found');
                  return VideoModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    url: url,
                    title: _generateTitle(platform.name),
                    thumbnail: item['thumb'],
                    downloadUrl: downloadUrl,
                    dateAdded: DateTime.now(),
                    platform: platform.name,
                  );
                }
              }
            }

            // Get first item if no video found
            if (picker.isNotEmpty) {
              final firstItem = picker.first;
              final downloadUrl = firstItem['url'] as String?;
              if (downloadUrl != null && downloadUrl.isNotEmpty) {
                return VideoModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  url: url,
                  title: _generateTitle(platform.name),
                  thumbnail: firstItem['thumb'],
                  downloadUrl: downloadUrl,
                  dateAdded: DateTime.now(),
                  platform: platform.name,
                );
              }
            }
          }

          if (data['status'] == 'error') {
            print('DownloadService: Cobalt error: ${data['text'] ?? data['error']}');
            continue;
          }
        }
      } catch (e) {
        print('DownloadService: Cobalt instance $instance error: $e');
        continue;
      }
    }

    return null;
  }

  /// Generate a title based on platform
  String _generateTitle(String platform) {
    final timestamp = DateTime.now().toString().substring(0, 16);
    final platformName = LinkParser.getDisplayName(
      SocialPlatform.values.firstWhere(
        (p) => p.name == platform,
        orElse: () => SocialPlatform.unknown,
      ),
    );
    return '$platformName Video - $timestamp';
  }

  /// Download video file to device storage
  Future<DownloadModel> downloadFile(
    VideoModel video, {
    ProgressCallback? onProgress,
    bool isPremium = false,
  }) async {
    // Request storage permission
    final permissionGranted = await _requestStoragePermission();
    if (!permissionGranted) {
      throw Exception('İçerik kaydetmek için depolama izni gerekli');
    }

    final downloadModel = DownloadModel(
      id: video.id,
      videoModel: video,
      status: DownloadStatus.downloading,
      progress: 0,
      startedAt: DateTime.now(),
    );

    try {
      // Get save directory
      final saveDir = await _getSaveDirectory();
      final fileName = _generateFileName(video);
      final savePath = '$saveDir/$fileName';

      // Create cancel token
      final cancelToken = CancelToken();
      _activeDownloads[video.id] = cancelToken;

      // Download with progress tracking
      await _dio.download(
        video.downloadUrl,
        savePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = (received / total * 100).round();
            onProgress?.call(received, total);
            downloadModel.progress = progress;
          }
        },
        options: Options(
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          },
        ),
      );

      // Remove from active downloads
      _activeDownloads.remove(video.id);

      // Update model with completed status
      downloadModel.status = DownloadStatus.completed;
      downloadModel.progress = 100;
      downloadModel.completedAt = DateTime.now();
      downloadModel.localPath = savePath;
      downloadModel.fileSize = await File(savePath).length();

      // Save to storage
      await _saveDownloadRecord(downloadModel);

      return downloadModel;
    } catch (e) {
      _activeDownloads.remove(video.id);

      downloadModel.status = DownloadStatus.failed;
      downloadModel.error = e.toString();

      if (e is DioException && e.type == DioExceptionType.cancel) {
        downloadModel.status = DownloadStatus.cancelled;
        downloadModel.error = 'Kaydetme iptal edildi';
      }

      rethrow;
    }
  }

  /// Cancel an active download
  void cancelDownload(String downloadId) {
    final cancelToken = _activeDownloads[downloadId];
    if (cancelToken != null && !cancelToken.isCancelled) {
      cancelToken.cancel('Kaydetme kullanıcı tarafından iptal edildi');
    }
  }

  /// Get all download records
  List<DownloadModel> getAllDownloads() {
    final downloads = _storageService.getAll<DownloadModel>('downloads');
    downloads.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return downloads;
  }

  /// Delete a download record and optionally the file
  Future<void> deleteDownload(String downloadId, {bool deleteFile = true}) async {
    final downloads = _storageService.getBox<DownloadModel>('downloads');
    final download = downloads?.get(downloadId);

    if (download != null && deleteFile && download.localPath != null) {
      final file = File(download.localPath!);
      if (await file.exists()) {
        await file.delete();
      }
    }

    downloads?.delete(downloadId);
  }

  /// Request storage permission
  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage.isGranted) {
        return true;
      }

      if (await Permission.videos.request().isGranted &&
          await Permission.photos.request().isGranted) {
        return true;
      }

      if (await Permission.storage.request().isGranted) {
        return true;
      }

      if (await Permission.manageExternalStorage.request().isGranted) {
        return true;
      }

      return false;
    } else if (Platform.isIOS) {
      return true;
    }
    return true;
  }

  /// Get directory to save downloads
  Future<String> _getSaveDirectory() async {
    Directory? directory;

    if (Platform.isAndroid) {
      directory = Directory('/storage/emulated/0/Download/Pockify');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
    } else if (Platform.isIOS) {
      directory = await getApplicationDocumentsDirectory();
      final pockifyDir = Directory('${directory.path}/Pockify');
      if (!await pockifyDir.exists()) {
        await pockifyDir.create(recursive: true);
      }
      return pockifyDir.path;
    } else {
      directory = await getDownloadsDirectory();
      directory ??= await getApplicationDocumentsDirectory();
    }

    return directory.path;
  }

  /// Generate a unique filename for the video
  String _generateFileName(VideoModel video) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final sanitizedTitle = video.title
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .substring(0, video.title.length > 30 ? 30 : video.title.length);
    return '${video.platform}_${sanitizedTitle}_$timestamp.mp4';
  }

  /// Save download record to storage
  Future<void> _saveDownloadRecord(DownloadModel download) async {
    final box = _storageService.getBox<DownloadModel>('downloads');
    await box?.put(download.id, download);
  }
  
  /// Get list of supported platforms
  List<SocialPlatform> getSupportedPlatforms() {
    return LinkParser.getSupportedPlatforms();
  }
}
