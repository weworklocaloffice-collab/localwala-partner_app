import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:partner/app/modules/realestate/executive/loan_status/bloc/executive_loan_status_bloc.dart';
import 'package:partner/app/modules/realestate/models/loan.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

class ExecutiveLoanStatusScreen extends StatelessWidget {
  const ExecutiveLoanStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return BlocProvider<ExecutiveLoanStatusBloc>(
      create: (_) => ExecutiveLoanStatusBloc()..add(const ExecutiveLoanStatusLoad()),
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.realEstateExecLoans)),
        body: BlocBuilder<ExecutiveLoanStatusBloc, ExecutiveLoanStatusState>(
          builder: (BuildContext context, ExecutiveLoanStatusState state) {
            switch (state.status) {
              case ExecutiveLoanStatusStateStatus.initial:
              case ExecutiveLoanStatusStateStatus.loading:
                return const Center(child: CircularProgressIndicator());
              case ExecutiveLoanStatusStateStatus.failure:
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(state.message, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => context.read<ExecutiveLoanStatusBloc>().add(const ExecutiveLoanStatusLoad()),
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                );
              case ExecutiveLoanStatusStateStatus.loaded:
                if (state.items.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () async => context.read<ExecutiveLoanStatusBloc>().add(const ExecutiveLoanStatusRefreshed()),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(height: 400, child: Center(child: Text(l10n.realEstateExecLoansEmpty))),
                    ),
                  );
                }
                return NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification n) {
                    if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
                      context.read<ExecutiveLoanStatusBloc>().add(const ExecutiveLoanStatusNextPage());
                    }
                    return false;
                  },
                  child: RefreshIndicator(
                    onRefresh: () async => context.read<ExecutiveLoanStatusBloc>().add(const ExecutiveLoanStatusRefreshed()),
                    child: ListView.separated(
                      itemCount: state.items.length + (state.loadingMore ? 1 : 0),
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (BuildContext context, int index) {
                        if (index >= state.items.length) {
                          return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
                        }
                        final RealEstateLoanModel loan = state.items[index];
                        return ListTile(
                          title: Text(loan.customer?.displayName ?? loan.id),
                          subtitle: Text('${loan.property?.title ?? '-'}\n${loan.status ?? '-'}'),
                          trailing: Text(loan.requestedAmount?.toString() ?? ''),
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
