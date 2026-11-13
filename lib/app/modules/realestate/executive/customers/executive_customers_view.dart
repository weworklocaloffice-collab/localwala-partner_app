/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright Â© 2026 WeWorkLocal.
 * All Rights Reserved.
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:partner/app/modules/realestate/executive/customers/bloc/executive_customers_bloc.dart';
import 'package:partner/app/modules/realestate/models/lead.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

/// Customers derived from assigned leads — one row per distinct
/// customer, with the linked lead count. Tapping a row expands the
/// lead refs (property + status). Rows do not navigate: history lives
/// in the Leads and Visits tabs.
class ExecutiveCustomersScreen extends StatelessWidget {
  const ExecutiveCustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return BlocProvider<ExecutiveCustomersBloc>(
      create: (_) => ExecutiveCustomersBloc()..add(const ExecutiveCustomersLoad()),
      child: BlocBuilder<ExecutiveCustomersBloc, ExecutiveCustomersState>(
        builder: (BuildContext context, ExecutiveCustomersState state) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.realEstateExecCustomers)),
            body: Builder(
              builder: (BuildContext context) {
                switch (state.status) {
                  case ExecutiveCustomersStatus.initial:
                  case ExecutiveCustomersStatus.loading:
                    return const Center(child: CircularProgressIndicator());
                  case ExecutiveCustomersStatus.failure:
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(l10n.somethingWentWrong, style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () =>
                                context.read<ExecutiveCustomersBloc>().add(const ExecutiveCustomersLoad()),
                            child: Text(l10n.retry),
                          ),
                        ],
                      ),
                    );
                  case ExecutiveCustomersStatus.loaded:
                    if (state.customers.isEmpty) {
                      return RefreshIndicator(
                        onRefresh: () async =>
                            context.read<ExecutiveCustomersBloc>().add(const ExecutiveCustomersRefreshed()),
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: 400,
                            child: Center(child: Text(l10n.realEstateCustomersEmpty)),
                          ),
                        ),
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () async =>
                          context.read<ExecutiveCustomersBloc>().add(const ExecutiveCustomersRefreshed()),
                      child: ListView.separated(
                        itemCount: state.customers.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (BuildContext context, int index) {
                          final RealEstateCustomerRef c = state.customers[index];
                          final List<RealEstateLeadModel> leads = state.leadsByCustomer[c.id] ?? const <RealEstateLeadModel>[];
                          return ExpansionTile(
                            title: Text(c.displayName),
                            subtitle: Text(
                              '${l10n.realEstateExecLeadCount(leads.length)}'
                              '${c.mobile != null ? ' · ${c.mobile}' : ''}',
                            ),
                            children: leads
                                .map(
                                  (RealEstateLeadModel l) => ListTile(
                                    dense: true,
                                    title: Text(l.property?.title ?? l.propertyId ?? l.id),
                                    trailing: Text(l.status ?? '—'),
                                  ),
                                )
                                .toList(),
                          );
                        },
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
