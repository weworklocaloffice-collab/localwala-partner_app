/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

import 'package:flutter/material.dart';
import 'package:partner/app/modules/realestate/vendor/customers/vendor_customers_view.dart';
import 'package:partner/app/modules/realestate/vendor/dashboard/vendor_dashboard_view.dart';
import 'package:partner/app/modules/realestate/vendor/leads/vendor_leads_view.dart';
import 'package:partner/app/modules/realestate/vendor/listings/vendor_listings_view.dart';
import 'package:partner/app/modules/realestate/vendor/more/vendor_more_view.dart';
import 'package:partner/app/modules/realestate/vendor/packages/vendor_packages_view.dart';
import 'package:partner/app/modules/realestate/vendor/payments/vendor_payments_view.dart';
import 'package:partner/app/modules/realestate/vendor/documents/vendor_documents_view.dart';
import 'package:partner/app/modules/realestate/vendor/analytics/vendor_analytics_view.dart';
import 'package:partner/app/modules/realestate/vendor/commissions/vendor_commissions_view.dart';
import 'package:partner/app/modules/realestate/vendor/support/vendor_support_view.dart';
import 'package:partner/app/modules/realestate/vendor/profile/vendor_profile_view.dart';
import 'package:partner/app/modules/realestate/vendor/visits/vendor_visits_view.dart';
import 'package:partner/app/shell/role_gate/bloc/role_gate_bloc.dart';

/// One bottom-nav destination of the vendor shell.
///
/// Tabs render from [vendorTabs] in registration order — a feature that
/// has not landed yet is simply absent from the list, never a placeholder.
/// Same registry idea as `DairyShell`, scoped to the vendor's bottom nav
/// (plan §3.1.1 condition 3: each module owns its `nav_config.dart`).
class VendorTab {
  /// Stable id (`'dashboard'`, `'listings'`, …).
  final String id;

  /// Display label. English, like `DairyShell.label` — tab labels are
  /// module-owned display strings, not localised keys.
  final String label;

  final IconData icon;

  /// The tab page. The argument is the resolved `RoleGateState`, matching
  /// the shell convention (`XxxShellScreen(gate: state)`).
  final Widget Function(RoleGateState gate) build;

  const VendorTab({
    required this.id,
    required this.label,
    required this.icon,
    required this.build,
  });
}

/// Closed list of vendor tabs. Adding a feature means adding an entry
/// here AND its screen — there is no place where a tab can be introduced
/// silently, and no screen renders without a tab entry.
final List<VendorTab> vendorTabs = <VendorTab>[
  VendorTab(
    id: 'dashboard',
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    build: (RoleGateState gate) => const VendorDashboardScreen(),
  ),
  VendorTab(
    id: 'listings',
    label: 'Listings',
    icon: Icons.list_alt_outlined,
    build: (RoleGateState gate) => const VendorListingsScreen(),
  ),
  VendorTab(
    id: 'leads',
    label: 'Leads',
    icon: Icons.people_alt_outlined,
    build: (RoleGateState gate) => const VendorLeadsScreen(),
  ),
  VendorTab(
    id: 'visits',
    label: 'Visits',
    icon: Icons.calendar_month_outlined,
    build: (RoleGateState gate) => const VendorVisitsScreen(),
  ),
  VendorTab(
    id: 'more',
    label: 'More',
    icon: Icons.more_horiz_outlined,
    build: (RoleGateState gate) => const VendorMoreScreen(),
  ),
];

/// One entry of the vendor "More" menu (plan §11.1).
///
/// Second-level destinations — customers, packages, payments, documents,
/// analytics, commissions, support, profile — register here instead of
/// the bottom nav. Same registry idea as [VendorTab]: a feature that has
/// not landed yet is absent from the list, never a dead menu row.
class VendorMoreItem {
  /// Stable id (`'customers'`, `'packages'`, …).
  final String id;

  /// Display label. English, like tab labels — module-owned strings.
  final String label;

  final IconData icon;

  /// The destination page.
  final WidgetBuilder build;

  const VendorMoreItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.build,
  });
}

/// Closed list of More destinations, in menu order.
final List<VendorMoreItem> vendorMoreItems = <VendorMoreItem>[
  VendorMoreItem(
    id: 'customers',
    label: 'Customers',
    icon: Icons.people_outline,
    build: (BuildContext context) => const VendorCustomersScreen(),
  ),
  VendorMoreItem(
    id: 'packages',
    label: 'Packages',
    icon: Icons.card_membership_outlined,
    build: (BuildContext context) => const VendorPackagesScreen(),
  ),
  VendorMoreItem(
    id: 'payments',
    label: 'Payments',
    icon: Icons.receipt_long_outlined,
    build: (BuildContext context) => const VendorPaymentsScreen(),
  ),
  VendorMoreItem(
    id: 'documents',
    label: 'Documents',
    icon: Icons.folder_outlined,
    build: (BuildContext context) => const VendorDocumentsScreen(),
  ),
  VendorMoreItem(
    id: 'analytics',
    label: 'Analytics',
    icon: Icons.analytics_outlined,
    build: (BuildContext context) => const VendorAnalyticsScreen(),
  ),
  VendorMoreItem(
    id: 'commissions',
    label: 'Commissions',
    icon: Icons.payments_outlined,
    build: (BuildContext context) => const VendorCommissionsScreen(),
  ),
  VendorMoreItem(
    id: 'support',
    label: 'Support',
    icon: Icons.support_agent_outlined,
    build: (BuildContext context) => const VendorSupportScreen(),
  ),
  VendorMoreItem(
    id: 'profile',
    label: 'Profile',
    icon: Icons.person_outline,
    build: (BuildContext context) => const VendorProfileScreen(),
  ),
];
