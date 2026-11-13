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
import 'package:partner/app/modules/realestate/models/property_document.dart';
import 'package:partner/app/modules/realestate/vendor/listings/detail/bloc/listing_detail_bloc.dart';
import 'package:partner/app/modules/realestate/vendor/listings/form/bloc/listing_form_bloc.dart';
import 'package:partner/app/modules/realestate/vendor/listings/form/listing_form_view.dart';
import 'package:partner/app/modules/realestate/vendor/widgets/listing_status_chip.dart';
import 'package:partner/app/presentation/styles/theme.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

/// One listing in full: header facts, counters, specs, timeline,
/// documents, and the vendor-reachable transitions.
///
/// Pops with `true` when content changed (transition or edit save) so
/// the listings tab refreshes; `false` otherwise.
class ListingDetailScreen extends StatelessWidget {
  const ListingDetailScreen({super.key, required this.propertyId});

  final String propertyId;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return BlocProvider<ListingDetailBloc>(
      create: (_) => ListingDetailBloc()..add(ListingDetailLoadRequested(propertyId)),
      child: BlocConsumer<ListingDetailBloc, ListingDetailState>(
        listenWhen: (ListingDetailState previous, ListingDetailState current) =>
            previous.message != current.message && current.message.isNotEmpty,
        listener: (BuildContext context, ListingDetailState state) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
        },
        builder: (BuildContext context, ListingDetailState state) {
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (bool didPop, dynamic result) {
              if (didPop) return;
              Navigator.of(context).pop(context.read<ListingDetailBloc>().state.changed);
            },
            child: Scaffold(
              appBar: AppBar(
                title: Text(state.property?.propertyCode ?? l10n.realEstateNavListings),
                actions: <Widget>[
                  if (state.status == ListingDetailStatus.loaded && state.property != null)
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: l10n.realEstateDetailEdit,
                      onPressed: () => _openEdit(context, state.property!),
                    ),
                ],
              ),
              body: Builder(
                builder: (BuildContext context) {
                  switch (state.status) {
                    case ListingDetailStatus.initial:
                    case ListingDetailStatus.loading:
                      return const Center(child: CircularProgressIndicator());
                    case ListingDetailStatus.failure:
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(l10n.somethingWentWrong, style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () => context
                                  .read<ListingDetailBloc>()
                                  .add(ListingDetailLoadRequested(propertyId)),
                              child: Text(l10n.retry),
                            ),
                          ],
                        ),
                      );
                    case ListingDetailStatus.loaded:
                      return _DetailBody(state: state, l10n: l10n);
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openEdit(BuildContext context, RealEstatePropertyModel property) async {
    final bool? saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => ListingFormScreen(property: property)),
    );
    if (saved == true && context.mounted) {
      final ListingDetailBloc bloc = context.read<ListingDetailBloc>();
      bloc.add(const ListingDetailContentChanged());
      bloc.add(const ListingDetailRefreshed());
    }
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.state, required this.l10n});

  final ListingDetailState state;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final RealEstatePropertyModel property = state.property!;
    final AppThemeData theme = appThemeData[Theme.of(context).brightness == Brightness.dark ? AppTheme.dark : AppTheme.light]!;

    String? cover;
    for (final Map<String, dynamic> item in property.media) {
      if ((item['type']?.toString() ?? 'IMAGE') == 'IMAGE') {
        final String? url = item['thumbUrl']?.toString() ?? item['url']?.toString();
        if (url != null && url.isNotEmpty) {
          cover = url;
          break;
        }
      }
    }

    final String priceText;
    if (property.priceOnRequest) {
      priceText = 'Price on request';
    } else if (property.price != null) {
      priceText = '₹${formatIndianPrice(property.price!)}'
          '${property.pricePeriod == 'MONTH' ? '/mo' : ''}';
    } else {
      priceText = '—';
    }

    final List<ListingMilestone> milestones = listingMilestones(property);
    final List<DetailAction> actions = availableDetailActions(property.status);

    return RefreshIndicator(
      onRefresh: () async =>
          context.read<ListingDetailBloc>().add(const ListingDetailRefreshed()),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (cover != null)
              Image.network(
                resolveMediaUrl(cover),
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  height: 200,
                  color: theme.divider.withValues(alpha: 0.3),
                  child: Icon(Icons.apartment_outlined, size: 56, color: theme.bodyText),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ListingStatusChip(status: property.status, availability: property.availability),
                  const SizedBox(height: 8),
                  Text(
                    property.title ?? '—',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: theme.titleText,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    priceText,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: theme.titleText),
                  ),
                  if ((property.mapAddress ?? property.addressLine ?? '').isNotEmpty) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      (property.mapAddress?.isNotEmpty == true ? property.mapAddress : property.addressLine) ?? '',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: theme.bodyText),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    '${property.views} views · ${property.enquiries} enquiries · ${property.visits} visits · ${property.leads} leads',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: theme.bodyText),
                  ),
                  if ((property.description ?? '').isNotEmpty) ...<Widget>[
                    const SizedBox(height: 12),
                    Text(property.description!, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                  if (property.specs != null && property.specs!.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 16),
                    Text('Details', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    for (final MapEntry<String, dynamic> entry in property.specs!.entries)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                SpecFieldDescriptor.humanize(entry.key),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: theme.bodyText),
                              ),
                            ),
                            Text(
                              entry.value?.toString() ?? '—',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: theme.titleText),
                            ),
                          ],
                        ),
                      ),
                  ],
                  if (property.amenities.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 16),
                    Text(l10n.realEstateFormAmenities, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        for (final String amenity in property.amenities)
                          Chip(label: Text(amenity, style: Theme.of(context).textTheme.labelSmall)),
                      ],
                    ),
                  ],
                  if (milestones.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 20),
                    Text(l10n.realEstateDetailTimeline, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    for (final ListingMilestone milestone in milestones)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: <Widget>[
                            Icon(Icons.check_circle_outline, size: 16, color: theme.bodyText),
                            const SizedBox(width: 8),
                            Text(
                              milestone.label,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: theme.bodyText),
                            ),
                            const Spacer(),
                            Text(
                              milestone.at.toString().split(' ').first,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: theme.bodyText),
                            ),
                          ],
                        ),
                      ),
                  ],
                  const SizedBox(height: 20),
                  Text(
                    '${l10n.realEstateDetailDocuments} (${state.documents.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (state.documents.isEmpty)
                    Text(
                      '—',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: theme.bodyText),
                    )
                  else
                    for (final RealEstateDocumentModel doc in state.documents)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
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
                                    doc.title ?? doc.category ?? '—',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: theme.titleText,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  Text(
                                    '${doc.category ?? ''} · ${doc.visibility ?? ''}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: theme.bodyText),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: theme.divider),
                              ),
                              child: Text(
                                (doc.status ?? '—').replaceAll('_', ' '),
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                  if (actions.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 20),
                    for (final DetailAction action in actions) ...<Widget>[
                      _ActionButton(action: action, l10n: l10n, transitioning: state.transitioning),
                      const SizedBox(height: 8),
                    ],
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.action, required this.l10n, required this.transitioning});

  final DetailAction action;
  final AppLocalizations l10n;
  final bool transitioning;

  String _label() {
    switch (action.kind) {
      case DetailActionKind.submit:
        return l10n.realEstateDetailSubmit;
      case DetailActionKind.resubmit:
        return l10n.realEstateDetailResubmit;
      case DetailActionKind.withdraw:
        return l10n.realEstateDetailWithdraw;
      case DetailActionKind.archive:
        return l10n.realEstateDetailArchive;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool primary = action.kind == DetailActionKind.submit || action.kind == DetailActionKind.resubmit;

    Future<void> confirm() async {
      final ListingDetailBloc bloc = context.read<ListingDetailBloc>();
      final bool? proceed = await showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) {
          final bool consumes =
              action.kind == DetailActionKind.submit && bloc.state.property?.entitlementId == null;
          return AlertDialog(
            title: Text(_label()),
            content: consumes ? Text(l10n.realEstateDetailSubmitNote) : null,
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(l10n.realEstateDetailCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(l10n.realEstateDetailConfirm),
              ),
            ],
          );
        },
      );
      if (proceed == true && context.mounted) {
        context.read<ListingDetailBloc>().add(ListingDetailTransitionRequested(action.target));
      }
    }

    final Widget child = transitioning
        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
        : Text(_label());

    if (primary) {
      return FilledButton(
        onPressed: transitioning ? null : confirm,
        child: child,
      );
    }
    return OutlinedButton(
      onPressed: transitioning ? null : confirm,
      child: child,
    );
  }
}
