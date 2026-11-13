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
import 'package:partner/app/modules/realestate/vendor/leads/bloc/vendor_leads_bloc.dart';
import 'package:partner/app/modules/realestate/vendor/leads/detail/lead_detail_view.dart';
import 'package:partner/app/modules/realestate/vendor/widgets/lead_card.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

/// Vendor leads: ten lifecycle tabs, each with its own cached pages,
/// pull-to-refresh and infinite scroll.
///
/// Rows are display-only until the lead detail screen registers — no
/// dead affordance.
class VendorLeadsScreen extends StatelessWidget {
  const VendorLeadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return BlocProvider<VendorLeadsBloc>(
      create: (_) => VendorLeadsBloc()..add(const VendorLeadsTabSelected(leadsTabAll)),
      child: BlocBuilder<VendorLeadsBloc, VendorLeadsState>(
        builder: (BuildContext context, VendorLeadsState state) {
          return DefaultTabController(
            length: leadsTabs.length,
            child: Scaffold(
              appBar: AppBar(title: Text(l10n.realEstateNavLeads)),
              body: Column(
                children: <Widget>[
                  TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    tabs: leadsTabs.map((LeadsTab t) => Tab(text: t.label)).toList(),
                    onTap: (int index) => context
                        .read<VendorLeadsBloc>()
                        .add(VendorLeadsTabSelected(leadsTabs[index].id)),
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

  final VendorLeadsState state;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    switch (state.status) {
      case VendorLeadsStatus.initial:
      case VendorLeadsStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case VendorLeadsStatus.failure:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(l10n.somethingWentWrong, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => context.read<VendorLeadsBloc>().add(const VendorLeadsRefreshed()),
                child: Text(l10n.retry),
              ),
            ],
          ),
        );
      case VendorLeadsStatus.loaded:
        if (state.items.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async =>
                context.read<VendorLeadsBloc>().add(const VendorLeadsRefreshed()),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child: Center(
                  child: Text(l10n.realEstateLeadsEmpty, style: Theme.of(context).textTheme.bodyMedium),
                ),
              ),
            ),
          );
        }
        return _LeadsList(state: state);
    }
  }
}

class _LeadsList extends StatefulWidget {
  const _LeadsList({required this.state});

  final VendorLeadsState state;

  @override
  State<_LeadsList> createState() => _LeadsListState();
}

class _LeadsListState extends State<_LeadsList> {
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
      context.read<VendorLeadsBloc>().add(const VendorLeadsNextPage());
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<RealEstateLeadModel> items = widget.state.items;

    return RefreshIndicator(
      onRefresh: () async =>
          context.read<VendorLeadsBloc>().add(const VendorLeadsRefreshed()),
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
          final RealEstateLeadModel lead = items[index];
          return VendorLeadCard(
            lead: lead,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<bool>(
                builder: (_) => LeadDetailScreen(leadId: lead.id),
              ),
            ),
          );
        },
      ),
    );
  }
}
