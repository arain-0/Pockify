import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'services/storage_service.dart';
import 'services/ad_service.dart';
import 'services/purchase_service.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/splash_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/onboarding/disclaimer_dialog.dart';
import 'features/downloads/bloc/download_bloc.dart';
import 'features/downloads/bloc/download_event.dart';
import 'models/video_model.dart';
import 'models/download_model.dart';
import 'core/theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Allow all orientations for tablet support
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.backgroundDark,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(VideoModelAdapter());
  Hive.registerAdapter(DownloadModelAdapter());
  Hive.registerAdapter(DownloadStatusAdapter());

  // Initialize services
  final storageService = StorageService();
  await storageService.init();

  // Load theme
  final themeStr = storageService.getValue<String>('app_theme') ?? 'dark';
  ThemeProvider.setTheme(themeStr);

  final adService = AdService();
  await adService.initialize();

  final purchaseService = PurchaseService();
  await purchaseService.initialize();

  runApp(const PockifyApp());
}

class PockifyApp extends StatelessWidget {
  const PockifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => DownloadBloc()..add(LoadDownloads()),
        ),
      ],
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: ThemeProvider.themeNotifier,
        builder: (context, themeMode, _) {
          return MaterialApp(
            title: 'Pockify',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            home: const AppWrapper(),
          );
        },
      ),
    );
  }
}

class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  final StorageService _storageService = StorageService();

  bool _showSplash = true;
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  void _checkOnboardingStatus() {
    final onboardingCompleted =
        _storageService.getValue<bool>('onboarding_completed') ?? false;
    setState(() {
      _showOnboarding = !onboardingCompleted;
    });
  }

  void _onSplashComplete() {
    setState(() {
      _showSplash = false;
    });

    // Show disclaimer if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_showOnboarding) {
        DisclaimerDialog.showIfNeeded(context);
      }
    });
  }

  void _onOnboardingComplete() {
    setState(() {
      _showOnboarding = false;
    });

    // Show disclaimer after onboarding
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DisclaimerDialog.showIfNeeded(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen(onComplete: _onSplashComplete);
    }

    if (_showOnboarding) {
      return OnboardingScreen(onComplete: _onOnboardingComplete);
    }

    return const HomeScreen();
  }
}
