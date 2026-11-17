/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:partner/app/modules/realestate/executive/customers/executive_customers_view.dart';
import 'package:partner/app/modules/realestate/executive/followups/executive_followups_view.dart';
import 'package:partner/app/modules/realestate/executive/holds/executive_holds_view.dart';
import 'package:partner/app/modules/realestate/executive/loan_status/executive_loan_status_view.dart';
import 'package:partner/app/modules/realestate/executive/notifications/executive_notifications_view.dart';
import 'package:partner/app/modules/realestate/executive/sales/executive_sales_view.dart';
import 'package:partner/app/modules/realestate/executive/settlements/executive_settlements_view.dart';
import 'package:partner/app/modules/realestate/executive/today/bloc/executive_today_bloc.dart';
import 'package:partner/app/modules/realestate/models/commission.dart';
import 'package:partner/app/modules/realestate/models/hold.dart';
import 'package:partner/app/modules/realestate/repository/executive_repository.dart';
import 'package:partner/app/presentation/styles/theme.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

/// Executive home: identity, assignment counters, latest holds and
/// earnings, plus notifications.
///
/// Holds and commissions are read-only here (plan §11.4) - work
/// happens in the Visits and Follow-ups tabs. Amounts arrive in
/// rupees and are never recomputed on device.
class ExecutiveTodayScreen extends StatelessWidget {
  const ExecutiveTodayScreen({super.key});

  static int _count(Map<String, dynamic> map, String key) {
    final dynamic v = map[key];
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return BlocProvider<ExecutiveTodayBloc>(
      create: (_) => ExecutiveTodayBloc()..add(const ExecutiveTodayLoad()),
      child: BlocBuilder<ExecutiveTodayBloc, ExecutiveTodayState>(
        builder: (BuildContext context, ExecutiveTodayState state) {
          final AppThemeData theme =
              appThemeData[Theme.of(context).brightness == Brightness.dark ? AppTheme.dark : AppTheme.light]!;

          return Scaffold(
            appBar: AppBar(
              title: Text(l10n.realEstateNavDashboard),
              actions: <Widget>[
                Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      tooltip: l10n.realEstateExecNotifications,
                      onPressed: () async {
                        await showModalBottomSheet<void>(
                          context: context,
                          showDragHandle: true,
                          builder: (_) => const _NotificationsSheet(),
                        );
                        if (context.mounted) {
                          context.read<ExecutiveTodayBloc>().add(const ExecutiveTodayLoad());
                        }
                      },
                    ),
                    if (state.unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.error,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${state.unreadCount}',
                            style: const TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            body: Builder(
              builder: (BuildContext context) {
                switch (state.status) {
                  case ExecutiveTodayStatus.initial:
                  case ExecutiveTodayStatus.loading:
                    return const Center(child: CircularProgressIndicator());
                  case ExecutiveTodayStatus.failure:
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(l10n.somethingWentWrong, style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () =>
                                context.read<ExecutiveTodayBloc>().add(const ExecutiveTodayLoad()),
                            child: Text(l10n.retry),
                          ),
                        ],
                      ),
                    );
                  case ExecutiveTodayStatus.loaded:
                    return _TodayBody(state: state, theme: theme);
                }
              },
            ),
          );
        },
      ),
    );
  }
}

class _TodayBody extends StatelessWidget {
  const _TodayBody({required this.state, required this.theme});

