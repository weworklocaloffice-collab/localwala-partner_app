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

import 'package:partner/app/core/repositories/auth_repository.dart';
import 'package:partner/app/shell/role_gate/bloc/role_gate_bloc.dart';
import 'package:partner/app/shell/vertical_picker/bloc/vertical_picker_bloc.dart';
import 'package:partner/app/shell/vertical_picker/vertical_picker_view.dart';
import 'package:partner/app/router/app_route_config.dart';
import 'package:partner/gen/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Entry after authentication.
///
/// The app shell is a thin dispatcher. It does not know which shells
/// exist or how to render them — it asks the active module for the right
/// shell, via the vertical registry (`vertical_picker_bloc.dart`) and the
/// module's own `nav_config.dart`.
///
/// Two decisions happen here, in order:
///
/// 1. **Vertical choice.** If the account spans more than one vertical
///    and no pick is persisted, the vertical picker renders instead of a
///    shell (plan §3.2: `shell/vertical_picker/`).
/// 2. **Role dispatch.** The resolved session's active vertical selects a
///    `VerticalMeta` from the registry; its `resolveShell` maps the
///    active role to that module's shell.
///
/// ## Before (the ternary we replaced)
///
/// ```dart
/// return state.isDriver
///   ? DeliveryShellScreen(gate: state)
///   : PartnerShellScreen(gate: state);
/// ```
///
/// That line is the failure mode the plan explicitly bans: it does
/// not scale beyond the second role, and a real-estate executive
/// would have to be added to the same `if` chain. The registry means
/// landing a new vertical touches one entry, not this file.
class AppHomeScreen extends StatelessWidget {
  const AppHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return BlocBuilder<RoleGateBloc, RoleGateState>(
      builder: (BuildContext context, RoleGateState state) {
        switch (state.status) {
          case RoleGateStatus.initial:
          case RoleGateStatus.loading:
            return const Scaffold(body: Center(child: CircularProgressIndicator()));

          case RoleGateStatus.failure:
            if (state.statusCode == 401) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                AppRouter.pushNamed(context, AppRouter.loginRoute);
              });
              return const Scaffold(body: SizedBox.shrink());
            }
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(l10n.somethingWentWrong, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => context.read<RoleGateBloc>().add(const RoleGateResolveEvent()),
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
            );

          case RoleGateStatus.resolved:
            return _dispatch(context, state);
        }
      },
    );
  }

  /// Vertical choice first, then the module's shell.
  Widget _dispatch(BuildContext context, RoleGateState state) {
    final session = state.session;

    // A plain customer signing in here resolves to no dairy role and no
    // realestate shell. Without this guard `fromJson` falls back to the
    // partner role and renders a partner shell with no outlet, which the
    // customer cannot use and which never recovers. Show an explicit
    // dead end with a way out instead.
    // A plain customer (no partner memberships) has no dairy role, no
    // realestate shell and only the default 'dairy' vertical. Anything
    // beyond that is a real partner account even when availableRoles is
    // empty (stores / local_services resolve via session.role / default shell).
    final bool hasPartnerVertical = session != null &&
        (session.availableVerticals.any((String v) => v != 'dairy') ||
            session.availableRealEstateShells.isNotEmpty);
    if (session != null &&
        session.availableRoles.isEmpty &&
        session.availableRealEstateShells.isEmpty &&
        !hasPartnerVertical) {
      return const _NoPartnerAccessScreen();
    }

    if (session != null && session.needsVerticalChoice) {
      return VerticalPickerView(
        session: session,
        onPicked: (String vertical) => context.read<RoleGateBloc>().add(RoleGatePickVerticalEvent(vertical)),
      );
    }

    // An unmade choice (single-vertical session) and an id this build does
    // not recognise both fall through to the first registered vertical —
    // dairy. A role the module does not register falls through to the
    // module's default shell inside `resolveShell`, so a vendor/executive
    // check that lands here unrecognised never renders a driver manifest.
    final VerticalMeta vertical = findVerticalMeta(session?.activeVertical) ?? verticalRegistry.first;
    return vertical.resolveShell(state.activeRole.wire, state);
  }
}

/// Shown when the signed-in account holds no shell this app can render.
///
/// This is the customer-account case: `/dairy/profile/available_roles` returns
/// an empty list, which is correct, but the session model needs a default role
/// to exist at all. Rather than guess and render a partner dashboard, stop and
/// offer the only sensible action — sign out.
class _NoPartnerAccessScreen extends StatelessWidget {
  const _NoPartnerAccessScreen();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(Icons.lock_outline, size: 48),
                const SizedBox(height: 16),
                Text(
                  'This account has no partner access.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in with a partner or delivery account.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    await AuthRepository().logout();
                    if (context.mounted) {
                      AppRouter.pushNamed(context, AppRouter.loginRoute);
                    }
                  },
                  child: Text(l10n.logout),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}