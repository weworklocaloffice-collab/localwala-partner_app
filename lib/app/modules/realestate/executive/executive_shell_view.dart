/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright Ac 2026 WeWorkLocal.
 * All Rights Reserved.
 */

import 'package:flutter/material.dart';
import 'package:partner/app/presentation/styles/theme.dart';
import 'package:partner/app/shell/role_gate/bloc/role_gate_bloc.dart';
import 'package:partner/app/modules/realestate/executive/today/executive_today_view.dart';
import 'package:partner/app/modules/realestate/executive/leads/executive_leads_view.dart';
import 'package:partner/app/modules/realestate/executive/visits/executive_visits_view.dart';
import 'package:partner/app/modules/realestate/executive/earnings/executive_earnings_view.dart';
import 'package:partner/app/modules/realestate/executive/profile/executive_profile_view.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

/// Executive nav tree: Today -> Leads -> Visits -> Earnings -> Profile.
///
/// Follow-ups and Customers remain reachable from Today so the shell
/// matches the five-tab plan without dropping either working queue.
class ExecutiveShellScreen extends StatefulWidget {
  const ExecutiveShellScreen({super.key, required this.gate});

  final RoleGateState gate;

  @override
  State<ExecutiveShellScreen> createState() => _ExecutiveShellState();
}

class _ExecutiveShellState extends State<ExecutiveShellScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = appThemeData[
        Theme.of(context).brightness == Brightness.dark ? AppTheme.dark : AppTheme.light]!;
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    final List<Widget> pages =
        executiveTabs.map((ExecutiveTab tab) => tab.build(widget.gate)).toList();
    final int index = _index.clamp(0, pages.length - 1);

    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (int value) => setState(() => _index = value),
        backgroundColor: theme.cardBg,
        destinations: executiveTabs
            .map(
              (ExecutiveTab tab) => NavigationDestination(
                icon: Icon(tab.icon),
                label: tab.label(l10n),
              ),
            )
            .toList(),
      ),
    );
  }
}

class ExecutiveTab {
  final String id;
  final String Function(AppLocalizations l10n) label;
  final IconData icon;
  final Widget Function(RoleGateState gate) build;

  const ExecutiveTab({
    required this.id,
    required this.label,
    required this.icon,
    required this.build,
  });
}

final List<ExecutiveTab> executiveTabs = <ExecutiveTab>[
  ExecutiveTab(
    id: 'today',
    label: (AppLocalizations l10n) => l10n.realEstateNavDashboard,
    icon: Icons.today_outlined,
    build: (RoleGateState gate) => const ExecutiveTodayScreen(),
  ),
  ExecutiveTab(
    id: 'leads',
    label: (AppLocalizations l10n) => l10n.realEstateNavLeads,
    icon: Icons.people_alt_outlined,
    build: (RoleGateState gate) => const ExecutiveLeadsScreen(),
  ),
  ExecutiveTab(
    id: 'visits',
    label: (AppLocalizations l10n) => l10n.realEstateNavVisits,
    icon: Icons.calendar_month_outlined,
    build: (RoleGateState gate) => const ExecutiveVisitsScreen(),
  ),
  ExecutiveTab(
    id: 'earnings',
    label: (AppLocalizations l10n) => l10n.realEstateExecEarnings,
    icon: Icons.account_balance_wallet_outlined,
    build: (RoleGateState gate) => const ExecutiveEarningsScreen(),
  ),
  ExecutiveTab(
    id: 'profile',
    label: (AppLocalizations l10n) => l10n.realEstateNavProfile,
    icon: Icons.person_outline,
    build: (RoleGateState gate) => const ExecutiveProfileScreen(),
  ),
];
