/*
 * WeWorkLocal
 * Hyperlocal Commerce & Service Platform
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
import 'package:partner/app/modules/stores/driver/stores_driver_shell_view.dart';
import 'package:partner/app/modules/stores/partner/stores_partner_shell_view.dart';
import 'package:partner/app/shell/role_gate/bloc/role_gate_bloc.dart';

/// Roles the stores vertical can hold.
///
/// Wire values are the SERVER values from `API/src/config/roles.js` (`storePartner`,
/// `storeDriver`) — not shortened forms. Shortening them here is how a driver session falls
/// through to the partner shell and a rider ends up holding partner authority, which is the
/// exact failure the jhatka note in that file describes.
enum StoresAppRole {
  /// Outlet owner or an employee scoped to this outlet (BR-40).
  partner('storePartner', 'Partner'),

  /// Store-owned driver. BR-05: never the LocalWala platform fleet.
  driver('storeDriver', 'Driver');

  const StoresAppRole(this.wire, this.label);

  final String wire;
  final String label;

  static StoresAppRole? fromWire(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final StoresAppRole role in StoresAppRole.values) {
      if (role.wire == value) return role;
    }
    return null;
  }
}

/// The stores module's shell registry.
///
/// Separate module, separate registry — a change to dairy or jhatka money must never be
/// able to break stores settlement. `app_shell.dart` asks `vertical_picker_bloc.dart` for
/// the vertical, which asks here for the role shell. No conditions in the app shell.
///
/// ## How the role reaches this file
///
/// `app_shell.dart` passes `state.activeRole.wire`, and `activeRole` is a `DairyAppRole` —
/// so the argument is a DAIRY wire and is meaningless here. Following the realestate
/// precedent, `verticalRegistry` resolves stores from `session.role`, the raw server value,
/// instead. If that is unrecognised we fall back to the partner shell.
///
/// ## CORRECTION: the partner shell is NOT the lower-privilege one
///
/// An earlier version of this comment claimed the fallback "is the lower-privilege of the
/// two". Reading `API/src/config/roles.js` says the opposite: `storePartner` carries 58
/// rights and `storeDriver` carries 14, and the driver's set is delivery, earnings and
/// remittance only — no catalogue, no inventory, no money.
///
/// So the fallback is the HIGHER-privilege shell, and the failure mode is: a driver session
/// whose wire value ever fails to match is shown the outlet owner's screens. That is not a
/// privilege escalation, because the server refuses every one of those calls (`storeAuth`
/// against a driver token answers 403) — it is a misleading UI full of dead screens.
///
/// The defence is upstream, and it is what `test/stores_nav_config_test.dart` enforces: the
/// wire values are compared against `roles.js`, so the drift that triggers the fallback
/// cannot happen unnoticed. Whether an unknown role should instead be refused outright is a
/// product decision, deliberately left unchanged here.
class StoresShell {
  final String role;
  final String label;
  final Widget Function(RoleGateState state) build;

  const StoresShell({
    required this.role,
    required this.label,
    required this.build,
  });
}

final List<StoresShell> storesShells = <StoresShell>[
  StoresShell(
    role: StoresAppRole.partner.wire,
    label: StoresAppRole.partner.label,
    build: (state) => StoresPartnerShellScreen(gate: state),
  ),
  StoresShell(
    role: StoresAppRole.driver.wire,
    label: StoresAppRole.driver.label,
    build: (state) => StoresDriverShellScreen(gate: state),
  ),
];

StoresShell? findStoresShell(String role) {
  for (final shell in storesShells) {
    if (shell.role == role) return shell;
  }
  return null;
}

/// Partner is the default, and it is the MORE privileged of the two shells — see the class
/// doc above. Kept because a partner session is far more common than a rider session, so
/// this is the less disruptive failure; not kept because it is safer.
StoresShell get defaultStoresShell => storesShells.first;