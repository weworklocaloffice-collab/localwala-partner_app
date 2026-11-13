import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:partner/gen/l10n/app_localizations.dart';
import 'package:partner/app/modules/stores/partner/dashboard/bloc/stores_dashboard_bloc.dart';
import 'package:partner/app/modules/stores/partner/settlements/stores_settlements_screen.dart';
import 'package:partner/app/modules/stores/partner/subscription/stores_subscription_screen.dart';
import 'package:partner/app/modules/stores/partner/support/stores_complaints_screen.dart';
import 'package:partner/app/modules/stores/partner/marketing/stores_featured_screen.dart';
import 'package:partner/app/modules/stores/partner/promotions/stores_promotions_screen.dart';
import 'package:partner/app/modules/stores/partner/warranty/stores_warranty_screen.dart';
import 'package:partner/app/modules/stores/partner/staff/stores_team_screen.dart';
import 'package:partner/app/modules/stores/widgets/stores_ui_states.dart';

String _statusLine(Map<String, dynamic> data) {
  if (data['isOpenNow'] == true) {
    return 'Open';
  }
  if (data['isOpenNow'] == null) {
    return '';
  }
  final String reason =
      data['openReason'] == null ? '' : '${data['openReason']}';
  final String opens =
      data['nextOpensAt'] == null ? '' : _nice(data['nextOpensAt']);
  final String why = reason.isEmpty || reason == 'open' ? 'Closed' : 'Closed — $reason';
  return opens.isEmpty ? why : '$why · opens $opens';
}

String _nice(dynamic value) {
  final DateTime? parsed = DateTime.tryParse('$value');
  if (parsed == null) return '$value';
  final DateTime local = parsed.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.hour)}:${two(local.minute)}';
}

class StoresDashboardScreen extends StatelessWidget {
  const StoresDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return BlocProvider<StoresDashboardBloc>(
      create: (_) => StoresDashboardBloc()..add(const StoresDashboardLoadEvent()),
      child: BlocBuilder<StoresDashboardBloc, StoresDashboardState>(
        builder: (BuildContext context, StoresDashboardState state) {
          return Scaffold(
            appBar: AppBar(
              title: Text(l10n.storesTitleStore),
              actions: <Widget>[
                IconButton(
                  onPressed: () => context.read<StoresDashboardBloc>().add(const StoresDashboardLoadEvent()),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            body: _buildBody(context, l10n, state),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n, StoresDashboardState state) {
    switch (state.status) {
      case StoresDashboardStatus.initial:
      case StoresDashboardStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case StoresDashboardStatus.failure:
        return Center(child: Text(state.message));
      case StoresDashboardStatus.loaded:
        break;
    }
    final Map<String, dynamic> data = state.data;
    final Map<String, dynamic> totals =
        (data['totals'] as Map<String, dynamic>?) ?? const <String, dynamic>{};

    return ListView(
      children: <Widget>[
        const StoresSectionHeader(title: 'Today'),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: <Widget>[
            StoresMetricTile(
              label: 'Orders',
              value: '${totals['orderCount'] ?? totals['orders'] ?? 0}',
            ),
            StoresMetricTile(
              label: 'Revenue',
              value: '${totals['revenue'] ?? totals['grossOrderValue'] ?? 0}',
            ),
            StoresMetricTile(
              label: 'Pending',
              value: '${totals['pending'] ?? 0}',
            ),
            StoresMetricTile(
              label: 'Delivered',
              value: '${totals['delivered'] ?? 0}',
            ),
          ],
        ),
        const StoresSectionHeader(title: 'This session'),
        ListTile(
          leading: const Icon(Icons.storefront_outlined),
          title: Text(l10n.storesTitleOutlet),
          subtitle: Text(
            '${data['outlet'] ?? data['outletName'] ?? 'Active outlet'}\n'
            '${_statusLine(data)}',
          ),
          isThreeLine: true,
        ),
        ListTile(
          leading: const Icon(Icons.business_outlined),
          title: Text(l10n.storesTitleChain),
          subtitle: Text('${data['chain'] ?? data['chainName'] ?? '-'}'),
        ),
        ListTile(
          leading: const Icon(Icons.card_membership_outlined),
          title: Text(l10n.storesTitleSubscription),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const StoresSubscriptionScreen()),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.account_balance_wallet_outlined),
          title: Text(l10n.storesTabSettlements),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const StoresSettlementsScreen()),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.support_agent_outlined),
          title: Text(l10n.storesTitleSupport),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const StoresComplaintsScreen()),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.star_outlined),
          title: Text(l10n.storesTitleFeatured),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const StoresFeaturedScreen()),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.group_outlined),
          title: Text(l10n.storesTitleTeam),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const StoresTeamScreen()),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.local_offer_outlined),
          title: Text(l10n.storesTitlePromotions),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const StoresPromotionsScreen()),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.verified_outlined),
          title: Text(l10n.storesTitleWarranty),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const StoresWarrantyScreen()),
          ),
        ),
      ],
    );
  }
}
