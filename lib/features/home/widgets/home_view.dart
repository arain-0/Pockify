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
      final platformName = platform == SocialPlatform.tiktok ? 'TikTok' : 'Instagram';

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
        'Geçersiz link. Lütfen TikTok veya Instagram linki girin.',
        isError: true,
      );
      return;
    }

    // Start download via Bloc
    context.read<DownloadBloc>().add(StartDownload(link));
    
    // Show feedback
    final platform = LinkParser.parse(link);
    final platformName = platform == SocialPlatform.tiktok ? 'TikTok' : 'Instagram';
    _showSnackBar(
      '$platformName videosu indiriliyor...',
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
                label: 'İndirilenler',
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

  @override
  Widget build(BuildContext context) {
    return BlocListener<DownloadBloc, DownloadState>(
      listener: (context, state) {
        // Show error message if download fails
        if (state.error != null) {
          _showSnackBar(state.error!, isError: true);
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
                      'İstediğini İndir. Çevrimdışı İzle.',
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
                                  hintText: 'TikTok veya Instagram Linki Yapıştır',
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
                              // Action Button
                              if (isDownloading)
                                Container(
                                  height: 50,
                                  width: double.infinity,
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: AppColors.primary,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'İndiriliyor...',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
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
                                      'YAPIŞTIR VE İNDİR',
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: AppColors.success, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'TikTok',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.check_circle, color: AppColors.success, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Instagram',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
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
