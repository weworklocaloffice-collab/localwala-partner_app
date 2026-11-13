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
import 'package:partner/app/core/models/user_session_model.dart';
import 'package:partner/app/core/repositories/auth_repository.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

part 'role_gate_event.dart';
part 'role_gate_state.dart';

/// Resolves which shell to render.
///
/// This is the whole reason both roles live in one binary: an owner-operator
/// holds `dairyPartner` and `dairyDriver`, and the session decides which shell
/// renders. The shells never blend â€” each keeps its own nav tree.
///
/// Every read is offline tolerant. A cached session is preferred over failing,
/// because a rider can be unreachable for the whole route.
class RoleGateBloc extends Bloc<RoleGateEvent, RoleGateState> {
  static const Duration _defaultStartupDiscoveryTimeout = Duration(seconds: 12);

  RoleGateBloc({
    AuthRepository? authRepository,
    Duration startupDiscoveryTimeout = _defaultStartupDiscoveryTimeout,
  })
    : _authRepository = authRepository ?? AuthRepository(),
      _startupDiscoveryTimeout = startupDiscoveryTimeout,
      super(const RoleGateState()) {
    on<RoleGateResolveEvent>(_onRoleGateResolveEvent);
    on<RoleGateSwitchEvent>(_onRoleGateSwitchEvent);
    on<RoleGateSwitchToPartnerEvent>(_onRoleGateSwitchToPartnerEvent);
    on<RoleGatePickVerticalEvent>(_onRoleGatePickVerticalEvent);
    on<RoleGateSwitchRealEstateShellEvent>(_onRoleGateSwitchRealEstateShellEvent);
  }

  final AuthRepository _authRepository;
  final Duration _startupDiscoveryTimeout;

