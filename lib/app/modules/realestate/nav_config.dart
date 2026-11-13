/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

import 'package:flutter/material.dart';
import 'package:partner/app/modules/realestate/executive/executive_shell_view.dart';
import 'package:partner/app/modules/realestate/vendor/vendor_shell_view.dart';
import 'package:partner/app/shell/role_gate/bloc/role_gate_bloc.dart';

/// The realestate module's shell registry.
///
/// Each module owns its shells: the app-level shell (`shell/app_shell.dart`)
/// and the vertical picker dispatch through this lookup — neither knows
/// which shells exist or how to render them. Same pattern as the dairy
/// module's `nav_config.dart`.
///
/// ## Roles
///
/// Realestate shells are keyed by wire strings (`'vendor'`,
/// `'executive'`), not by an enum: the session carries
/// `availableRealEstateShells` as strings, and the role gate persists the
/// pick client-side. There is no server switch-role call for shells.
///
/// ## Adding the executive shell (or a third shell)
///
/// 1. Build the shell view next to `vendor_shell_view.dart`.
/// 2. Add a `RealEstateShell` entry to [realEstateShells] below.
///
/// No change to `app_shell.dart` or the vertical picker is required — both
/// read this registry.
class RealEstateShell {
  /// The shell wire id (`'vendor'`, `'executive'`).
  final String role;

  /// Human label for listings. Not localised, same as `DairyShell.label`.
  final String label;

  /// The shell widget. The argument is the resolved `RoleGateState`
  /// — every shell needs the session to render.
  final Widget Function(RoleGateState state) build;

  const RealEstateShell({
    required this.role,
    required this.label,
    required this.build,
  });
}

/// Closed list of realestate shells. Adding a shell means adding an entry
/// here — there is no place in the app where a new shell can be introduced
/// silently.
///
/// The list is `final`, not `const`, because the build closures reference
/// widgets that are not const-constructible.
final List<RealEstateShell> realEstateShells = <RealEstateShell>[
  RealEstateShell(
    role: 'vendor',
    label: 'Vendor',
    build: (RoleGateState state) => VendorShellScreen(gate: state),
  ),
  RealEstateShell(
    role: 'executive',
    label: 'Executive',
    build: (RoleGateState state) => ExecutiveShellScreen(gate: state),
  ),
];

/// Look up the shell for a wire id. Returns `null` for an unknown shell —
/// the caller decides the fallback (the app shell falls back to the first
/// registered shell).
RealEstateShell? findRealEstateShell(String role) {
  for (final RealEstateShell shell in realEstateShells) {
    if (shell.role == role) return shell;
  }
  return null;
}

/// The default shell when no shell is resolved.
RealEstateShell get defaultRealEstateShell => realEstateShells.first;
