import 'package:flutter/material.dart';

class ThemeProvider {
  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

  static void setTheme(String theme) {
    switch (theme) {
      case 'light':
        themeNotifier.value = ThemeMode.light;
        break;
      case 'system':
        themeNotifier.value = ThemeMode.system;
        break;
      case 'dark':
      default:
        themeNotifier.value = ThemeMode.dark;
        break;
    }
  }
}
