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

import 'package:flutter/material.dart';

import 'package:partner/app/core/config/api_request_service.dart';
import 'package:partner/app/modules/jhatka/partner/money/jhatka_money_repository.dart';
import 'package:partner/app/modules/jhatka/partner/weighing/jhatka_money.dart'
    as jhatka_money;

/// One payout: lines, rule snapshot, status.
///
/// The list carries totals; only the detail carries what produced them — which
/// orders, what rule, what was deducted. An owner disputing a payout needs this
/// screen, not the list row.
class PayoutDetailScreen extends StatefulWidget {
  const PayoutDetailScreen({super.key, required this.payoutId});

  final String payoutId;

  @override
  State<PayoutDetailScreen> createState() => _PayoutDetailScreenState();
}

class _PayoutDetailScreenState extends State<PayoutDetailScreen> {
  final JhatkaMoneyRepository _repository = JhatkaMoneyRepository();

  bool _loading = true;
  String? _error;
  Map<String, dynamic> _payout = <String, dynamic>{};

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
    final DioApiResponse response = await _repository.payoutDetail(
      widget.payoutId,
    );
    if (!mounted) return;
    if (response.errorType != NetErrorType.none) {
      setState(() {
        _loading = false;
        _error = 'Could not load the payout.';
      });
      return;
    }
    final Map<String, dynamic> body = decodeBody(response);
    setState(() {
      _loading = false;
      _payout = Map<String, dynamic>.from((body['payout'] ?? {}) as Map);
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> lines =
        (_payout['lines'] as List?) ?? const <dynamic>[];
    final Map<String, dynamic>? rule = (_payout['ruleSnapshot'] as Map?)
        ?.cast<String, dynamic>();
    return Scaffold(
      appBar: AppBar(title: Text('Payout ${_payout['payoutNo'] ?? ''}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: <Widget>[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Status: ${_payout['status'] ?? '—'}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          // Detail read is hydrated: RUPEES via getters.
                          Text(
                            'Net: ${jhatka_money.formatRupees((_payout['netAmount'] ?? 0) as num)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (rule != null) ...<Widget>[
                            const SizedBox(height: 8),
                            Text(
                              'Rule: ${rule['name'] ?? rule['code'] ?? '—'} '
                              '(${rule['ratePercent'] ?? rule['rate'] ?? '?'}%)',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const Text(
                              'Frozen at payout time — a rule change never '
                              'restates history.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Lines (${lines.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ...lines.map((dynamic raw) {
                    final Map<String, dynamic> line = Map<String, dynamic>.from(
                      raw as Map,
                    );
                    return Card(
                      child: ListTile(
                        title: Text(
                          'Order ${line['orderNo'] ?? line['order'] ?? '—'}',
                        ),
                        subtitle: Text(
                          'Gross ${jhatka_money.formatRupees((line['grossOrderValue'] ?? 0) as num)} · '
                          'Commission ${jhatka_money.formatRupees((line['commissionEarned'] ?? 0) as num)}',
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}
