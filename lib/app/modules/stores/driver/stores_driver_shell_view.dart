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

import 'package:partner/app/core/models/user_session_model.dart';
import 'package:partner/app/modules/stores/driver/deliveries/stores_deliveries_screen.dart';
import 'package:partner/app/modules/stores/driver/earnings/stores_driver_earnings_screen.dart';
import 'package:partner/app/presentation/pages/account/profile_view.dart';
import 'package:partner/app/shell/role_gate/bloc/role_gate_bloc.dart';
import 'package:partner/gen/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Store-driver nav tree.
///
/// Three destinations: deliveries, earnings, account.
///
/// Deliberately absent compared with the dairy driver shell: no can-scan (a store order is
/// picked from a list, not scanned against a dairy manifest), no run history (store delivery
/// is order-centric — there is no `DeliveryRun` in this vertical, §2.4) and no depot
/// reconciliation.
///
/// BR-05: this driver is the outlet's own. They never open `Deliveryman_app`.
class StoresDriverShellScreen extends StatefulWidget {
  const StoresDriverShellScreen({super.key, required this.gate});

  final RoleGateState gate;

  @override
  State<StoresDriverShellScreen> createState() => _StoresDriverShellScreenState();
}

class _StoresDriverShellScreenState extends State<StoresDriverShellScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: <Widget>[
          const StoresDeliveriesScreen(),
          const StoresDriverEarningsScreen(),
          ProfileScreen(
            session: widget.gate.session ?? const UserSessionModel(id: ''),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (int i) => setState(() => _index = i),
        destinations: <NavigationDestination>[
          NavigationDestination(icon: const Icon(Icons.list_alt_outlined), label: l10n.storesNavDeliveries),
          NavigationDestination(icon: const Icon(Icons.payments_outlined), label: l10n.storesNavEarnings),
          NavigationDestination(icon: const Icon(Icons.person_outline), label: l10n.storesNavAccount),
        ],
      ),
    );
  }
}