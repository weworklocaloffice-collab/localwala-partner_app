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

import 'package:partner/app/presentation/pages/splash/bloc/splash_bloc.dart';
import 'package:partner/app/presentation/styles/theme.dart';
import 'package:partner/app/router/app_route_config.dart';
import 'package:partner/gen/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SplashBloc>().add(const SplashInitialEvent());
  }

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = appThemeData[Theme.of(context).brightness == Brightness.dark ? AppTheme.dark : AppTheme.light]!;

    return BlocConsumer<SplashBloc, SplashState>(
      listenWhen: (SplashState previous, SplashState current) => previous.status != current.status,
      listener: (BuildContext context, SplashState state) {
        if (state.status == SplashStatus.success) {
          AppRouter.pushNamedAndRemoveAll(
            context,
            state.loggedIn ? AppRouter.homeRoute : AppRouter.loginRoute,
          );
        }
        if (state.status == SplashStatus.failure) {
          AppRouter.pushNamedAndRemoveAll(context, AppRouter.serverErrorRoute);
        }
      },
      builder: (BuildContext context, SplashState state) {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  height: 96,
                  width: 96,
                  decoration: BoxDecoration(
                    color: theme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(Icons.water_drop_outlined, size: 48, color: theme.primary),
                ),
                const SizedBox(height: 20),
                Text(
                  AppLocalizations.of(context)!.appName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 28),
                const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5)),
              ],
            ),
          ),
        );
      },
    );
  }
}