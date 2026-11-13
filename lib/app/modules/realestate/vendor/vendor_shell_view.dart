/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

import 'package:flutter/material.dart';
import 'package:partner/app/modules/realestate/vendor/nav_config.dart';
import 'package:partner/app/presentation/styles/theme.dart';
import 'package:partner/app/shell/role_gate/bloc/role_gate_bloc.dart';

/// Vendor nav tree: Dashboard · Listings · Leads · Visits · More.
///
/// The tabs render from `vendor/nav_config.dart` — the shell does not know
/// which tabs exist. Each tab keeps its own navigation state via the
/// [IndexedStack], matching the dairy shells.
class VendorShellScreen extends StatefulWidget {
  const VendorShellScreen({super.key, required this.gate});

  /// Resolved session passed down by `AppHomeScreen`. Passed explicitly so
  /// tab pages that need the session do not each look the bloc up.
  final RoleGateState gate;

  @override
  State<VendorShellScreen> createState() => _VendorShellScreenState();
}

class _VendorShellScreenState extends State<VendorShellScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = appThemeData[Theme.of(context).brightness == Brightness.dark ? AppTheme.dark : AppTheme.light]!;

    final List<Widget> pages = vendorTabs.map((VendorTab tab) => tab.build(widget.gate)).toList();
    final int index = _index.clamp(0, pages.length - 1);

    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (int value) => setState(() => _index = value),
        backgroundColor: theme.cardBg,
        destinations: vendorTabs
            .map(
              (VendorTab tab) => NavigationDestination(
                icon: Icon(tab.icon),
                label: tab.label,
              ),
            )
            .toList(),
      ),
    );
  }
}
