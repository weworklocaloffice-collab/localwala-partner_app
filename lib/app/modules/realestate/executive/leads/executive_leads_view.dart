/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright Â© 2026 WeWorkLocal.
 * All Rights Reserved.
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:partner/app/modules/realestate/executive/leads/bloc/executive_leads_bloc.dart';
import 'package:partner/app/modules/realestate/executive/lead_detail/executive_lead_detail_view.dart';
import 'package:partner/app/modules/realestate/models/lead.dart';
import 'package:partner/app/modules/realestate/models/lead_detail.dart';
import 'package:partner/app/modules/realestate/repository/executive_repository.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

/// Assigned leads: customer, property, status, visit/follow-up counts.
///
/// Tapping a row loads `GET /executive/leads/:leadId` into a bottom
/// sheet (visits, follow-ups, hold/sale refs). Assignment itself is
/// server side (BR-07) — no action here mutates.
class ExecutiveLeadsScreen extends StatelessWidget {
  const ExecutiveLeadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return BlocProvider<ExecutiveLeadsBloc>(
      create: (_) => ExecutiveLeadsBloc()..add(const ExecutiveLeadsLoad()),
      child: BlocBuilder<ExecutiveLeadsBloc, ExecutiveLeadsState>(
        builder: (BuildContext context, ExecutiveLeadsState state) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.realEstateNavLeads)),
            body: Builder(
              builder: (BuildContext context) {
                switch (state.status) {
                  case ExecutiveLeadsStatus.initial:
                  case ExecutiveLeadsStatus.loading:
                    return const Center(child: CircularProgressIndicator());
                  case ExecutiveLeadsStatus.failure:
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(l10n.somethingWentWrong, style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () =>
                                context.read<ExecutiveLeadsBloc>().add(const ExecutiveLeadsLoad()),
                            child: Text(l10n.retry),
                          ),
                        ],
                      ),
                    );
                  case ExecutiveLeadsStatus.loaded:
                    if (state.items.isEmpty) {
                      return RefreshIndicator(
                        onRefresh: () async =>
                            context.read<ExecutiveLeadsBloc>().add(const ExecutiveLeadsRefreshed()),
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: 400,
                            child: Center(child: Text(l10n.realEstateExecNoLeadsAssigned)),
                          ),
                        ),
                      );
                    }
                    return NotificationListener<ScrollNotification>(
                      onNotification: (ScrollNotification n) {
                        if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
                          context.read<ExecutiveLeadsBloc>().add(const ExecutiveLeadsNextPage());
                        }
                        return false;
                      },
                      child: RefreshIndicator(
                        onRefresh: () async =>
                            context.read<ExecutiveLeadsBloc>().add(const ExecutiveLeadsRefreshed()),
                        child: ListView.separated(
                          itemCount: state.items.length + (state.loadingMore ? 1 : 0),
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (BuildContext context, int index) {
                            if (index >= state.items.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }
                            final RealEstateLeadModel lead = state.items[index];
                            return ListTile(
                              title: Text(lead.customer?.displayName ?? lead.leadCode ?? lead.id),
                              subtitle: Text(
                                '${lead.property?.title ?? lead.propertyId ?? '—'}\n'
                                '${l10n.realEstateExecLeadSummary(lead.visitCount, lead.followUpCount)}',
                              ),
                              trailing: Text(lead.status ?? '—'),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => ExecutiveLeadDetailScreen(leadId: lead.id),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                }
              },
            ),
          );
        },
      ),
    );
  }


}

class _LeadDetailSheet extends StatefulWidget {
  const _LeadDetailSheet({required this.leadId});

  final String leadId;

  @override
  State<_LeadDetailSheet> createState() => _LeadDetailSheetState();
}

class _LeadDetailSheetState extends State<_LeadDetailSheet> {
  RealEstateLeadDetail? _detail;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final RealEstateLeadDetail? d = await RealEstateExecutiveRepository().lead(widget.leadId);
      if (!mounted) return;
      setState(() {
        _detail = d;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    if (_loading) return const SizedBox(height: 240, child: Center(child: CircularProgressIndicator()));
    if (_error != null) return SizedBox(height: 200, child: Center(child: Text(_error!)));
    final RealEstateLeadDetail? d = _detail;
    if (d == null) return SizedBox(height: 200, child: Center(child: Text(l10n.realEstateExecLeadNotFound)));
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(d.lead.customer?.displayName ?? d.lead.id, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              '${l10n.realEstateCheckoutStatus}: ${d.lead.status ?? '—'}\n'
              '${l10n.realEstateExecLeadSummary(d.visits.length, d.followUps.length)}',
            ),
            if (d.latestLoanStatus != null)
              Text('${l10n.realEstateExecLatestLoan}: ${d.latestLoanStatus}'),
            const SizedBox(height: 8),
            ...d.followUps.map(
              (f) => ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text('${f.mode ?? l10n.realEstateExecFollowUp} · ${f.status ?? ''}'),
                subtitle: Text(f.notes ?? ''),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
