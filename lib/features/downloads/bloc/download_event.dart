import 'package:equatable/equatable.dart';

abstract class DownloadEvent extends Equatable {
  const DownloadEvent();

  @override
  List<Object?> get props => [];
}

class LoadDownloads extends DownloadEvent {}

class ProcessLink extends DownloadEvent {
  final String url;

  const ProcessLink(this.url);

  @override
  List<Object?> get props => [url];
}

class ClearPreview extends DownloadEvent {}

class StartDownload extends DownloadEvent {
  final String url;

  const StartDownload(this.url);

  @override
  List<Object?> get props => [url];
}

class CancelDownload extends DownloadEvent {
  final String downloadId;

  const CancelDownload(this.downloadId);

  @override
  List<Object?> get props => [downloadId];
}

class DeleteDownload extends DownloadEvent {
  final String downloadId;
  final bool deleteFile;

  const DeleteDownload(this.downloadId, {this.deleteFile = true});

  @override
  List<Object?> get props => [downloadId, deleteFile];
}

class DeleteMultipleDownloads extends DownloadEvent {
  final List<String> downloadIds;
  final bool deleteFiles;

  const DeleteMultipleDownloads(this.downloadIds, {this.deleteFiles = true});

  @override
  List<Object?> get props => [downloadIds, deleteFiles];
}

class UpdateDownloadProgress extends DownloadEvent {
  final String downloadId;
  final int progress;

  const UpdateDownloadProgress(this.downloadId, this.progress);

  @override
  List<Object?> get props => [downloadId, progress];
}

class ToggleViewMode extends DownloadEvent {}

class SearchDownloads extends DownloadEvent {
  final String query;

  const SearchDownloads(this.query);

  @override
  List<Object?> get props => [query];
}

class FilterDownloads extends DownloadEvent {
  final String? platform;

  const FilterDownloads(this.platform);

  @override
  List<Object?> get props => [platform];
}

class ToggleSelectionMode extends DownloadEvent {}

class ToggleItemSelection extends DownloadEvent {
  final String downloadId;

  const ToggleItemSelection(this.downloadId);

  @override
  List<Object?> get props => [downloadId];
}

class SelectAllItems extends DownloadEvent {}

class ClearSelection extends DownloadEvent {}
