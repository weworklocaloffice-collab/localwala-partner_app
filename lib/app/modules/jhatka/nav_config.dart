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
import 'package:partner/app/modules/jhatka/partner/driver/rider_shell_view.dart';
import 'package:partner/app/modules/jhatka/partner/partner_shell_view.dart';
import 'package:partner/app/shell/role_gate/bloc/role_gate_bloc.dart';

/// Roles this module can hold. Mirrors the role enums added to
/// `API/src/config/roles.js` for the Jhatka vertical.
///
/// Wire values are the SERVER values (`jhatkaPartner`, `jhatkaDriver`) — not
/// shortened forms. Shortening them here is how a rider session falls through
/// to the partner shell and a rider ends up holding partner authority.
enum JhatkaAppRole {
  /// Outlet operator. Manages the counter.
  partner('jhatkaPartner', 'Partner'),

  /// Outlet-owned rider. Delivers, never manages.
  driver('jhatkaDriver', 'Rider');

  const JhatkaAppRole(this.wire, this.label);

  final String wire;
  final String label;

  static JhatkaAppRole? fromWire(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final JhatkaAppRole role in JhatkaAppRole.values) {
      if (role.wire == value) return role;
    }
    return null;
  }
}

/// The Jhatka module's shell registry.
///
/// Separate module, separate registry — a change to dairy weighing must never
/// be able to break Jhatka money. The app shell asks the vertical registry
/// (`vertical_picker_bloc.dart`) for this module; that registry asks here for
/// the role shell. No conditions in `app_shell.dart`.
///
/// NOTE (auth follow-up): `AuthRepository` and `RoleGateBloc` are still
/// dairy-typed (`DairyAppRole` in method signatures, persisted wire lists).
/// Until they widen to carry jhatka wires, a jhatka rider session cannot
/// resolve here at login — the mapping above is correct and waiting, but the
/// plumbing (`fetchAvailableRoles`, `switchRole`, role-gate screen) needs the
/// same treatment dairy got. Tracked, not silently assumed.
class JhatkaShell {
  /// The wire role (`'partner'`).
  final String role;

  final String label;

  final Widget Function(RoleGateState state) build;

  const JhatkaShell({
    required this.role,
    required this.label,
    required this.build,
  });
}

final List<JhatkaShell> jhatkaShells = <JhatkaShell>[
  JhatkaShell(
    role: JhatkaAppRole.partner.wire,
    label: JhatkaAppRole.partner.label,
    build: (state) => JhatkaPartnerShellScreen(gate: state),
  ),
  JhatkaShell(
    role: JhatkaAppRole.driver.wire,
    label: JhatkaAppRole.driver.label,
    build: (state) => JhatkaRiderShellScreen(gate: state),
  ),
];

JhatkaShell? findJhatkaShell(String role) {
  for (final shell in jhatkaShells) {
    if (shell.role == role) return shell;
  }
  return null;
}

JhatkaShell get defaultJhatkaShell => jhatkaShells.first;
