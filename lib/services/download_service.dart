import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/video_model.dart';
import '../models/download_model.dart';
import '../core/utils/link_parser.dart';
import 'storage_service.dart';

typedef ProgressCallback = void Function(int received, int total);

class DownloadService {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(minutes: 5),
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    },
  ));

  final StorageService _storageService = StorageService();

  // Add multiple API endpoints with fallback
  static const List<String> _apiEndpoints = [
    'https://co.wuk.sh/api/json',
    'https://api.cobalt.tools/api/json',
  ];

  // Active downloads tracking
  final Map<String, CancelToken> _activeDownloads = {};

  // Add retry logic
  Future<T> _retryWithBackoff<T>(Future<T> Function() operation, {int maxAttempts = 3}) async {
    int attempts = 0;
    while (attempts < maxAttempts) {
      try {
        return await operation();
      } catch (e) {
        attempts++;
        if (attempts >= maxAttempts) rethrow;
        await Future.delayed(Duration(seconds: attempts * 2));
      }
    }
    throw Exception('Maksimum deneme sayısına ulaşıldı');
  }

  /// Process a social media link and get video information
  Future<VideoModel?> processLink(String url) async {
    print('DownloadService: Processing link: $url');
    final platform = LinkParser.parse(url);
    if (platform == SocialPlatform.unknown) {
      throw Exception('Desteklenmeyen platform. TikTok veya Instagram linki girin.');
    }
    print('DownloadService: Platform detected: ${platform.name}');

    // Try each endpoint
    for (final endpoint in _apiEndpoints) {
      try {
        return await _retryWithBackoff(() async {
          print('DownloadService: Calling Cobalt API at $endpoint');
          final response = await _dio.post(
            endpoint,
            data: {
              'url': url,
              'vCodec': 'h264',
              'vQuality': '720',
              'aFormat': 'mp3',
              'filenamePattern': 'basic',
              'isAudioOnly': false,
              'twitterGif': false,
              'tiktokH265': false,
            },
          );
          print('DownloadService: API Response status: ${response.statusCode}');

          if (response.statusCode == 200) {
            final data = response.data;

            if (data['status'] == 'error') {
              throw Exception(data['text'] ?? 'Video bilgisi alınamadı');
            }

            if (data['status'] == 'redirect' || data['status'] == 'stream') {
              final downloadUrl = data['url'] as String?;
              if (downloadUrl == null) {
                throw Exception('İndirme linki bulunamadı');
              }

              return VideoModel(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                url: url,
                title: _extractTitle(url, platform),
                thumbnail: data['thumb'] as String?,
                downloadUrl: downloadUrl,
                dateAdded: DateTime.now(),
                platform: platform.name,
              );
            }

            if (data['status'] == 'picker') {
              // Multiple options available, use first video
              final picker = data['picker'] as List?;
              if (picker != null && picker.isNotEmpty) {
                final firstOption = picker.first;
                return VideoModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  url: url,
                  title: _extractTitle(url, platform),
                  thumbnail: firstOption['thumb'] as String?,
                  downloadUrl: firstOption['url'] as String,
                  dateAdded: DateTime.now(),
                  platform: platform.name,
                );
              }
            }
            throw Exception('Beklenmeyen API yanıtı');
          }
          throw Exception('API hatası: ${response.statusCode}');
        });
      } catch (e) {
        print('DownloadService: Error with endpoint $endpoint: $e');
        // Continue to next endpoint if this one fails
        if (endpoint == _apiEndpoints.last) {
           if (e is DioException) {
              if (e.type == DioExceptionType.connectionTimeout) {
                throw Exception('Bağlantı zaman aşımına uğradı');
              } else if (e.type == DioExceptionType.receiveTimeout) {
                throw Exception('Yanıt zaman aşımına uğradı');
              } else if (e.response != null) {
                final errorData = e.response?.data;
                if (errorData is Map && errorData['text'] != null) {
                  throw Exception(errorData['text']);
                }
                throw Exception('Sunucu hatası: ${e.response?.statusCode}');
              }
              throw Exception('Bağlantı hatası: ${e.message}');
           }
           rethrow;
        }
      }
    }
    throw Exception('Tüm sunuculara erişim başarısız oldu.');
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
      throw Exception('Depolama izni gerekli');
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
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
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
        downloadModel.error = 'İndirme iptal edildi';
      }

      rethrow;
    }
  }

  /// Cancel an active download
  void cancelDownload(String downloadId) {
    final cancelToken = _activeDownloads[downloadId];
    if (cancelToken != null && !cancelToken.isCancelled) {
      cancelToken.cancel('İndirme kullanıcı tarafından iptal edildi');
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
      // Check for MANAGE_EXTERNAL_STORAGE for Android 11+ (API 30+)
      // Note: This permission requires special app review on Play Store
      if (await Permission.manageExternalStorage.isGranted) {
        return true;
      }

      // For Android 13+ (API 33+), use media permissions
      if (await Permission.videos.request().isGranted &&
          await Permission.photos.request().isGranted) {
        return true;
      }

      // For Android 10-12
      if (await Permission.storage.request().isGranted) {
        return true;
      }

      // If we are here, we might need to request manage external storage
      if (await Permission.manageExternalStorage.request().isGranted) {
        return true;
      }

      return false;
    } else if (Platform.isIOS) {
      // iOS doesn't need storage permission for app documents
      return true;
    }
    return true;
  }

  /// Get directory to save downloads
  Future<String> _getSaveDirectory() async {
    Directory? directory;

    if (Platform.isAndroid) {
      // Try to save to Downloads folder
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

  /// Extract a title from the URL
  String _extractTitle(String url, SocialPlatform platform) {
    final timestamp = DateTime.now().toString().substring(0, 16);
    switch (platform) {
      case SocialPlatform.tiktok:
        return 'TikTok Video - $timestamp';
      case SocialPlatform.instagram:
        return 'Instagram Reels - $timestamp';
      default:
        return 'Video - $timestamp';
    }
  }

  /// Save download record to storage
  Future<void> _saveDownloadRecord(DownloadModel download) async {
    final box = _storageService.getBox<DownloadModel>('downloads');
    await box?.put(download.id, download);
  }
}
