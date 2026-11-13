/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright Â© 2026 WeWorkLocal.
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

import 'dart:async';
import 'dart:convert';

import 'package:partner/app/core/observer.dart';
import 'package:partner/app/env.dart';
import 'package:partner/app/modules/dairy/nav_config.dart';
import 'package:partner/app/modules/jhatka/partner/partner_shell_view.dart';
import 'package:partner/app/shell/role_gate/bloc/role_gate_bloc.dart';
import 'package:partner/app/presentation/pages/splash/bloc/splash_bloc.dart';
import 'package:partner/app/presentation/styles/app_localization/app_localization_bloc.dart';
import 'package:partner/app/presentation/styles/theme.dart';
import 'package:partner/app/presentation/styles/theme_bloc/theme_bloc.dart';
import 'package:partner/app/router/app_route_config.dart';
import 'package:partner/app/services/local_notification_service.dart';
import 'package:partner/firebase_options.dart';
import 'package:partner/gen/l10n/app_localizations.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Opens the screen a Jhatka push points at. The shell must already exist for
/// this path; a killed-app launch is covered by [JhatkaPartnerShellScreen.pendingRoute].
void _handlePartnerNotificationTap(Map<String, dynamic> data) {
  final String route = (data['route'] ?? '').toString();
  if (!route.startsWith('/jhatka')) return;
  if (JhatkaPartnerShellScreen.openRoute(route)) return;

  JhatkaPartnerShellScreen.pendingRoute = route;
  DairyPartnerApp.navigatorKey.currentState?.pushNamedAndRemoveUntil(
    AppRouter.homeRoute,
    (Route<dynamic> r) => false,
  );
}

/// Cold start has no navigator yet and the splash still owns navigation, so
/// remember the route and let the Jhatka shell consume it when it mounts.
void _rememberPartnerLaunchRoute(Map<String, dynamic> data) {
  final String route = (data['route'] ?? '').toString();
  if (route.startsWith('/jhatka')) {
    JhatkaPartnerShellScreen.pendingRoute = route;
  }
}

void main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      Bloc.observer = const AppBlocObserver();

      if (!kIsWeb) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        FirebaseMessaging.onBackgroundMessage(
          firebaseMessagingBackgroundHandler,
        );
        FlutterError.onError =
            FirebaseCrashlytics.instance.recordFlutterFatalError;

        final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
        await analytics.setAnalyticsCollectionEnabled(true);

        await FirebaseMessaging.instance
            .setForegroundNotificationPresentationOptions(
              alert: true,
              badge: true,
              sound: true,
            );
        LocalNotificationService.onTap = (String? payload) {
          if (payload == null || payload.isEmpty) return;
          try {
            final Map<String, dynamic> data =
                jsonDecode(payload) as Map<String, dynamic>;
            _handlePartnerNotificationTap(data);
          } catch (_) {
            // A malformed payload must never crash the app on tap.
          }
        };
        await LocalNotificationService.initialize();
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          LocalNotificationService.showNotification(message);
        });
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          _handlePartnerNotificationTap(message.data);
        });
        final RemoteMessage? launchMessage = await FirebaseMessaging.instance
            .getInitialMessage();
        if (launchMessage != null) {
          _rememberPartnerLaunchRoute(launchMessage.data);
        }
      }

      runApp(const DairyPartnerApp());
    },
    (Object error, StackTrace stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    },
  );
}

class DairyPartnerApp extends StatelessWidget {
  const DairyPartnerApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      // Providers are grouped per bundle, not one flat list (plan §12.2):
      // shell blocs are vertical-agnostic and always mounted; each module
      // owns its own bundle in its `nav_config.dart`, and `main.dart` only
      // ever spreads bundles in. BlocProviders are lazy, so a bundle for a
      // vertical the session is not in never constructs a bloc.
      providers: <BlocProvider<dynamic>>[
        // Shell bundle — live for the whole app session.
        BlocProvider<ThemeBloc>(
          create: (_) => ThemeBloc()..add(const ThemeInitialEvent()),
        ),
        BlocProvider<AppLocalizationBloc>(
          create: (_) =>
              AppLocalizationBloc()..add(const AppLocalizationInitialEvent()),
        ),
        BlocProvider<SplashBloc>(create: (_) => SplashBloc()),
        BlocProvider<RoleGateBloc>(
          create: (_) => RoleGateBloc()..add(const RoleGateResolveEvent()),
        ),
        // Module bundles.
        ...dairyModuleProviders,
      ],
      child: Builder(
        builder: (BuildContext context) {
          final bool isDarkTheme = context.watch<ThemeBloc>().state.isDarkTheme;
          final String currentLanguage = context
              .watch<AppLocalizationBloc>()
              .state
              .appLanguage;
          final MediaQueryData mediaQuery = MediaQuery.of(context);

          return MediaQuery(
            data: mediaQuery.copyWith(
              textScaler: TextScaler.linear(
                mediaQuery.textScaler.scale(1).clamp(0.9, 1.1),
              ),
            ),
            child: MaterialApp(
              title: Environments.appName,
              navigatorKey: DairyPartnerApp.navigatorKey,
              initialRoute: AppRouter.initialRoute,
              onGenerateRoute: AppRouter.onGenerateRouted,
              localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: Environments.supportedLanguages,
              locale: Locale(currentLanguage),
              debugShowCheckedModeBanner: false,
              theme: getThemeData(isDarkTheme ? AppTheme.dark : AppTheme.light),
            ),
          );
        },
      ),
    );
  }
}
