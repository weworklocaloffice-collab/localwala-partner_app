/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart' show IconData, Icons, Widget;
import 'package:partner/app/core/models/user_session_model.dart';
import 'package:partner/app/modules/dairy/nav_config.dart';
import 'package:partner/app/modules/jhatka/nav_config.dart';
import 'package:partner/app/modules/local_services/nav_config.dart';
import 'package:partner/app/modules/realestate/nav_config.dart';
import 'package:partner/app/modules/stores/nav_config.dart';
import 'package:partner/app/shell/role_gate/bloc/role_gate_bloc.dart';

part 'vertical_picker_event.dart';
part 'vertical_picker_state.dart';

/// Renders the shell for a wire role inside a vertical.
///
/// The app shell calls this to dispatch; it never inspects the vertical
/// itself. Adding a vertical adds a [VerticalMeta] entry below — the
/// dispatch code in `app_shell.dart` does not change.
typedef VerticalShellResolver = Widget Function(String roleWire, RoleGateState state);

/// One entry per vertical the partner app can enter.
class VerticalMeta {
  /// Session wire id (`'dairy'`, `'realestate'`, …).
  final String id;

  /// Display name in the picker.
  final String label;

  final IconData icon;

  /// How the app shell renders this vertical's shell for a wire role.
  final VerticalShellResolver resolveShell;

  const VerticalMeta({
    required this.id,
    required this.label,
    required this.icon,
    required this.resolveShell,
  });
}

/// Registry of verticals this build knows how to render.
///
/// The vertical picker reads it to build the option cards; the app shell
/// reads it to dispatch the resolved session. It is the only place a
/// vertical is named in shell code — plan §3.2.1: one registry entry per
/// module, never a condition in `app_shell.dart`.
///
/// Adding a vertical means adding one entry here plus that vertical's
/// `modules/<v>/nav_config.dart`.
final List<VerticalMeta> verticalRegistry = <VerticalMeta>[
  VerticalMeta(
    id: 'dairy',
    label: 'Dairy',
    icon: Icons.local_drink_outlined,
    resolveShell: (String role, RoleGateState state) => (findDairyShell(role) ?? defaultDairyShell).build(state),
  ),
  VerticalMeta(
    id: 'jhatka',
    label: 'Jhatka',
    icon: Icons.storefront_outlined,
    resolveShell: (String role, RoleGateState state) {
      // Accept both session-native Jhatka wires and the dairy wire mapping
      // used by the old shared role enum.
      final String jhatkaRole =
          role == 'driver' || role == 'jhatkaDriver' ? 'jhatkaDriver' : 'jhatkaPartner';
      return (findJhatkaShell(jhatkaRole) ?? defaultJhatkaShell).build(state);
    },
  ),
  VerticalMeta(
    id: 'realestate',
    label: 'Real Estate',
    icon: Icons.apartment_outlined,
    // The role argument is the dairy wire role, meaningless here: the
    // realestate shell comes from the session's persisted shell pick.
    resolveShell: (String role, RoleGateState state) =>
        (findRealEstateShell(state.session?.activeRealEstateShell ?? '') ?? defaultRealEstateShell).build(state),
  ),
  VerticalMeta(
    id: 'local_services',
    label: 'Local Services',
    icon: Icons.handyman_outlined,
    // The role argument is the dairy wire role, meaningless here (realestate
    // precedent): the single partner shell renders for any authenticated
    // session that reached it; the server enforces rights per request.
    resolveShell: (String role, RoleGateState state) => defaultLocalServicesShell.build(state),
  ),
  VerticalMeta(
    id: 'stores',
    label: 'Stores',
    icon: Icons.shopping_basket_outlined,
    // Same reason as realestate: `app_shell` hands us the DAIRY-typed activeRole wire,
    // which is meaningless for stores. The stores roles (`storePartner` / `storeDriver`,
    // per API/src/config/roles.js) are read off the session's raw `role` instead, so a
    // driver lands on the driver shell rather than falling through to the partner one.
    resolveShell: (String role, RoleGateState state) {
      final String wire = state.session?.role ?? '';
      return (findStoresShell(wire) ?? defaultStoresShell).build(state);
    },
  ),
];

/// Look up a registered vertical by session id.
///
/// Returns null for an id this build does not know (a session that raced
/// ahead of an install, or an unmade choice) — the caller falls back to
/// the first entry, which is dairy.
VerticalMeta? findVerticalMeta(String? id) {
  if (id == null || id.isEmpty) return null;
  for (final VerticalMeta meta in verticalRegistry) {
    if (meta.id == id) return meta;
  }
  return null;
}

/// Resolves the picker's option list and records the user's pick.
///
/// Like `RoleGateBloc`, every read is offline tolerant: the options come
/// from the cached session, not from the network. The pick itself is
/// persisted by the role gate once the view reports it.
class VerticalPickerBloc extends Bloc<VerticalPickerEvent, VerticalPickerState> {
  VerticalPickerBloc() : super(const VerticalPickerState()) {
    on<VerticalPickerLoadEvent>(_onVerticalPickerLoadEvent);
    on<VerticalPickerSelectEvent>(_onVerticalPickerSelectEvent);
  }

  FutureOr<void> _onVerticalPickerLoadEvent(VerticalPickerLoadEvent event, Emitter<VerticalPickerState> emit) {
    emit(state.copyWith(status: VerticalPickerStatus.loading));

    final List<VerticalMeta> options = <VerticalMeta>[];
    for (final VerticalMeta meta in verticalRegistry) {
      if (event.session.availableVerticals.contains(meta.id)) options.add(meta);
    }

    // The server reports a vertical this build has no registry entry for
    // (or reports none the user holds). Fall back to the full registry so
    // the picker is never an empty dead end — dairy is always registered.
    emit(
      VerticalPickerState(
        status: VerticalPickerStatus.resolved,
        options: options.isNotEmpty ? options : verticalRegistry,
      ),
    );
  }

  FutureOr<void> _onVerticalPickerSelectEvent(VerticalPickerSelectEvent event, Emitter<VerticalPickerState> emit) {
    // One pick per showing: ignore taps after the first.
    if (!state.hasSelection) {
      emit(state.copyWith(selectedVertical: event.vertical));
    }
  }
}
