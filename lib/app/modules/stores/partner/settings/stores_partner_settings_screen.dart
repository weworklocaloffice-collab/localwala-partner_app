import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:partner/gen/l10n/app_localizations.dart';
import 'package:partner/app/modules/stores/partner/settings/bloc/stores_settings_bloc.dart';

class StoresPartnerSettingsScreen extends StatelessWidget {
  const StoresPartnerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return BlocProvider<StoresSettingsBloc>(
      create: (_) => StoresSettingsBloc()..add(const StoresSettingsLoadEvent()),
      child: BlocBuilder<StoresSettingsBloc, StoresSettingsState>(
        builder: (BuildContext context, StoresSettingsState state) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.storesTitleSettings)),
            body: _buildBody(context, l10n, state),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n, StoresSettingsState state) {
    switch (state.status) {
      case StoresSettingsStatus.initial:
      case StoresSettingsStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case StoresSettingsStatus.failure:
        return Center(child: Text(state.message));
      case StoresSettingsStatus.loaded:
        break;
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        for (final MapEntry<String, dynamic> e in state.outlet.entries)
          Semantics(
            label: '${e.key}: ${e.value}',
            child: ListTile(title: Text(e.key), subtitle: Text('${e.value}')),
          ),
      ],
    );
  }
}
