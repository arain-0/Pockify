import 'package:hive/hive.dart';

part 'video_model.g.dart';

@HiveType(typeId: 0)
class VideoModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String url; // Original URL

  @HiveField(2)
  final String title;

  @HiveField(3)
  final String? thumbnail;

  @HiveField(4)
  final String downloadUrl; // File path or remote URL if not downloaded

  @HiveField(5)
  final DateTime dateAdded;

  @HiveField(6)
  final String platform; // 'tiktok' or 'instagram'

  VideoModel({
    required this.id,
    required this.url,
    required this.title,
    this.thumbnail,
    required this.downloadUrl,
    required this.dateAdded,
    required this.platform,
  });
}
