/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
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
import 'package:partner/app/modules/jhatka/partner/money/jhatka_money_repository.dart';
import 'package:partner/app/modules/jhatka/partner/money/payout_detail_screen.dart';
import 'package:partner/app/modules/jhatka/partner/weighing/jhatka_money.dart'
    as jhatka_money;
import 'package:partner/app/presentation/styles/theme.dart';
import 'package:partner/app/presentation/styles/widgets.dart';
import 'package:flutter/material.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

/// Settlement summary, payouts and payables for the outlet.
///
/// Units differ by endpoint and the screen must not guess: the summary speaks
/// paise (`totalRevenuePaise`), payout documents speak rupees. Each figure is
/// formatted with its unit made explicit. A rolled-forward payout shows its
/// own `rolledForwardReason` — the money is carried, not lost.
class PayoutsScreen extends StatefulWidget {
  const PayoutsScreen({super.key});

  @override
  State<PayoutsScreen> createState() => _PayoutsScreenState();
}

class _PayoutsScreenState extends State<PayoutsScreen> {
  final JhatkaMoneyRepository _repository = JhatkaMoneyRepository();

  bool _loading = true;
  String? _error;
  Map<String, dynamic> _summary = const <String, dynamic>{};
  List<dynamic> _payouts = const <dynamic>[];
  List<dynamic> _payables = const <dynamic>[];
  Map<String, dynamic> _terms = const <String, dynamic>{};
  List<dynamic> _settlements = const <dynamic>[];
  Map<String, dynamic> _analytics = const <String, dynamic>{};
  String? _actingOn;

