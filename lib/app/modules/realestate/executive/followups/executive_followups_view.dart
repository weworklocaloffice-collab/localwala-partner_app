/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright Â© 2026 WeWorkLocal.
 * All Rights Reserved.
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:partner/app/modules/realestate/executive/followups/bloc/executive_followups_bloc.dart';
import 'package:partner/app/modules/realestate/models/follow_up.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

/// Pending follow-ups: due date, mode, notes, one-tap complete.
///
/// Scheduled from a visit; completed here. A wrong entry is completed
/// and re-created — there is no edit.
class ExecutiveFollowUpsScreen extends StatelessWidget {
  const ExecutiveFollowUpsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return BlocProvider<ExecutiveFollowUpsBloc>(
      create: (_) => ExecutiveFollowUpsBloc()..add(const ExecutiveFollowUpsLoad()),
      child: BlocBuilder<ExecutiveFollowUpsBloc, ExecutiveFollowUpsState>(
        builder: (BuildContext context, ExecutiveFollowUpsState state) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.realEstateLeadDetailFollowUps)),
            body: Column(
              children: <Widget>[
                if (state.actionError.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    color: Colors.red.shade50,
                    child: Text(state.actionError, style: const TextStyle(color: Colors.red)),
                  ),
                Expanded(child: _Body(state: state)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state});

  final ExecutiveFollowUpsState state;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    switch (state.status) {
      case ExecutiveFollowUpsStatus.initial:
      case ExecutiveFollowUpsStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case ExecutiveFollowUpsStatus.failure:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(l10n.somethingWentWrong, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () =>
                    context.read<ExecutiveFollowUpsBloc>().add(const ExecutiveFollowUpsLoad()),
                child: Text(l10n.retry),
              ),
            ],
          ),
        );
      case ExecutiveFollowUpsStatus.loaded:
        if (state.items.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async =>
                context.read<ExecutiveFollowUpsBloc>().add(const ExecutiveFollowUpsRefreshed()),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: 400,
                child: Center(child: Text(l10n.realEstateExecNoPendingFollowUps)),
              ),
            ),
          );
        }
        return NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification n) {
            if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
              context.read<ExecutiveFollowUpsBloc>().add(const ExecutiveFollowUpsNextPage());
            }
            return false;
          },
          child: RefreshIndicator(
            onRefresh: () async =>
                context.read<ExecutiveFollowUpsBloc>().add(const ExecutiveFollowUpsRefreshed()),
            child: ListView.separated(
              itemCount: state.items.length + (state.loadingMore ? 1 : 0),
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (BuildContext context, int index) {
                if (index >= state.items.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final RealEstateFollowUpModel f = state.items[index];
                final bool busy = state.completingId == f.id;
                return ListTile(
                  title: Text('${f.mode ?? l10n.realEstateExecFollowUp} · ${f.status ?? ''}'),
                  subtitle: Text(
                    '${f.nextFollowUpAt?.toLocal().toString().split('.').first ?? 'unscheduled'}${f.notes != null && f.notes!.isNotEmpty ? '\n${f.notes}' : ''}',
                  ),
                  isThreeLine: true,
                  trailing: busy
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                      : (f.status == 'COMPLETED'
                          ? const Icon(Icons.check_circle_outline, color: Colors.green)
                          : TextButton(
                              onPressed: () => context
                                  .read<ExecutiveFollowUpsBloc>()
                                  .add(ExecutiveFollowUpComplete(f.id)),
                              child: Text(l10n.realEstateExecDone),
                            )),
                );
              },
            ),
          ),
        );
    }
  }
}
