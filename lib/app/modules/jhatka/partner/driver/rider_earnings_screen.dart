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
import 'package:partner/app/modules/jhatka/partner/driver/jhatka_rider_repository.dart';
import 'package:partner/app/modules/jhatka/partner/weighing/jhatka_money.dart'
    as jhatka_money;
import 'package:partner/app/presentation/styles/widgets.dart';
import 'package:flutter/material.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

/// The rider's own settlement history.
///
/// Read-only: settlements are written by the payout flow, and a rider
/// questioning one talks to the outlet, not to an edit screen.
class RiderEarningsScreen extends StatefulWidget {
  const RiderEarningsScreen({super.key});

  @override
  State<RiderEarningsScreen> createState() => _RiderEarningsScreenState();
}

class _RiderEarningsScreenState extends State<RiderEarningsScreen> {
  final JhatkaRiderRepository _repository = JhatkaRiderRepository();

  bool _loading = true;
  String? _error;
  List<dynamic> _settlements = const <dynamic>[];

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
    final DioApiResponse response = await _repository.earnings();
    if (!mounted) return;
    if (response.errorType != NetErrorType.none) {
      setState(() {
        _loading = false;
        _error = 'Could not load earnings.';
      });
      return;
    }
    final Map<String, dynamic> body = decodeBody(response);
    setState(() {
      _loading = false;
      _settlements = (body['settlements'] as List?) ?? const <dynamic>[];
    });
  }

  @override
  Widget build(BuildContext context) {
    return SectionListScreen(
      title: AppLocalizations.of(context)!.navEarnings,
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
            title: AppLocalizations.of(context)!.jhatkaEarningsUnavailable,
            message: _error!,
            icon: Icons.cloud_off_outlined,
          )
        else if (_settlements.isEmpty)
          EmptyState(
            title: AppLocalizations.of(context)!.realEstateExecSettlementsEmpty,
            message: 'Completed payout periods appear here.',
            icon: Icons.payments_outlined,
          )
        else
          Card(
            child: Column(
              children: _settlements.map((dynamic raw) {
                final Map<String, dynamic> settlement =
                    Map<String, dynamic>.from(raw as Map);
                final Map<String, dynamic>? totals =
                    (settlement['totals'] as Map?)?.cast<String, dynamic>();
                final Map<String, dynamic>? period =
                    (settlement['period'] as Map?)?.cast<String, dynamic>();
                // Lean read: raw PAISE via moneyField-less totals. formatPaise,
                // not formatRupees â€” the one boundary that matters on this screen.
                final num net =
                    (totals?['netAmount'] ?? totals?['amountPaid'] ?? 0) as num;
                return ListTile(
                  title: Text(
                    'Settlement ${(settlement['settlementNo'] ?? 'â€”').toString()}',
                  ),
                  subtitle: Text(
                    '${jhatka_money.formatPaise(net)} Â· '
                    '${(settlement['status'] ?? '').toString()}'
                    '${period != null ? '\n${period['label'] ?? ''}' : ''}'
                    '${settlement['paidAt'] != null ? '\nPaid ${settlement['paidAt']}' : ''}',
                  ),
                  isThreeLine: true,
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Text(
                        '${totals?['deliveryCount'] ?? totals?['successfulCount'] ?? 0} deliveries',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (((totals?['failedCount'] as num?) ?? 0) > 0)
                        Text(
                          '${totals!['failedCount']} failed',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.redAccent),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
