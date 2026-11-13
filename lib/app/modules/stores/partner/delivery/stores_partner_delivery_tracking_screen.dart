import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:partner/gen/l10n/app_localizations.dart';
import 'package:partner/app/modules/stores/partner/delivery/bloc/stores_delivery_bloc.dart';

class StoresPartnerDeliveryTrackingScreen extends StatelessWidget {
  const StoresPartnerDeliveryTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return BlocProvider<StoresDeliveryBloc>(
      create: (_) => StoresDeliveryBloc()..add(const StoresDeliveryLoadEvent()),
      child: BlocBuilder<StoresDeliveryBloc, StoresDeliveryState>(
        builder: (BuildContext context, StoresDeliveryState state) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.storesTitleDeliveryTracking)),
            body: _buildBody(context, l10n, state),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n, StoresDeliveryState state) {
    switch (state.status) {
      case StoresDeliveryStatus.initial:
      case StoresDeliveryStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case StoresDeliveryStatus.failure:
        return Center(child: Text(state.message));
      case StoresDeliveryStatus.loaded:
        break;
    }
    if (state.rows.isEmpty) {
      return Center(child: Text(l10n.storesNoDeliveries));
    }
    return ListView.separated(
      itemCount: state.rows.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (BuildContext context, int index) {
        final Map<String, dynamic> d = state.rows[index];
        return Semantics(
          label: '${d['status'] ?? l10n.storesFallbackDelivery}',
          child: ListTile(
            leading: const Icon(Icons.local_shipping_outlined),
            title: Text('${d['status'] ?? l10n.storesFallbackDelivery}'),
            subtitle: Text('${d['order'] ?? ''}'),
          ),
        );
      },
    );
  }
}
