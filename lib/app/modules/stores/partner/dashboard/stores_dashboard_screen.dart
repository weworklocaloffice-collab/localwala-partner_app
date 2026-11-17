import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:partner/gen/l10n/app_localizations.dart';
import 'package:partner/app/modules/stores/partner/dashboard/bloc/stores_dashboard_bloc.dart';
import 'package:partner/app/modules/stores/partner/delivery/stores_partner_delivery_tracking_screen.dart';
import 'package:partner/app/modules/stores/partner/dispatch/stores_partner_dispatch_screen.dart';
import 'package:partner/app/modules/stores/partner/drivers/stores_drivers_screen.dart';
import 'package:partner/app/modules/stores/partner/inventory/stores_inventory_screen.dart';
import 'package:partner/app/modules/stores/partner/orders/stores_order_detail_screen.dart';
import 'package:partner/app/modules/stores/partner/orders/stores_orders_screen.dart';
import 'package:partner/app/modules/stores/partner/settlements/stores_settlements_screen.dart';
import 'package:partner/app/modules/stores/partner/subscription/stores_subscription_screen.dart';
import 'package:partner/app/modules/stores/partner/support/stores_complaints_screen.dart';
import 'package:partner/app/modules/stores/partner/marketing/stores_featured_screen.dart';
import 'package:partner/app/modules/stores/partner/promotions/stores_promotions_screen.dart';
import 'package:partner/app/modules/stores/partner/warranty/stores_warranty_screen.dart';
import 'package:partner/app/modules/stores/partner/staff/stores_team_screen.dart';
import 'package:partner/app/modules/stores/widgets/stores_ui_states.dart';

Map<String, dynamic> _map(dynamic value) =>
    value is Map<String, dynamic> ? value : const <String, dynamic>{};

List<Map<String, dynamic>> _rows(dynamic value) => value is List
    ? value.whereType<Map<String, dynamic>>().toList()
    : const <Map<String, dynamic>>[];

num _num(dynamic value) => value is num ? value : num.tryParse('$value') ?? 0;

String _count(dynamic value) => '${_num(value).round()}';

String _money(dynamic value) => '₹${_num(value).round()}';

String _name(dynamic value) {
  final String text = value == null ? '' : '$value'.trim();
  return text.isEmpty ? '-' : text;
}

