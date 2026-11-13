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

import 'dart:math' as math;

import 'package:partner/app/core/config/api_request_service.dart';
import 'package:partner/app/core/models/user_session_model.dart';
import 'package:partner/app/core/repositories/partner_repository.dart';
import 'package:partner/app/modules/dairy/partner/delivery_run_list/partner_delivery_run_list_view.dart';
import 'package:partner/app/shell/role_gate/bloc/role_gate_bloc.dart';
import 'package:partner/app/presentation/styles/theme.dart';
import 'package:partner/app/presentation/styles/widgets.dart';
import 'package:partner/gen/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The partner's home screen.
///
/// Backed by `GET /v1/dairy/partner/dashboard`, which answers the dashboard panels
/// in one call. That matters here: this is the first screen an operator sees, and
/// six separate requests before first paint is a visible wait on rural mobile data.
///
/// ## Per-panel degradation
///
/// The API gathers each panel independently and reports one that failed as
/// `{ ok: false, error }` rather than failing the whole response. This screen
/// mirrors that: a partner whose payables are broken still sees today's orders,
/// with the affected panel showing a retry action. Losing the whole dashboard over one
/// unrelated query would be the worse outcome for someone trying to run a business.
class PartnerDashboardScreen extends StatefulWidget {
  const PartnerDashboardScreen({
    super.key,
    required this.gate,
    this.outletLocationComplete = true,
    this.outletVerified = true,
    this.onCompleteOutletLocation,
    this.onRefreshOutletStatus,
    this.partnerRepository,
    this.onNavigate,
  });

  final RoleGateState gate;
  final bool outletLocationComplete;
  final bool outletVerified;
  final VoidCallback? onCompleteOutletLocation;
  final VoidCallback? onRefreshOutletStatus;
  final PartnerRepository? partnerRepository;
  final ValueChanged<int>? onNavigate;

  @override
  State<PartnerDashboardScreen> createState() => _PartnerDashboardScreenState();
}

class _PartnerDashboardScreenState extends State<PartnerDashboardScreen> {
  late final PartnerRepository _partnerRepository =
      widget.partnerRepository ?? PartnerRepository();

  bool _loading = true;
  bool _refreshing = false;
  String? _loadError;
  Map<String, dynamic>? _panels;
  Map<String, dynamic>? _outlet;
  DateTime? _generatedAt;
  String _selectedTrendPeriod = '7d';
  String _loadedTrendPeriod = '7d';
  int _requestGeneration = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final int requestGeneration = ++_requestGeneration;
    final String requestedPeriod = _selectedTrendPeriod;
    final bool hadDashboard = _panels != null;
    setState(() {
      _loading = !hadDashboard;
      _refreshing = hadDashboard;
      _loadError = null;
    });

    final DioApiResponse response = await _partnerRepository.dashboard(
      period: _selectedTrendPeriod,
    );

    if (!mounted || requestGeneration != _requestGeneration) return;

    if (response.errorType != NetErrorType.none) {
      setState(() {
        _loading = false;
        _refreshing = false;
        if (hadDashboard) {
          _selectedTrendPeriod = _loadedTrendPeriod;
        } else {
          _loadError = AppLocalizations.of(context)!.couldNotLoadDashboard;
          _panels = null;
          _generatedAt = null;
        }
      });
      if (hadDashboard && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.couldNotLoadDashboard)),
        );
      }
      return;
    }
