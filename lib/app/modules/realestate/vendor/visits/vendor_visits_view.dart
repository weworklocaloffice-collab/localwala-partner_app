/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:partner/app/modules/realestate/models/visit.dart';
import 'package:partner/app/modules/realestate/vendor/leads/detail/lead_detail_view.dart';
import 'package:partner/app/modules/realestate/vendor/visits/bloc/vendor_visits_bloc.dart';
import 'package:partner/app/modules/realestate/vendor/widgets/listing_status_chip.dart';
import 'package:partner/app/presentation/styles/theme.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

/// Vendor visit schedule: read-only rows of what is happening on the
/// vendor's listings, newest scheduled first.
///
/// Rows navigate to the lead detail (which exists); there is no vendor
/// visit-detail screen, and the vendor cannot change anything about a
/// visit (BR-08, BR-09).
class VendorVisitsScreen extends StatelessWidget {
  const VendorVisitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return BlocProvider<VendorVisitsBloc>(
      create: (_) => VendorVisitsBloc()..add(const VendorVisitsTabSelected(visitsTabAll)),
      child: BlocBuilder<VendorVisitsBloc, VendorVisitsState>(
        builder: (BuildContext context, VendorVisitsState state) {
          return DefaultTabController(
            length: visitsTabs.length,
            child: Scaffold(
              appBar: AppBar(title: Text(l10n.realEstateNavVisits)),
              body: Column(
                children: <Widget>[
                  TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    tabs: visitsTabs.map((VisitsTab t) => Tab(text: t.label)).toList(),
                    onTap: (int index) => context
                        .read<VendorVisitsBloc>()
                        .add(VendorVisitsTabSelected(visitsTabs[index].id)),
                  ),
                  Expanded(child: _TabBody(state: state)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TabBody extends StatelessWidget {
  const _TabBody({required this.state});

  final VendorVisitsState state;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    switch (state.status) {
      case VendorVisitsStatus.initial:
      case VendorVisitsStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case VendorVisitsStatus.failure:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(l10n.somethingWentWrong, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => context.read<VendorVisitsBloc>().add(const VendorVisitsRefreshed()),
                child: Text(l10n.retry),
              ),
            ],
          ),
        );
      case VendorVisitsStatus.loaded:
        if (state.items.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async =>
                context.read<VendorVisitsBloc>().add(const VendorVisitsRefreshed()),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child: Center(
                  child: Text(l10n.realEstateVisitsEmpty, style: Theme.of(context).textTheme.bodyMedium),
                ),
              ),
            ),
          );
        }
        return _VisitsList(state: state);
    }
  }
}

class _VisitsList extends StatefulWidget {
  const _VisitsList({required this.state});

  final VendorVisitsState state;

  @override
  State<_VisitsList> createState() => _VisitsListState();
}

class _VisitsListState extends State<_VisitsList> {
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
      context.read<VendorVisitsBloc>().add(const VendorVisitsNextPage());
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<RealEstateVisitModel> items = widget.state.items;
    final AppThemeData theme = appThemeData[Theme.of(context).brightness == Brightness.dark ? AppTheme.dark : AppTheme.light]!;

    return RefreshIndicator(
      onRefresh: () async =>
          context.read<VendorVisitsBloc>().add(const VendorVisitsRefreshed()),
      child: ListView.separated(
        controller: _controller,
        padding: const EdgeInsets.all(16),
        itemCount: items.length + (widget.state.loadingMore ? 1 : 0),
        separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 12),
        itemBuilder: (BuildContext context, int index) {
          if (index >= items.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: CircularProgressIndicator(),
              ),
            );
          }
          final RealEstateVisitModel visit = items[index];
          final bool hasLead = visit.leadId != null && visit.leadId!.isNotEmpty;

          return Material(
            color: theme.cardBg,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: hasLead
                  ? () => Navigator.of(context).push(
                        MaterialPageRoute<bool>(
                          builder: (_) => LeadDetailScreen(leadId: visit.leadId!),
                        ),
                      )
                  : null,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        ListingStatusChip(status: visit.status),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            visit.scheduledAt?.toString().split(' ').first ?? '—',
                            textAlign: TextAlign.right,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: theme.bodyText),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      visit.property?.title ?? '—',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: theme.titleText,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      visit.customer?.displayName ?? '—',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: theme.bodyText),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
