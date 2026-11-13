/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 *
 * Proprietary and Confidential.
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:partner/app/core/models/user_session_model.dart';
import 'package:partner/app/modules/dairy/driver/delivery_shell_view.dart';
import 'package:partner/app/modules/dairy/partner/partner_shell_view.dart';
import 'package:partner/app/presentation/pages/auth/login/bloc/login_bloc.dart';
import 'package:partner/app/presentation/pages/auth/register/bloc/registration_bloc.dart';
import 'package:partner/app/shell/role_gate/bloc/role_gate_bloc.dart';

/// The dairy module's shell registry.
///
/// Each module owns its bottom-nav and shells. The app-level shell
/// (`shell/app_shell.dart`) is a thin dispatcher that asks the active
/// module for the right shell — it does not know which shells exist
/// or how to render them.
///
/// ## Why this is per-module, not a shared list
///
/// A shared list with `if (isDriver) ... else if (isPartner) ...`
/// is the failure mode the plan explicitly calls out: it does not
/// scale beyond the second role. When a real estate executive or
/// vendor lands in this same app, they need their own shell and
/// their own bottom nav. Their own `nav_config.dart` does that.
///
/// ## Adding a third role to the dairy module
///
/// 1. Build `<role>_shell_view.dart` next to `partner_shell_view.dart`.
/// 2. Add a `DairyShell` entry to [dairyShells] below.
/// 3. Add the new role to `DairyAppRole` in the session model.
///
/// No change to `app_shell.dart` is required — that file is now
/// a one-liner that calls into this lookup.
class DairyShell {
  /// The wire value of `DairyAppRole` (e.g. `'dairyDriver'`, `'dairyPartner'`).
  final String role;

  /// Human label for the shell. Not read by a screen today — the vertical
  /// picker renders verticals (from the registry in `vertical_picker_bloc.dart`),
  /// not roles; role choice lives in the role gate screen.
  final String label;

  /// The shell widget. The argument is the resolved `RoleGateState`
  /// — every shell needs the session and active role to render.
  final Widget Function(RoleGateState state) build;

  const DairyShell({
    required this.role,
    required this.label,
    required this.build,
  });
}

/// Closed list of dairy shells. Adding a new role means adding an
/// entry here AND to `DairyAppRole` — there is no place in the app
/// where a new role can be introduced silently.
///
/// The list is `final`, not `const`, because the build closures
/// reference widgets that are not const-constructible.
final List<DairyShell> dairyShells = <DairyShell>[
  DairyShell(
    role: DairyAppRole.driver.wire,
    label: 'Driver',
    build: (state) => DeliveryShellScreen(gate: state),
  ),
  DairyShell(
    role: DairyAppRole.partner.wire,
    label: 'Partner',
    build: (state) => PartnerShellScreen(gate: state),
  ),
];

/// Look up the shell for a wire role. Returns `null` for an unknown
/// role — the caller decides the fallback (the app shell falls back
/// to the first registered shell, which is the partner dashboard by
/// convention because it is the lower-privilege of the two dairy
/// roles).
DairyShell? findDairyShell(String role) {
  for (final shell in dairyShells) {
    if (shell.role == role) return shell;
  }
  return null;
}

/// The default shell when no role is resolved. Used by `app_shell.dart`
/// as the fall-through when the bloc is in `resolved` state but the
/// role on the session is not registered.
DairyShell get defaultDairyShell => dairyShells.first;

/// The dairy module's app-level bloc bundle.
///
/// `main.dart` mounts module bundles instead of one flat provider list
/// per vertical (plan §12.2: five verticals in one app would put 60–80
/// flat providers in a single file). Login and registration live here
/// because both drive dairy-namespaced auth endpoints (`v1/auth/dairy/*`);
/// if auth becomes shared across verticals they move to the shell bundle
/// in `main.dart`.
///
/// `BlocProvider` is lazy — a bloc in this bundle is not constructed
/// until a dairy screen reads it — so mounting every registered bundle
/// costs nothing for the vertical the session is not in.
final List<BlocProvider<StateStreamableSource<Object?>>> dairyModuleProviders =
    <BlocProvider<StateStreamableSource<Object?>>>[
      BlocProvider<LoginBloc>(create: (_) => LoginBloc()),
      BlocProvider<RegistrationBloc>(create: (_) => RegistrationBloc()),
    ];
