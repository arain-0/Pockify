import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../services/storage_service.dart';

class DisclaimerDialog extends StatelessWidget {
  final VoidCallback onAccept;

  const DisclaimerDialog({
    super.key,
    required this.onAccept,
  });

  static Future<void> showIfNeeded(BuildContext context) async {
    final storageService = StorageService();
    final accepted = storageService.getValue<bool>('disclaimer_accepted') ?? false;

    if (!accepted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => DisclaimerDialog(
          onAccept: () async {
            await storageService.setValue('disclaimer_accepted', true);
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      contentPadding: EdgeInsets.zero,
      content: Container(
        width: double.maxFinite,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shield_outlined,
                color: AppColors.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            // Title
            const Text(
              'Onemli Bilgilendirme',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Content
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pockify, kullanicilarin kendi iceriklerini veya izin aldiklari icerikleri yonetmeleri icin tasarlanmistir.',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 16),
                  _WarningItem(
                    text: 'Telif hakki olan iceriklerin izinsiz indirilmesi ve dagitilmasi yasaktir.',
                  ),
                  SizedBox(height: 12),
                  _WarningItem(
                    text: 'Bu uygulama TikTok, Instagram veya herhangi bir sosyal medya platformuyla baglantili degildir.',
                  ),
                  SizedBox(height: 12),
                  _WarningItem(
                    text: 'Iceriklerin yasal kullanimindan tamamen kullanici sorumludur.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Terms text
            Text(
              'Devam ederek Kullanim Sartlarini ve Gizlilik Politikasini kabul etmis olursunuz.',
              style: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.8),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // Accept button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: onAccept,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Kabul Ediyorum',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WarningItem extends StatelessWidget {
  final String text;

  const _WarningItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.warning_amber_rounded,
          color: AppColors.warning,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