  final ExecutiveTodayState state;
  final AppThemeData theme;

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> byStatus =
        state.dashboard['visitsByStatus'] is Map ? Map<String, dynamic>.from(state.dashboard['visitsByStatus'] as Map) : <String, dynamic>{};
    final List<MapEntry<String, dynamic>> rows = byStatus.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final List<RealEstateHoldModel> holds = state.holds?.items ?? const <RealEstateHoldModel>[];
    final List<RealEstateCommissionModel> commissions =
        state.commissions?.items ?? const <RealEstateCommissionModel>[];
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return RefreshIndicator(
      onRefresh: () async => context.read<ExecutiveTodayBloc>().add(const ExecutiveTodayLoad()),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: <Widget>[
                _MetricTile(
                  theme: theme,
                  label: l10n.realEstateExecTotalVisits,
                  value: ExecutiveTodayScreen._count(state.dashboard, 'totalVisits').toString(),
                ),
                _MetricTile(
                  theme: theme,
                  label: l10n.realEstateExecActiveLeads,
                  value: ExecutiveTodayScreen._count(state.dashboard, 'activeLeads').toString(),
                ),
                _MetricTile(
                  theme: theme,
                  label: 'Today visits',
                  value: ExecutiveTodayScreen._count(state.dashboard, 'todayVisits').toString(),
                ),
                _MetricTile(
                  theme: theme,
                  label: 'Upcoming',
                  value: ExecutiveTodayScreen._count(state.dashboard, 'upcomingVisits').toString(),
                ),
                _MetricTile(
                  theme: theme,
                  label: 'New leads',
                  value: ExecutiveTodayScreen._count(state.dashboard, 'newLeads').toString(),
                ),
                _MetricTile(
                  theme: theme,
                  label: 'Follow-ups',
                  value: ExecutiveTodayScreen._count(state.dashboard, 'followUps').toString(),
                ),
                _MetricTile(
                  theme: theme,
                  label: 'Overdue',
                  value: ExecutiveTodayScreen._count(state.dashboard, 'overdueFollowUps').toString(),
                ),
                _MetricTile(
                  theme: theme,
                  label: 'Interested',
                  value: ExecutiveTodayScreen._count(state.dashboard, 'interestedCustomers').toString(),
                ),
                _MetricTile(
                  theme: theme,
                  label: 'Loan leads',
                  value: ExecutiveTodayScreen._count(state.dashboard, 'loanLeads').toString(),
                ),
                _MetricTile(
                  theme: theme,
                  label: 'Held',
                  value: ExecutiveTodayScreen._count(state.dashboard, 'heldProperties').toString(),
                ),
                _MetricTile(
                  theme: theme,
                  label: 'Sales',
                  value: ExecutiveTodayScreen._count(state.dashboard, 'sales').toString(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(l10n.realEstateExecQuickLinks, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ExecutiveFollowUpsScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.schedule_outlined),
                    label: Text(l10n.realEstateLeadDetailFollowUps),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ExecutiveCustomersScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.people_outline),
                    label: Text(l10n.realEstateExecCustomers),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const ExecutiveHoldsScreen()),
                    ),
                    icon: const Icon(Icons.lock_clock_outlined),
                    label: Text(l10n.realEstateExecLatestHolds),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const ExecutiveLoanStatusScreen()),
                    ),
                    icon: const Icon(Icons.account_balance_outlined),
                    label: Text(l10n.realEstateExecLoans),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const ExecutiveSalesScreen()),
                    ),
                    icon: const Icon(Icons.sell_outlined),
                    label: Text(l10n.realEstateExecSales),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const ExecutiveSettlementsScreen()),
                    ),
                    icon: const Icon(Icons.receipt_long_outlined),
                    label: Text(l10n.realEstateExecSettlements),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const ExecutiveNotificationsScreen()),
                    ),
                    icon: const Icon(Icons.notifications_outlined),
                    label: Text(l10n.realEstateExecNotifications),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(l10n.realEstateExecVisitsByStatus, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            if (rows.isEmpty)
              Text(l10n.realEstateExecNoVisitsAssigned, style: Theme.of(context).textTheme.bodyMedium)
            else
              ...rows.map(
                (MapEntry<String, dynamic> e) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(e.key),
                  trailing: Text('${e.value}'),
                ),
              ),
            const SizedBox(height: 16),
            Text(l10n.realEstateExecLatestHolds, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            if (holds.isEmpty)
              Text(l10n.realEstateExecNoHolds, style: Theme.of(context).textTheme.bodyMedium)
            else
              ...holds.map(
                (RealEstateHoldModel h) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(h.holdCode ?? h.id),
                  trailing: Text(h.status ?? '-'),
                ),
              ),
            const SizedBox(height: 16),
            Text(l10n.realEstateExecLatestEarnings, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            if (commissions.isEmpty)
              Text(l10n.realEstateExecCommissionsEmpty, style: Theme.of(context).textTheme.bodyMedium)
            else
              ...commissions.map(
                (RealEstateCommissionModel c) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(c.commissionNo ?? c.id),
                  subtitle: Text(c.status ?? ''),
                  trailing: Text('?${c.amount?.toStringAsFixed(2) ?? '-'}'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.theme, required this.label, required this.value});

  final AppThemeData theme;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.divider),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: theme.titleText,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: theme.bodyText),
          ),
        ],
      ),
    );
  }
}

class _NotificationsSheet extends StatefulWidget {
  const _NotificationsSheet();

  @override
  State<_NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<_NotificationsSheet> {
  final RealEstateExecutiveRepository _repo = RealEstateExecutiveRepository();
  List<Map<String, dynamic>> _items = const <Map<String, dynamic>>[];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final List<Map<String, dynamic>> items = await _repo.notifications(page: 1, limit: 20);
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _markRead(String id) async {
    try {
      await _repo.markNotificationRead(id);
      if (!mounted) return;
      await _load();
    } catch (e) {
      if (!mounted) return;
      final AppLocalizations l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.realEstateExecCouldNotMarkRead}: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    if (_loading) return const SizedBox(height: 240, child: Center(child: CircularProgressIndicator()));
    if (_error != null) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(_error!),
              const SizedBox(height: 8),
              ElevatedButton(onPressed: _load, child: Text(l10n.retry)),
            ],
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(child: Text(l10n.realEstateExecNoNotifications)),
      );
    }
    return SafeArea(
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: _items.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (BuildContext context, int index) {
          final Map<String, dynamic> n = _items[index];
          final bool unread = n['readAt'] == null;
          final String id = '${n['_id'] ?? n['id'] ?? ''}';
          return ListTile(
            title: Text('${n['title'] ?? l10n.realEstateExecNotification}'),
            subtitle: n['body'] != null ? Text('${n['body']}') : null,
            trailing: unread
                ? TextButton(
                    onPressed: () => _markRead(id),
                    child: Text(l10n.realEstateExecMarkRead),
                  )
                : const Icon(Icons.check_circle_outline, color: Colors.green),
          );
        },
      ),
    );
  }
}