  /// Last 30 days, yyyy-mm-dd. The server requires an explicit window.
  String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

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
    final DateTime now = DateTime.now();
    final List<DioApiResponse> results =
        await Future.wait(<Future<DioApiResponse>>[
          _repository.settlementSummary(
            fromDate: _iso(now.subtract(const Duration(days: 30))),
            toDate: _iso(now),
          ),
          _repository.payouts(),
          _repository.payables(),
          _repository.commissionTerms(),
          _repository.analytics(),
          _repository.settlements(),
        ]);
    if (!mounted) return;
    if (results.any((DioApiResponse r) => r.errorType != NetErrorType.none)) {
      setState(() {
        _loading = false;
        _error = 'Could not load money.';
      });
      return;
    }
    setState(() {
      _loading = false;
      _summary = Map<String, dynamic>.from(
        (decodeBody(results[0])['summary'] ?? {}) as Map,
      );
      _payouts =
          (decodeBody(results[1])['payouts'] as List?) ?? const <dynamic>[];
      _payables =
          (decodeBody(results[2])['payables'] as List?) ?? const <dynamic>[];
      _terms = Map<String, dynamic>.from(decodeBody(results[3]));
      _analytics = Map<String, dynamic>.from(
        (decodeBody(results[4])['analytics'] ?? decodeBody(results[4])) as Map,
      );
      _settlements =
          (decodeBody(results[5])['settlements'] as List?) ?? const <dynamic>[];
    });
  }

  Future<void> _act(String key, Future<DioApiResponse> Function() call) async {
    setState(() => _actingOn = key);
    final DioApiResponse response = await call();
    if (!mounted) return;
    setState(() => _actingOn = null);
    if (response.errorType == NetErrorType.none) {
      await _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.jhatkaDidNotGoThrough),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SectionListScreen(
      title: AppLocalizations.of(context)!.jhatkaNavMoney,
      icon: Icons.payments_outlined,
      onRefresh: _load,
      children: <Widget>[
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          EmptyState(
            title: AppLocalizations.of(context)!.jhatkaMoneyUnavailable,
            message: _error!,
            icon: Icons.cloud_off_outlined,
          )
        else ...<Widget>[
          _summaryCard(),
          _sectionTitle('Payouts (${_payouts.length})'),
          ..._payouts.map(_payoutTile),
          const SizedBox(height: 12),
          _sectionTitle('Payables (${_payables.length})'),
          ..._payables.map(_payableTile),
          const SizedBox(height: 12),
          _sectionTitle('Settlements (${_settlements.length})'),
          ..._settlements.map(_settlementTile),
          const SizedBox(height: 12),
          _analyticsCard(),
          const SizedBox(height: 12),
          _commissionTermsCard(),
        ],
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _summaryCard() {
    int paiseOf(String key) => ((_summary[key] as num?) ?? 0).toInt();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              'Last 30 days',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Orders ${_summary['totalOrders'] ?? 0}'),
            Text(
              'Revenue ${jhatka_money.formatPaise(paiseOf('totalRevenuePaise'))}',
            ),
            Text(
              'Refunds ${jhatka_money.formatPaise(paiseOf('totalRefundsPaise'))}',
            ),
            Text(
              'Net ${jhatka_money.formatPaise(paiseOf('netRevenuePaise'))}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _payoutTile(dynamic raw) {
    final Map<String, dynamic> payout = Map<String, dynamic>.from(raw as Map);
    final String id = (payout['id'] ?? payout['_id'] ?? '').toString();
    final String status = (payout['status'] ?? '').toString();
    final String? rolled =
        (payout['rolledForwardReason'] ?? payout['statusReason'])?.toString();
    // Lean list read: raw PAISE, not rupees.
    final num net = (payout['netAmount'] ?? payout['netPayout'] ?? 0) as num;
    return Card(
      child: ListTile(
        title: Text('Payout ${payout['payoutNo'] ?? '—'}'),
        subtitle: Text(
          '${jhatka_money.formatPaise(net)} · $status'
          '${rolled != null && rolled.isNotEmpty ? '\n$rolled' : ''}',
        ),
        isThreeLine: rolled != null && rolled.isNotEmpty,
        // Tap for the lines behind the total — what produced it, what rule,
        // what was deducted. The list row cannot carry that weight.
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => PayoutDetailScreen(payoutId: id),
            ),
          );
        },
        trailing: StatusChip(label: status, color: AppColors.grey),
      ),
    );
  }

  Widget _payableTile(dynamic raw) {
    final Map<String, dynamic> payable = Map<String, dynamic>.from(raw as Map);
    final String id = (payable['id'] ?? payable['_id'] ?? '').toString();
    final String status = (payable['status'] ?? '').toString();
    final bool busy = _actingOn == 'payable:$id';
    // Lean list read: raw PAISE, not rupees.
    final num net = (payable['netAmount'] ?? 0) as num;
    return Card(
      child: ListTile(
        title: Text('Payable ${payable['payableNo'] ?? '—'}'),
        subtitle: Text('${jhatka_money.formatPaise(net)} · $status'),
        trailing: busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : status == 'draft' || status == 'approved'
            ? TextButton(
                onPressed: () =>
                    _act('payable:$id', () => _repository.payPayable(id)),
                child: Text(AppLocalizations.of(context)!.jhatkaActionPay),
              )
            : StatusChip(label: status, color: AppColors.grey),
      ),
    );
  }

  /// Platform settlements. Read-only here — finalise and dispute are admin
  /// actions. Shown so the outlet sees the same statement the platform settled,
  /// rather than discovering it in the payout alone.
  Widget _settlementTile(dynamic raw) {
    final Map<String, dynamic> settlement = Map<String, dynamic>.from(
      raw as Map,
    );
    final String status = (settlement['status'] ?? '').toString();
    // Lean list read: raw PAISE, not rupees — same convention as payouts above.
    final num net =
        (settlement['netAmount'] ?? settlement['netPayout'] ?? 0) as num;
    return Card(
      child: ListTile(
        title: Text('Settlement ${settlement['settlementNo'] ?? '—'}'),
        subtitle: Text('${jhatka_money.formatPaise(net)} · $status'),
        trailing: StatusChip(label: status, color: AppColors.grey),
      ),
    );
  }

  Widget _analyticsCard() {
    Map<String, dynamic> section(String key) {
      final dynamic value = _analytics[key];
      return value is Map
          ? Map<String, dynamic>.from(value)
          : <String, dynamic>{};
    }

    final Map<String, dynamic> orders = section('orders');
    final Map<String, dynamic> wastage = section('wastage');
    final Map<String, dynamic> subscriptions = section('subscriptions');
    final Map<String, dynamic> inventory = section('inventory');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              'Outlet pulse',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Orders ${orders['count'] ?? 0} · '
              'est ${jhatka_money.formatRupees((orders['estimatedTotal'] as num?) ?? 0)} · '
              'refunded ${jhatka_money.formatRupees((orders['refundedTotal'] as num?) ?? 0)}',
            ),
            Text(
              'Wastage ${wastage['count'] ?? 0} (${wastage['orderLinked'] ?? 0} order-linked)',
            ),
            Text(
              'Subscriptions ${subscriptions['count'] ?? 0} · '
              'occurrences +${subscriptions['occurrencesGenerated'] ?? 0} / '
              'skipped ${subscriptions['occurrencesSkipped'] ?? 0}',
            ),
            Text(
              'Low stock ${inventory['lowStockCount'] ?? 0} · '
              'expired ${inventory['expiredCount'] ?? 0}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _commissionTermsCard() {
    Map<String, dynamic>? mapOf(dynamic value) =>
        value is Map ? Map<String, dynamic>.from(value) : null;
    final Map<String, dynamic>? rule = mapOf(_terms['activeRule']);
    final Map<String, dynamic>? snapshot = mapOf(_terms['lastAppliedSnapshot']);
    final Map<String, dynamic>? period = mapOf(_terms['lastPayoutPeriod']);

    String percentOf(dynamic value) {
      final double? parsed = value == null
          ? null
          : double.tryParse(value.toString());
      return parsed == null ? '—' : '${parsed.toStringAsFixed(2)}%';
    }

    String dateOf(dynamic value) {
      final DateTime? parsed = value == null
          ? null
          : DateTime.tryParse(value.toString());
      if (parsed == null) return value?.toString() ?? '—';
      return '${parsed.day.toString().padLeft(2, '0')}/'
          '${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
    }

    String modelOf(dynamic value) {
      if (value == 'franchise') return 'Franchise';
      if (value == 'commission_partner') return 'Commission partner';
      return value?.toString() ?? '—';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              'Commission terms',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Set by LocalWala admin. This screen is read-only.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text('Business model: ${modelOf(_terms['businessModel'])}'),
            if (rule == null)
              const Text('No active commission rule for this business model.')
            else ...<Widget>[
              Text('Rule: ${rule['name'] ?? rule['code'] ?? '—'}'),
              Text('Basis: ${rule['basis'] ?? '—'}'),
              Text('Platform fee: ${percentOf(rule['platformFeePercent'])}'),
              Text('Partner rate: ${percentOf(rule['ratePercent'])}'),
              Text('Effective from: ${dateOf(rule['effectiveFrom'])}'),
            ],
            const SizedBox(height: 8),
            Text(
              snapshot == null
                  ? 'Last payout rule: no payout generated yet.'
                  : 'Last payout rule: '
                        '${snapshot['name'] ?? snapshot['code'] ?? '—'}'
                        ' (platform ${percentOf(snapshot['platformFeePercent'])},'
                        ' partner ${percentOf(snapshot['ratePercent'])})',
            ),
            if (period != null)
              Text(
                'Last payout period: ${dateOf(period['from'])} to '
                '${dateOf(period['to'])}',
              ),
          ],
        ),
      ),
    );
  }
}
