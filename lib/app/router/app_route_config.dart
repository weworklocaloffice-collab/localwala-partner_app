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
 * Unauthorized copying, modification, distribution,
 * publication, resale, reverse engineering, or use of
 * this software without prior written authorization is
 * strictly prohibited.
 */

import 'package:partner/app/presentation/pages/auth/login/login_view.dart';
import 'package:partner/app/presentation/pages/auth/register/register_view.dart';
import 'package:partner/app/presentation/pages/extra_pages/connection_view.dart';
import 'package:partner/app/presentation/pages/extra_pages/not_found_view.dart';
import 'package:partner/app/presentation/pages/extra_pages/server_error_view.dart';
import 'package:partner/app/shell/home_shell/app_shell.dart';
import 'package:partner/app/shell/role_gate/role_gate_view.dart';
import 'package:partner/app/presentation/pages/splash/splash_view.dart';
import 'package:flutter/material.dart';

class AppRouter {
  static const String initialRoute = '/';
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String homeRoute = '/home';
  static const String roleGateRoute = '/role_gate';
  static const String serverErrorRoute = '/server_error';
  static const String internetConnectionRoute = '/internet_connection';
  static const String notFoundErrorRoute = '/not_found_error';

  static Route<dynamic> onGenerateRouted(RouteSettings routeSettings) {
    final String name = routeSettings.name ?? initialRoute;
    final Uri? incoming = Uri.tryParse(name);
    final bool isDriverInvite = incoming != null &&
        (incoming.scheme == 'localwala' && incoming.host == 'register' ||
            incoming.path == registerRoute) &&
        (incoming.queryParameters['invite']?.isNotEmpty ?? false);
    if (isDriverInvite) {
      return MaterialPageRoute(
        settings: routeSettings,
        builder: (_) => RegisterScreen(
          initialInviteCode: incoming.queryParameters['invite'],
          initialMobile: incoming.queryParameters['mobile'],
        ),
      );
    }

    switch (routeSettings.name) {
      case initialRoute:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case loginRoute:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case registerRoute:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());

      case homeRoute:
        return MaterialPageRoute(builder: (_) => const AppHomeScreen());

      case roleGateRoute:
        return MaterialPageRoute(builder: (_) => const RoleGateScreen());

      case serverErrorRoute:
        return MaterialPageRoute(
          builder: (BuildContext ctx) => ServerErrorScreen(onRetry: () => pushNamedAndRemoveAll(ctx, homeRoute)),
        );

      case internetConnectionRoute:
        return MaterialPageRoute(builder: (_) => const ConnectionScreen());

      case notFoundErrorRoute:
        return MaterialPageRoute(builder: (_) => const NotFoundScreen());

      default:
        return MaterialPageRoute(builder: (_) => const NotFoundScreen());
    }
  }

  static void pushNamed(BuildContext context, String route) {
    Navigator.of(context).pushNamed(route);
  }

  static void pushNamedAndRemoveAll(BuildContext context, String route) {
    Navigator.of(context).pushNamedAndRemoveUntil(route, (Route<dynamic> _) => false);
  }
}
