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

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:partner/app/core/config/shared_pref_keys.dart';
import 'package:partner/app/presentation/styles/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'theme_event.dart';
part 'theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc() : super(const ThemeState()) {
    on<ThemeInitialEvent>(_onThemeInitialEvent);
    on<ThemeChangeEvent>(_onThemeChangeEvent);
  }

  FutureOr<void> _onThemeInitialEvent(ThemeInitialEvent event, Emitter<ThemeState> emit) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool isDark = prefs.getBool(SharedPreferencesKey.publicKeys.isDark) ?? false;
    emit(ThemeState(appTheme: isDark ? AppTheme.dark : AppTheme.light));
  }

  FutureOr<void> _onThemeChangeEvent(ThemeChangeEvent event, Emitter<ThemeState> emit) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool isDark = event.appTheme == AppTheme.dark;
    await prefs.setBool(SharedPreferencesKey.publicKeys.isDark, isDark);
    emit(ThemeState(appTheme: event.appTheme));
  }
}