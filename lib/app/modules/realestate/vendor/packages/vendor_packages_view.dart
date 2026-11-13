/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:partner/app/modules/realestate/models/listing_entitlement.dart';
import 'package:partner/app/modules/realestate/models/listing_package.dart';
import 'package:partner/app/modules/realestate/vendor/packages/bloc/vendor_packages_bloc.dart';
import 'package:partner/app/modules/realestate/vendor/checkout/vendor_checkout_view.dart';
import 'package:partner/app/modules/realestate/vendor/widgets/package_card.dart';
import 'package:partner/app/presentation/styles/theme.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

/// Purchase catalogue with the entitlement balance on top.
///
/// Browse + balance only — buying lives in the checkout screen, which
/// passes the `onBuy` the cards already accept.
class VendorPackagesScreen extends StatelessWidget {
  const VendorPackagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return BlocProvider<VendorPackagesBloc>(
      create: (_) => VendorPackagesBloc()..add(const VendorPackagesLoadRequested()),
      child: BlocBuilder<VendorPackagesBloc, VendorPackagesState>(
        builder: (BuildContext context, VendorPackagesState state) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.realEstateNavPackages)),
            body: Builder(
              builder: (BuildContext context) {
                switch (state.status) {
                  case VendorPackagesStatus.initial:
                  case VendorPackagesStatus.loading:
                    return const Center(child: CircularProgressIndicator());
                  case VendorPackagesStatus.failure:
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(l10n.somethingWentWrong, style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => context
                                .read<VendorPackagesBloc>()
                                .add(const VendorPackagesRefreshed()),
                            child: Text(l10n.retry),
                          ),
                        ],
                      ),
                    );
                  case VendorPackagesStatus.loaded:
                    return _PackagesBody(state: state, l10n: l10n);
                }
              },
            ),
          );
        },
      ),
    );
  }
}

class _PackagesBody extends StatelessWidget {
  const _PackagesBody({required this.state, required this.l10n});

  final VendorPackagesState state;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = appThemeData[Theme.of(context).brightness == Brightness.dark ? AppTheme.dark : AppTheme.light]!;
    final int balance = totalRemaining(state.entitlements);
    final String balanceText = balance < 0 ? l10n.realEstateDashUnlimited : balance.toString();

    return RefreshIndicator(
      onRefresh: () async =>
          context.read<VendorPackagesBloc>().add(const VendorPackagesRefreshed()),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.divider),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          l10n.realEstateDashListingsLeft,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: theme.bodyText),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          balanceText,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: theme.titleText,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.card_membership_outlined, size: 40, color: theme.primary),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (state.packages.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text(l10n.realEstatePackagesEmpty, style: Theme.of(context).textTheme.bodyMedium),
                ),
              )
            else
              for (final RealEstatePackageModel package in state.packages) ...<Widget>[
                VendorPackageCard(
                  package: package,
                  onBuy: (RealEstatePackageModel p) async {
                    final bool? bought = await Navigator.of(context).push<bool>(
                      MaterialPageRoute<bool>(
                        builder: (_) => VendorCheckoutScreen(packageCode: p.code ?? ''),
                      ),
                    );
                    if (bought == true && context.mounted) {
                      context.read<VendorPackagesBloc>().add(const VendorPackagesRefreshed());
                    }
                  },
                ),
                const SizedBox(height: 12),
              ],
            const SizedBox(height: 8),
            if (state.entitlements.isNotEmpty) ...<Widget>[
              Text(
                '${l10n.realEstatePackagesActiveCount}: ${state.entitlements.length}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: theme.bodyText),
              ),
              const SizedBox(height: 8),
              for (final RealEstateEntitlementModel entitlement in state.entitlements)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          entitlement.packageSnapshot?['name']?.toString() ??
                              entitlement.packageSnapshot?['code']?.toString() ??
                              '—',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: theme.bodyText),
                        ),
                      ),
                      Text(
                        entitlement.totalCount == null
                            ? l10n.realEstateDashUnlimited
                            : '${entitlement.totalCount! - entitlement.consumedCount} / ${entitlement.totalCount}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: theme.bodyText),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
