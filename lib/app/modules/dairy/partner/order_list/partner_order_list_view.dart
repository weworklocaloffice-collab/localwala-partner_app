/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright Â© 2026 WeWorkLocal.
 * All Rights Reserved.
 *
 * Website: https://localwala.tech
 * Email: weworklocal1@gmail.com
 *
 * Proprietary and Confidential.
 *
 * Unauthorized copying, modification, distribution,
 * publication, resale, reverse engineering, or use of
 * this software without prior written authorization is
 * strictly prohibited.
 */

import 'package:partner/app/core/config/api_request_service.dart';
import 'package:partner/app/core/repositories/partner_repository.dart';
import 'package:partner/app/presentation/styles/theme.dart';
import 'package:partner/app/presentation/styles/widgets.dart';
import 'package:partner/gen/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// One-time orders for the outlet.
///
/// Backed by `GET /partner/orders/list`, with accept / reject / ready wired to
/// the single status route the API exposes (`PATCH /orders/:status/:order`).
///
/// The order status route carries the order id only. The outlet comes from the
/// token, so the API refuses a partner acting on another outlet's order — this
/// screen has no outlet to send and could not widen its scope if it tried.
class PartnerOrderListScreen extends StatefulWidget {
  const PartnerOrderListScreen({super.key, this.partnerRepository});

  final PartnerRepository? partnerRepository;

  @override
  State<PartnerOrderListScreen> createState() => _PartnerOrderListScreenState();
}

class _PartnerOrderListScreenState extends State<PartnerOrderListScreen> {
  late final PartnerRepository _partnerRepository =
      widget.partnerRepository ?? PartnerRepository();

  bool _loading = true;
  String? _error;
  List<dynamic> _orders = const <dynamic>[];
  String? _actingOn;
  String _searchQuery = '';
  _OrderFilter _filter = _OrderFilter.all;

  List<Map<String, dynamic>> _visibleOrders() {
    final String query = _searchQuery.trim().toLowerCase();
    return _orders
        .whereType<Map>()
        .map((Map row) => Map<String, dynamic>.from(row))
        .where((Map<String, dynamic> order) {
          final String status = order['status']?.toString() ?? '';
          final bool matchesFilter = switch (_filter) {
            _OrderFilter.all => true,
            _OrderFilter.needsAction =>
              status == 'pending_payments' || status == 'confirmed',
            _OrderFilter.inProgress =>
              status == 'preparing' || status == 'out_for_delivery',
            _OrderFilter.completed =>
              status == 'delivered' || status == 'cancelled' || status == 'refunded',
          };
          if (!matchesFilter) return false;
          if (query.isEmpty) return true;
          final String customer = order['user'] is Map
              ? '${(order['user'] as Map)['firstName'] ?? ''} ${(order['user'] as Map)['lastName'] ?? ''}'
              : '';
          return '${order['orderNo'] ?? ''} $customer $status'
              .toLowerCase()
              .contains(query);
        })
        .toList();
  }

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

    final DioApiResponse response = await _partnerRepository.orders();

    if (!mounted) return;

