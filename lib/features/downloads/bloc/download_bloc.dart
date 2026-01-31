import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../services/download_service.dart';
import '../../../services/purchase_service.dart';
import '../../../services/ad_service.dart';
import '../../../models/download_model.dart';
import 'download_event.dart';
import 'download_state.dart';

class DownloadBloc extends Bloc<DownloadEvent, DownloadState> {
  final DownloadService _downloadService;
  final PurchaseService _purchaseService;
  final AdService _adService;

  DownloadBloc({
    DownloadService? downloadService,
    PurchaseService? purchaseService,
    AdService? adService,
  })  : _downloadService = downloadService ?? DownloadService(),
        _purchaseService = purchaseService ?? PurchaseService(),
        _adService = adService ?? AdService(),
        super(const DownloadState()) {
    on<LoadDownloads>(_onLoadDownloads);
    on<StartDownload>(_onStartDownload);
    on<CancelDownload>(_onCancelDownload);
    on<DeleteDownload>(_onDeleteDownload);
    on<DeleteMultipleDownloads>(_onDeleteMultipleDownloads);
    on<UpdateDownloadProgress>(_onUpdateDownloadProgress);
    on<ToggleViewMode>(_onToggleViewMode);
    on<SearchDownloads>(_onSearchDownloads);
    on<FilterDownloads>(_onFilterDownloads);
    on<ToggleSelectionMode>(_onToggleSelectionMode);
    on<ToggleItemSelection>(_onToggleItemSelection);
    on<SelectAllItems>(_onSelectAllItems);
    on<ClearSelection>(_onClearSelection);
  }

  void _onLoadDownloads(LoadDownloads event, Emitter<DownloadState> emit) {
    emit(state.copyWith(isLoading: true));

    try {
      final downloads = _downloadService.getAllDownloads();
      emit(state.copyWith(
        downloads: downloads,
        filteredDownloads: downloads,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onStartDownload(
    StartDownload event,
    Emitter<DownloadState> emit,
  ) async {
    // Check daily limit for free users
    if (!await _purchaseService.canDownload()) {
      emit(state.copyWith(
        error: 'Günlük indirme limitine ulaştınız. Premium\'a geçin veya yarın tekrar deneyin.',
      ));
      return;
    }

    emit(state.copyWith(isLoading: true, error: null));

    try {
      // Process link to get video info
      final video = await _downloadService.processLink(event.url);
      if (video == null) {
        emit(state.copyWith(
          isLoading: false,
          error: 'Video bilgisi alınamadı',
        ));
        return;
      }

      // Start download with progress tracking
      final download = await _downloadService.downloadFile(
        video,
        isPremium: _purchaseService.isPremium,
        onProgress: (received, total) {
          final progress = (received / total * 100).round();
          add(UpdateDownloadProgress(video.id, progress));
        },
      );

      // Increment download count and show ad if needed
      await _purchaseService.incrementDownloadCount();
      _adService.onDownloadComplete();

      // Reload downloads
      add(LoadDownloads());
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  void _onCancelDownload(CancelDownload event, Emitter<DownloadState> emit) {
    _downloadService.cancelDownload(event.downloadId);
    add(LoadDownloads());
  }

  Future<void> _onDeleteDownload(
    DeleteDownload event,
    Emitter<DownloadState> emit,
  ) async {
    await _downloadService.deleteDownload(
      event.downloadId,
      deleteFile: event.deleteFile,
    );
    add(LoadDownloads());
  }

  Future<void> _onDeleteMultipleDownloads(
    DeleteMultipleDownloads event,
    Emitter<DownloadState> emit,
  ) async {
    for (final id in event.downloadIds) {
      await _downloadService.deleteDownload(id, deleteFile: event.deleteFiles);
    }
    emit(state.copyWith(
      isSelectionMode: false,
      selectedIds: {},
    ));
    add(LoadDownloads());
  }

  void _onUpdateDownloadProgress(
    UpdateDownloadProgress event,
    Emitter<DownloadState> emit,
  ) {
    final updatedProgress = Map<String, int>.from(state.downloadProgress);
    updatedProgress[event.downloadId] = event.progress;
    emit(state.copyWith(downloadProgress: updatedProgress));
  }

  void _onToggleViewMode(ToggleViewMode event, Emitter<DownloadState> emit) {
    final newMode =
        state.viewMode == ViewMode.grid ? ViewMode.list : ViewMode.grid;
    emit(state.copyWith(viewMode: newMode));
  }

  void _onSearchDownloads(SearchDownloads event, Emitter<DownloadState> emit) {
    final query = event.query.toLowerCase();
    final filtered = state.downloads.where((d) {
      return d.videoModel.title.toLowerCase().contains(query) ||
          d.videoModel.platform.toLowerCase().contains(query);
    }).toList();

    emit(state.copyWith(
      searchQuery: event.query,
      filteredDownloads: filtered,
    ));
  }

  void _onFilterDownloads(FilterDownloads event, Emitter<DownloadState> emit) {
    List<DownloadModel> filtered;

    if (event.platform == null || event.platform!.isEmpty) {
      filtered = state.downloads;
    } else {
      filtered = state.downloads
          .where((d) => d.videoModel.platform == event.platform)
          .toList();
    }

    emit(state.copyWith(
      platformFilter: event.platform,
      filteredDownloads: filtered,
    ));
  }

  void _onToggleSelectionMode(
    ToggleSelectionMode event,
    Emitter<DownloadState> emit,
  ) {
    emit(state.copyWith(
      isSelectionMode: !state.isSelectionMode,
      selectedIds: {},
    ));
  }

  void _onToggleItemSelection(
    ToggleItemSelection event,
    Emitter<DownloadState> emit,
  ) {
    final selectedIds = Set<String>.from(state.selectedIds);

    if (selectedIds.contains(event.downloadId)) {
      selectedIds.remove(event.downloadId);
    } else {
      selectedIds.add(event.downloadId);
    }

    emit(state.copyWith(selectedIds: selectedIds));
  }

  void _onSelectAllItems(SelectAllItems event, Emitter<DownloadState> emit) {
    final allIds = state.filteredDownloads.map((d) => d.id).toSet();
    emit(state.copyWith(selectedIds: allIds));
  }

  void _onClearSelection(ClearSelection event, Emitter<DownloadState> emit) {
    emit(state.copyWith(selectedIds: {}));
  }
}
