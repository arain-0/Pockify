import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/pockify_logo.dart';
import '../../../core/utils/link_parser.dart';
import '../../downloads/bloc/download_bloc.dart';
import '../../downloads/bloc/download_event.dart';
import '../../downloads/bloc/download_state.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with WidgetsBindingObserver {
  final TextEditingController _linkController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkClipboard();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _linkController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkClipboard();
    }
  }

  Future<void> _checkClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && LinkParser.isValidUrl(data!.text!)) {
      if (!mounted) return;

      final platform = LinkParser.parse(data.text!);
      final platformName = LinkParser.getDisplayName(platform);

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$platformName linki tespit edildi'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          action: SnackBarAction(
            label: 'YAPIŞTIR',
            textColor: Colors.white,
            onPressed: () {
              _linkController.text = data.text!;
              HapticFeedback.mediumImpact();
              _processLink(data.text!);
            },
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _handlePaste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      setState(() {
        _linkController.text = data.text!;
        HapticFeedback.mediumImpact();
      });
      _processLink(data.text!);
    } else {
      _showSnackBar('Panoda link bulunamadı', isError: true);
    }
  }

  void _processLink(String link) {
    // Validate the link
    if (!LinkParser.isValidUrl(link)) {
      _showSnackBar(
        'Geçersiz link. YouTube, TikTok, Instagram veya Twitter linki girin.',
        isError: true,
      );
      return;
    }

    // Start download via Bloc
    context.read<DownloadBloc>().add(StartDownload(link));

    // Show feedback
    final platform = LinkParser.parse(link);
    final platformName = LinkParser.getDisplayName(platform);
    _showSnackBar(
      '$platformName içeriği kaydediliyor...',
      isError: false,
      showAction: true,
    );
    
    // Clear the text field
    _linkController.clear();
  }

  void _showSnackBar(String message, {bool isError = false, bool showAction = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: showAction
            ? SnackBarAction(
                label: 'Koleksiyon',
                textColor: Colors.white,
                onPressed: () {
                  // Navigate to downloads tab (index 1)
                  // This is handled by parent HomeScreen
                },
              )
            : null,
      ),
    );
  }

  Widget _buildPlatformChip(String platform) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle, color: AppColors.success, size: 14),
        const SizedBox(width: 4),
        Text(
          platform,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DownloadBloc, DownloadState>(
      listenWhen: (previous, current) {
        // Only listen when error changes from null to a non-null value
        // and they are different errors
        if (previous.error == null && current.error != null) {
          return true;
        }
        // Also trigger if error changed to a different error
        if (previous.error != null && current.error != null && previous.error != current.error) {
          return true;
        }
        return false;
      },
      listener: (context, state) {
        // Show error message if download fails
        if (state.error != null) {
          // Store the error message before clearing
          final errorMessage = state.error!;

          // Clear error immediately to prevent re-triggering
          context.read<DownloadBloc>().add(ClearError());

          // Show the snackbar with the stored message
          _showSnackBar(errorMessage, isError: true);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Stack(
          children: [
            // Prime Video Style Gradient Overlay
            Positioned.fill(
              child: Container(
                color: AppColors.backgroundDark,
              ),
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),
                    // Logo Section - New Pockify Logo
                    const PockifyLogo(
                      size: 120,
                    ).animate().scale(duration: 800.ms, curve: Curves.easeOutBack),
                    
                    const SizedBox(height: 32),
                    
                    // Text Section
                    Text(
                      'POCKIFY',
                      style: AppTypography.textTheme.displayLarge?.copyWith(
                        color: AppColors.primary,
                        letterSpacing: 4.0, // Cinematic spacing
                        fontWeight: FontWeight.w900,
                      ),
                    ).animate().fadeIn(delay: 300.ms).moveY(begin: 10, end: 0),
                    
                    const SizedBox(height: 12),
                    Text(
                      'Favori İçeriklerini Kaydet. Her Zaman Eriş.',
                      style: AppTypography.textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ).animate().fadeIn(delay: 500.ms),

                    const Spacer(flex: 2),

                    // Input Section - Prime Video Style
                    BlocBuilder<DownloadBloc, DownloadState>(
                      builder: (context, state) {
                        final isDownloading = state.isLoading;
                        
                        return Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceDark,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            children: [
                              TextField(
                                controller: _linkController,
                                style: const TextStyle(color: Colors.white),
                                textAlign: TextAlign.center,
                                enabled: !isDownloading,
                                decoration: InputDecoration(
                                  hintText: 'Video Linkini Yapıştır',
                                  hintStyle: TextStyle(color: Colors.grey.shade600),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  disabledBorder: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                onSubmitted: (value) {
                                  if (value.isNotEmpty) {
                                    _processLink(value);
                                  }
                                },
                              ),
                              // Action Button with Progress
                              if (isDownloading)
                                Builder(
                                  builder: (context) {
                                    // Get progress from any active download
                                    final progress = state.downloadProgress.isNotEmpty
                                        ? state.downloadProgress.values.last
                                        : 0;

                                    return Container(
                                      height: 50,
                                      width: double.infinity,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  value: progress > 0 ? progress / 100 : null,
                                                  color: AppColors.primary,
                                                  strokeWidth: 2,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                progress > 0
                                                    ? 'Kaydediliyor... %$progress'
                                                    : 'İçerik bilgisi alınıyor...',
                                                style: TextStyle(
                                                  color: AppColors.textSecondary,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (progress > 0)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 4),
                                              child: LinearProgressIndicator(
                                                value: progress / 100,
                                                backgroundColor: AppColors.surfaceDark,
                                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                                minHeight: 3,
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  },
                                )
                              else
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: _handlePaste,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: const Text(
                                      'YAPIŞTIR VE KAYDET',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.2, end: 0);
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Supported platforms hint
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        _buildPlatformChip('YouTube'),
                        _buildPlatformChip('TikTok'),
                        _buildPlatformChip('Instagram'),
                        _buildPlatformChip('Twitter'),
                      ],
                    ).animate().fadeIn(delay: 900.ms),
                    
                    const Spacer(flex: 3),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
