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
import 'package:partner/app/modules/jhatka/partner/catalogue/catalogue_screen.dart';
import 'package:partner/app/modules/jhatka/partner/fleet/fleet_screen.dart';
import 'package:partner/app/modules/jhatka/partner/compliance/compliance_screen.dart';
import 'package:partner/app/modules/jhatka/partner/inventory/inventory_screen.dart';
import 'package:partner/app/modules/jhatka/partner/labels/labels_screen.dart';
import 'package:partner/app/modules/jhatka/partner/money/payouts_screen.dart';
import 'package:partner/app/modules/jhatka/partner/procurement/procurement_screen.dart';
import 'package:partner/app/modules/jhatka/partner/supply/supply_request_screen.dart';
import 'package:partner/app/modules/jhatka/partner/subscriptions/subscriptions_screen.dart';
import 'package:partner/app/modules/jhatka/partner/dashboard/dashboard_screen.dart';
import 'package:partner/app/modules/jhatka/partner/weighing/jhatka_order_list_view.dart';
import 'package:partner/app/presentation/pages/account/profile_view.dart';
import 'package:partner/app/shell/role_gate/bloc/role_gate_bloc.dart';
import 'package:flutter/material.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

/// Partner (outlet) nav tree for the Jhatka vertical.
///
/// Starts with orders — the counter's daily surface — and grows tab by tab
/// (inventory, subscriptions, payouts) as those screens land. Tabs are added
/// here, never in `app_shell.dart`.
class JhatkaPartnerShellScreen extends StatefulWidget {
  const JhatkaPartnerShellScreen({super.key, required this.gate});

  final RoleGateState gate;

  /// Route remembered when a push is tapped before this shell exists. The shell
  /// consumes it on mount, which covers the killed-app launch path.
  static String? pendingRoute;

  static _JhatkaPartnerShellScreenState? _activeState;

  /// Switches to the tab a push route points at. Returns false when the shell is
  /// not mounted, so the caller can remember the route and reopen the shell.
  static bool openRoute(String? route) {
    final _JhatkaPartnerShellScreenState? state = _activeState;
    if (state == null || !state.mounted) return false;
    return state._openRoute(route);
  }

  @override
  State<JhatkaPartnerShellScreen> createState() =>
      _JhatkaPartnerShellScreenState();
}

class _JhatkaPartnerShellScreenState extends State<JhatkaPartnerShellScreen> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    JhatkaPartnerShellScreen._activeState = this;
    final String? pending = JhatkaPartnerShellScreen.pendingRoute;
    JhatkaPartnerShellScreen.pendingRoute = null;
    final int? index = _tabForRoute(pending);
    if (index != null) _index = index;
  }

  @override
  void dispose() {
    if (identical(JhatkaPartnerShellScreen._activeState, this)) {
      JhatkaPartnerShellScreen._activeState = null;
    }
    super.dispose();
  }

  /// Maps a backend push route to the shell tab that owns it. Unknown routes
  /// leave the shell where it is.
  static int? _tabForRoute(String? route) {
    switch (route) {
      case '/jhatka':
      case '/jhatka/home':
        return 0;
      case '/jhatka/orders':
      case '/jhatka/weigh':
        return 1;
      case '/jhatka/inventory':
      case '/jhatka/recalls':
        return 2;
      case '/jhatka/procurement':
        return 3;
      case '/jhatka/supply':
        return 4;
      case '/jhatka/subscriptions':
        return 5;
      case '/jhatka/money':
      case '/jhatka/payouts':
        return 6;
      case '/jhatka/labels':
        return 7;
      case '/jhatka/compliance':
        return 8;
      case '/jhatka/catalogue':
        return 9;
      case '/jhatka/delivery':
      case '/jhatka/fleet':
        return 10;
      case '/jhatka/settings':
      case '/jhatka/profile':
        return 11;
    }
    return null;
  }

  bool _openRoute(String? route) {
    final int? index = _tabForRoute(route);
    if (index == null) return false;
    if (index != _index) setState(() => _index = index);
    // A push tapped from a pushed screen (order, weigh, sheet) must reveal the
    // shell tab, not just change the IndexedStack underneath it.
    Navigator.of(context).popUntil((Route<dynamic> r) => r.isFirst);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: <Widget>[
          const DashboardScreen(),
          const JhatkaOrderListScreen(),
          const InventoryScreen(),
          const ProcurementScreen(),
          const SupplyRequestScreen(),
          const SubscriptionsScreen(),
          const PayoutsScreen(),
          const LabelsScreen(),
          const ComplianceScreen(),
          const CatalogueScreen(),
          const FleetScreen(),
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
            icon: Icon(Icons.insights_outlined),
            label: AppLocalizations.of(context)!.jhatkaToday,
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            label: AppLocalizations.of(context)!.navOrders,
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            label: AppLocalizations.of(context)!.navInventory,
          ),
          NavigationDestination(
            icon: Icon(Icons.local_shipping_outlined),
            label: AppLocalizations.of(context)!.jhatkaNavProcurement,
          ),
          NavigationDestination(
            icon: Icon(Icons.agriculture_outlined),
            label: AppLocalizations.of(context)!.jhatkaSupplyTitle,
          ),
          NavigationDestination(
            icon: Icon(Icons.repeat_outlined),
            label: AppLocalizations.of(context)!.navSubscriptions,
          ),
          NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            label: AppLocalizations.of(context)!.jhatkaNavMoney,
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_2_outlined),
            label: AppLocalizations.of(context)!.jhatkaNavLabels,
          ),
          NavigationDestination(
            icon: Icon(Icons.verified_outlined),
            label: AppLocalizations.of(context)!.jhatkaNavCompliance,
          ),
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            label: AppLocalizations.of(context)!.storesNavCatalogue,
          ),
          NavigationDestination(
            icon: Icon(Icons.delivery_dining_outlined),
            label: AppLocalizations.of(context)!.jhatkaNavFleet,
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
