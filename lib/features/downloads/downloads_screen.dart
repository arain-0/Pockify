import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../models/download_model.dart';
import 'bloc/download_bloc.dart';
import 'bloc/download_event.dart';
import 'bloc/download_state.dart';
import 'widgets/video_player_screen.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<DownloadBloc>().add(LoadDownloads());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DownloadBloc, DownloadState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.backgroundDark,
          appBar: _buildAppBar(context, state),
          body: Column(
            children: [
              _buildSearchAndFilter(context, state),
              Expanded(
                child: state.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : state.filteredDownloads.isEmpty
                        ? _buildEmptyState()
                        : state.viewMode == ViewMode.grid
                            ? _buildGridView(context, state)
                            : _buildListView(context, state),
              ),
            ],
          ),
          bottomNavigationBar: state.isSelectionMode && state.hasSelection
              ? _buildSelectionBar(context, state)
              : null,
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, DownloadState state) {
    if (state.isSelectionMode) {
      return AppBar(
        backgroundColor: AppColors.surfaceDark,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            context.read<DownloadBloc>().add(ToggleSelectionMode());
          },
        ),
        title: Text('${state.selectedCount} seçildi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.select_all),
            onPressed: () {
              context.read<DownloadBloc>().add(SelectAllItems());
            },
          ),
        ],
      );
    }

    return AppBar(
      backgroundColor: Colors.transparent,
      title: const Text(
        'Koleksiyonum',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            state.viewMode == ViewMode.grid ? Icons.list : Icons.grid_view,
            color: AppColors.textPrimary,
          ),
          onPressed: () {
            context.read<DownloadBloc>().add(ToggleViewMode());
          },
        ),
        IconButton(
          icon: const Icon(Icons.checklist, color: AppColors.textPrimary),
          onPressed: () {
            context.read<DownloadBloc>().add(ToggleSelectionMode());
          },
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter(BuildContext context, DownloadState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search field
          TextField(
            controller: _searchController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'İçeriklerde ara...',
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              prefixIcon:
                  const Icon(Icons.search, color: AppColors.textSecondary),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon:
                          const Icon(Icons.clear, color: AppColors.textSecondary),
                      onPressed: () {
                        _searchController.clear();
                        context
                            .read<DownloadBloc>()
                            .add(const SearchDownloads(''));
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.surfaceDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              context.read<DownloadBloc>().add(SearchDownloads(value));
            },
          ),
          const SizedBox(height: 12),
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  context,
                  'Tümü',
                  state.platformFilter == null,
                  () => context
                      .read<DownloadBloc>()
                      .add(const FilterDownloads(null)),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  'TikTok',
                  state.platformFilter == 'tiktok',
                  () => context
                      .read<DownloadBloc>()
                      .add(const FilterDownloads('tiktok')),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  'Instagram',
                  state.platformFilter == 'instagram',
                  () => context
                      .read<DownloadBloc>()
                      .add(const FilterDownloads('instagram')),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  'Facebook',
                  state.platformFilter == 'facebook',
                  () => context
                      .read<DownloadBloc>()
                      .add(const FilterDownloads('facebook')),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  'Twitter',
                  state.platformFilter == 'twitter',
                  () => context
                      .read<DownloadBloc>()
                      .add(const FilterDownloads('twitter')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardDark,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_outline,
            size: 80,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Koleksiyonunuz boş',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Link yapıştırarak içerik kaydetmeye başlayın',
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(BuildContext context, DownloadState state) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: state.filteredDownloads.length,
      itemBuilder: (context, index) {
        final download = state.filteredDownloads[index];
        return _buildGridItem(context, download, state);
      },
    );
  }

  Widget _buildGridItem(
    BuildContext context,
    DownloadModel download,
    DownloadState state,
  ) {
    final isSelected = state.selectedIds.contains(download.id);

    return GestureDetector(
      onTap: () {
        if (state.isSelectionMode) {
          context.read<DownloadBloc>().add(ToggleItemSelection(download.id));
        } else if (download.isCompleted && download.localPath != null) {
          _playVideo(context, download);
        }
      },
      onLongPress: () {
        if (!state.isSelectionMode) {
          context.read<DownloadBloc>().add(ToggleSelectionMode());
          context.read<DownloadBloc>().add(ToggleItemSelection(download.id));
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: download.videoModel.thumbnail != null
                        ? CachedNetworkImage(
                            imageUrl: download.videoModel.thumbnail!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: AppColors.surfaceDark,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: AppColors.surfaceDark,
                              child: const Icon(
                                Icons.video_library,
                                color: AppColors.textSecondary,
                                size: 40,
                              ),
                            ),
                          )
                        : Container(
                            color: AppColors.surfaceDark,
                            child: const Icon(
                              Icons.video_library,
                              color: AppColors.textSecondary,
                              size: 40,
                            ),
                          ),
                  ),
                  // Play icon overlay
                  if (download.isCompleted)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  // Download progress
                  if (download.isDownloading)
                    Container(
                      color: Colors.black.withValues(alpha: 0.7),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: download.progress / 100,
                              color: AppColors.primary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${download.progress}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Selection checkbox
                  if (state.isSelectionMode)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            isSelected ? Icons.check : Icons.circle_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  // Platform badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getPlatformColor(download.videoModel.platform),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        download.videoModel.platform.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    download.videoModel.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (download.fileSize != null)
                        Text(
                          download.fileSizeFormatted,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      const Spacer(),
                      _buildStatusBadge(download),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView(BuildContext context, DownloadState state) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.filteredDownloads.length,
      itemBuilder: (context, index) {
        final download = state.filteredDownloads[index];
        return _buildListItem(context, download, state);
      },
    );
  }

  Widget _buildListItem(
    BuildContext context,
    DownloadModel download,
    DownloadState state,
  ) {
    final isSelected = state.selectedIds.contains(download.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: isSelected
            ? Border.all(color: AppColors.primary, width: 2)
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: download.videoModel.thumbnail != null
                  ? CachedNetworkImage(
                      imageUrl: download.videoModel.thumbnail!,
                      width: 80,
                      height: 60,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 80,
                        height: 60,
                        color: AppColors.surfaceDark,
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 80,
                        height: 60,
                        color: AppColors.surfaceDark,
                        child: const Icon(Icons.video_library),
                      ),
                    )
                  : Container(
                      width: 80,
                      height: 60,
                      color: AppColors.surfaceDark,
                      child: const Icon(Icons.video_library),
                    ),
            ),
            if (state.isSelectionMode)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(
                      isSelected ? Icons.check : Icons.circle_outlined,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          download.videoModel.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getPlatformColor(download.videoModel.platform),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                download.videoModel.platform.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (download.fileSize != null)
              Text(
                download.fileSizeFormatted,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: state.isSelectionMode
            ? null
            : PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                color: AppColors.cardDark,
                onSelected: (value) => _handleMenuAction(context, value, download),
                itemBuilder: (context) => [
                  if (download.isCompleted)
                    const PopupMenuItem(
                      value: 'play',
                      child: Row(
                        children: [
                          Icon(Icons.play_arrow, color: AppColors.textPrimary),
                          SizedBox(width: 12),
                          Text('Oynat', style: TextStyle(color: AppColors.textPrimary)),
                        ],
                      ),
                    ),
                  if (download.isCompleted)
                    const PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(Icons.share, color: AppColors.textPrimary),
                          SizedBox(width: 12),
                          Text('Paylaş', style: TextStyle(color: AppColors.textPrimary)),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: AppColors.error),
                        SizedBox(width: 12),
                        Text('Sil', style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
              ),
        onTap: () {
          if (state.isSelectionMode) {
            context.read<DownloadBloc>().add(ToggleItemSelection(download.id));
          } else if (download.isCompleted && download.localPath != null) {
            _playVideo(context, download);
          }
        },
        onLongPress: () {
          if (!state.isSelectionMode) {
            context.read<DownloadBloc>().add(ToggleSelectionMode());
            context.read<DownloadBloc>().add(ToggleItemSelection(download.id));
          }
        },
      ),
    );
  }

  Widget _buildStatusBadge(DownloadModel download) {
    Color color;
    IconData icon;

    switch (download.status) {
      case DownloadStatus.completed:
        color = AppColors.success;
        icon = Icons.check_circle;
        break;
      case DownloadStatus.downloading:
        color = AppColors.primary;
        icon = Icons.downloading;
        break;
      case DownloadStatus.failed:
        color = AppColors.error;
        icon = Icons.error;
        break;
      case DownloadStatus.cancelled:
        color = AppColors.warning;
        icon = Icons.cancel;
        break;
      default:
        color = AppColors.textSecondary;
        icon = Icons.hourglass_empty;
    }

    return Icon(icon, color: color, size: 16);
  }

  Widget _buildSelectionBar(BuildContext context, DownloadState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            icon: Icons.share,
            label: 'Paylaş',
            onTap: () => _shareSelected(context, state),
          ),
          _buildActionButton(
            icon: Icons.delete,
            label: 'Sil',
            color: AppColors.error,
            onTap: () => _deleteSelected(context, state),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = AppColors.textPrimary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Color _getPlatformColor(String platform) {
    switch (platform.toLowerCase()) {
      case 'tiktok':
        return const Color(0xFF000000);
      case 'instagram':
        return const Color(0xFFE1306C);
      case 'facebook':
        return const Color(0xFF1877F2);
      case 'twitter':
        return const Color(0xFF1DA1F2);
      case 'youtube':
        return const Color(0xFFFF0000);
      default:
        return AppColors.primary;
    }
  }

  void _handleMenuAction(
    BuildContext context,
    String action,
    DownloadModel download,
  ) {
    switch (action) {
      case 'play':
        _playVideo(context, download);
        break;
      case 'share':
        _shareVideo(download);
        break;
      case 'delete':
        _showDeleteDialog(context, download);
        break;
    }
  }

  void _playVideo(BuildContext context, DownloadModel download) {
    if (download.localPath != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPlayerScreen(
            videoPath: download.localPath!,
            title: download.videoModel.title,
          ),
        ),
      );
    }
  }

  void _shareVideo(DownloadModel download) async {
    if (download.localPath != null) {
      await Share.shareXFiles([XFile(download.localPath!)]);
    }
  }

  void _showDeleteDialog(BuildContext context, DownloadModel download) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text(
          'İçeriği Sil',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Bu içeriği silmek istediğinizden emin misiniz?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              context.read<DownloadBloc>().add(DeleteDownload(download.id));
              Navigator.pop(context);
            },
            child: const Text(
              'Sil',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _shareSelected(BuildContext context, DownloadState state) async {
    final selectedDownloads = state.downloads
        .where((d) => state.selectedIds.contains(d.id) && d.localPath != null)
        .map((d) => XFile(d.localPath!))
        .toList();

    if (selectedDownloads.isNotEmpty) {
      await Share.shareXFiles(selectedDownloads);
    }
  }

  void _deleteSelected(BuildContext context, DownloadState state) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text(
          'Seçilenleri Sil',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          '${state.selectedCount} içeriği silmek istediğinizden emin misiniz?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              context.read<DownloadBloc>().add(
                    DeleteMultipleDownloads(state.selectedIds.toList()),
                  );
              Navigator.pop(context);
            },
            child: const Text(
              'Sil',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
