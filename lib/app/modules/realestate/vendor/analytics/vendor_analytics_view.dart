/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:partner/app/modules/realestate/vendor/analytics/bloc/vendor_analytics_bloc.dart';
import 'package:partner/app/presentation/styles/theme.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

/// Analytics tiles: views, enquiries, leads, visits, conversion.
class VendorAnalyticsScreen extends StatelessWidget {
  const VendorAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return BlocProvider<VendorAnalyticsBloc>(
      create: (_) => VendorAnalyticsBloc()..add(const VendorAnalyticsLoadRequested()),
      child: BlocBuilder<VendorAnalyticsBloc, VendorAnalyticsState>(
        builder: (BuildContext context, VendorAnalyticsState state) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.realEstateNavAnalytics)),
            body: Builder(
              builder: (BuildContext context) {
                switch (state.status) {
                  case VendorAnalyticsStatus.initial:
                  case VendorAnalyticsStatus.loading:
                    return const Center(child: CircularProgressIndicator());
                  case VendorAnalyticsStatus.failure:
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            state.message.isNotEmpty ? state.message : l10n.somethingWentWrong,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => context
                                .read<VendorAnalyticsBloc>()
                                .add(const VendorAnalyticsRefreshed()),
                            child: Text(l10n.retry),
                          ),
                        ],
                      ),
                    );
                  case VendorAnalyticsStatus.loaded:
                    return _AnalyticsBody(data: state.data);
                }
              },
            ),
          );
        },
      ),
    );
  }
}

class _AnalyticsBody extends StatelessWidget {
  const _AnalyticsBody({required this.data});

  final Map<String, dynamic> data;

  String _text(dynamic v) => v == null ? '—' : v.toString();

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = appThemeData[Theme.of(context).brightness == Brightness.dark ? AppTheme.dark : AppTheme.light]!;
    final List<MapEntry<String, dynamic>> entries = data.entries.toList();

    if (entries.isEmpty) {
      return const Center(child: Text('—'));
    }

    return RefreshIndicator(
      onRefresh: () async =>
          context.read<VendorAnalyticsBloc>().add(const VendorAnalyticsRefreshed()),
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.4,
        ),
        itemCount: entries.length,
        itemBuilder: (BuildContext context, int index) {
          final MapEntry<String, dynamic> entry = entries[index];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.divider),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  _text(entry.value),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: theme.titleText,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.key,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
