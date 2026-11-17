/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:partner/app/modules/realestate/models/property.dart';
import 'package:partner/app/modules/realestate/vendor/listings/bloc/vendor_listings_bloc.dart';
import 'package:partner/app/modules/realestate/vendor/listings/detail/listing_detail_view.dart';
import 'package:partner/app/modules/realestate/vendor/listings/form/listing_form_view.dart';
import 'package:partner/app/modules/realestate/vendor/modals/vendor_listing_filter_modal.dart';
import 'package:partner/app/modules/realestate/vendor/widgets/property_card.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

/// Vendor listings: nine lifecycle tabs (blueprint §39), each with its own
/// cached pages, pull-to-refresh and infinite scroll.
///
/// Tapping a row navigates to the listing detail once it registers — rows
/// are display-only until then, with no dead affordance.
class VendorListingsScreen extends StatelessWidget {
  const VendorListingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return BlocProvider<VendorListingsBloc>(
      create: (_) => VendorListingsBloc()..add(const VendorListingsTabSelected(listingsTabAll)),
      child: BlocBuilder<VendorListingsBloc, VendorListingsState>(
        builder: (BuildContext context, VendorListingsState state) {
          return DefaultTabController(
            length: listingsTabs.length,
            child: Scaffold(
              appBar: AppBar(
                title: Text(l10n.realEstateNavListings),
                actions: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: () => VendorListingFilterModal.show(context),
                  ),
                ],
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () async {
                  final bool? saved = await Navigator.of(context).push<bool>(
                    MaterialPageRoute<bool>(
                      builder: (_) => const ListingFormScreen(),
                    ),
                  );
                  if (saved == true && context.mounted) {
                    context.read<VendorListingsBloc>().add(const VendorListingsRefreshed());
                  }
                },
                child: const Icon(Icons.add),
              ),
              body: Column(
                children: <Widget>[
                  TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    tabs: listingsTabs.map((ListingsTab t) => Tab(text: t.label)).toList(),
                    onTap: (int index) => context
                        .read<VendorListingsBloc>()
                        .add(VendorListingsTabSelected(listingsTabs[index].id)),
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

  final VendorListingsState state;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    switch (state.status) {
      case VendorListingsStatus.initial:
      case VendorListingsStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case VendorListingsStatus.failure:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(l10n.somethingWentWrong, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => context.read<VendorListingsBloc>().add(const VendorListingsRefreshed()),
                child: Text(l10n.retry),
              ),
            ],
          ),
        );
      case VendorListingsStatus.loaded:
        if (state.items.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async =>
                context.read<VendorListingsBloc>().add(const VendorListingsRefreshed()),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child: Center(
                  child: Text(l10n.realEstateListingsEmpty, style: Theme.of(context).textTheme.bodyMedium),
                ),
              ),
            ),
          );
        }
        return _ListingsList(state: state);
    }
  }
}

class _ListingsList extends StatefulWidget {
  const _ListingsList({required this.state});

  final VendorListingsState state;

  @override
  State<_ListingsList> createState() => _ListingsListState();
}

class _ListingsListState extends State<_ListingsList> {
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
      context.read<VendorListingsBloc>().add(const VendorListingsNextPage());
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<RealEstatePropertyModel> items = widget.state.items;

    return RefreshIndicator(
      onRefresh: () async =>
          context.read<VendorListingsBloc>().add(const VendorListingsRefreshed()),
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
          final RealEstatePropertyModel property = items[index];
          return VendorPropertyCard(
            property: property,
            onTap: () async {
              final bool? changed = await Navigator.of(context).push<bool>(
                MaterialPageRoute<bool>(
                  builder: (_) => ListingDetailScreen(propertyId: property.id),
                ),
              );
              if (changed == true && context.mounted) {
                context.read<VendorListingsBloc>().add(const VendorListingsRefreshed());
              }
            },
          );
        },
      ),
    );
  }
}
