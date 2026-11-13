import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:partner/gen/l10n/app_localizations.dart';
import 'package:partner/app/modules/stores/partner/postsale/bloc/stores_postsale_bloc.dart';
import 'package:partner/app/modules/stores/stores_partner_repository.dart';

class StoresPostSaleScreen extends StatelessWidget {
  const StoresPostSaleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return BlocProvider<StoresPostSaleBloc>(
      create: (_) => StoresPostSaleBloc()..add(const StoresPostSaleLoadEvent()),
      child: BlocBuilder<StoresPostSaleBloc, StoresPostSaleState>(
        builder: (BuildContext context, StoresPostSaleState state) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.storesTitlePostsale)),
            body: _buildBody(context, l10n, state),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n, StoresPostSaleState state) {
    switch (state.status) {
      case StoresPostSaleStatus.initial:
      case StoresPostSaleStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case StoresPostSaleStatus.failure:
        return Center(child: Text(state.message));
      case StoresPostSaleStatus.loaded:
        break;
    }
    if (state.rows.isEmpty) {
      return Center(child: Text(l10n.storesNoReturns));
    }
    final StoresPartnerRepository repo = StoresPartnerRepository();
    return ListView.separated(
      itemCount: state.rows.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (BuildContext context, int index) {
        final Map<String, dynamic> row = state.rows[index];
        final String status = '${row['status'] ?? 'unknown'}';
        return Semantics(
          label: '${row['reason'] ?? l10n.storesFallbackReturn}',
          child: ListTile(
            leading: const Icon(Icons.assignment_return_outlined),
            title: Text('${row['reason'] ?? l10n.storesFallbackReturn}'),
            subtitle: Text('$status · ${row['totalRefundAmount'] ?? 0}'),
            trailing: status == 'received'
                ? TextButton(
                    onPressed: () async {
                      final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
                      final String? id = row['_id']?.toString();
                      if (id == null) return;
                      try {
                        await repo.returnStatus(id, 'refunded');
                        messenger.showSnackBar(SnackBar(content: Text(l10n.storesMsgReturnRefunded)));
                        if (context.mounted) {
                          context.read<StoresPostSaleBloc>().add(const StoresPostSaleLoadEvent());
                        }
                      } on StoresApiException catch (e) {
                        messenger.showSnackBar(SnackBar(content: Text(e.message)));
                      }
                    },
                    child: Text(l10n.storesActionRefund),
                  )
                : null,
          ),
        );
      },
    );
  }
}
