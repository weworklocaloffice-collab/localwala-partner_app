import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:partner/gen/l10n/app_localizations.dart';
import 'package:partner/app/modules/stores/partner/returns/bloc/stores_returns_bloc.dart';

class StoresPartnerReturnsScreen extends StatelessWidget {
  const StoresPartnerReturnsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return BlocProvider<StoresReturnsBloc>(
      create: (_) => StoresReturnsBloc()..add(const StoresReturnsLoadEvent()),
      child: BlocBuilder<StoresReturnsBloc, StoresReturnsState>(
        builder: (BuildContext context, StoresReturnsState state) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.storesTitleReturns)),
            body: _buildBody(context, l10n, state),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n, StoresReturnsState state) {
    switch (state.status) {
      case StoresReturnsStatus.initial:
      case StoresReturnsStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case StoresReturnsStatus.failure:
        return Center(child: Text(state.message));
      case StoresReturnsStatus.loaded:
        break;
    }
    if (state.rows.isEmpty) {
      return Center(child: Text(l10n.storesNoReturns));
    }
    return ListView.separated(
      itemCount: state.rows.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (BuildContext context, int index) {
        final Map<String, dynamic> r = state.rows[index];
        return Semantics(
          label: '${r['status'] ?? l10n.storesFallbackReturn}',
          child: ListTile(
            leading: const Icon(Icons.assignment_return_outlined),
            title: Text('${r['status'] ?? l10n.storesFallbackReturn}'),
            subtitle: Text('${r['reason'] ?? ''}'),
          ),
        );
      },
    );
  }
}
