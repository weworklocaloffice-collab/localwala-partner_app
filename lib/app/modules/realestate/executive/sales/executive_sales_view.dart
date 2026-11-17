import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:partner/app/modules/realestate/executive/sales/bloc/executive_sales_bloc.dart';
import 'package:partner/app/modules/realestate/models/sale.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

class ExecutiveSalesScreen extends StatelessWidget {
  const ExecutiveSalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return BlocProvider<ExecutiveSalesBloc>(
      create: (_) => ExecutiveSalesBloc()..add(const ExecutiveSalesLoad()),
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.realEstateExecSales)),
        body: BlocBuilder<ExecutiveSalesBloc, ExecutiveSalesState>(
          builder: (BuildContext context, ExecutiveSalesState state) {
            switch (state.status) {
              case ExecutiveSalesStatus.initial:
              case ExecutiveSalesStatus.loading:
                return const Center(child: CircularProgressIndicator());
              case ExecutiveSalesStatus.failure:
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(state.message, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => context.read<ExecutiveSalesBloc>().add(const ExecutiveSalesLoad()),
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                );
              case ExecutiveSalesStatus.loaded:
                if (state.items.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () async => context.read<ExecutiveSalesBloc>().add(const ExecutiveSalesRefreshed()),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(height: 400, child: Center(child: Text(l10n.realEstateExecSalesEmpty))),
                    ),
                  );
                }
                return NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification n) {
                    if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
                      context.read<ExecutiveSalesBloc>().add(const ExecutiveSalesNextPage());
                    }
                    return false;
                  },
                  child: RefreshIndicator(
                    onRefresh: () async => context.read<ExecutiveSalesBloc>().add(const ExecutiveSalesRefreshed()),
                    child: ListView.separated(
                      itemCount: state.items.length + (state.loadingMore ? 1 : 0),
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (BuildContext context, int index) {
                        if (index >= state.items.length) {
                          return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
                        }
                        final RealEstateSaleModel s = state.items[index];
                        return ListTile(
                          title: Text(s.saleCode ?? s.id),
                          subtitle: Text('${s.status ?? '-'}  •  ${s.saleValue ?? '-'}'),
                          trailing: Text(s.soldAt?.toLocal().toString().split('.').first ?? ''),
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
