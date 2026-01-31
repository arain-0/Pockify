import 'package:equatable/equatable.dart';
import '../../../models/download_model.dart';
import '../../../models/video_model.dart';

enum ViewMode { grid, list }

class DownloadState extends Equatable {
  final List<DownloadModel> downloads;
  final List<DownloadModel> filteredDownloads;
  final bool isLoading;
  final bool isProcessing; // Link is being processed
  final String? error;
  final ViewMode viewMode;
  final String searchQuery;
  final String? platformFilter;
  final bool isSelectionMode;
  final Set<String> selectedIds;
  final Map<String, int> downloadProgress;
  final VideoModel? previewVideo; // Video preview before download

  const DownloadState({
    this.downloads = const [],
    this.filteredDownloads = const [],
    this.isLoading = false,
    this.isProcessing = false,
    this.error,
    this.viewMode = ViewMode.grid,
    this.searchQuery = '',
    this.platformFilter,
    this.isSelectionMode = false,
    this.selectedIds = const {},
    this.downloadProgress = const {},
    this.previewVideo,
  });

  bool get hasDownloads => downloads.isNotEmpty;
  bool get hasSelection => selectedIds.isNotEmpty;
  int get selectedCount => selectedIds.length;
  bool get hasPreview => previewVideo != null;

  List<DownloadModel> get completedDownloads =>
      downloads.where((d) => d.isCompleted).toList();

  List<DownloadModel> get activeDownloads =>
      downloads.where((d) => d.isDownloading || d.isPending).toList();

  DownloadState copyWith({
    List<DownloadModel>? downloads,
    List<DownloadModel>? filteredDownloads,
    bool? isLoading,
    bool? isProcessing,
    String? error,
    ViewMode? viewMode,
    String? searchQuery,
    String? platformFilter,
    bool? isSelectionMode,
    Set<String>? selectedIds,
    Map<String, int>? downloadProgress,
    VideoModel? previewVideo,
    bool clearPreview = false,
    bool clearError = false,
  }) {
    return DownloadState(
      downloads: downloads ?? this.downloads,
      filteredDownloads: filteredDownloads ?? this.filteredDownloads,
      isLoading: isLoading ?? this.isLoading,
      isProcessing: isProcessing ?? this.isProcessing,
      error: clearError ? null : (error ?? this.error),
      viewMode: viewMode ?? this.viewMode,
      searchQuery: searchQuery ?? this.searchQuery,
      platformFilter: platformFilter ?? this.platformFilter,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      selectedIds: selectedIds ?? this.selectedIds,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      previewVideo: clearPreview ? null : (previewVideo ?? this.previewVideo),
    );
  }

  @override
  List<Object?> get props => [
        downloads,
        filteredDownloads,
        isLoading,
        isProcessing,
        error,
        viewMode,
        searchQuery,
        platformFilter,
        isSelectionMode,
        selectedIds,
        downloadProgress,
        previewVideo,
      ];
}
