import 'package:flutter/material.dart';

class AppColors {
  // Instagram Inspired Brand Colors
  static const Color primary = Color(0xFFC13584); // Instagram Pink/Magenta
  static const Color secondary = Color(0xFF833AB4); // Instagram Purple
  static const Color accent = Color(0xFFF77737); // Instagram Orange

  // Backgrounds - True Pitch Black (Matches logo background exactly)
  static const Color backgroundDark = Color(0xFF000000); // Absolute Black
  static const Color backgroundLight = Color(0xFFF3F3F3); // Açık mod
  static const Color surfaceDark = Color(0xFF000000); // Absolute Black
  static const Color cardDark = Color(0xFF121212); // Very Subtle difference for cards

  // Status
  static const Color success = Color(0xFF00D68F); // İndirme başarılı
  static const Color error = Color(0xFFFF4757); // Hata durumları
  static const Color warning = Color(0xFFFFBE0B); // Uyarı durumları

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF); // Ana metin
  static const Color textSecondary = Color(0xFFB0B0B0); // İkincil metinler
  static const Color textTertiary = Color(0xFF6E6E6E);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [secondary, primary, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF000000), Color(0xFF000000)], // Solid Black
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [secondary, primary, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
