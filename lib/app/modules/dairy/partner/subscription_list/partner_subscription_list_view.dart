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

/// Recurring plans sold by this outlet.
///
/// Backed by `GET /partner/subscriptions/list`, with pause and resume on
/// `PATCH /partner/subscriptions/{subscription}/pause|resume`.
///
/// The outlet comes from the access token, so nothing here is scoped by a value
/// the app could choose.
class PartnerSubscriptionListScreen extends StatefulWidget {
  const PartnerSubscriptionListScreen({super.key, this.partnerRepository});

  final PartnerRepository? partnerRepository;

  @override
  State<PartnerSubscriptionListScreen> createState() =>
      _PartnerSubscriptionListScreenState();
}

class _PartnerSubscriptionListScreenState
    extends State<PartnerSubscriptionListScreen> {
  late final PartnerRepository _partnerRepository =
      widget.partnerRepository ?? PartnerRepository();

  bool _loading = true;
  String? _error;
  List<dynamic> _subscriptions = const <dynamic>[];
  String? _actingOn;
  String _searchQuery = '';
  _SubscriptionFilter _filter = _SubscriptionFilter.all;

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

    final DioApiResponse response = await _partnerRepository.subscriptions();

    if (!mounted) return;

    if (response.errorType != NetErrorType.none) {
      setState(() {
        _loading = false;
        _error = AppLocalizations.of(context)!.couldNotLoadPlans;
      });
      return;
    }
final Map<String, dynamic> body = decodeBody(response);
    setState(() {
      _loading = false;
      _subscriptions = (body['subscriptions'] as List?) ?? const <dynamic>[];
    });
  }

  /// Pause or resume, then reload so the row reflects what the API decided.
  Future<void> _act(String subscriptionId, String action) async {
    setState(() => _actingOn = subscriptionId);
    final DioApiResponse response = await _partnerRepository.subscriptionAction(
      subscriptionId,
      action,
    );

    if (!mounted) return;
    setState(() => _actingOn = null);

    if (response.errorType == NetErrorType.none) {
      await _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.couldNotUpdatePlan)),
      );
    }
  }

  /// The plan holder, from the populated `user` on the row.
  String _holder(Map<String, dynamic> subscription, AppLocalizations l10n) {
    final Map<String, dynamic> user = Map<String, dynamic>.from(
      (subscription['user'] as Map?) ?? <String, dynamic>{},
    );
    final String name = <String>[
      user['firstName']?.toString() ?? '',
      user['lastName']?.toString() ?? '',
    ].where((String part) => part.isNotEmpty).join(' ');
    return name.isEmpty ? l10n.customer : name;
  }

  String _plan(Map<String, dynamic> subscription, AppLocalizations l10n) {
    final Map<String, dynamic> sku = Map<String, dynamic>.from(
      (subscription['sku'] as Map?) ?? <String, dynamic>{},
    );
    final Map<String, dynamic> pack = Map<String, dynamic>.from(
      (sku['packSize'] as Map?) ?? <String, dynamic>{},
    );
    final String product = sku['name']?.toString() ?? l10n.planFallback;
    final num? value = (pack['value'] as num?) ?? (pack['quantity'] as num?);
    final String unit = pack['unit']?.toString() ?? '';
    final String size = value == null ? '' : ' · $value $unit';
    final String schedule = _scheduleLabel(
      subscription['scheduleType']?.toString() ?? '',
      l10n,
    );
    final String quantity = subscription['quantity']?.toString() ?? '';
    return '$product$size · $schedule · ${l10n.quantityLabel} $quantity';
  }

  String _scheduleLabel(String schedule, AppLocalizations l10n) {
    switch (schedule) {
      case 'daily':
        return l10n.scheduleDaily;
      case 'alternate_days':
        return l10n.scheduleAlternateDays;
      case 'weekly':
        return l10n.scheduleWeekly;
      case 'custom_days':
        return l10n.scheduleCustomDays;
      default:
        return schedule.replaceAll('_', ' ');
    }
  }

  String _statusLabel(String status, AppLocalizations l10n) {
    switch (status) {
      case 'pending_payments':
        return l10n.statusPendingPayments;
      case 'active':
        return l10n.statusActive;
      case 'paused':
        return l10n.statusPaused;
      case 'cancelled':
        return l10n.statusCancelled;
      case 'completed':
        return l10n.statusCompleted;
      default:
        return status.isEmpty ? l10n.unknownStatus : status;
    }
  }

  Color _statusColour(String status) {
    switch (status) {
      case 'active':
        return AppColors.canInStore;
      case 'paused':
        return AppColors.expirySoon;
      case 'cancelled':
      case 'completed':
        return AppColors.expired;
      default:
        return AppColors.grey;
    }
  }

  List<Map<String, dynamic>> _visibleSubscriptions(AppLocalizations l10n) {
    final String query = _searchQuery.trim().toLowerCase();
    return _subscriptions
        .whereType<Map>()
        .map((Map row) => Map<String, dynamic>.from(row))
        .where((Map<String, dynamic> subscription) {
          final String status = subscription['status']?.toString() ?? '';
          if (_filter == _SubscriptionFilter.active && status != 'active') {
            return false;
          }
          if (_filter == _SubscriptionFilter.paused && status != 'paused') {
            return false;
          }
          if (query.isEmpty) return true;
          return '${_holder(subscription, l10n)} ${_plan(subscription, l10n)} $status'
              .toLowerCase()
              .contains(query);
        })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final List<Map<String, dynamic>> subscriptions = _subscriptions
        .whereType<Map>()
        .map((Map row) => Map<String, dynamic>.from(row))
        .toList();
    final List<Map<String, dynamic>> visibleSubscriptions =
        _visibleSubscriptions(l10n);
    final int activeCount = subscriptions
        .where((Map<String, dynamic> row) => row['status'] == 'active')
        .length;
    final int pausedCount = subscriptions
        .where((Map<String, dynamic> row) => row['status'] == 'paused')
        .length;

    return SectionListScreen(
      title: l10n.navSubscriptions,
      icon: Icons.event_repeat_outlined,
      onRefresh: _load,
      children: <Widget>[
        if (!_loading && _error == null && subscriptions.isNotEmpty) ...<Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: MetricTile(
                  label: 'Active plans',
                  value: '$activeCount',
                  icon: Icons.event_available_outlined,
                  accent: AppColors.canInStore,
                ),
              ),
              Expanded(
                child: MetricTile(
                  label: 'Paused plans',
                  value: '$pausedCount',
                  icon: Icons.pause_circle_outline,
                  accent: AppColors.expirySoon,
                ),
              ),
            ],
          ),
          Card(
            child: TextField(
              key: const ValueKey<String>('dairy-subscriptions-search'),
              onChanged: (String value) => setState(() => _searchQuery = value),
              decoration: const InputDecoration(
                hintText: 'Search customer, product or schedule',
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
                _filterChip('All · ${subscriptions.length}', _SubscriptionFilter.all),
                const SizedBox(width: 8),
                _filterChip('Active · $activeCount', _SubscriptionFilter.active),
                const SizedBox(width: 8),
                _filterChip('Paused · $pausedCount', _SubscriptionFilter.paused),
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
            title: l10n.subscriptionsUnavailable,
            message: _error!,
            icon: Icons.cloud_off_outlined,
          )
        else if (_subscriptions.isEmpty)
          EmptyState(
            title: l10n.noSubscriptions,
            message: l10n.noSubscriptionsHint,
            icon: Icons.event_repeat_outlined,
          )
        else if (visibleSubscriptions.isEmpty)
          const EmptyState(
            title: 'No matching subscriptions',
            message: 'Try another search or plan status.',
            icon: Icons.search_off_outlined,
          )
        else
          Card(
            child: Column(
              children: visibleSubscriptions.asMap().entries.map((
                MapEntry<int, Map<String, dynamic>> entry,
              ) {
                return Column(
                  children: <Widget>[
                    if (entry.key > 0)
                      const Divider(height: 1, indent: 16, endIndent: 16),
                    _subscriptionRow(context, entry.value, l10n),
                  ],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _subscriptionRow(
    BuildContext context,
    Map<String, dynamic> subscription,
    AppLocalizations l10n,
  ) {
    final String id = (subscription['id'] ?? subscription['_id']).toString();
    final String status = subscription['status']?.toString() ?? '';
    final bool busy = _actingOn == id;
    // Cancelled and completed plans are history, so they have no actions.
    final bool actionable = status == 'active' || status == 'paused';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          Icons.event_repeat_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(_holder(subscription, l10n)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(_plan(subscription, l10n)),
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
                  tooltip: status == 'paused' ? l10n.resume : l10n.pause,
                  icon: Icon(
                    status == 'paused'
                        ? Icons.play_circle_outline
                        : Icons.pause_circle_outline,
                  ),
                  onPressed: () => _act(
                    id,
                    status == 'paused' ? 'resume' : 'pause',
                  ),
                )
              : null,
      isThreeLine: true,
    );
  }

  Widget _filterChip(String label, _SubscriptionFilter filter) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: ChoiceChip(
      label: Text(label),
      selected: _filter == filter,
      onSelected: (_) => setState(() => _filter = filter),
    ),
  );
}

enum _SubscriptionFilter { all, active, paused }
