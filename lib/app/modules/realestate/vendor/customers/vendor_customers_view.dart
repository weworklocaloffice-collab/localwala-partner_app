/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:partner/app/modules/realestate/models/lead.dart';
import 'package:partner/app/modules/realestate/vendor/customers/bloc/vendor_customers_bloc.dart';
import 'package:partner/app/presentation/styles/theme.dart';
import 'package:partner/gen/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

/// Vendor customers: every customer behind a lead or a visit, with a
/// call button. Rows do not navigate — customer history lives in the
/// leads and visits tabs, and a cross-tab filter is a later unit, not a
/// dead row action today.
class VendorCustomersScreen extends StatelessWidget {
  const VendorCustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return BlocProvider<VendorCustomersBloc>(
      create: (_) => VendorCustomersBloc()..add(const VendorCustomersLoadRequested()),
      child: BlocBuilder<VendorCustomersBloc, VendorCustomersState>(
        builder: (BuildContext context, VendorCustomersState state) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.navCustomers)),
            body: Builder(
              builder: (BuildContext context) {
                switch (state.status) {
                  case VendorCustomersStatus.initial:
                  case VendorCustomersStatus.loading:
                    return const Center(child: CircularProgressIndicator());
                  case VendorCustomersStatus.failure:
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(l10n.somethingWentWrong, style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => context
                                .read<VendorCustomersBloc>()
                                .add(const VendorCustomersRefreshed()),
                            child: Text(l10n.retry),
                          ),
                        ],
                      ),
                    );
                  case VendorCustomersStatus.loaded:
                    if (state.items.isEmpty) {
                      return RefreshIndicator(
                        onRefresh: () async => context
                            .read<VendorCustomersBloc>()
                            .add(const VendorCustomersRefreshed()),
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: Center(
                              child: Text(
                                l10n.realEstateCustomersEmpty,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                    return _CustomersList(state: state);
                }
              },
            ),
          );
        },
      ),
    );
  }
}

class _CustomersList extends StatefulWidget {
  const _CustomersList({required this.state});

  final VendorCustomersState state;

  @override
  State<_CustomersList> createState() => _CustomersListState();
}

class _CustomersListState extends State<_CustomersList> {
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_controller.hasClients) return;
    final double max = _controller.position.maxScrollExtent;
    if (max <= 0) return;
    if (_controller.offset >= max - 300) {
      context.read<VendorCustomersBloc>().add(const VendorCustomersNextPage());
    }
  }

  Future<void> _call(String mobile) async {
    await launchUrl(Uri(scheme: 'tel', path: mobile));
  }

  @override
  Widget build(BuildContext context) {
    final List<RealEstateCustomerRef> items = widget.state.items;
    final AppThemeData theme = appThemeData[Theme.of(context).brightness == Brightness.dark ? AppTheme.dark : AppTheme.light]!;

    return RefreshIndicator(
      onRefresh: () async =>
          context.read<VendorCustomersBloc>().add(const VendorCustomersRefreshed()),
      child: ListView.separated(
        controller: _controller,
        padding: const EdgeInsets.all(16),
        itemCount: items.length + (widget.state.loadingMore ? 1 : 0),
        separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 8),
        itemBuilder: (BuildContext context, int index) {
          if (index >= items.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: CircularProgressIndicator(),
              ),
            );
          }
          final RealEstateCustomerRef customer = items[index];
          final String name = customer.displayName;

          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.divider),
            ),
            child: Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 18,
                  backgroundColor: theme.primary.withValues(alpha: 0.12),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: theme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: theme.titleText,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      if ((customer.mobile ?? '').isNotEmpty)
                        Text(
                          customer.mobile!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: theme.bodyText),
                        ),
                    ],
                  ),
                ),
                if ((customer.mobile ?? '').isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.call_outlined),
                    onPressed: () => _call(customer.mobile!),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
