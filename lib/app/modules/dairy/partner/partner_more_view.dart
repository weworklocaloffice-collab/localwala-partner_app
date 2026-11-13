import 'package:partner/app/core/models/user_session_model.dart';
import 'package:partner/app/modules/dairy/partner/delivery_run_list/partner_delivery_run_list_view.dart';
import 'package:partner/app/modules/dairy/partner/driver_list/partner_driver_list_view.dart';
import 'package:partner/app/modules/dairy/partner/earnings/partner_earnings_view.dart';
import 'package:partner/app/modules/dairy/partner/partner_coverage_view.dart';
import 'package:partner/app/modules/dairy/partner/partner_availability_view.dart';
import 'package:partner/app/modules/dairy/partner/partner_marketing_view.dart';
import 'package:partner/app/modules/dairy/partner/partner_outlet_location_view.dart';
import 'package:partner/app/modules/dairy/partner/partner_report_view.dart';
import 'package:partner/app/modules/dairy/partner/partner_support_view.dart';
import 'package:partner/app/presentation/pages/account/profile_view.dart';
import 'package:partner/gen/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Secondary partner destinations live here so the primary navigation remains
/// focused on the four screens used throughout the operating day.
class PartnerMoreScreen extends StatelessWidget {
  const PartnerMoreScreen({
    super.key,
    required this.session,
    this.outletVerified = true,
    this.locationComplete = true,
    this.onLocationRequired,
    this.onOpenLocationSetup,
    this.onRefreshOutletStatus,
    this.activeOutletName = '',
    this.outletCount = 1,
    this.onChangeOutlet,
  });

  final UserSessionModel session;
  final bool outletVerified;
  final bool locationComplete;
  final VoidCallback? onLocationRequired;
  final VoidCallback? onOpenLocationSetup;
  final VoidCallback? onRefreshOutletStatus;
  final String activeOutletName;
  final int outletCount;
  final VoidCallback? onChangeOutlet;

  void _open(BuildContext context, Widget screen, {bool requiresLocation = true}) {
    if (requiresLocation && !locationComplete) {
      onLocationRequired?.call();
      return;
    }
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final Color accent = Theme.of(context).colorScheme.primary;
    final String name = '${session.firstName} ${session.lastName}'.trim();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.storesNavMore)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: <Widget>[
          if (!outletVerified)
            Card(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: ListTile(
                leading: const Icon(Icons.verified_user_outlined),
                title: const Text('Waiting for admin verification'),
                subtitle: const Text('Outlet address and map pin setup will be available after approval.'),
                trailing: const Icon(Icons.refresh),
                onTap: onRefreshOutletStatus,
              ),
            )
          else if (!locationComplete)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: ListTile(
                leading: const Icon(Icons.location_off_outlined),
                title: const Text('Outlet setup incomplete'),
                subtitle: const Text('Set the outlet address and map pin to unlock operations.'),
                trailing: const Icon(Icons.chevron_right),
                onTap: onOpenLocationSetup ?? onLocationRequired,
              ),
            ),
          if (!outletVerified || !locationComplete) const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                radius: 26,
                backgroundColor: accent.withValues(alpha: 0.12),
                child: Icon(Icons.storefront_outlined, color: accent),
              ),
              title: Text(name.isEmpty ? 'Dairy partner' : name),
              subtitle: Text(session.email ?? 'Partner account'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _open(context, ProfileScreen(session: session), requiresLocation: false),
            ),
          ),
          if (outletCount > 1)
            Card(
              margin: const EdgeInsets.only(top: 10),
              child: ListTile(
                leading: const Icon(Icons.swap_horiz),
                title: const Text('Current outlet'),
                subtitle: Text(activeOutletName.isEmpty ? 'Select an outlet' : activeOutletName),
                trailing: const Icon(Icons.chevron_right),
                onTap: onChangeOutlet,
              ),
            ),
          const SizedBox(height: 20),
          _groupLabel('Operations'),
          _entry(
            context,
            icon: Icons.map_outlined,
            title: 'Delivery area',
            subtitle: 'View coverage and request nearby localities',
            screen: const PartnerCoverageScreen(),
          ),
          _entry(
            context,
            icon: Icons.bar_chart_outlined,
            title: 'Reports',
            subtitle: 'Review sales, discounts, products, and settlements',
            screen: const PartnerReportScreen(),
          ),
          _entry(
            context,
            icon: Icons.support_agent_outlined,
            title: 'Dairy support',
            subtitle: 'Contact Dairy support and track case updates',
            screen: const PartnerSupportScreen(),
            requiresLocation: false,
          ),
          _entry(
            context,
            icon: Icons.schedule_outlined,
            title: 'Business availability',
            subtitle: 'Set opening hours, order cut-off and active localities',
            screen: const PartnerAvailabilityScreen(),
          ),
          _entry(
            context,
            icon: Icons.campaign_outlined,
            title: 'Marketing & promotions',
            subtitle: 'Book sponsored placements and track campaign results',
            screen: const PartnerMarketingScreen(),
          ),
          _entry(
            context,
            icon: Icons.route_outlined,
            title: l10n.navRuns,
            subtitle: 'Plan and track delivery runs',
            screen: const PartnerDeliveryRunListScreen(),
          ),
          _entry(
            context,
            icon: Icons.people_outline,
            title: l10n.navDrivers,
            subtitle: 'Manage delivery partners',
            screen: const PartnerDriverListScreen(),
          ),
          const SizedBox(height: 12),
          _groupLabel('Finance'),
          _entry(
            context,
            icon: Icons.account_balance_wallet_outlined,
            title: l10n.navEarnings,
            subtitle: 'View earnings and settlements',
            screen: const PartnerEarningsScreen(),
          ),
          const SizedBox(height: 12),
          _groupLabel('Account'),
          if (outletVerified)
            _entry(
              context,
              icon: Icons.add_location_alt_outlined,
              title: 'Outlet address and pin',
              subtitle: 'Set or update the physical outlet location',
              screen: const PartnerOutletLocationScreen(),
              requiresLocation: false,
              onTap: onOpenLocationSetup,
            ),
          _entry(
            context,
            icon: Icons.person_outline,
            title: l10n.navAccount,
            subtitle: 'Business and owner profile',
            screen: ProfileScreen(session: session),
            requiresLocation: false,
          ),
        ],
      ),
    );
  }

  Widget _groupLabel(String label) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
    child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
  );

  Widget _entry(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget screen,
    bool requiresLocation = true,
    VoidCallback? onTap,
  }) => Card(
    margin: const EdgeInsets.only(bottom: 6),
    child: ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap ?? () => _open(context, screen, requiresLocation: requiresLocation),
    ),
  );
}