final Map<String, dynamic> body = decodeBody(response);
    final Map<String, dynamic>? dashboard =
        body['dashboard'] as Map<String, dynamic>?;
    final DateTime? generatedAt = DateTime.tryParse(
      dashboard?['generatedAt']?.toString() ?? '',
    );

    setState(() {
      _loading = false;
      _refreshing = false;
      _panels = dashboard;
      _outlet = dashboard?['outlet'] as Map<String, dynamic>?;
      _generatedAt = generatedAt;
      _loadedTrendPeriod = requestedPeriod;
    });
  }

  /// A panel that gathered successfully, or null when it did not.
  Map<String, dynamic>? _panel(String name) {
    final Map<String, dynamic>? panel = _panels?[name] as Map<String, dynamic>?;
    if (panel == null || panel['ok'] != true) return null;
    return Map<String, dynamic>.from(panel['data'] as Map? ?? <String, dynamic>{});
  }

  /// Whether a panel came back `{ ok: false, error }`.
  ///
  /// The API isolates panels, so one broken query costs the operator that tile
  /// and not the screen. That promise is only meaningful if the screen actually
  /// says so — a silently blank tile would be indistinguishable from a panel
  /// with no data, which is the confusion this avoids.
  bool _panelFailed(String name) {
    final Map<String, dynamic>? panel = _panels?[name] as Map<String, dynamic>?;
    return panel != null && panel['ok'] == false;
  }

  String _rupees(Object? amount) {
    final double value = double.tryParse(amount?.toString() ?? '') ?? 0;
    return '₹${value.toStringAsFixed(0)}';
  }

  String _complianceLabel(String status, AppLocalizations l10n) {
    switch (status) {
      case 'pending':
        return l10n.compliancePending;
      case 'valid':
        return l10n.complianceValid;
      case 'expiring':
        return l10n.complianceExpiring;
      case 'expired':
        return l10n.complianceExpired;
      default:
        return status.isEmpty ? l10n.unknownStatus : status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final AppThemeData theme = appThemeData[Theme.of(context).brightness == Brightness.dark ? AppTheme.dark : AppTheme.light]!;
    final bool canSwitch = widget.gate.canSwitchRole;
    final UserSessionModel? session = widget.gate.session;

    return Scaffold(
      appBar: AppBar(
        title: Text(_outlet?['name']?.toString() ?? l10n.navHome),
        leading: Icon(Icons.storefront_outlined, color: theme.primary),
        actions: <Widget>[
          IconButton(
            tooltip: l10n.retry,
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
          if (canSwitch)
            IconButton(
              tooltip: l10n.switchToDelivery,
              icon: const Icon(Icons.pedal_bike_outlined),
              onPressed: () =>
                  context.read<RoleGateBloc>().add(const RoleGateSwitchEvent(DairyAppRole.driver)),
            ),
        ],
      ),
      body: _body(context, l10n, theme, session),
    );
  }

  Widget _body(
    BuildContext context,
    AppLocalizations l10n,
    AppThemeData theme,
    UserSessionModel? session,
  ) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null || _panels == null) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: <Widget>[
            const SizedBox(height: 120),
            EmptyState(
              title: l10n.dashboardUnavailable,
              message: _loadError ?? l10n.noDataReturned,
              icon: Icons.cloud_off_outlined,
            ),
          ],
        ),
      );
    }

    final Map<String, dynamic>? today = _panel('today');
    final Map<String, dynamic>? salesTrend = _panel('salesTrend');
    final Map<String, dynamic>? lowStock = _panel('lowStock');
    final Map<String, dynamic>? expiryAlerts = _panel('expiryAlerts');
    final Map<String, dynamic>? compliance = _panel('compliance');
    final Map<String, dynamic>? payables = _panel('payables');
    final Map<String, dynamic>? plans = _panel('subscriptions');
    final Map<String, dynamic>? deliveries = _panel('deliveries');

    final List<dynamic> lowStockItems =
        (lowStock?['items'] as List?) ?? const <dynamic>[];
    final Map<String, dynamic> outOfStock =
        Map<String, dynamic>.from(lowStock?['outOfStock'] as Map? ?? <String, dynamic>{});
    final List<dynamic> outOfStockItems =
        (outOfStock['items'] as List?) ?? const <dynamic>[];
    final List<dynamic> expiryItems =
        (expiryAlerts?['items'] as List?) ?? const <dynamic>[];

    // Keep failures identifiable without exposing raw API or database errors.
    final int failedCount = <String>[
        'today',
        'salesTrend',
        'lowStock',
        'expiryAlerts',
        'compliance',
        'payables',
        'subscriptions',
        'deliveries',
      ].where(_panelFailed).length;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: <Widget>[
          if (_refreshing) const LinearProgressIndicator(minHeight: 2),
          _enterpriseHeader(context, l10n, theme, session),

          if (!widget.outletVerified)
            Card(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: ListTile(
                leading: const Icon(Icons.verified_user_outlined),
                title: const Text('Waiting for admin verification'),
                subtitle: const Text('After approval, you will add the outlet address and map pin to unlock operations.'),
                trailing: const Icon(Icons.refresh),
                onTap: widget.onRefreshOutletStatus,
              ),
            )
          else if (!widget.outletLocationComplete)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: ListTile(
                leading: const Icon(Icons.add_location_alt_outlined),
                title: const Text('Complete your outlet location'),
                subtitle: const Text('Add the physical address and map pin to unlock products, inventory and outlet operations.'),
                trailing: const Icon(Icons.chevron_right),
                onTap: widget.onCompleteOutletLocation,
              ),
            ),

          _attentionSection(
            context,
            l10n,
            theme,
            today: today,
            lowStock: lowStock,
            outOfStock: outOfStock,
            expiryAlerts: expiryAlerts,
            compliance: compliance,
            deliveries: deliveries,
            checksUnavailable: _panelFailed('today')
                || _panelFailed('lowStock')
                || _panelFailed('expiryAlerts')
                || _panelFailed('compliance')
                || _panelFailed('deliveries'),
          ),

          if (failedCount > 0)
            Card(
              child: ListTile(
                leading: Icon(Icons.warning_amber_outlined, color: AppColors.expired),
                title: Text(l10n.somePanelsFailed),
                subtitle: Text(l10n.temporarilyUnavailable),
                trailing: TextButton(onPressed: _load, child: Text(l10n.retry)),
              ),
            ),

          // Today's trading.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'Today at a glance',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: MetricTile(
                  label: l10n.navOrders,
                  value: today == null ? '—' : '${today['orders']}',
                  icon: Icons.receipt_long_outlined,
                  accent: theme.primary,
                ),
              ),
              Expanded(
                child: MetricTile(
                  label: l10n.revenueToday,
                  value: today == null ? '—' : _rupees(today['revenue']),
                  icon: Icons.payments_outlined,
                  accent: theme.secondary,
                ),
              ),
            ],
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: MetricTile(
                  label: l10n.navSubscriptions,
                  value: plans == null ? '—' : '${plans['active']}',
                  icon: Icons.event_repeat_outlined,
                ),
              ),
              Expanded(
                child: MetricTile(
                  label: l10n.runsInProgress,
                  value: deliveries == null ? '—' : '${deliveries['runsInProgress']}',
                  icon: Icons.route_outlined,
                  accent: AppColors.canWithCustomer,
                ),
              ),
            ],
          ),

          _salesTrendPanel(context, l10n, theme, salesTrend),

          _sectionCard(
            title: l10n.navInventory,
            icon: Icons.inventory_2_outlined,
            onTap: widget.onNavigate == null
                ? null
                : () => widget.onNavigate!(2),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              if (lowStock == null)
                _unavailable(l10n)
              else if (lowStockItems.isEmpty)
                Text(
                  l10n.lowStockSummary(
                    int.tryParse(lowStock['count']?.toString() ?? '') ?? 0,
                    int.tryParse(lowStock['threshold']?.toString() ?? '') ?? 0,
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              else ...lowStockItems.map((dynamic raw) {
                final Map<String, dynamic> item = Map<String, dynamic>.from(raw as Map);
                final int quantity = int.tryParse(item['availableQty']?.toString() ?? '') ?? 0;
                final int threshold = int.tryParse(item['stockAlertThreshold']?.toString() ?? '') ?? 10;
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(item['name']?.toString() ?? ''),
                  subtitle: Text('Alert at $threshold units'),
                  trailing: Text(l10n.quantityLeft(quantity)),
                );
              }),
              if (outOfStockItems.isNotEmpty) ...<Widget>[
                const Divider(),
                Text('Out of stock · ${outOfStock['count'] ?? outOfStockItems.length}', style: Theme.of(context).textTheme.titleSmall),
                ...outOfStockItems.map((dynamic raw) {
                  final Map<String, dynamic> item = Map<String, dynamic>.from(raw as Map);
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.remove_shopping_cart_outlined, color: AppColors.expired),
                    title: Text(item['name']?.toString() ?? ''),
                    subtitle: const Text('Unavailable until stock is replenished'),
                  );
                }),
              ],
              const Divider(),
              Text('Product and milk batch expiry · next ${expiryAlerts?['windowHours'] ?? 72} hours', style: Theme.of(context).textTheme.titleSmall),
              if (expiryAlerts == null)
                _unavailable(l10n)
              else if (expiryItems.isEmpty)
                const Padding(padding: EdgeInsets.only(top: 6), child: Text('No milk batches are expired or expiring soon.'))
              else ...expiryItems.map((dynamic raw) {
                final Map<String, dynamic> item = Map<String, dynamic>.from(raw as Map);
                final String expiry = item['expiry']?.toString() ?? '';
                final DateTime? parsed = DateTime.tryParse(expiry);
                final String expiryLabel = parsed == null ? expiry : parsed.toLocal().toString().substring(0, 16);
                final bool expired = item['status'] == 'expired';
                final bool finishedProduct = item['itemType'] == 'finished_product';
                final dynamic pack = item['packSize'];
                final dynamic productQty = expired ? (item['expiredQty'] ?? item['availableQty'] ?? 0) : (item['availableQty'] ?? 0);
                final String packLabel = pack is Map
                    ? '${pack['value'] ?? pack['quantity'] ?? ''} ${pack['unit'] ?? ''}'.trim()
                    : '';
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(expired ? Icons.error_outline : Icons.warning_amber_outlined, color: expired ? AppColors.expired : theme.secondary),
                  title: Text(finishedProduct
                      ? '${item['productName'] ?? 'Packaged product'} · batch ${item['batchNo'] ?? ''} · ${expired ? 'Expired' : 'Expiring soon'}'
                      : 'Milk batch ${item['batchNo'] ?? ''} · ${expired ? 'Expired' : 'Expiring soon'}'),
                  subtitle: Text(finishedProduct
                      ? 'Expiry $expiryLabel · $productQty packs${packLabel.isEmpty ? '' : ' ($packLabel)'}${expired ? ' expired' : ' remaining'}'
                      : 'Expiry $expiryLabel · ${item['availableQtyL'] ?? 0} L remaining'),
                );
              }),
            ]),
          ),

          _sectionCard(
            title: l10n.fssaiLicence,
            icon: Icons.verified_outlined,
            child: compliance == null
                ? _unavailable(l10n)
                : ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      _complianceLabel(
                        compliance['status']?.toString() ?? '',
                        l10n,
                      ),
                    ),
                    subtitle: Text(
                      compliance['daysToExpiry'] == null
                          ? l10n.noLicenceRecorded
                          : l10n.daysToExpiry(
                              int.tryParse(
                                    compliance['daysToExpiry'].toString(),
                                  ) ??
                                  0,
                            ),
                    ),
                    trailing: compliance['status'] == 'expired'
                        ? const Icon(Icons.error_outline, color: AppColors.expired)
                        : null,
                  ),
          ),

          _sectionCard(
            title: l10n.supplierPayables,
            icon: Icons.receipt_outlined,
            child: payables == null
                ? _unavailable(l10n)
                : ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(_rupees(payables['payable'])),
                    subtitle: Text(
                      l10n.approvedStatements(
                        int.tryParse(payables['count']?.toString() ?? '') ?? 0,
                      ),
                    ),
                  ),
          ),

          Card(
            child: ListTile(
              leading: Icon(Icons.route_outlined, color: theme.primary),
              title: Text(l10n.todayRuns),
              subtitle: deliveries == null
                  ? null
                  : Text(
                      l10n.stopsPendingCount(
                        int.tryParse(
                              deliveries['stopsPending']?.toString() ?? '',
                            ) ??
                            0,
                      ),
                    ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const PartnerDeliveryRunListScreen(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _enterpriseHeader(
    BuildContext context,
    AppLocalizations l10n,
    AppThemeData theme,
    UserSessionModel? session,
  ) {
    final String outletName = _outlet?['name']?.toString() ?? l10n.navHome;
    final String ownerName = '${session?.firstName ?? ''} ${session?.lastName ?? ''}'.trim();
    final Map<String, dynamic> locality = Map<String, dynamic>.from(
      _outlet?['locality'] as Map? ?? <String, dynamic>{},
    );
    final Map<String, dynamic> city = Map<String, dynamic>.from(
      _outlet?['city'] as Map? ?? <String, dynamic>{},
    );
    final String serviceArea = <String>[
      locality['name']?.toString() ?? '',
      city['name']?.toString() ?? '',
    ].where((String value) => value.isNotEmpty).join(', ');
    final bool outletReady = widget.outletVerified && widget.outletLocationComplete;
    final String readiness = !widget.outletVerified
        ? 'Verification pending'
        : outletReady
            ? 'Ready to operate'
            : 'Setup required';
    final DateTime? updatedAt = _generatedAt?.toLocal();
    final String updatedTime = updatedAt == null
        ? ''
        : '${updatedAt.hour.toString().padLeft(2, '0')}:${updatedAt.minute.toString().padLeft(2, '0')}';
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[theme.primary, theme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const CircleAvatar(
                backgroundColor: Colors.white24,
                child: Icon(Icons.storefront_outlined, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      outletName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ownerName.isEmpty ? 'Dairy partner workspace' : 'Welcome back, $ownerName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.86),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (serviceArea.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Row(children: <Widget>[
              const Icon(Icons.location_on_outlined, size: 16, color: Colors.white70),
              const SizedBox(width: 4),
              Expanded(child: Text(serviceArea, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70))),
            ]),
          ],
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(24)),
            child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
              Icon(outletReady ? Icons.check_circle_outline : Icons.info_outline, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(readiness, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
            ]),
          ),
          const SizedBox(height: 18),
          Text(
            'Business overview',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          if (updatedTime.isNotEmpty) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              'Updated at $updatedTime',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.82)),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _quickAction(l10n.navOrders, Icons.receipt_long_outlined, 1),
              _quickAction(l10n.navInventory, Icons.inventory_2_outlined, 2),
              _quickAction(l10n.navSubscriptions, Icons.event_repeat_outlined, 3),
            ],
          ),
        ],
      ),
    );
  }

  Widget _salesTrendPanel(
    BuildContext context,
    AppLocalizations l10n,
    AppThemeData theme,
    Map<String, dynamic>? trend,
  ) {
    final List<dynamic> rawDays = (trend?['days'] as List?) ?? const <dynamic>[];
    final List<Map<String, dynamic>> days = rawDays
        .whereType<Map>()
        .map((Map<dynamic, dynamic> row) => Map<String, dynamic>.from(row))
        .toList();
    final List<double> revenue = days
        .map((Map<String, dynamic> row) => double.tryParse(row['revenue']?.toString() ?? '') ?? 0)
        .toList();
    final double totalRevenue = double.tryParse(trend?['totalRevenue']?.toString() ?? '') ?? 0;
    final double previousRevenue = double.tryParse(trend?['previousRevenue']?.toString() ?? '') ?? 0;
    final int totalOrders = int.tryParse(trend?['totalOrders']?.toString() ?? '') ?? 0;
    final String periodLabel = _selectedTrendPeriod == '30d' ? '30 days' : '7 days';
    final double? change = previousRevenue <= 0
        ? null
        : ((totalRevenue - previousRevenue) / previousRevenue) * 100;
    final String comparison = change == null
        ? (totalRevenue > 0 ? 'No sales in the previous period' : 'No sales in either period')
        : '${change >= 0 ? '↑' : '↓'} ${change.abs().toStringAsFixed(1)}% vs previous $periodLabel';

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.insights_outlined, color: theme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Sales trend', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                ),
                Text(periodLabel, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: <Widget>[
                ChoiceChip(
                  label: const Text('7 days'),
                  selected: _selectedTrendPeriod == '7d',
                  onSelected: (_) => _selectTrendPeriod('7d'),
                ),
                ChoiceChip(
                  label: const Text('30 days'),
                  selected: _selectedTrendPeriod == '30d',
                  onSelected: (_) => _selectTrendPeriod('30d'),
                ),
              ],
            ),
            if (trend == null)
              _unavailable(l10n)
            else ...<Widget>[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(_rupees(totalRevenue), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                        Text('$totalOrders orders in the last $periodLabel', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  if (change != null || totalRevenue > 0)
                    Text(
                      comparison,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: change == null
                            ? theme.secondary
                            : change >= 0
                                ? Colors.green.shade700
                                : AppColors.expired,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Semantics(
                label: 'Daily revenue chart for the last $periodLabel',
                child: SizedBox(
                  height: 128,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _RevenueTrendPainter(
                      values: revenue,
                      barColor: theme.primary,
                      gridColor: Theme.of(context).dividerColor.withValues(alpha: 0.45),
                    ),
                  ),
                ),
              ),
              if (days.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(_shortDate(days.first['date']), style: Theme.of(context).textTheme.labelSmall),
                    Text(_shortDate(days.last['date']), style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }

  void _selectTrendPeriod(String period) {
    if (period == _selectedTrendPeriod) return;
    setState(() => _selectedTrendPeriod = period);
    _load();
  }

  String _shortDate(Object? value) {
    final List<String> parts = (value?.toString() ?? '').split('-');
    return parts.length == 3 ? '${parts[1]}/${parts[2]}' : value?.toString() ?? '';
  }

  Widget _attentionSection(
    BuildContext context,
    AppLocalizations l10n,
    AppThemeData theme, {
    required Map<String, dynamic>? today,
    required Map<String, dynamic>? lowStock,
    required Map<String, dynamic> outOfStock,
    required Map<String, dynamic>? expiryAlerts,
    required Map<String, dynamic>? compliance,
    required Map<String, dynamic>? deliveries,
    required bool checksUnavailable,
  }) {
    int count(Object? value) => int.tryParse(value?.toString() ?? '') ?? 0;

    final int lowStockCount = count(lowStock?['count']);
    final int outOfStockCount = count(outOfStock['count']);
    final int expiredCount = count(expiryAlerts?['expiredCount']);
    final int expiringSoonCount = count(expiryAlerts?['expiringSoonCount']);
    final int pendingStops = count(deliveries?['stopsPending']);
    final String complianceStatus = compliance?['status']?.toString() ?? '';
    final List<Widget> items = <Widget>[];
    final Map<String, dynamic> ordersByStatus = Map<String, dynamic>.from(
      today?['byStatus'] as Map? ?? <String, dynamic>{},
    );
    int ordersInStatus(String status) {
      final Map<String, dynamic> row = Map<String, dynamic>.from(
        ordersByStatus[status] as Map? ?? <String, dynamic>{},
      );
      return count(row['orders']);
    }

    final int ordersToProcess = ordersInStatus('confirmed') + ordersInStatus('preparing');
    final int issueCount = ordersToProcess
        + lowStockCount
        + outOfStockCount
        + expiredCount
        + expiringSoonCount
        + pendingStops
        + (complianceStatus == 'expired' || complianceStatus == 'expiring' ? 1 : 0);

    if (ordersToProcess > 0) {
      items.add(_attentionTile(
        icon: Icons.receipt_long_outlined,
        title: 'Orders to process: $ordersToProcess',
        subtitle: 'Confirmed and preparing orders are waiting for the next step.',
        color: theme.primary,
        onTap: widget.onNavigate == null ? null : () => widget.onNavigate!(1),
      ));
    }

    if (outOfStockCount > 0 || lowStockCount > 0) {
      items.add(_attentionTile(
        icon: Icons.inventory_2_outlined,
        title: outOfStockCount > 0
            ? 'Out of stock products: $outOfStockCount'
            : 'Low-stock items: $lowStockCount',
        subtitle: outOfStockCount > 0 && lowStockCount > 0
            ? '$lowStockCount additional products are below their stock threshold.'
            : 'Review stock levels and replenish products.',
        color: outOfStockCount > 0 ? AppColors.expired : theme.secondary,
        onTap: widget.onNavigate == null ? null : () => widget.onNavigate!(2),
      ));
    }

    if (expiredCount > 0 || expiringSoonCount > 0) {
      items.add(_attentionTile(
        icon: Icons.schedule_outlined,
        title: expiredCount > 0
            ? 'Expired batches: $expiredCount'
            : 'Batches expiring soon: $expiringSoonCount',
        subtitle: 'Review batch dates and take action in inventory.',
        color: expiredCount > 0 ? AppColors.expired : theme.secondary,
        onTap: widget.onNavigate == null ? null : () => widget.onNavigate!(2),
      ));
    }

    if (complianceStatus == 'expired' || complianceStatus == 'expiring') {
      items.add(_attentionTile(
        icon: Icons.verified_user_outlined,
        title: complianceStatus == 'expired' ? 'Food licence expired' : 'Food licence expiring soon',
        subtitle: 'Review your outlet compliance details.',
        color: AppColors.expired,
        onTap: widget.onNavigate == null ? null : () => widget.onNavigate!(4),
      ));
    }

    if (pendingStops > 0) {
      items.add(_attentionTile(
        icon: Icons.route_outlined,
        title: 'Pending delivery stops: $pendingStops',
        subtitle: "Open today's delivery run to review pending stops.",
        color: theme.primary,
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => const PartnerDeliveryRunListScreen(),
        )),
      ));
    }

    final bool checksLoaded = today != null && lowStock != null && expiryAlerts != null && compliance != null && deliveries != null;
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(children: <Widget>[
              const Icon(Icons.assignment_turned_in_outlined, size: 19),
              const SizedBox(width: 8),
              Expanded(child: Text('Needs attention', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
              if (issueCount > 0) Text('$issueCount', style: Theme.of(context).textTheme.labelLarge),
            ]),
            const SizedBox(height: 6),
            if (items.isNotEmpty)
              ...items
            else if (!checksUnavailable && checksLoaded)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(children: <Widget>[
                  Icon(Icons.check_circle_outline, color: theme.primary),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('No urgent operational issues found.')),
                ]),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(l10n.temporarilyUnavailable),
              ),
          ],
        ),
      ),
    );
  }

  Widget _attentionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback? onTap,
  }) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: onTap == null ? null : const Icon(Icons.chevron_right),
        onTap: onTap,
      );

  Widget _quickAction(
    String label,
    IconData icon,
    int destination,
  ) => OutlinedButton.icon(
    onPressed: widget.onNavigate == null
        ? null
        : () => widget.onNavigate!(destination),
    icon: Icon(icon, size: 16),
    label: Text(label),
    style: OutlinedButton.styleFrom(
      foregroundColor: Colors.white,
      side: BorderSide(color: Colors.white.withValues(alpha: 0.55)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
  );

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    VoidCallback? onTap,
  }) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(icon, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (onTap != null) const Icon(Icons.chevron_right, size: 18),
                ],
              ),
              const SizedBox(height: 6),
              child,
            ],
          ),
        ),
      ),
    );
  }

  /// Shown in place of a panel the API could not gather.
  ///
  /// The other panels still render — that is the whole point of gathering them
  /// independently.
  Widget _unavailable(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(l10n.temporarilyUnavailable)),
          TextButton(onPressed: _load, child: Text(l10n.retry)),
        ],
      ),
    );
  }
}

class _RevenueTrendPainter extends CustomPainter {
  const _RevenueTrendPainter({
    required this.values,
    required this.barColor,
    required this.gridColor,
  });

  final List<double> values;
  final Color barColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final Paint grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (int line = 0; line < 4; line++) {
      final double y = size.height * line / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    if (values.isEmpty) return;
    final double maximum = values.fold<double>(0, (double best, double value) => math.max(best, value).toDouble());
    if (maximum <= 0) return;

    final double slot = size.width / values.length;
    final double barWidth = math.min(18, slot * 0.62).toDouble();
    final Paint bar = Paint()..color = barColor;
    for (int index = 0; index < values.length; index++) {
      final double value = values[index];
      if (value <= 0) continue;
      final double barHeight = (size.height - 8) * value / maximum;
      final double left = index * slot + (slot - barWidth) / 2;
      final Rect rect = Rect.fromLTWH(left, size.height - barHeight, barWidth, barHeight);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), bar);
    }
  }

  @override
  bool shouldRepaint(_RevenueTrendPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.barColor != barColor || oldDelegate.gridColor != gridColor;
}
