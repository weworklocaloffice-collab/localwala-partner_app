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

import 'package:partner/app/modules/stores/stores_partner_repository.dart';
import 'package:partner/app/modules/stores/widgets/stores_ui_states.dart';
import 'package:flutter/material.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

/// One settlement statement with the line items behind its net amount.
///
/// Read-only by design: the platform settles the outlet, so a partner does not press
/// "paid". The API still accepts the status routes for operators, but this screen never
/// offers them.
class StoresSettlementDetailScreen extends StatefulWidget {
  const StoresSettlementDetailScreen({super.key, required this.settlementId});

  final String settlementId;

  @override
  State<StoresSettlementDetailScreen> createState() =>
      _StoresSettlementDetailScreenState();
}

class _StoresSettlementDetailScreenState
    extends State<StoresSettlementDetailScreen> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() =>
      StoresPartnerRepository().settlement(widget.settlementId);

  void _reload() {
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.storesTitleSettlement),
        actions: <Widget>[
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: StoresAsyncView<Map<String, dynamic>>(
        future: _future,
        builder: (BuildContext context, Map<String, dynamic> body) {
          final dynamic raw = body['settlement'] ?? body;
          if (raw is! Map<String, dynamic>) {
            return const StoresEmptyView(
              message: 'Settlement not found.',
              icon: Icons.search_off_outlined,
            );
          }
          return _statement(context, raw);
        },
      ),
    );
  }

  Widget _statement(BuildContext context, Map<String, dynamic> settlement) {
    final dynamic totals = settlement['totals'];
    final Map<String, dynamic> sums = totals is Map<String, dynamic>
        ? totals
        : <String, dynamic>{};
    final dynamic rawItems = settlement['lineItems'];
    final List<Map<String, dynamic>> items = rawItems is List
        ? rawItems.whereType<Map<String, dynamic>>().toList()
        : <Map<String, dynamic>>[];

    return ListView(
      children: <Widget>[
        ListTile(
          leading: const Icon(Icons.account_balance_wallet_outlined),
          title: Text(AppLocalizations.of(context)!.storesSettlementNumber('')),
          subtitle: Text(
            '${settlement['period'] ?? 'period'} · '
            '${_date(settlement['from'])} – ${_date(settlement['to'])}',
          ),
          trailing: Text('${settlement['status'] ?? 'pending'}'),
        ),
        const StoresSectionHeader(title: 'Totals'),
        _row('Orders', '${sums['orderCount'] ?? 0}'),
        _row('Gross order value', _money(sums['grossOrderValue'])),
        _row('Refunds', _money(sums['refunds'])),
        _row('Delivery tips', _money(sums['deliveryTips'])),
        _row('Platform fees', _money(sums['platformFees'])),
        _row('Net payable', _money(sums['netAmount']), strong: true),
        if (settlement['settlementDate'] != null)
          _row('Settled on', _date(settlement['settlementDate'])),
        if (settlement['payoutMethod'] != null)
          _row('Payout method', '${settlement['payoutMethod']}'),
        if (settlement['gatewayReference'] != null)
          _row('Reference', '${settlement['gatewayReference']}'),
        if (settlement['failureReason'] != null)
          _row('Failure reason', '${settlement['failureReason']}'),
        const StoresSectionHeader(title: 'Line items'),
         if (items.isEmpty)
           Padding(
             padding: EdgeInsets.all(16),
             child: Text(AppLocalizations.of(context)!.storesMsgNoLineItems),
           )
        else
          for (final Map<String, dynamic> item in items)
            ListTile(
              dense: true,
              title: Text(AppLocalizations.of(context)!.storesOrderNumber('')),
              subtitle: Text(
                '${item['itemCount'] ?? 0} items · '
                'refund ${_money(item['refundAmount'])} · '
                'tip ${_money(item['deliveryTip'])}',
              ),
              trailing: Text(_money(item['netAmount'])),
            ),
      ],
    );
  }

  Widget _row(String label, String value, {bool strong = false}) {
    final TextStyle? style = strong
        ? const TextStyle(fontWeight: FontWeight.w600)
        : null;
    return ListTile(
      dense: true,
      title: Text(label, style: style),
      trailing: Text(value, style: style),
    );
  }
}

String _money(dynamic value) {
  if (value is num) return value.toStringAsFixed(2);
  if (value == null) return '0.00';
  return '$value';
}

String _date(dynamic value) {
  final DateTime? parsed = DateTime.tryParse('$value');
  if (parsed == null) return value == null ? '—' : '$value';
  final DateTime local = parsed.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)}';
}
