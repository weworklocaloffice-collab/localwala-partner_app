import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:partner/app/modules/realestate/executive/lead_detail/bloc/executive_lead_detail_bloc.dart';
import 'package:partner/app/modules/realestate/models/lead_detail.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

class ExecutiveLeadDetailScreen extends StatelessWidget {
  const ExecutiveLeadDetailScreen({super.key, required this.leadId});

  final String leadId;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return BlocProvider<ExecutiveLeadDetailBloc>(
      create: (_) => ExecutiveLeadDetailBloc()..add(ExecutiveLeadDetailLoad(leadId)),
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.realEstateNavLeads)),
        body: BlocBuilder<ExecutiveLeadDetailBloc, ExecutiveLeadDetailState>(
          builder: (BuildContext context, ExecutiveLeadDetailState state) {
            switch (state.status) {
              case ExecutiveLeadDetailStatus.initial:
              case ExecutiveLeadDetailStatus.loading:
                return const Center(child: CircularProgressIndicator());
              case ExecutiveLeadDetailStatus.failure:
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(state.message, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => context
                            .read<ExecutiveLeadDetailBloc>()
                            .add(ExecutiveLeadDetailRefreshed(leadId)),
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                );
              case ExecutiveLeadDetailStatus.loaded:
                final RealEstateLeadDetail d = state.detail!;
                return RefreshIndicator(
                  onRefresh: () async => context
                      .read<ExecutiveLeadDetailBloc>()
                      .add(ExecutiveLeadDetailRefreshed(leadId)),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: <Widget>[
                      Text(d.lead.customer?.displayName ?? d.lead.leadCode ?? d.lead.id,
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(d.lead.property?.title ?? d.lead.propertyId ?? '-'),
                      Text('Status: ${d.lead.status ?? '-'}'),
                      if (d.latestLoanStatus != null) Text('Loan: $d.latestLoanStatus'),
                      if (d.hold != null) Text('Hold: ${d.hold!.id}'),
                      if (d.sale != null) Text('Sale: ${d.sale!.saleCode ?? d.sale!.id}'),
                      const Divider(),
                      Text('Visits (${d.visits.length})', style: Theme.of(context).textTheme.titleMedium),
                      ...d.visits.map((v) => ListTile(title: Text(v.id), subtitle: Text(v.status ?? ''))),
                      const Divider(),
                      Text('Follow-ups (${d.followUps.length})', style: Theme.of(context).textTheme.titleMedium),
                      ...d.followUps.map((f) => ListTile(title: Text(f.id), subtitle: Text(f.status ?? ''))),
                    ],
                  ),
                );
            }
          },
        ),
      ),
    );
  }
}
