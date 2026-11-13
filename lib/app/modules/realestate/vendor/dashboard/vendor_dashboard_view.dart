/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:partner/app/modules/realestate/vendor/dashboard/bloc/vendor_dashboard_bloc.dart';
import 'package:partner/app/presentation/styles/theme.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

/// Vendor dashboard: identity, publish eligibility, and the counters that
/// matter daily — active listings, leads, visits, live holds, sales, and
/// the entitlement balance that gates publishing (BR-02, BR-05).
class VendorDashboardScreen extends StatelessWidget {
  const VendorDashboardScreen({super.key});

  static int _count(Map<String, dynamic> map, String key) {
    final dynamic v = map[key];
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return BlocProvider<VendorDashboardBloc>(
      create: (_) => VendorDashboardBloc()..add(const VendorDashboardLoadEvent()),
      child: BlocBuilder<VendorDashboardBloc, VendorDashboardState>(
        builder: (BuildContext context, VendorDashboardState state) {
          final AppThemeData theme =
              appThemeData[Theme.of(context).brightness == Brightness.dark ? AppTheme.dark : AppTheme.light]!;
          final String businessName =
              state.summary['displayName']?.toString().isNotEmpty == true
                  ? state.summary['displayName'].toString()
                  : (state.summary['businessName']?.toString() ?? l10n.realEstateNavDashboard);

          return Scaffold(
            appBar: AppBar(title: Text(businessName)),
            body: Builder(
              builder: (BuildContext context) {
                switch (state.status) {
                  case VendorDashboardStatus.initial:
                  case VendorDashboardStatus.loading:
                    return const Center(child: CircularProgressIndicator());
                  case VendorDashboardStatus.failure:
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(l10n.somethingWentWrong, style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () =>
                                context.read<VendorDashboardBloc>().add(const VendorDashboardLoadEvent()),
                            child: Text(l10n.retry),
                          ),
                        ],
                      ),
                    );
                  case VendorDashboardStatus.loaded:
                    return _DashboardBody(state: state, theme: theme, l10n: l10n);
                }
              },
            ),
          );
        },
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.state, required this.theme, required this.l10n});

  final VendorDashboardState state;
  final AppThemeData theme;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final bool mayPublish = state.summary['mayPublish'] == true;
    final int remaining = VendorDashboardScreen._count(state.summary, 'remainingEntitlements');
    final String listingsLeft =
        remaining < 0 ? l10n.realEstateDashUnlimited : remaining.toString();

    return RefreshIndicator(
      onRefresh: () async =>
          context.read<VendorDashboardBloc>().add(const VendorDashboardLoadEvent()),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (!mayPublish)
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.divider),
                ),
                child: Text(
                  '${l10n.realEstateDashVerificationPending} (${state.summary['verificationStatus']?.toString() ?? '—'})',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: theme.bodyText),
                ),
              ),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: <Widget>[
                _MetricTile(
                  theme: theme,
                  label: l10n.realEstateDashActiveListings,
                  value: VendorDashboardScreen._count(state.summary, 'activeListings').toString(),
                ),
                _MetricTile(
                  theme: theme,
                  label: l10n.realEstateDashTotalLeads,
                  value: VendorDashboardScreen._count(state.analytics, 'leads').toString(),
                ),
                _MetricTile(
                  theme: theme,
                  label: l10n.realEstateDashVisits,
                  value: VendorDashboardScreen._count(state.analytics, 'visits').toString(),
                ),
                _MetricTile(
                  theme: theme,
                  label: l10n.realEstateDashLiveHolds,
                  value: VendorDashboardScreen._count(state.analytics, 'liveHolds').toString(),
                ),
                _MetricTile(
                  theme: theme,
                  label: l10n.realEstateDashSales,
                  value: VendorDashboardScreen._count(state.analytics, 'sales').toString(),
                ),
                _MetricTile(
                  theme: theme,
                  label: l10n.realEstateDashListingsLeft,
                  value: listingsLeft,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.theme, required this.label, required this.value});

  final AppThemeData theme;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.divider),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: theme.titleText,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: theme.bodyText),
          ),
        ],
      ),
    );
  }
}
