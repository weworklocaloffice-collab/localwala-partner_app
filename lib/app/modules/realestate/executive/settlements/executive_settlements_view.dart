import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:partner/app/modules/realestate/executive/settlements/bloc/executive_settlements_bloc.dart';
import 'package:partner/app/modules/realestate/models/settlement.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

class ExecutiveSettlementsScreen extends StatelessWidget {
  const ExecutiveSettlementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return BlocProvider<ExecutiveSettlementsBloc>(
      create: (_) => ExecutiveSettlementsBloc()..add(const ExecutiveSettlementsLoad()),
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.realEstateExecSettlements)),
        body: BlocBuilder<ExecutiveSettlementsBloc, ExecutiveSettlementsState>(
          builder: (BuildContext context, ExecutiveSettlementsState state) {
            switch (state.status) {
              case ExecutiveSettlementsStatus.initial:
              case ExecutiveSettlementsStatus.loading:
                return const Center(child: CircularProgressIndicator());
              case ExecutiveSettlementsStatus.failure:
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(state.message, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => context.read<ExecutiveSettlementsBloc>().add(const ExecutiveSettlementsLoad()),
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                );
              case ExecutiveSettlementsStatus.loaded:
                if (state.items.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () async => context.read<ExecutiveSettlementsBloc>().add(const ExecutiveSettlementsRefreshed()),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(height: 400, child: Center(child: Text(l10n.realEstateExecSettlementsEmpty))),
                    ),
                  );
                }
                return NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification n) {
                    if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
                      context.read<ExecutiveSettlementsBloc>().add(const ExecutiveSettlementsNextPage());
                    }
                    return false;
                  },
                  child: RefreshIndicator(
                    onRefresh: () async => context.read<ExecutiveSettlementsBloc>().add(const ExecutiveSettlementsRefreshed()),
                    child: ListView.separated(
                      itemCount: state.items.length + (state.loadingMore ? 1 : 0),
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (BuildContext context, int index) {
                        if (index >= state.items.length) {
                          return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
                        }
                        final RealEstateSettlementModel s = state.items[index];
                        return ListTile(
                          title: Text(s.settlementNo ?? s.id),
                          subtitle: Text('${s.partyType ?? '-'}  •  ${s.status ?? '-'}'),
                          trailing: Text(s.net?.toString() ?? ''),
                        );
                      },
                    ),
                  ),
                );
            }
          },
        ),
      ),
    );
  }
}
