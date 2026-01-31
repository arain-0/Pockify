import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  // Test Ad Unit IDs - Replace with real IDs in production
  static const String _testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  static const String _testRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
  static const String _testNativeAdUnitId = 'ca-app-pub-3940256099942544/2247696110';

  // Production Ad Unit IDs - TODO: Replace with real IDs
  static const String _prodBannerAdUnitId = 'ca-app-pub-XXXXX/XXXXX';
  static const String _prodInterstitialAdUnitId = 'ca-app-pub-XXXXX/XXXXX';
  static const String _prodRewardedAdUnitId = 'ca-app-pub-XXXXX/XXXXX';
  static const String _prodNativeAdUnitId = 'ca-app-pub-XXXXX/XXXXX';

  String get bannerAdUnitId => kDebugMode ? _testBannerAdUnitId : _prodBannerAdUnitId;
  String get interstitialAdUnitId => kDebugMode ? _testInterstitialAdUnitId : _prodInterstitialAdUnitId;
  String get rewardedAdUnitId => kDebugMode ? _testRewardedAdUnitId : _prodRewardedAdUnitId;
  String get nativeAdUnitId => kDebugMode ? _testNativeAdUnitId : _prodNativeAdUnitId;

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  bool _isInterstitialAdReady = false;
  bool _isRewardedAdReady = false;

  int _downloadCount = 0;
  static const int _adsPerDownloads = 2; // Show ad every 2 downloads

  bool _isPremium = false;

  void setPremiumStatus(bool isPremium) {
    _isPremium = isPremium;
  }

  Future<void> initialize() async {
    await MobileAds.instance.initialize();

    // Request consent info update (EU)
    final params = ConsentRequestParameters();
    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        if (await ConsentInformation.instance.isConsentFormAvailable()) {
          ConsentForm.loadAndShowConsentFormIfRequired(
            (error) {
              if (error != null) {
                debugPrint('Consent form error: ${error.message}');
              }
            },
          );
        }
      },
      (error) {
        debugPrint('Consent info update error: ${error.message}');
      },
    );

    _loadInterstitialAd();
    _loadRewardedAd();
  }

  // Banner Ad
  BannerAd createBannerAd({
    required Function(Ad) onAdLoaded,
    required Function(Ad, LoadAdError) onAdFailedToLoad,
  }) {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: onAdFailedToLoad,
      ),
    );
  }

  // Interstitial Ad
  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
          _interstitialAd!.setImmersiveMode(true);
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial ad failed to load: ${error.message}');
          _isInterstitialAdReady = false;
        },
      ),
    );
  }

  Future<void> showInterstitialAd({VoidCallback? onAdClosed}) async {
    if (_isPremium) {
      onAdClosed?.call();
      return;
    }

    if (_isInterstitialAdReady && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _loadInterstitialAd();
          onAdClosed?.call();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _loadInterstitialAd();
          onAdClosed?.call();
        },
      );
      await _interstitialAd!.show();
    } else {
      onAdClosed?.call();
    }
  }

  // Native Ad
  void loadNativeAd({
    required Function(NativeAd) onAdLoaded,
    required Function(Ad, LoadAdError) onAdFailedToLoad,
  }) {
    NativeAd(
      adUnitId: nativeAdUnitId,
      factoryId: 'listTile', // Ensure this factoryId is registered in native code
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          onAdLoaded(ad as NativeAd);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          onAdFailedToLoad(ad, error);
        },
      ),
    ).load();
  }

  // Rewarded Ad
  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdReady = true;
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded ad failed to load: ${error.message}');
          _isRewardedAdReady = false;
        },
      ),
    );
  }

  Future<bool> showRewardedAd({
    required Function(RewardItem) onUserEarnedReward,
    VoidCallback? onAdClosed,
  }) async {
    if (!_isRewardedAdReady || _rewardedAd == null) {
      return false;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadRewardedAd();
        onAdClosed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadRewardedAd();
        onAdClosed?.call();
      },
    );

    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        onUserEarnedReward(reward);
      },
    );
    return true;
  }

  // Track downloads and show ads accordingly
  void onDownloadComplete() {
    if (_isPremium) return;

    _downloadCount++;
    if (_downloadCount >= _adsPerDownloads) {
      _downloadCount = 0;
      showInterstitialAd();
    }
  }

  bool get isInterstitialAdReady => _isInterstitialAdReady && !_isPremium;
  bool get isRewardedAdReady => _isRewardedAdReady;

  void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
  }
}
