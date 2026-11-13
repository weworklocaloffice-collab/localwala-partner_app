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

import 'package:partner/app/core/models/user_session_model.dart';
import 'package:partner/app/modules/jhatka/partner/driver/rider_deliveries_screen.dart';
import 'package:partner/app/modules/jhatka/partner/driver/rider_earnings_screen.dart';
import 'package:partner/app/presentation/pages/account/profile_view.dart';
import 'package:partner/app/shell/role_gate/bloc/role_gate_bloc.dart';
import 'package:flutter/material.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

/// Rider nav tree: deliveries, earnings, account.
///
/// Riders are outlet staff using the Partner app — no Deliveryman_app module
/// exists for Jhatka, by design. The driver role carries genuinely different
/// rights from the partner role, so this shell is separate from the partner
/// shell rather than a tab inside it. Which shell a session gets is the role
/// gate's decision, driven by `nav_config.dart`.
class JhatkaRiderShellScreen extends StatefulWidget {
  const JhatkaRiderShellScreen({super.key, required this.gate});

  final RoleGateState gate;

  @override
  State<JhatkaRiderShellScreen> createState() => _JhatkaRiderShellScreenState();
}

class _JhatkaRiderShellScreenState extends State<JhatkaRiderShellScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: <Widget>[
          const RiderDeliveriesScreen(),
          const RiderEarningsScreen(),
          ProfileScreen(
            session: widget.gate.session ?? const UserSessionModel(id: ''),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (int i) => setState(() => _index = i),
        destinations: <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.delivery_dining_outlined),
            label: AppLocalizations.of(context)!.storesNavDeliveries,
          ),
          NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            label: AppLocalizations.of(context)!.navEarnings,
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: AppLocalizations.of(context)!.navAccount,
          ),
        ],
      ),
    );
  }
}
