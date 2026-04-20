import 'package:flutter/material.dart';

class AppColors {
  static const Color surface = Color(0xFFF4FAFD);
  static const Color surfaceContainer = Color(0xFFE9EFF2);
  static const Color surfaceContainerLow = Color(0xFFEEF5F7);
  static const Color surfaceContainerHigh = Color(0xFFE3E9EC);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);

  // Global sidebar colors
  static const Color inverseSurface = Color(0xFF001B53);
  static const Color sidebarText = Color(0xFFD6DCEA);
  static const Color sidebarMuted = Color(0xFFB0B8C7);
  static const Color sidebarActiveBg = Color(0x0F00B894);

  static const Color primary = Color(0xFF006B55);
  static const Color primaryContainer = Color(0xFF00B894);
  static const Color primaryFixed = Color(0xFF6DFAD2);

  static const Color onSurface = Color(0xFF161D1F);
  static const Color secondary = Color(0xFF586062);
  static const Color outlineVariant = Color(0xFFBBCAC3);

  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryContainer],
  );
}