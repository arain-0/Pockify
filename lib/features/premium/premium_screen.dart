import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../services/purchase_service.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final PurchaseService _purchaseService = PurchaseService();
  SubscriptionPlan? _selectedPlan = SubscriptionPlan.yearly;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _purchaseService.onPurchaseStatusChanged = _onPurchaseStatusChanged;
  }

  void _onPurchaseStatusChanged(AppPurchaseStatus status, String? message) {
    setState(() {
      _isLoading = status == AppPurchaseStatus.pending;
    });

    if (status == AppPurchaseStatus.purchased || status == AppPurchaseStatus.restored) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == AppPurchaseStatus.restored
                ? 'Satin alimlar geri yuklendi!'
                : 'Premium\'a hosgeldiniz!',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } else if (status == AppPurchaseStatus.error && message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = _purchaseService.isPremium;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              _buildFeaturesList(),
              const SizedBox(height: 24),
              if (isPremium)
                _buildAlreadyPremiumView()
              else ...[
                _buildPlanCards(),
                const SizedBox(height: 24),
                _buildPurchaseButton(),
                const SizedBox(height: 16),
                _buildRestoreButton(),
                const SizedBox(height: 32),
                _buildTermsText(),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlreadyPremiumView() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: AppColors.success,
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'Zaten Premium Üyesiniz!',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tüm özelliklerin keyfini çıkarın.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Close button
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: const Icon(Icons.close, color: AppColors.textSecondary),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          // Crown icon with gradient
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.workspace_premium,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'POCKIFY PREMIUM',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sınırsız içerik yönetimi deneyimi',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesList() {
    final features = [
      {'icon': Icons.all_inclusive, 'text': 'Sınırsız kaydetme'},
      {'icon': Icons.hd, 'text': '1080p / 4K kalite'},
      {'icon': Icons.block, 'text': 'Reklamsız deneyim'},
      {'icon': Icons.music_note, 'text': 'MP3 olarak ses kaydetme'},
      {'icon': Icons.folder_special, 'text': 'Gizli klasör (şifreli)'},
      {'icon': Icons.cloud_upload, 'text': 'Bulut yedekleme'},
      {'icon': Icons.support_agent, 'text': 'Öncelikli destek'},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: features.map((feature) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    feature['icon'] as IconData,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  feature['text'] as String,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPlanCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Yearly - Most Popular
          _buildPlanCard(
            plan: SubscriptionPlan.yearly,
            name: 'Yillik Plan',
            price: '₺149.99',
            period: '/yil',
            subtitle: '₺12.50/ay - %58 tasarruf',
            badge: 'EN POPULER',
            hasTrial: true,
          ),
          const SizedBox(height: 12),
          // Monthly
          _buildPlanCard(
            plan: SubscriptionPlan.monthly,
            name: 'Aylik Plan',
            price: '₺29.99',
            period: '/ay',
            subtitle: 'Istedigin zaman iptal et',
          ),
          const SizedBox(height: 12),
          // Weekly
          _buildPlanCard(
            plan: SubscriptionPlan.weekly,
            name: 'Haftalik Plan',
            price: '₺14.99',
            period: '/hafta',
            subtitle: '3 gunluk ucretsiz deneme',
            hasTrial: true,
          ),
          const SizedBox(height: 12),
          // Lifetime
          _buildPlanCard(
            plan: SubscriptionPlan.lifetime,
            name: 'Omur Boyu',
            price: '₺399.99',
            period: '',
            subtitle: 'Bir kere ode, sonsuza kadar kullan',
            badge: 'TEK SEFERLIK',
            badgeColor: AppColors.accent,
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required SubscriptionPlan plan,
    required String name,
    required String price,
    required String period,
    required String subtitle,
    String? badge,
    Color badgeColor = AppColors.primary,
    bool hasTrial = false,
  }) {
    final isSelected = _selectedPlan == plan;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlan = plan;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.surfaceDark,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Radio button
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            // Plan info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  if (hasTrial)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: AppColors.success,
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '3 Gun Ucretsiz Deneme',
                            style: TextStyle(
                              color: AppColors.success,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            // Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (period.isNotEmpty)
                  Text(
                    period,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _handlePurchase,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Devam Et',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildRestoreButton() {
    return TextButton(
      onPressed: _isLoading ? null : _handleRestore,
      child: const Text(
        'Satin Alimlari Geri Yukle',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildTermsText() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        'Abonelik otomatik olarak yenilenir. Donem bitiminden en az 24 saat once iptal edilmezse otomatik olarak yenilenir. Abonelikler uygulama icerisinden yonetilebilir.',
        style: TextStyle(
          color: AppColors.textSecondary.withValues(alpha: 0.7),
          fontSize: 11,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  void _handlePurchase() {
    if (_selectedPlan != null) {
      _purchaseService.purchasePlan(_selectedPlan!);
    }
  }

  void _handleRestore() {
    _purchaseService.restorePurchases();
  }
}