  FutureOr<void> _onRoleGateResolveEvent(RoleGateResolveEvent event, Emitter<RoleGateState> emit) async {
    try {
      emit(state.copyWith(status: RoleGateStatus.loading, alertMessage: ''));

      if (!await _authRepository.isLoggedIn()) {
        emit(state.copyWith(status: RoleGateStatus.failure, statusCode: 401, alertMessage: 'not_authenticated'));
        return;
      }

      UserSessionModel? session = await _authRepository.session();
      if (session == null) {
        emit(state.copyWith(status: RoleGateStatus.failure, statusCode: 401, alertMessage: 'not_authenticated'));
        return;
      }

      // Role and vertical discovery are best-effort refreshes of the cached
      // session. Run them together and bound startup wait: the app must still
      // open its last-known shell if the API is restarting or unreachable.
      final List<Object?> discovery = await Future.wait<Object?>(<Future<Object?>>[
        _loadForStartup<UserSessionModel>(_authRepository.fetchAvailableRoles),
        _loadForStartup<({List<String> verticals, List<String> shells})>(
          _authRepository.fetchAvailableVerticals,
        ),
      ]);

      final UserSessionModel? fresh = discovery[0] as UserSessionModel?;
      if (fresh != null) {
        session = UserSessionModel.fromJson(<String, dynamic>{
          ...fresh.toJson(),
          'id': session.id,
          'activeRole': fresh.availableRoles.contains(session.activeRole)
              ? session.activeRole.wire
              : fresh.activeRole.wire,
          // Once the user has picked a vertical, keep that local choice. On a
          // first cold start after login the server's default is authoritative
          // (Jhatka must open Jhatka, not the dairy fallback).
          'activeVertical': session.activeVertical.isNotEmpty
              ? session.activeVertical
              : fresh.activeVertical,
        });
        await _authRepository.saveSession(session);
      }

      // Vertical + shell discovery probes the actor endpoints. Null means
      // offline — keep the cached lists. A definitive answer replaces them,
      // and the persisted picks are re-validated through fromJson.
      final verticals =
          discovery[1] as ({List<String> verticals, List<String> shells})?;
      if (verticals != null) {
        session = UserSessionModel.fromJson(<String, dynamic>{
          ...session.toJson(),
          'availableVerticals': verticals.verticals,
          'availableRealEstateShells': verticals.shells,
        });
        await _authRepository.saveSession(session);
      }

      emit(state.copyWith(status: RoleGateStatus.resolved, session: session, activeRole: session.activeRole));
    } catch (e, stacktrace) {
      emit(state.copyWith(status: RoleGateStatus.failure, statusCode: 0, alertMessage: e.toString()));
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, stacktrace);
    }
  }

  Future<T?> _loadForStartup<T>(Future<T?> Function() load) async {
    try {
      return await load().timeout(_startupDiscoveryTimeout);
    } catch (_) {
      // Discovery is optional at startup. Keep the persisted session when the
      // server is offline, slow, or temporarily restarting.
      return null;
    }
  }

  FutureOr<void> _onRoleGateSwitchEvent(RoleGateSwitchEvent event, Emitter<RoleGateState> emit) async {
    if (event.role == state.activeRole) return;

    try {
      emit(state.copyWith(status: RoleGateStatus.loading));

      final bool allowed = await _authRepository.switchRole(event.role);
      if (!allowed) {
        emit(
          state.copyWith(
            status: RoleGateStatus.resolved,
            alertMessage: 'Role not permitted for this account',
          ),
        );
        return;
      }

      await _authRepository.saveActiveRole(event.role);
      final UserSessionModel? session = await _authRepository.session();

      emit(
        state.copyWith(
          status: RoleGateStatus.resolved,
          session: session,
          activeRole: event.role,
          alertMessage: '',
        ),
      );
    } catch (e, stacktrace) {
      emit(state.copyWith(status: RoleGateStatus.failure, statusCode: 0, alertMessage: e.toString()));
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, stacktrace);
    }
  }

  FutureOr<void> _onRoleGateSwitchToPartnerEvent(
    RoleGateSwitchToPartnerEvent event,
    Emitter<RoleGateState> emit,
  ) {
    if (state.availableRoles.contains(DairyAppRole.partner)) {
      add(const RoleGateSwitchEvent(DairyAppRole.partner));
    }
  }

  /// Persists the vertical chosen in the picker and re-emits `resolved`
  /// from the saved session — no network round-trip, the same local-save
  /// path [RoleGateSwitchEvent] uses for roles.
  FutureOr<void> _onRoleGatePickVerticalEvent(RoleGatePickVerticalEvent event, Emitter<RoleGateState> emit) async {
    try {
      await _authRepository.saveActiveVertical(event.vertical);
      final UserSessionModel? session = await _authRepository.session();
      emit(
        state.copyWith(
          status: RoleGateStatus.resolved,
          session: session,
          activeRole: session?.activeRole ?? state.activeRole,
          alertMessage: '',
        ),
      );
    } catch (e, stacktrace) {
      emit(state.copyWith(status: RoleGateStatus.failure, statusCode: 0, alertMessage: e.toString()));
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, stacktrace);
    }
  }

  /// Persists the realestate shell chosen in the role gate and re-emits
  /// `resolved` from the saved session. A shell the session does not hold
  /// is ignored — the UI disables those choices, and this is the second
  /// copy of that guard.
  FutureOr<void> _onRoleGateSwitchRealEstateShellEvent(
    RoleGateSwitchRealEstateShellEvent event,
    Emitter<RoleGateState> emit,
  ) async {
    if (event.shell != state.activeRealEstateShell &&
        state.availableRealEstateShells.contains(event.shell)) {
      try {
        await _authRepository.saveActiveRealEstateShell(event.shell);
        final UserSessionModel? session = await _authRepository.session();
        emit(
          state.copyWith(
            status: RoleGateStatus.resolved,
            session: session,
            alertMessage: '',
          ),
        );
      } catch (e, stacktrace) {
        emit(state.copyWith(status: RoleGateStatus.failure, statusCode: 0, alertMessage: e.toString()));
        if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, stacktrace);
      }
    }
  }
}
