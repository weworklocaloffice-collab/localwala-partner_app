import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:partner/app/modules/realestate/executive/customer_detail/bloc/executive_customer_detail_bloc.dart';
import 'package:partner/app/modules/realestate/models/lead.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

class ExecutiveCustomerDetailScreen extends StatelessWidget {
  const ExecutiveCustomerDetailScreen({super.key, required this.customerId});

  final String customerId;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return BlocProvider<ExecutiveCustomerDetailBloc>(
      create: (_) => ExecutiveCustomerDetailBloc()..add(ExecutiveCustomerDetailLoad(customerId)),
      child: Scaffold(
        appBar: AppBar(title: const Text('Customer')),
        body: BlocBuilder<ExecutiveCustomerDetailBloc, ExecutiveCustomerDetailState>(
          builder: (BuildContext context, ExecutiveCustomerDetailState state) {
            switch (state.status) {
              case ExecutiveCustomerDetailStatus.initial:
              case ExecutiveCustomerDetailStatus.loading:
                return const Center(child: CircularProgressIndicator());
              case ExecutiveCustomerDetailStatus.failure:
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(state.message, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => context.read<ExecutiveCustomerDetailBloc>().add(ExecutiveCustomerDetailRefreshed(customerId)),
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                );
              case ExecutiveCustomerDetailStatus.loaded:
                if (state.leads.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () async => context.read<ExecutiveCustomerDetailBloc>().add(ExecutiveCustomerDetailRefreshed(customerId)),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(height: 400, child: Center(child: Text('No leads'))),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => context.read<ExecutiveCustomerDetailBloc>().add(ExecutiveCustomerDetailRefreshed(customerId)),
                  child: ListView.separated(
                    itemCount: state.leads.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (BuildContext context, int index) {
                      final RealEstateLeadModel lead = state.leads[index];
                      return ListTile(
                        title: Text(lead.property?.title ?? lead.propertyId ?? lead.id),
                        subtitle: Text(lead.status ?? '-'),
                      );
                    },
                  ),
                );
            }
          },
        ),
      ),
    );
  }
}