    if (response.errorType != NetErrorType.none) {
      setState(() {
        _loading = false;
        _error = AppLocalizations.of(context)!.couldNotLoadOrders;
      });
      return;
    }
final Map<String, dynamic> body = decodeBody(response);
    setState(() {
      _loading = false;
      _orders = (body['orders'] as List?) ?? const <dynamic>[];
    });
  }

  /// Accept / reject / ready, then reload so the row reflects what the API decided.
  Future<void> _act(String orderId, String action) async {
    setState(() => _actingOn = orderId);
    final DioApiResponse response =
        await _partnerRepository.orderAction(orderId, action);
    if (!mounted) return;
    setState(() => _actingOn = null);
    if (response.errorType == NetErrorType.none) {
      await _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.orderActionFailed)),
      );
    }
  }

  Color _statusColour(String status) {
    switch (status) {
      case 'delivered':
        return AppColors.canInStore;
      case 'cancelled':
        return AppColors.expired;
      case 'confirmed':
        return AppColors.expirySoon;
      default:
        return AppColors.grey;
    }
  }

  String _rupees(Object? amount) {
    final double value = double.tryParse(amount?.toString() ?? '') ?? 0;
    return '₹${value.toStringAsFixed(0)}';
  }

  String _statusLabel(String status, AppLocalizations l10n) {
    switch (status) {
      case 'pending_payments':
        return l10n.statusPendingPayments;
      case 'confirmed':
        return l10n.statusConfirmed;
      case 'preparing':
        return l10n.statusPreparing;
      case 'out_for_delivery':
        return l10n.statusOutForDelivery;
      case 'delivered':
        return l10n.delivered;
      case 'cancelled':
        return l10n.statusCancelled;
      case 'refunded':
        return l10n.statusRefunded;
      default:
        return status.isEmpty ? l10n.unknownStatus : status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final List<Map<String, dynamic>> orders = _orders
        .whereType<Map>()
        .map((Map row) => Map<String, dynamic>.from(row))
        .toList();
    final List<Map<String, dynamic>> visibleOrders = _visibleOrders();
    final int needsAction = orders.where((Map<String, dynamic> order) {
      final String status = order['status']?.toString() ?? '';
      return status == 'pending_payments' || status == 'confirmed';
    }).length;
    final int inProgress = orders.where((Map<String, dynamic> order) {
      final String status = order['status']?.toString() ?? '';
      return status == 'preparing' || status == 'out_for_delivery';
    }).length;

    return SectionListScreen(
      title: l10n.navOrders,
      icon: Icons.receipt_long_outlined,
      onRefresh: _load,
      children: <Widget>[
        if (!_loading && _error == null && orders.isNotEmpty) ...<Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: MetricTile(
                  label: 'Total orders',
                  value: '${orders.length}',
                  icon: Icons.receipt_long_outlined,
                ),
              ),
              Expanded(
                child: MetricTile(
                  label: 'Need attention',
                  value: '$needsAction',
                  icon: Icons.pending_actions_outlined,
                  accent: needsAction > 0 ? AppColors.expirySoon : AppColors.canInStore,
                ),
              ),
            ],
          ),
          Card(
            child: TextField(
              key: const ValueKey<String>('dairy-orders-search'),
              onChanged: (String value) => setState(() => _searchQuery = value),
              decoration: const InputDecoration(
                hintText: 'Search order number or customer',
                prefixIcon: Icon(Icons.search),
                border: InputBorder.none,
              ),
            ),
          ),
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: <Widget>[
                _filterChip('All · ${orders.length}', _OrderFilter.all),
                const SizedBox(width: 8),
                _filterChip('Needs action · $needsAction', _OrderFilter.needsAction),
                const SizedBox(width: 8),
                _filterChip('In progress · $inProgress', _OrderFilter.inProgress),
                const SizedBox(width: 8),
                _filterChip('Completed', _OrderFilter.completed),
              ],
            ),
          ),
        ],
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          EmptyState(
            title: l10n.ordersUnavailable,
            message: _error!,
            icon: Icons.cloud_off_outlined,
          )
        else if (_orders.isEmpty)
          EmptyState(
            title: l10n.noOrders,
            message: l10n.noOrdersHint,
            icon: Icons.receipt_long_outlined,
          )
        else if (visibleOrders.isEmpty)
          const EmptyState(
            title: 'No matching orders',
            message: 'Try another search or status filter.',
            icon: Icons.search_off_outlined,
          )
        else
          Card(
            child: Column(
              children: visibleOrders.asMap().entries.map((MapEntry<int, Map<String, dynamic>> entry) {
                if (entry.key > 0) {
                  return Column(
                    children: <Widget>[
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      _orderRow(context, entry.value, l10n),
                    ],
                  );
                }
                return _orderRow(context, entry.value, l10n);
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _orderRow(
    BuildContext context,
    Map<String, dynamic> order,
    AppLocalizations l10n,
  ) {
    final String id = (order['id'] ?? order['_id'] ?? '').toString();
    final String status = order['status']?.toString() ?? '';
    final bool busy = _actingOn == id;
    // Only an order still awaiting the outlet can be actioned; the API
    // refuses the rest, so the action is hidden rather than shown to fail.
    final bool actionable = status == 'pending_payments' || status == 'confirmed';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          Icons.receipt_long_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text('${l10n.orderLabel} #${order['orderNo'] ?? '—'}'),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Items ${_rupees(order['itemTotal'])}  ·  Total ${_rupees(order['grandTotal'])}'),
            const SizedBox(height: 6),
            StatusChip(
              label: _statusLabel(status, l10n),
              color: _statusColour(status),
            ),
          ],
        ),
      ),
      trailing: busy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : actionable
              ? IconButton(
                  tooltip: l10n.markReady,
                  icon: const Icon(Icons.check_circle_outline),
                  onPressed: () => _act(id, 'ready'),
                )
              : null,
      isThreeLine: true,
    );
  }

  Widget _filterChip(String label, _OrderFilter filter) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: ChoiceChip(
      label: Text(label),
      selected: _filter == filter,
      onSelected: (_) => setState(() => _filter = filter),
    ),
  );
}

enum _OrderFilter { all, needsAction, inProgress, completed }
