import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:partner/gen/l10n/app_localizations.dart';
import 'package:partner/app/modules/stores/partner/exchanges/bloc/stores_exchanges_bloc.dart';

class StoresPartnerExchangesScreen extends StatelessWidget {
  const StoresPartnerExchangesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return BlocProvider<StoresExchangesBloc>(
      create: (_) => StoresExchangesBloc()..add(const StoresExchangesLoadEvent()),
      child: BlocBuilder<StoresExchangesBloc, StoresExchangesState>(
        builder: (BuildContext context, StoresExchangesState state) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.storesTitleExchanges)),
            body: _buildBody(context, l10n, state),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n, StoresExchangesState state) {
    switch (state.status) {
      case StoresExchangesStatus.initial:
      case StoresExchangesStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case StoresExchangesStatus.failure:
        return Center(child: Text(state.message));
      case StoresExchangesStatus.loaded:
        break;
    }
    if (state.rows.isEmpty) {
      return Center(child: Text(l10n.storesNoExchanges));
    }
    return ListView.separated(
      itemCount: state.rows.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (BuildContext context, int index) {
        final Map<String, dynamic> e = state.rows[index];
        return Semantics(
          label: '${e['status'] ?? l10n.storesFallbackExchange}',
          child: ListTile(
            leading: const Icon(Icons.swap_horiz_outlined),
            title: Text('${e['status'] ?? l10n.storesFallbackExchange}'),
            subtitle: Text('${e['reason'] ?? ''}'),
          ),
        );
      },
    );
  }
}
