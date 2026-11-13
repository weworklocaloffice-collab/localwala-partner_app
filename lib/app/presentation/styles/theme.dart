/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 *
 * Website: https://localwala.tech
 * Email: weworklocal1@gmail.com
 *
 * Proprietary and Confidential.
 *
 * Unauthorized copying, modification, distribution,
 * publication, resale, reverse engineering, or use of
 * this software without prior written authorization is
 * strictly prohibited.
 */

import 'package:flutter/material.dart';

enum AppTheme { light, dark }

class AppColors {
  static const Color primary = Color(0xFF1565C0);
  static const Color secondary = Color(0xFF0F9D58);
  static const Color accent = Color(0xFFF2A007);

  // Perishable / expiry signal. Used for batch and FEFO expiry badges.
  static const Color expirySoon = Color(0xFFED6C02);
  static const Color expired = Color(0xFFD32F2F);

  static const Color screenDark = Color(0xFF11161D);
  static const Color screenLight = Color(0xFFF7F8FA);
  static const Color grey = Color(0xFF8A94A6);
  static const Color border = Color(0xFFE3E7EE);
  static const Color textDark = Color(0xFF1B2430);
  static const Color textLight = Color(0xFFF5F7FA);

  // Can ledger states
  static const Color canWithCustomer = Color(0xFF6B4FBB);
  static const Color canWithAgent = Color(0xFF1B8FBF);
  static const Color canInStore = Color(0xFF2E7D32);
  static const Color canLost = Color(0xFFC62828);
}

class AppThemeData {
  final Color primary;
  final Color secondary;
  final Color scaffoldBg;
  final Color cardBg;
  final Color titleText;
  final Color bodyText;
  final Color divider;
  final bool isDark;

  const AppThemeData({
    required this.isDark,
    required this.primary,
    required this.secondary,
    required this.scaffoldBg,
    required this.cardBg,
    required this.titleText,
    required this.bodyText,
    required this.divider,
  });
}

const Map<AppTheme, AppThemeData> appThemeData = <AppTheme, AppThemeData>{
  AppTheme.light: AppThemeData(
    isDark: false,
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    scaffoldBg: AppColors.screenLight,
    cardBg: Colors.white,
    titleText: AppColors.textDark,
    bodyText: AppColors.textDark,
    divider: AppColors.border,
  ),
  AppTheme.dark: AppThemeData(
    isDark: true,
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    scaffoldBg: AppColors.screenDark,
    cardBg: Color(0xFF1A222D),
    titleText: AppColors.textLight,
    bodyText: AppColors.textLight,
    divider: Color(0xFF2A3542),
  ),
};

ThemeData getThemeData(AppTheme appTheme) {
  final AppThemeData data = appThemeData[appTheme]!;
  final ColorScheme scheme = ColorScheme.fromSeed(
    seedColor: data.primary,
    brightness: appTheme == AppTheme.dark ? Brightness.dark : Brightness.light,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: data.scaffoldBg,
    primaryColor: data.primary,
    dividerColor: data.divider,
    appBarTheme: AppBarTheme(
      backgroundColor: data.cardBg,
      foregroundColor: data.titleText,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'semibold',
        color: data.titleText,
        fontSize: 17,
      ),
    ),
    cardTheme: CardThemeData(
      color: data.cardBg,
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    textTheme: TextTheme(
      titleLarge: TextStyle(fontFamily: 'semibold', color: data.titleText, fontSize: 18),
      titleMedium: TextStyle(fontFamily: 'medium', color: data.titleText, fontSize: 15),
      bodyMedium: TextStyle(fontFamily: 'regular', color: data.bodyText, fontSize: 14),
      bodySmall: TextStyle(fontFamily: 'regular', color: AppColors.grey, fontSize: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: data.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontFamily: 'semibold', fontSize: 15),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: data.cardBg,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: data.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: data.primary, width: 1.4),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: data.cardBg,
      indicatorColor: data.primary.withValues(alpha: 0.14),
      labelTextStyle: WidgetStatePropertyAll<TextStyle>(
        TextStyle(fontFamily: 'medium', fontSize: 11, color: data.bodyText),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: data.primary),
  );
}