import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:partner/gen/l10n/app_localizations.dart';
import 'package:partner/app/modules/stores/partner/orders/bloc/stores_orders_bloc.dart';
import 'package:partner/app/modules/stores/partner/orders/stores_order_detail_screen.dart';
import 'package:partner/app/modules/stores/stores_permissions.dart';
import 'package:partner/app/modules/stores/widgets/stores_ui_states.dart';

class StoresOrdersScreen extends StatelessWidget {
  const StoresOrdersScreen({super.key, this.initialLifecycle, this.permissions});

  /// Opens the list already filtered, so a dashboard action ("Picking: 3") lands on
  /// exactly the queue its count described.
  final String? initialLifecycle;

  /// Role rights for the detail screen's action buttons. Null means unknown, which
  /// leaves them visible and lets the server refuse (§6.23 is advisory in the UI).
  final StoresPermissions? permissions;

  static const List<String> _filters = <String>[
    'created',
    'accepted',
    'picking',
    'ready',
    'out_for_delivery',
    'delivered',
    'completed',
    'cancelled',
  ];

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return BlocProvider<StoresOrdersBloc>(
      create: (_) => StoresOrdersBloc(),
      child: BlocBuilder<StoresOrdersBloc, StoresOrdersState>(
        builder: (BuildContext context, StoresOrdersState state) {
          return Scaffold(
            appBar: AppBar(
              title: Text(l10n.storesTitleOrders),
              actions: <Widget>[
                IconButton(
                  onPressed: () => context.read<StoresOrdersBloc>().add(StoresOrdersLoadEvent(lifecycle: state.lifecycle)),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            body: Column(
              children: <Widget>[
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: _filters.map((String status) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FilterChip(
                          label: Text(status.replaceAll('_', ' ')),
                          selected: state.lifecycle == status,
                          onSelected: (bool selected) {
                            context.read<StoresOrdersBloc>().add(
                                  StoresOrdersLoadEvent(lifecycle: selected ? status : null),
                                );
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                Expanded(
                  child: _buildList(context, l10n, state),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildList(BuildContext context, AppLocalizations l10n, StoresOrdersState state) {
    switch (state.status) {
      case StoresOrdersStatus.initial:
        context.read<StoresOrdersBloc>().add(
              StoresOrdersLoadEvent(lifecycle: initialLifecycle),
            );
        return const Center(child: CircularProgressIndicator());
      case StoresOrdersStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case StoresOrdersStatus.failure:
        return Center(child: Text(state.message));
      case StoresOrdersStatus.loaded:
        break;
    }
    final List<Map<String, dynamic>> orders = state.orders;
    if (orders.isEmpty) {
      return const StoresEmptyView(
        message: 'No orders here yet.',
        icon: Icons.receipt_long_outlined,
      );
    }
    return ListView.separated(
      itemCount: orders.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (BuildContext context, int index) {
        final Map<String, dynamic> order = orders[index];
        final String id = '${order['_id'] ?? ''}';
        return ListTile(
          leading: const Icon(Icons.shopping_bag_outlined),
          title: Text(l10n.storesOrderNumber(order['orderNo']?.toString() ?? '-')),
          subtitle: Text(
            '${order['lifecycle'] ?? ''} · ${order['grandTotal'] ?? 0}',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            if (id.isEmpty) return;
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => StoresOrderDetailScreen(orderId: id, permissions: permissions),
              ),
            );
          },
        );
      },
    );
  }
}