String _greeting() {
  final int hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

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

String _label(dynamic value) {
  final String text = value == null ? '' : '$value';
  if (text.isEmpty) return '-';
  return text.replaceAll('_', ' ');
}

const Set<String> _bannerSubscriptionStatuses = <String>{
  'payment_due',
  'retrying',
  'grace_period',
  'suspended',
};

String? _subscriptionAlert(Map<String, dynamic> subscription) {
  final String status = subscription['status'] is String
      ? subscription['status'] as String
      : '';
  if (!_bannerSubscriptionStatuses.contains(status)) return null;
  if (status == 'suspended') {
    return 'Subscription suspended - renew to restore catalogue and order access';
  }
  final int? days = subscription['daysToBilling'] is num
      ? (subscription['daysToBilling'] as num).round()
      : _daysFromNow(subscription['graceEndsAt']);
  final String when;
  if (days == null) {
    when = '';
  } else if (days < 0) {
    when = days == -1 ? ' - overdue by 1 day' : ' - overdue by ${-days} days';
  } else if (days == 0) {
    when = ' - due today';
  } else {
    when = days == 1 ? ' - due in 1 day' : ' - due in $days days';
  }
  if (status == 'grace_period') {
    return 'Subscription grace period$when - renew before access is suspended';
  }
  if (status == 'retrying') {
    return 'Subscription payment retrying$when - update your payment method';
  }
  return 'Subscription payment due$when - renew to keep accepting orders';
}

int? _daysFromNow(dynamic value) {
  final DateTime? parsed = value == null ? null : DateTime.tryParse('$value');
  if (parsed == null) return null;
  return parsed.toLocal().difference(DateTime.now()).inDays;
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

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
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
    final Map<String, dynamic> totals = _map(data['totals']);
    final Map<String, dynamic> sales = _map(data['sales']);
    final Map<String, dynamic> drivers = _map(data['drivers']);
    final Map<String, dynamic> inventory = _map(data['inventory']);
    final Map<String, dynamic> reviews = _map(data['reviews']);
    final List<Map<String, dynamic>> topProducts = _rows(data['topProducts']);
    final List<Map<String, dynamic>> recentOrders = _rows(data['recentOrders']);
    final bool? isOpen = data['isOpenNow'] is bool ? data['isOpenNow'] as bool : null;
    final Map<String, dynamic> subscription = _map(data['subscription']);
    final Map<String, dynamic> alerts = _map(data['alerts']);
    final String? subscriptionAlert = _subscriptionAlert(subscription);

    return RefreshIndicator(
      onRefresh: () async {
        context.read<StoresDashboardBloc>().add(const StoresDashboardLoadEvent());
      },
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(_greeting(), style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        _name(data['outlet'] ?? data['outletName']),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    if (isOpen != null)
                      Chip(
                        label: Text(isOpen ? 'OPEN' : 'CLOSED'),
                        avatar: Icon(
                          isOpen ? Icons.circle : Icons.circle_outlined,
                          size: 12,
                          color: isOpen ? Colors.green : Colors.red,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${_statusLine(data)} · ${_name(data['chain'] ?? data['chainName'])}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (subscriptionAlert != null)
            _DashboardBanner(
              icon: Icons.credit_card_outlined,
              message: subscriptionAlert,
              actionLabel: 'Fix',
              critical: subscription['status'] == 'suspended',
              onTap: () => _open(context, const StoresSubscriptionScreen()),
            ),
          if (alerts['noActiveDriver'] == true)
            _DashboardBanner(
              icon: Icons.sports_motorsports_outlined,
              message: 'No active driver - deliveries cannot be assigned',
              actionLabel: 'Manage',
              critical: true,
              onTap: () => _open(context, const StoresDriversScreen()),
            ),
          const StoresSectionHeader(title: 'Today'),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            childAspectRatio: 1.6,
            children: <Widget>[
              StoresMetricTile(label: 'Orders', value: _count(totals['orderCount'])),
              StoresMetricTile(label: 'Revenue', value: _money(totals['revenue'])),
              StoresMetricTile(label: 'Avg order value', value: _money(totals['avgOrderValue'])),
              StoresMetricTile(label: 'Delivered', value: _count(totals['delivered'])),
              StoresMetricTile(
                label: 'Low stock',
                value: _count(totals['lowStock'] ?? inventory['lowStock']),
                onTap: () => _open(context, const StoresInventoryScreen()),
              ),
              StoresMetricTile(
                label: 'Out of stock',
                value: _count(totals['outOfStock'] ?? inventory['outOfStock']),
                onTap: () => _open(context, const StoresInventoryScreen()),
              ),
              StoresMetricTile(
                label: 'Drivers available',
                value: '${_count(drivers['available'])}/${_count(drivers['total'])}',
                onTap: () => _open(context, const StoresDriversScreen()),
              ),
              StoresMetricTile(
                label: 'Rating',
                value: _num(totals['rating'] ?? reviews['avgRating']).toStringAsFixed(1),
              ),
            ],
          ),
          const StoresSectionHeader(title: 'Orders to act on'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: <Widget>[
                _OrderAction(
                  label: 'New',
                  count: _count(totals['newOrders']),
                  icon: Icons.receipt_long_outlined,
                  onTap: () => _open(
                    context,
                    const StoresOrdersScreen(initialLifecycle: 'accepted'),
                  ),
                ),
                _OrderAction(
                  label: 'Picking',
                  count: _count(totals['picking']),
                  icon: Icons.shopping_basket_outlined,
                  onTap: () => _open(
                    context,
                    const StoresOrdersScreen(initialLifecycle: 'picking'),
                  ),
                ),
                _OrderAction(
                  label: 'Packing',
                  count: _count(totals['packing']),
                  icon: Icons.inventory_2_outlined,
                  onTap: () => _open(
                    context,
                    const StoresOrdersScreen(initialLifecycle: 'packing'),
                  ),
                ),
                _OrderAction(
                  label: 'Ready',
                  count: _count(totals['ready']),
                  icon: Icons.local_shipping_outlined,
                  onTap: () => _open(context, const StoresPartnerDispatchScreen()),
                ),
              ],
            ),
          ),
          const StoresSectionHeader(title: 'Inventory'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: ListTile(
              leading: const Icon(Icons.warehouse_outlined),
              title: Text(
                'Low stock ${_count(inventory['lowStock'])} · '
                'Out of stock ${_count(inventory['outOfStock'])}',
              ),
              subtitle: Text('${_count(inventory['totalSkus'])} SKUs tracked'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _open(context, const StoresInventoryScreen()),
            ),
          ),
          const StoresSectionHeader(title: 'Delivery'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: ListTile(
              leading: const Icon(Icons.sports_motorsports_outlined),
              title: Text(
                '${_count(drivers['available'])} available · '
                '${_count(drivers['onDelivery'])} on delivery',
              ),
              subtitle: Text('${_count(drivers['total'])} active drivers'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _open(context, const StoresDriversScreen()),
            ),
          ),
          Card(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: ListTile(
              leading: const Icon(Icons.local_shipping_outlined),
              title: const Text('Active deliveries'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _open(context, const StoresPartnerDeliveryTrackingScreen()),
            ),
          ),
          const StoresSectionHeader(title: 'Sales'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: Row(
                children: <Widget>[
                  _SalesTile(label: 'Today', value: _money(sales['today'])),
                  _SalesTile(label: 'This week', value: _money(sales['week'])),
                  _SalesTile(label: 'This month', value: _money(sales['month'])),
                ],
              ),
            ),
          ),
          if (topProducts.isNotEmpty) ...<Widget>[
            const StoresSectionHeader(title: 'Top products'),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: topProducts.take(5).map((Map<String, dynamic> product) {
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.local_fire_department_outlined),
                    title: Text(_name(product['name'])),
                    subtitle: Text('${_count(product['totalSold'])} sold'),
                    trailing: Text(_money(product['totalRevenue'])),
                  );
                }).toList(),
              ),
            ),
          ],
          if (recentOrders.isNotEmpty) ...<Widget>[
            const StoresSectionHeader(title: 'Recent orders'),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: recentOrders.map((Map<String, dynamic> order) {
                  final String id = '${order['_id'] ?? ''}';
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.shopping_bag_outlined),
                    title: Text('Order ${_name(order['orderNo'])}'),
                    subtitle: Text(
                      '${_name(order['customerName'])} · ${_label(order['lifecycle'])}',
                    ),
                    trailing: Text(_money(order['grandTotal'])),
                    onTap: id.isEmpty
                        ? null
                        : () => _open(context, StoresOrderDetailScreen(orderId: id)),
                  );
                }).toList(),
              ),
            ),
          ],
          const StoresSectionHeader(title: 'Business'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.card_membership_outlined),
                  title: Text(l10n.storesTitleSubscription),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _open(context, const StoresSubscriptionScreen()),
                ),
                ListTile(
                  leading: const Icon(Icons.account_balance_wallet_outlined),
                  title: Text(l10n.storesTabSettlements),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _open(context, const StoresSettlementsScreen()),
                ),
                ListTile(
                  leading: const Icon(Icons.support_agent_outlined),
                  title: Text(l10n.storesTitleSupport),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _open(context, const StoresComplaintsScreen()),
                ),
                ListTile(
                  leading: const Icon(Icons.star_outlined),
                  title: Text(l10n.storesTitleFeatured),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _open(context, const StoresFeaturedScreen()),
                ),
                ListTile(
                  leading: const Icon(Icons.group_outlined),
                  title: Text(l10n.storesTitleTeam),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _open(context, const StoresTeamScreen()),
                ),
                ListTile(
                  leading: const Icon(Icons.local_offer_outlined),
                  title: Text(l10n.storesTitlePromotions),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _open(context, const StoresPromotionsScreen()),
                ),
                ListTile(
                  leading: const Icon(Icons.verified_outlined),
                  title: Text(l10n.storesTitleWarranty),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _open(context, const StoresWarrantyScreen()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderAction extends StatelessWidget {
  const _OrderAction({
    required this.label,
    required this.count,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String count;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        margin: const EdgeInsets.all(4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(icon, size: 20),
                const SizedBox(height: 6),
                Text(count, style: Theme.of(context).textTheme.titleMedium),
                Text(label, style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SalesTile extends StatelessWidget {
  const _SalesTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: <Widget>[
          Text(value, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _DashboardBanner extends StatelessWidget {
  const _DashboardBanner({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onTap,
    this.critical = false,
  });

  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onTap;
  final bool critical;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color background =
        critical ? scheme.errorContainer : scheme.secondaryContainer;
    final Color foreground =
        critical ? scheme.onErrorContainer : scheme.onSecondaryContainer;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      color: background,
      child: ListTile(
        leading: Icon(icon, color: foreground),
        title: Text(message, style: TextStyle(color: foreground)),
        trailing: TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(foregroundColor: foreground),
          child: Text(actionLabel),
        ),
      ),
    );
  }
}
