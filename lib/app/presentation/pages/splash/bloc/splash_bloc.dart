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
import 'package:partner/app/core/repositories/auth_repository.dart';

part 'splash_event.dart';
part 'splash_state.dart';

class SplashBloc extends Bloc<SplashEvent, SplashState> {
  SplashBloc({AuthRepository? authRepository})
    : _authRepository = authRepository ?? AuthRepository(),
      super(const SplashState()) {
    on<SplashInitialEvent>(_onSplashInitialEvent);
  }

  final AuthRepository _authRepository;

  FutureOr<void> _onSplashInitialEvent(SplashInitialEvent event, Emitter<SplashState> emit) async {
    try {
      emit(state.copyWith(status: SplashStatus.loading));
      final bool loggedIn = await _authRepository.isLoggedIn();
      emit(state.copyWith(status: SplashStatus.success, loggedIn: loggedIn));
    } catch (e) {
      emit(state.copyWith(status: SplashStatus.failure, statusCode: 0, alertMessage: e.toString()));
    }
  }
}