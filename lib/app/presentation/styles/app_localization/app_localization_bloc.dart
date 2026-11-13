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
import 'package:partner/app/env.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'app_localization_event.dart';
part 'app_localization_state.dart';

class AppLocalizationBloc extends Bloc<AppLocalizationEvent, AppLocalizationState> {
  AppLocalizationBloc() : super(const AppLocalizationState()) {
    on<AppLocalizationInitialEvent>(_onAppLocalizationInitialEvent);
    on<AppLocalizationChangeEvent>(_onAppLocalizationChangeEvent);
  }

  FutureOr<void> _onAppLocalizationInitialEvent(
    AppLocalizationInitialEvent event,
    Emitter<AppLocalizationState> emit,
  ) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String locale =
        prefs.getString(SharedPreferencesKey.publicKeys.defaultLanguage) ?? Environments.defaultLanguage;
    emit(AppLocalizationState(appLanguage: locale));
  }

  FutureOr<void> _onAppLocalizationChangeEvent(
    AppLocalizationChangeEvent event,
    Emitter<AppLocalizationState> emit,
  ) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(SharedPreferencesKey.publicKeys.defaultLanguage, event.locale);
    emit(AppLocalizationState(appLanguage: event.locale));
  }
}