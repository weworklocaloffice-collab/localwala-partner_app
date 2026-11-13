/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:partner/app/modules/realestate/models/commission.dart';
import 'package:partner/app/modules/realestate/models/property.dart';
import 'package:partner/app/modules/realestate/vendor/commissions/bloc/vendor_commissions_bloc.dart';
import 'package:partner/app/presentation/styles/theme.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

const List<String> _commissionFilters = <String>[
  '',
  'PENDING',
  'EARNED',
  'SETTLEMENT_CREATED',
  'PAID',
];

/// Commissions: the vendor's sale-commission rows with status filter.
class VendorCommissionsScreen extends StatelessWidget {
  const VendorCommissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return BlocProvider<VendorCommissionsBloc>(
      create: (_) => VendorCommissionsBloc()..add(const VendorCommissionsLoadRequested()),
      child: BlocBuilder<VendorCommissionsBloc, VendorCommissionsState>(
        builder: (BuildContext context, VendorCommissionsState state) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.realEstateNavCommissions)),
            body: Column(
              children: <Widget>[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: <Widget>[
                      for (final String f in _commissionFilters)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(f.isEmpty ? l10n.realEstateFilterAll : f),
                            selected: state.filter == f,
                            onSelected: (_) => context
                                .read<VendorCommissionsBloc>()
                                .add(VendorCommissionsFilterChanged(f)),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Builder(
                    builder: (BuildContext context) {
                      switch (state.status) {
                        case VendorCommissionsStatus.initial:
                        case VendorCommissionsStatus.loading:
                          return const Center(child: CircularProgressIndicator());
                        case VendorCommissionsStatus.failure:
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Text(
                                  state.message.isNotEmpty ? state.message : l10n.somethingWentWrong,
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: () => context
                                      .read<VendorCommissionsBloc>()
                                      .add(const VendorCommissionsRefreshed()),
                                  child: Text(l10n.retry),
                                ),
                              ],
                            ),
                          );
                        case VendorCommissionsStatus.loaded:
                          return _CommissionsBody(state: state, l10n: l10n);
                      }
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CommissionsBody extends StatelessWidget {
  const _CommissionsBody({required this.state, required this.l10n});

  final VendorCommissionsState state;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = appThemeData[Theme.of(context).brightness == Brightness.dark ? AppTheme.dark : AppTheme.light]!;

    if (state.commissions.isEmpty) {
      return Center(child: Text(l10n.realEstateCommissionsEmpty));
    }

    return RefreshIndicator(
      onRefresh: () async =>
          context.read<VendorCommissionsBloc>().add(const VendorCommissionsRefreshed()),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: state.commissions.length,
        separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 12),
        itemBuilder: (BuildContext context, int index) {
          final RealEstateCommissionModel c = state.commissions[index];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        c.commissionNo ?? c.id,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: theme.titleText,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    Text(
                      c.amount != null ? '₹${formatIndianPrice(c.amount!)}' : '—',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: theme.titleText),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${c.status ?? '—'}${c.rate != null ? ' · ${c.rate}%' : ''}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: theme.bodyText),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
