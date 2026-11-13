/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:partner/app/modules/realestate/models/follow_up.dart';
import 'package:partner/app/modules/realestate/models/lead.dart';
import 'package:partner/app/modules/realestate/models/lead_detail.dart';
import 'package:partner/app/modules/realestate/models/property.dart';
import 'package:partner/app/modules/realestate/models/visit.dart';
import 'package:partner/app/modules/realestate/vendor/leads/detail/bloc/lead_detail_bloc.dart';
import 'package:partner/app/modules/realestate/vendor/listings/detail/listing_detail_view.dart';
import 'package:partner/app/modules/realestate/vendor/widgets/listing_status_chip.dart';
import 'package:partner/app/presentation/styles/theme.dart';
import 'package:partner/gen/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

/// One lead with its crossroads: customer, property, source, executive,
/// status, visits, follow-ups, hold, sale and the latest loan status.
///
/// Read-only for the vendor — every mutation belongs to another actor —
/// so there are no transitions here, only navigation (property detail)
/// and a call button.
class LeadDetailScreen extends StatelessWidget {
  const LeadDetailScreen({super.key, required this.leadId});

  final String leadId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LeadDetailBloc>(
      create: (_) => LeadDetailBloc()..add(LeadDetailLoadRequested(leadId)),
      child: BlocBuilder<LeadDetailBloc, LeadDetailState>(
        builder: (BuildContext context, LeadDetailState state) {
          final AppLocalizations l10n = AppLocalizations.of(context)!;

          return Scaffold(
            appBar: AppBar(
              title: Text(state.detail?.lead.leadCode ?? l10n.realEstateNavLeads),
            ),
            body: Builder(
              builder: (BuildContext context) {
                switch (state.status) {
                  case LeadDetailStatus.initial:
                  case LeadDetailStatus.loading:
                    return const Center(child: CircularProgressIndicator());
                  case LeadDetailStatus.failure:
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(l10n.somethingWentWrong, style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => context
                                .read<LeadDetailBloc>()
                                .add(LeadDetailLoadRequested(leadId)),
                            child: Text(l10n.retry),
                          ),
                        ],
                      ),
                    );
                  case LeadDetailStatus.loaded:
                    return _DetailBody(detail: state.detail!, l10n: l10n);
                }
              },
            ),
          );
        },
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.detail, required this.l10n});

  final RealEstateLeadDetail detail;
  final AppLocalizations l10n;

  Future<void> _call(String mobile) async {
    await launchUrl(Uri(scheme: 'tel', path: mobile));
  }

  @override
  Widget build(BuildContext context) {
    final RealEstateLeadModel lead = detail.lead;
    final AppThemeData theme = appThemeData[Theme.of(context).brightness == Brightness.dark ? AppTheme.dark : AppTheme.light]!;
    final String customerName = lead.customer?.displayName ?? '—';
    final String mobile = lead.customer?.mobile ?? '';

    return RefreshIndicator(
      onRefresh: () async =>
          context.read<LeadDetailBloc>().add(const LeadDetailRefreshed()),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Customer card.
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.divider),
              ),
              child: Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: theme.primary.withValues(alpha: 0.12),
                    child: Text(
                      customerName.isNotEmpty ? customerName[0].toUpperCase() : '?',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: theme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          customerName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: theme.titleText,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        if (mobile.isNotEmpty)
                          Text(
                            mobile,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: theme.bodyText),
                          ),
                      ],
                    ),
                  ),
                  if (mobile.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.call_outlined),
                      onPressed: () => _call(mobile),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Status row.
            Row(
              children: <Widget>[
                ListingStatusChip(status: lead.status),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${l10n.realEstateLeadDetailSource}: ${lead.source ?? '—'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: theme.bodyText),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Property card (navigates — the detail screen exists).
            _SectionCard(
              theme: theme,
              title: l10n.realEstateLeadDetailProperty,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: lead.propertyId != null && lead.propertyId!.isNotEmpty
                    ? () => Navigator.of(context).push(
                          MaterialPageRoute<bool>(
                            builder: (_) => ListingDetailScreen(propertyId: lead.propertyId!),
                          ),
                        )
                    : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              lead.property?.title ?? '—',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: theme.titleText,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            if ((lead.property?.propertyCode ?? '').isNotEmpty)
                              Text(
                                lead.property!.propertyCode!,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: theme.bodyText),
                              ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Executive row (assigned state only — names stay server-side).
            _SectionCard(
              theme: theme,
              title: l10n.realEstateLeadDetailExecutive,
              child: Text(
                (lead.executiveId ?? '').isNotEmpty
                    ? l10n.realEstateLeadDetailAssigned
                    : l10n.realEstateLeadDetailUnassigned,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: theme.titleText),
              ),
            ),
            const SizedBox(height: 12),
            // Visits.
            _SectionCard(
              theme: theme,
              title: '${l10n.realEstateDashVisits} (${detail.visits.length})',
              child: detail.visits.isEmpty
                  ? Text('—', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: theme.bodyText))
                  : Column(
                      children: <Widget>[
                        for (final RealEstateVisitModel visit in detail.visits)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: <Widget>[
                                ListingStatusChip(status: visit.status),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    visit.scheduledAt?.toString().split(' ').first ?? '—',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: theme.bodyText),
                                  ),
                                ),
                                if ((visit.executiveName ?? '').isNotEmpty)
                                  Text(
                                    visit.executiveName!,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: theme.bodyText),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 12),
            // Follow-ups.
            _SectionCard(
              theme: theme,
              title: '${l10n.realEstateLeadDetailFollowUps} (${detail.followUps.length})',
              child: detail.followUps.isEmpty
                  ? Text('—', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: theme.bodyText))
                  : Column(
                      children: <Widget>[
                        for (final RealEstateFollowUpModel followUp in detail.followUps)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: <Widget>[
                                ListingStatusChip(status: followUp.status),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    followUp.mode ?? '—',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: theme.bodyText),
                                  ),
                                ),
                                Text(
                                  followUp.nextFollowUpAt?.toString().split(' ').first ?? '—',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: theme.bodyText),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),
            // Hold.
            if (detail.hold != null) ...<Widget>[
              const SizedBox(height: 12),
              _SectionCard(
                theme: theme,
                title: l10n.realEstateLeadDetailHold,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        ListingStatusChip(status: detail.hold!.status),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            detail.hold!.holdCode ?? '',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: theme.bodyText),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '₹${formatIndianPrice(detail.hold!.principal ?? 0)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: theme.titleText,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
            ],
            // Sale.
            if (detail.sale != null) ...<Widget>[
              const SizedBox(height: 12),
              _SectionCard(
                theme: theme,
                title: l10n.realEstateLeadDetailSale,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        ListingStatusChip(status: detail.sale!.status),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            detail.sale!.saleCode ?? '',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: theme.bodyText),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '₹${formatIndianPrice(detail.sale!.saleValue ?? 0)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: theme.titleText,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            // Loan (read-only status).
            _SectionCard(
              theme: theme,
              title: l10n.realEstateLeadDetailLoan,
              child: (detail.latestLoanStatus ?? '').isNotEmpty
                  ? ListingStatusChip(status: detail.latestLoanStatus)
                  : Text(
                      l10n.realEstateLeadDetailNoLoan,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: theme.bodyText),
                    ),
            ),
            // Activities.
            if (lead.activities.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              _SectionCard(
                theme: theme,
                title: l10n.realEstateLeadDetailActivity,
                child: Column(
                  children: <Widget>[
                    for (final RealEstateLeadActivity activity in lead.activities)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Icon(Icons.circle, size: 8, color: theme.bodyText),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    activity.action ?? activity.toStatus ?? '—',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: theme.titleText),
                                  ),
                                  if ((activity.note ?? '').isNotEmpty)
                                    Text(
                                      activity.note!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: theme.bodyText),
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              activity.createdAt?.toString().split(' ').first ?? '',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: theme.bodyText),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.theme, required this.title, required this.child});

  final AppThemeData theme;
  final String title;
  final Widget child;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: theme.bodyText,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
