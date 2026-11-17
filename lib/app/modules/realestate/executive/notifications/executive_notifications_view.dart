import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:partner/app/modules/realestate/executive/notifications/bloc/executive_notifications_bloc.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

class ExecutiveNotificationsScreen extends StatelessWidget {
  const ExecutiveNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return BlocProvider<ExecutiveNotificationsBloc>(
      create: (_) => ExecutiveNotificationsBloc()..add(const ExecutiveNotificationsLoad()),
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.realEstateExecNotifications)),
        body: BlocBuilder<ExecutiveNotificationsBloc, ExecutiveNotificationsState>(
          builder: (BuildContext context, ExecutiveNotificationsState state) {
            switch (state.status) {
              case ExecutiveNotificationsStatus.initial:
              case ExecutiveNotificationsStatus.loading:
                return const Center(child: CircularProgressIndicator());
              case ExecutiveNotificationsStatus.failure:
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(state.message, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => context.read<ExecutiveNotificationsBloc>().add(const ExecutiveNotificationsLoad()),
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                );
              case ExecutiveNotificationsStatus.loaded:
                if (state.items.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () async => context.read<ExecutiveNotificationsBloc>().add(const ExecutiveNotificationsRefreshed()),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(height: 400, child: Center(child: Text(l10n.realEstateExecNoNotifications))),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => context.read<ExecutiveNotificationsBloc>().add(const ExecutiveNotificationsRefreshed()),
                  child: ListView.separated(
                    itemCount: state.items.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (BuildContext context, int index) {
                      final Map<String, dynamic> n = state.items[index];
                      return ListTile(
                        title: Text(n['title']?.toString() ?? n['message']?.toString() ?? '-'),
                        subtitle: Text(n['createdAt']?.toString() ?? ''),
                      );
                    },
                  ),
                );
            }
          },
        ),
      ),
    );
  }
}
