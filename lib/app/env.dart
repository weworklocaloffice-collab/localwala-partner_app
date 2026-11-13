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
 * WeWorkLocal is a technology platform that connects
 * customers, vendors, service providers, and delivery
 * partners through a unified digital ecosystem.
 *
 * This source code, including all associated assets,
 * APIs, databases, business logic, designs, and
 * documentation, is proprietary to WeWorkLocal.
 *
 * Unauthorized copying, modification, distribution,
 * publication, resale, reverse engineering, or use of
 * this software without prior written authorization is
 * strictly prohibited.
 */

import 'package:flutter/material.dart';

class Environments {
  static const String appName = 'Localwala Dairy Partner'; // Required
  static const String companyName = 'weworklocal pvt ltd'; // Required
  // Override with --dart-define=API_BASE_URL=... . The default is the production
  // API; local builds must pass their emulator/host URL explicitly.
  static const String apiBaseURL = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://localwala.tech/',
  );
  static const String googleMapsKey = String.fromEnvironment(
    'GOOGLE_MAPS_KEY',
    defaultValue: '',
  ); // Required
  static const String defaultLanguage = 'en'; // Required
  static const String defaultCountryCode = '+91'; // append + // Required
  static const supportedLanguages = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('ar'),
    Locale('es'),
  ];
}

class LanguageEntityModel {
  final String code;
  final String value;
  final String locale;
  final String title;
  final String activeImage;
  final String deactiveImage;
  final String description;
  final String selectText;

  const LanguageEntityModel({
    required this.code,
    required this.value,
    required this.locale,
    required this.title,
    required this.activeImage,
    required this.deactiveImage,
    required this.description,
    required this.selectText,
  });
}

class AppSupportedLanguagesModel {
  const AppSupportedLanguagesModel._();

  static const languages = <LanguageEntityModel>[
    LanguageEntityModel(
      code: 'en',
      value: 'English',
      locale: 'en_US',
      title: 'Select Language',
      activeImage: 'assets/images/languages/usa-active.png',
      deactiveImage: 'assets/images/languages/usa-deactive.png',
      description:
          'Choose your preferred language to browse dairy products, manage subscriptions and delivery runs with ease.',
      selectText: 'Select',
    ),
    LanguageEntityModel(
      code: 'hi',
      value: 'हिंदी',
      locale: 'hi_IN',
      title: 'भाषा चुने',
      activeImage: 'assets/images/languages/india-active.png',
      deactiveImage: 'assets/images/languages/india-deactive.png',
      description:
          'डेयरी उत्पाद, सदस्यताओं और डिलीवरी रन को आसानी से देखने के लिए अपनी भाषा चुनें।',
      selectText: 'चुनें',
    ),
    LanguageEntityModel(
      code: 'ar',
      value: 'عربي',
      locale: 'ar_SA',
      title: 'اختر اللغة',
      activeImage: 'assets/images/languages/arabic-active.png',
      deactiveImage: 'assets/images/languages/arabic-deactive.png',
      description:
          'يرجى تحديد لغتك المفضلة لتصفح منتجات الألبان وإدارة الاشتراكات وجولات التوصيل بسهولة.',
      selectText: 'حدده',
    ),
    LanguageEntityModel(
      code: 'es',
      value: 'Español',
      locale: 'es_ES',
      title: 'Seleccionar idioma',
      activeImage: 'assets/images/languages/spanish-active.png',
      deactiveImage: 'assets/images/languages/spanish-deactive.png',
      description:
          'Seleccione su idioma preferido para navegar productos lácteos, gestionar suscripciones y entregas.',
      selectText: 'Selecciónelo',
    ),
  ];
}
