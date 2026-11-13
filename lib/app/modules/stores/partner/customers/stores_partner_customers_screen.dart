import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:partner/gen/l10n/app_localizations.dart';
import 'package:partner/app/modules/stores/partner/customers/bloc/stores_customers_bloc.dart';

class StoresPartnerCustomersScreen extends StatelessWidget {
  const StoresPartnerCustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return BlocProvider<StoresCustomersBloc>(
      create: (_) => StoresCustomersBloc()..add(const StoresCustomersLoadEvent()),
      child: BlocBuilder<StoresCustomersBloc, StoresCustomersState>(
        builder: (BuildContext context, StoresCustomersState state) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.storesTitleCustomers)),
            body: _buildBody(context, l10n, state),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n, StoresCustomersState state) {
    switch (state.status) {
      case StoresCustomersStatus.initial:
      case StoresCustomersStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case StoresCustomersStatus.failure:
        return Center(child: Text(state.message));
      case StoresCustomersStatus.loaded:
        break;
    }
    if (state.rows.isEmpty) {
      return Center(child: Text(l10n.storesNoCustomers));
    }
    return ListView.separated(
      itemCount: state.rows.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (BuildContext context, int index) {
        final Map<String, dynamic> c = state.rows[index];
        final dynamic cust = c['customer'];
        final String name = cust is Map ? '${cust['name'] ?? cust['mobile'] ?? ''}' : '${c['customer'] ?? ''}';
        return Semantics(
          label: name.isEmpty ? l10n.storesFallbackCustomer : name,
          child: ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(name.isEmpty ? l10n.storesFallbackCustomer : name),
            subtitle: Text(l10n.storesMsgCustomerOrders('${c['orderCount'] ?? 0}', '${c['totalSpent'] ?? 0}')),
          ),
        );
      },
    );
  }
}
