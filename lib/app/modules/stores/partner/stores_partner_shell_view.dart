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
import 'package:partner/app/modules/stores/partner/catalogue/stores_catalogue_screen.dart';
import 'package:partner/app/modules/stores/partner/dashboard/stores_dashboard_screen.dart';
import 'package:partner/app/modules/stores/partner/drivers/stores_drivers_screen.dart';
import 'package:partner/app/modules/stores/partner/more/stores_partner_more_screen.dart';
import 'package:partner/app/presentation/pages/account/profile_view.dart';
import 'package:partner/app/modules/stores/partner/orders/stores_orders_screen.dart';
import 'package:partner/app/modules/stores/partner/outlet/stores_outlet_switcher_screen.dart';
import 'package:partner/app/modules/stores/stores_partner_repository.dart';
import 'package:partner/app/shell/role_gate/bloc/role_gate_bloc.dart';
import 'package:partner/gen/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:partner/app/presentation/styles/theme.dart';

/// Partner (outlet) nav tree for the stores vertical.
///
/// FIVE destinations (plan §10.1, spec §38): Home, Orders, Catalogue, Delivery, More.
/// The old 7-tab bar — inventory, catalogue, drivers and post-sale each a full tab —
/// crowded the bar and orphaned subscriptions/payments/manual entry behind nothing at
/// all. The grouped More list holds everything else; the tabs match §38's own grouping
/// (Catalogue covers products; the More list covers inventory through account).
///
/// Tabs are declared here and never in `app_shell.dart` — plan §3.2 rule 3, each module
/// owns its nav. Labels come from the shared `.arb` files (`storesNav*` keys). The list is
/// not `const` because l10n resolves at runtime.
///
/// ## Outlet scoping (BR-38)
///
/// No screen here asks for an outlet id. The outlet switcher calls the server and the
/// server resolves every subsequent query, so a screen cannot read another outlet's data by
/// passing a different id.
///
/// ## Capability banner (BR-32)
///
/// The shell renders one `GET /partner/capabilities` banner when the response carries a
/// `banner` code — `SUBSCRIPTION_PAST_DUE`, `SUBSCRIPTION_GRACE_PERIOD` or
/// `SUBSCRIPTION_SUSPENDED`. The app reports the server's row rather than re-deriving the
/// matrix in Dart, so the two cannot drift apart. When it is `SUBSCRIPTION_SUSPENDED` the
/// banner is red; the other two are amber. Tab CONTENT is never hidden for this — the
/// server still answers reads for dead states, and fulfiling what is already paid is
/// deliberately never blocked.
class StoresPartnerShellScreen extends StatefulWidget {
  const StoresPartnerShellScreen({super.key, required this.gate});

  final RoleGateState gate;

  @override
  State<StoresPartnerShellScreen> createState() =>
      _StoresPartnerShellScreenState();
}

class _StoresPartnerShellScreenState extends State<StoresPartnerShellScreen> {
  int _index = 0;
  StoresPartnerRepository? _repo;
  String? _capabilityBanner;

  static const Map<String, Icon> _navIcons = <String, Icon>{
    'home': Icon(Icons.dashboard_outlined),
    'orders': Icon(Icons.receipt_long_outlined),
    'catalogue': Icon(Icons.category_outlined),
    'delivery': Icon(Icons.pedal_bike_outlined),
    'more': Icon(Icons.menu),
  };

  @override
  void initState() {
    super.initState();
    _loadCapabilities();
  }

  void _loadCapabilities() {
    final StoresPartnerRepository repo = _repo ?? StoresPartnerRepository();
    repo
        .capabilities()
        .then((Map<String, dynamic> caps) {
      final dynamic row = caps['capabilities'];
      final String? banner =
          row is Map && row['banner'] != null ? '${row['banner']}' : null;
      if (mounted && _capabilityBanner != banner) {
        setState(() => _capabilityBanner = banner);
      }
    }).catchError((Object _) {
      // Gating is advisory scaffolding: a failed capabilities call must never
      // blank the partner's ability to trade or work existing orders.
    });
  }

  /// Route pushed from the app bar so the switcher is reachable from ANY tab. Without this
  /// a partner operating several outlets can only change outlet by losing their place in
  /// the app, and BR-38 leaves them stuck on whatever the session resolved to at login.
  Future<void> _openOutletSwitcher() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const StoresOutletSwitcherScreen(),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.storesTitleStore),
        actions: <Widget>[
          IconButton(
            tooltip: l10n.storesTitleOutlets,
            onPressed: _openOutletSwitcher,
            icon: const Icon(Icons.swap_horiz),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          if (_capabilityBanner != null) _capabilityRow(context),
          Expanded(
            child: IndexedStack(
              index: _index,
              children: <Widget>[
                const StoresDashboardScreen(),
                const StoresOrdersScreen(),
                const StoresCatalogueScreen(),
                const StoresDriversScreen(),
                StoresPartnerMoreScreen(
                  accountScreen: ProfileScreen(
                    session: widget.gate.session ?? const UserSessionModel(id: ''),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (int i) => setState(() => _index = i),
        destinations: <NavigationDestination>[
          NavigationDestination(
            icon: _navIcons['home']!,
            label: l10n.storesNavHome,
          ),
          NavigationDestination(
            icon: _navIcons['orders']!,
            label: l10n.storesNavOrders,
          ),
          NavigationDestination(
            icon: _navIcons['catalogue']!,
            label: l10n.storesNavCatalogue,
          ),
          NavigationDestination(
            icon: _navIcons['delivery']!,
            label: l10n.storesNavDrivers,
          ),
          NavigationDestination(
            icon: _navIcons['more']!,
            label: l10n.storesNavMore,
          ),
        ],
      ),
    );
  }

  Widget _capabilityRow(BuildContext context) {
    final Color color = _capabilityBanner == 'SUBSCRIPTION_SUSPENDED'
        ? AppColors.expired
        : AppColors.expirySoon;

    return Material(
      color: color.withValues(alpha: 0.12),
      child: ListTile(
        dense: true,
        leading: Icon(
          color == AppColors.expired
              ? Icons.block_outlined
              : Icons.warning_amber_outlined,
          color: color,
        ),
        title: Text(
          _bannerText(context),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }

  String _bannerText(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    switch (_capabilityBanner) {
      case 'SUBSCRIPTION_PAST_DUE':
        return l10n.storesBannerSubscriptionPastDue;
      case 'SUBSCRIPTION_GRACE_PERIOD':
        return l10n.storesBannerSubscriptionGracePeriod;
      case 'SUBSCRIPTION_SUSPENDED':
        return l10n.storesBannerSubscriptionSuspended;
      default:
        return _capabilityBanner ?? '';
    }
  }
}
