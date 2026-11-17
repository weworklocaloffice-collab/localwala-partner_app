import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:partner/app/modules/realestate/executive/visit_detail/bloc/executive_visit_detail_bloc.dart';
import 'package:partner/app/modules/realestate/models/visit.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

class ExecutiveVisitDetailScreen extends StatelessWidget {
  const ExecutiveVisitDetailScreen({super.key, required this.visitId});

  final String visitId;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return BlocProvider<ExecutiveVisitDetailBloc>(
      create: (_) => ExecutiveVisitDetailBloc()..add(ExecutiveVisitDetailLoad(visitId)),
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.realEstateNavVisits)),
        body: BlocBuilder<ExecutiveVisitDetailBloc, ExecutiveVisitDetailState>(
          builder: (BuildContext context, ExecutiveVisitDetailState state) {
            switch (state.status) {
              case ExecutiveVisitDetailStatus.initial:
              case ExecutiveVisitDetailStatus.loading:
                return const Center(child: CircularProgressIndicator());
              case ExecutiveVisitDetailStatus.failure:
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(state.message, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => context
                            .read<ExecutiveVisitDetailBloc>()
                            .add(ExecutiveVisitDetailRefreshed(visitId)),
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                );
              case ExecutiveVisitDetailStatus.loaded:
                final RealEstateVisitModel v = state.visit!;
                return RefreshIndicator(
                  onRefresh: () async => context
                      .read<ExecutiveVisitDetailBloc>()
                      .add(ExecutiveVisitDetailRefreshed(visitId)),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: <Widget>[
                      Text(v.property?.title ?? v.propertyId ?? '-', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text('Customer: ${v.customer?.displayName ?? v.customerId ?? '-'}'),
                      Text('Status: ${v.status ?? '-'}'),
                      if (v.scheduledAt != null) Text('Scheduled: ${v.scheduledAt}'),
                      Text('Check-in radius: ${v.checkInRadiusMeters} m'),
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
