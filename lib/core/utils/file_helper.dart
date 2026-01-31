import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class FileHelper {
  static final FileHelper _instance = FileHelper._internal();
  factory FileHelper() => _instance;
  FileHelper._internal();

  /// Get the app's documents directory
  Future<Directory> getAppDocumentsDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final pockifyDir = Directory('${directory.path}/Pockify');
    if (!await pockifyDir.exists()) {
      await pockifyDir.create(recursive: true);
    }
    return pockifyDir;
  }

  /// Get the downloads directory
  Future<Directory> getDownloadsDir() async {
    if (Platform.isAndroid) {
      final dir = Directory('/storage/emulated/0/Download/Pockify');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    } else if (Platform.isIOS) {
      return getAppDocumentsDirectory();
    } else {
      final dir = await getDownloadsDirectory();
      return dir ?? await getAppDocumentsDirectory();
    }
  }

  /// Check if a file exists
  Future<bool> fileExists(String path) async {
    return File(path).exists();
  }

  /// Delete a file
  Future<bool> deleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get file size
  Future<int> getFileSize(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Format file size to human readable string
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Share a file
  Future<void> shareFile(String path, {String? text}) async {
    final file = XFile(path);
    await Share.shareXFiles([file], text: text);
  }

  /// Share multiple files
  Future<void> shareFiles(List<String> paths, {String? text}) async {
    final files = paths.map((path) => XFile(path)).toList();
    await Share.shareXFiles(files, text: text);
  }

  /// Get total storage used by downloads
  Future<int> getTotalStorageUsed() async {
    try {
      final dir = await getDownloadsDir();
      int total = 0;

      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          total += await entity.length();
        }
      }

      return total;
    } catch (e) {
      return 0;
    }
  }

  /// Clear all downloaded files
  Future<bool> clearAllDownloads() async {
    try {
      final dir = await getDownloadsDir();
      if (await dir.exists()) {
        await for (final entity in dir.list()) {
          if (entity is File) {
            await entity.delete();
          }
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get list of all downloaded files
  Future<List<FileSystemEntity>> getAllDownloadedFiles() async {
    try {
      final dir = await getDownloadsDir();
      final files = <FileSystemEntity>[];

      await for (final entity in dir.list()) {
        if (entity is File) {
          files.add(entity);
        }
      }

      return files;
    } catch (e) {
      return [];
    }
  }

  /// Get file extension
  String getFileExtension(String path) {
    final lastDot = path.lastIndexOf('.');
    if (lastDot != -1) {
      return path.substring(lastDot + 1).toLowerCase();
    }
    return '';
  }

  /// Check if file is a video
  bool isVideoFile(String path) {
    final ext = getFileExtension(path);
    return ['mp4', 'mov', 'avi', 'mkv', 'webm', 'm4v'].contains(ext);
  }

  /// Check if file is an audio
  bool isAudioFile(String path) {
    final ext = getFileExtension(path);
    return ['mp3', 'm4a', 'aac', 'wav', 'ogg', 'flac'].contains(ext);
  }
}
