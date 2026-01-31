import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../services/storage_service.dart';
import '../../services/purchase_service.dart';
import '../../core/utils/file_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storageService = StorageService();
  final PurchaseService _purchaseService = PurchaseService();
  final FileHelper _fileHelper = FileHelper();

  String _appVersion = '1.0.0';
  bool _wifiOnlyDownload = false;
  String _videoQuality = '720p';
  String _theme = 'dark';
  int _storageUsed = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final wifiOnly = _storageService.getValue<bool>('wifi_only_download') ?? false;
    final quality = _storageService.getValue<String>('video_quality') ?? '720p';
    final theme = _storageService.getValue<String>('app_theme') ?? 'dark';
    final storage = await _fileHelper.getTotalStorageUsed();

    setState(() {
      _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
      _wifiOnlyDownload = wifiOnly;
      _videoQuality = quality;
      _theme = theme;
      _storageUsed = storage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text(
          'Ayarlar',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        children: [
          _buildPremiumBanner(),
          const SizedBox(height: 20),
          _buildSectionHeader('Indirme Ayarlari'),
          _buildSwitchTile(
            Icons.wifi,
            'Sadece Wi-Fi ile Indir',
            'Mobil veri kullanilmaz',
            _wifiOnlyDownload,
            (value) {
              setState(() => _wifiOnlyDownload = value);
              _storageService.setValue('wifi_only_download', value);
            },
          ),
          _buildSelectTile(
            Icons.high_quality,
            'Video Kalitesi',
            _videoQuality,
            () => _showQualityDialog(),
          ),
          _buildInfoTile(
            Icons.storage,
            'Kullanilan Alan',
            _fileHelper.formatFileSize(_storageUsed),
          ),
          const SizedBox(height: 20),
          _buildSectionHeader('Gorunum'),
          _buildSelectTile(
            Icons.palette_outlined,
            'Tema',
            _theme == 'dark' ? 'Koyu' : (_theme == 'light' ? 'Acik' : 'Sistem'),
            () => _showThemeDialog(),
          ),
          const SizedBox(height: 20),
          _buildSectionHeader('Destek'),
          _buildNavigationTile(
            Icons.help_outline,
            'Yardim Merkezi',
            () => _launchUrl('https://pockify.app/help'),
          ),
          _buildNavigationTile(
            Icons.email_outlined,
            'Iletisim',
            () => _launchUrl('mailto:support@pockify.app'),
          ),
          _buildNavigationTile(
            Icons.star_outline,
            'Uygulamayi Puanla',
            () => _launchUrl('https://play.google.com/store/apps/details?id=app.pockify'),
          ),
          const SizedBox(height: 20),
          _buildSectionHeader('Yasal'),
          _buildNavigationTile(
            Icons.privacy_tip_outlined,
            'Gizlilik Politikasi',
            () => _launchUrl(AppConstants.privacyPolicyUrl),
          ),
          _buildNavigationTile(
            Icons.description_outlined,
            'Kullanim Sartlari',
            () => _launchUrl(AppConstants.termsOfServiceUrl),
          ),
          const SizedBox(height: 20),
          _buildSectionHeader('Hakkinda'),
          _buildInfoTile(
            Icons.info_outline,
            'Versiyon',
            _appVersion,
          ),
          const SizedBox(height: 24),
          _buildClearDataButton(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildPremiumBanner() {
    final isPremium = _purchaseService.isPremium;
    final remaining = _purchaseService.getRemainingDownloads();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isPremium ? AppColors.primaryGradient : null,
        color: isPremium ? null : AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: isPremium
            ? null
            : Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isPremium
                  ? Colors.white.withValues(alpha: 0.2)
                  : AppColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isPremium ? Icons.workspace_premium : Icons.rocket_launch,
              color: isPremium ? Colors.white : AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPremium ? 'Premium Aktif' : 'Premium\'a Gec',
                  style: TextStyle(
                    color: isPremium ? Colors.white : AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isPremium
                      ? 'Sinirsiz indirme keyfi'
                      : 'Bugun kalan: $remaining indirme',
                  style: TextStyle(
                    color: isPremium
                        ? Colors.white.withValues(alpha: 0.8)
                        : AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (!isPremium)
            Icon(
              Icons.chevron_right,
              color: AppColors.primary,
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    IconData icon,
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.textSecondary),
        title: Text(
          title,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildSelectTile(
    IconData icon,
    String title,
    String value,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.textSecondary),
        title: Text(
          title,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildNavigationTile(
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.textSecondary),
        title: Text(
          title,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: onTap,
      ),
    );
  }

  Widget _buildInfoTile(
    IconData icon,
    String title,
    String value,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.textSecondary),
        title: Text(
          title,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        trailing: Text(
          value,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _buildClearDataButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: OutlinedButton(
        onPressed: _showClearDataDialog,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text('Tum Verileri Temizle'),
      ),
    );
  }

  void _showQualityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text(
          'Video Kalitesi',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['360p', '480p', '720p', '1080p'].map((quality) {
            final isPremiumQuality = quality == '1080p';
            final isSelected = _videoQuality == quality;

            return ListTile(
              leading: Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              title: Text(
                quality,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              trailing: isPremiumQuality && !_purchaseService.isPremium
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Premium',
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    )
                  : null,
              onTap: () {
                if (isPremiumQuality && !_purchaseService.isPremium) {
                  Navigator.pop(context);
                  // Navigate to premium
                } else {
                  setState(() => _videoQuality = quality);
                  _storageService.setValue('video_quality', quality);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text(
          'Tema',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            {'key': 'dark', 'label': 'Koyu'},
            {'key': 'light', 'label': 'Acik'},
            {'key': 'system', 'label': 'Sistem'},
          ].map((themeOption) {
            final isSelected = _theme == themeOption['key'];

            return ListTile(
              leading: Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              title: Text(
                themeOption['label']!,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              onTap: () {
                setState(() => _theme = themeOption['key']!);
                _storageService.setValue('app_theme', themeOption['key']);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text(
          'Verileri Temizle',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Tum indirilen videolar ve ayarlar silinecek. Bu islem geri alinamaz.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Iptal'),
          ),
          TextButton(
            onPressed: () async {
              await _fileHelper.clearAllDownloads();
              await _storageService.clearAll();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tum veriler temizlendi'),
                  backgroundColor: AppColors.success,
                ),
              );
              _loadSettings();
            },
            child: const Text(
              'Temizle',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
