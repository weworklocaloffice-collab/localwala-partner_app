/*
 * WeWorkLocal
 * Hyperlocal Commerce & Service Platform
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

import 'package:partner/gen/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:partner/app/modules/stores/partner/settlements/stores_settlement_detail_screen.dart';
import 'package:partner/app/modules/stores/stores_partner_repository.dart';
import 'package:partner/app/modules/stores/widgets/stores_ui_states.dart';
import 'package:partner/app/presentation/styles/theme.dart';

/// §23 Payments — the money view.
///
/// Gross order value, refunds, adjustments, net settlement, settlement status/date and
/// the transaction reference, one row per closed period. It is a LIST over server-computed
/// rows, and the header sums sum only the rows actually loaded and say so — the app never
/// recomputes a settlement authority owes, it only reads what the settlement engine wrote.
/// Tapping a row opens the full statement with line items.
class StoresPaymentsScreen extends StatefulWidget {
  const StoresPaymentsScreen({super.key});

  @override
  State<StoresPaymentsScreen> createState() => _StoresPaymentsScreenState();
}

class _StoresPaymentsScreenState extends State<StoresPaymentsScreen> {
  StoresPartnerRepository? _repo;
  List<Map<String, dynamic>> _rows = <Map<String, dynamic>>[];
  bool _loading = true;
  bool _loadingMore = false;
  Object? _error;
  int _page = 1;
  int _totalPages = 1;
  num _gross = 0;
  num _refunds = 0;
  num _adjustments = 0;
  num _net = 0;

  @override
  void initState() {
    super.initState();
    _repo = StoresPartnerRepository();
    _load();
  }

  Future<void> _load({bool more = false}) async {
    final StoresPartnerRepository repo = _repo ?? StoresPartnerRepository();
    if (more) {
      setState(() => _loadingMore = true);
    } else {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final Map<String, dynamic> body = await repo.settlements(
        page: _page,
        limit: 20,
      );
      final dynamic raw = body['items'] ?? body['results'];
      final List<Map<String, dynamic>> fetched = raw is List
          ? raw.whereType<Map<String, dynamic>>().toList()
          : <Map<String, dynamic>>[];
      setState(() {
        _rows = _rows + fetched;
        _totalPages = _int(body['totalPages']) ?? 1;
        for (final Map<String, dynamic> row in fetched) {
          final dynamic totals = row['totals'];
          if (totals is Map) {
            _gross += _num(totals['grossOrderValue']);
            _refunds += _num(totals['refunds']);
            _adjustments += _num(totals['adjustments']);
            _net += _num(totals['netAmount']);
          }
        }
        _page = _page + 1;
        _loading = false;
        _loadingMore = false;
      });
    } on Object catch (error) {
      setState(() {
        _error = error;
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _rows = <Map<String, dynamic>>[];
      _page = 1;
      _totalPages = 1;
      _gross = 0;
      _refunds = 0;
      _adjustments = 0;
      _net = 0;
      _loading = true;
      _error = null;
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.storesTitlePayments),
        actions: <Widget>[
          IconButton(
            onPressed: _loading ? null : () => _refresh(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    if (_loading && _rows.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _rows.isEmpty) {
      return StoresErrorView(error: _error, onRetry: () => _refresh());
    }
    if (_rows.isEmpty) {
      return const StoresEmptyView(
        message:
            'No payments yet. They appear after the first settlement is generated.',
        icon: Icons.payments_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        itemCount: _rows.length + 1 + (_page < _totalPages ? 1 : 0),
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) return _summaryHeader(context);
          final int rowIndex = index - 1;
          if (rowIndex >= _rows.length) return _loadMore(context);
          return _paymentTile(context, _rows[rowIndex]);
        },
      ),
    );
  }

  Widget _summaryHeader(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '${_rows.length} periods shown',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: _tile(context, 'Gross', _money(_gross)),
                ),
                Expanded(
                  child: _tile(context, 'Refunds', _money(_refunds)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: _tile(context, 'Adjustments', _money(_adjustments)),
                ),
                Expanded(
                  child: _tile(
                    context,
                    'Net payable',
                    _money(_net),
                    strong: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, String label, String value,
      {bool strong = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          value,
          style: strong
              ? Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)
              : Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 2),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }

  Widget _loadMore(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: _loadingMore
            ? const CircularProgressIndicator()
            : OutlinedButton(
                onPressed: () => _load(more: true),
                child: Text(AppLocalizations.of(context)!.storesLoadMore),
              ),
      ),
    );
  }

  Widget _paymentTile(BuildContext context, Map<String, dynamic> row) {
    final dynamic totals = row['totals'];
    final Map<String, dynamic> sums =
        totals is Map<String, dynamic> ? totals : <String, dynamic>{};
    final String status = '${row['status'] ?? 'pending'}';

    return ListTile(
      leading: const Icon(Icons.payments_outlined),
      title: Text(AppLocalizations.of(context)!.storesSettlementNumber('')),
      subtitle: Text(
        'Gross ${_money(sums['grossOrderValue'])} · '
        'Refunds ${_money(sums['refunds'])} · '
        'Adjustments ${_money(sums['adjustments'])} · '
        'Net ${_money(sums['netAmount'])}'
        '${row['settlementDate'] != null ? '\nSettled ${_date(row['settlementDate'])}' : ''}'
        '${row['gatewayReference'] != null ? ' · Ref ${row['gatewayReference']}' : ''}',
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: _statusChip(context, status),
      onTap: () {
        final String? id =
            row['_id']?.toString() ?? row['id']?.toString();
        if (id == null) return;
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => StoresSettlementDetailScreen(settlementId: id),
          ),
        );
      },
    );
  }

  Widget _statusChip(BuildContext context, String status) {
    final Color color = status == 'settled'
        ? AppColors.secondary
        : status == 'failed' || status == 'reversed' || status == 'disputed'
            ? AppColors.expired
            : AppColors.expirySoon;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 11),
      ),
    );
  }
}

num _num(dynamic value) => value is num ? value : 0;

int? _int(dynamic value) => value is int ? value : null;

String _money(num value) => value.toStringAsFixed(2);

String _date(dynamic value) {
  final DateTime? parsed = DateTime.tryParse('$value');
  if (parsed == null) return value == null ? '—' : '$value';
  final DateTime local = parsed.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)}';
}
