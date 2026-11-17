import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:partner/app/modules/realestate/executive/holds/bloc/executive_holds_bloc.dart';
import 'package:partner/app/modules/realestate/models/hold.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

class ExecutiveHoldsScreen extends StatelessWidget {
  const ExecutiveHoldsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return BlocProvider<ExecutiveHoldsBloc>(
      create: (_) => ExecutiveHoldsBloc()..add(const ExecutiveHoldsLoad()),
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.realEstateExecLatestHolds)),
        body: BlocBuilder<ExecutiveHoldsBloc, ExecutiveHoldsState>(
          builder: (BuildContext context, ExecutiveHoldsState state) {
            switch (state.status) {
              case ExecutiveHoldsStatus.initial:
              case ExecutiveHoldsStatus.loading:
                return const Center(child: CircularProgressIndicator());
              case ExecutiveHoldsStatus.failure:
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(state.message, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => context.read<ExecutiveHoldsBloc>().add(const ExecutiveHoldsLoad()),
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                );
              case ExecutiveHoldsStatus.loaded:
                if (state.items.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () async => context.read<ExecutiveHoldsBloc>().add(const ExecutiveHoldsRefreshed()),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(height: 400, child: Center(child: Text(l10n.realEstateExecNoHolds))),
                    ),
                  );
                }
                return NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification n) {
                    if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
                      context.read<ExecutiveHoldsBloc>().add(const ExecutiveHoldsNextPage());
                    }
                    return false;
                  },
                  child: RefreshIndicator(
                    onRefresh: () async => context.read<ExecutiveHoldsBloc>().add(const ExecutiveHoldsRefreshed()),
                    child: ListView.separated(
                      itemCount: state.items.length + (state.loadingMore ? 1 : 0),
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (BuildContext context, int index) {
                        if (index >= state.items.length) {
                          return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
                        }
                        final RealEstateHoldModel h = state.items[index];
                        return ListTile(
                          title: Text(h.holdCode ?? h.id),
                          subtitle: Text('${h.status ?? '-'}  •  ${h.principal ?? '-'}'),
                          trailing: Text(h.expiresAt?.toLocal().toString().split('.').first ?? ''),
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
