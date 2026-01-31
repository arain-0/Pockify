import 'package:hive/hive.dart';
import 'video_model.dart';

part 'download_model.g.dart';

@HiveType(typeId: 1)
enum DownloadStatus {
  @HiveField(0)
  pending,
  @HiveField(1)
  downloading,
  @HiveField(2)
  completed,
  @HiveField(3)
  failed,
  @HiveField(4)
  cancelled,
}

@HiveType(typeId: 2)
class DownloadModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final VideoModel videoModel;

  @HiveField(2)
  DownloadStatus status;

  @HiveField(3)
  int progress;

  @HiveField(4)
  final DateTime startedAt;

  @HiveField(5)
  DateTime? completedAt;

  @HiveField(6)
  String? localPath;

  @HiveField(7)
  int? fileSize;

  @HiveField(8)
  String? error;

  DownloadModel({
    required this.id,
    required this.videoModel,
    required this.status,
    required this.progress,
    required this.startedAt,
    this.completedAt,
    this.localPath,
    this.fileSize,
    this.error,
  });

  bool get isCompleted => status == DownloadStatus.completed;
  bool get isFailed => status == DownloadStatus.failed;
  bool get isDownloading => status == DownloadStatus.downloading;
  bool get isPending => status == DownloadStatus.pending;
  bool get isCancelled => status == DownloadStatus.cancelled;

  String get fileSizeFormatted {
    if (fileSize == null) return '';
    if (fileSize! < 1024) return '$fileSize B';
    if (fileSize! < 1024 * 1024) return '${(fileSize! / 1024).toStringAsFixed(1)} KB';
    if (fileSize! < 1024 * 1024 * 1024) {
      return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(fileSize! / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String get durationFormatted {
    if (completedAt == null) return '';
    final duration = completedAt!.difference(startedAt);
    if (duration.inSeconds < 60) return '${duration.inSeconds}s';
    if (duration.inMinutes < 60) return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    return '${duration.inHours}h ${duration.inMinutes % 60}m';
  }

  String get statusText {
    switch (status) {
      case DownloadStatus.pending:
        return 'Bekliyor';
      case DownloadStatus.downloading:
        return 'İndiriliyor';
      case DownloadStatus.completed:
        return 'Tamamlandı';
      case DownloadStatus.failed:
        return 'Başarısız';
      case DownloadStatus.cancelled:
        return 'İptal Edildi';
    }
  }

  DownloadModel copyWith({
    String? id,
    VideoModel? videoModel,
    DownloadStatus? status,
    int? progress,
    DateTime? startedAt,
    DateTime? completedAt,
    String? localPath,
    int? fileSize,
    String? error,
  }) {
    return DownloadModel(
      id: id ?? this.id,
      videoModel: videoModel ?? this.videoModel,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      localPath: localPath ?? this.localPath,
      fileSize: fileSize ?? this.fileSize,
      error: error ?? this.error,
    );
  }
}
