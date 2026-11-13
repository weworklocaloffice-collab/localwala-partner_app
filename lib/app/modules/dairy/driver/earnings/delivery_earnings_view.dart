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
import 'package:partner/app/core/repositories/delivery_repository.dart';
import 'package:partner/app/presentation/styles/theme.dart';
import 'package:partner/app/presentation/styles/widgets.dart';
import 'package:partner/gen/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Rider money: what this rider has earned and the cash they are carrying.
///
/// Both figures come from the rider's own token — `GET /driver/earnings` and
/// `GET /driver/cash_in_hand` resolve the `DairyDriver` server-side, so there is
/// no id on this screen that could be swapped for another rider's.
///
/// `payoutMode` decides what "earned" means: `per_can` pays on empties returned
/// (`cansIn`), `salary` reports the agreed figure, and `per_litre` reports zero
/// with `perLitreSupported: false` rather than inventing a wage from cans.
class DeliveryEarningsScreen extends StatefulWidget {
  const DeliveryEarningsScreen({super.key});

  @override
  State<DeliveryEarningsScreen> createState() => _DeliveryEarningsScreenState();
}

class _DeliveryEarningsScreenState extends State<DeliveryEarningsScreen> {
  final DeliveryRepository _repository = DeliveryRepository();

  bool _loading = true;
  bool _week = false;
  String? _error;
  Map<String, dynamic> _earnings = <String, dynamic>{};
  Map<String, dynamic> _cash = <String, dynamic>{};

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
    final DateTime from = _week
        ? now.subtract(const Duration(days: 7))
        : DateTime(now.year, now.month, now.day);

    final DioApiResponse earnings = await _repository.earnings(
      from: from.toIso8601String(),
      to: now.toIso8601String(),
    );
    // Cash in hand is a position, not a period figure: a rider carrying last
    // week's collections must still see them today.
    final DioApiResponse cash = await _repository.cashInHand();

    if (!mounted) return;

    if (earnings.errorType != NetErrorType.none ||
        cash.errorType != NetErrorType.none) {
      setState(() {
        _loading = false;
        _error = 'Could not load earnings.';
      });
      return;
    }

    final Map<String, dynamic> earningsBody = decodeBody(earnings);
    final Map<String, dynamic> cashBody = decodeBody(cash);

    setState(() {
      _loading = false;
      _earnings = Map<String, dynamic>.from(
        (earningsBody['earnings'] as Map?) ?? <String, dynamic>{},
      );
      _cash = Map<String, dynamic>.from(
        (cashBody['cashInHand'] as Map?) ?? <String, dynamic>{},
      );
    });
  }

  /// The API already sends rupees, so this only formats.
  String _rupees(Object? amount) {
    final double value = double.tryParse(amount?.toString() ?? '') ?? 0;
    return '₹${value.toStringAsFixed(0)}';
  }

  String _payoutMode(AppLocalizations l10n) {
    switch (_earnings['payoutMode']?.toString()) {
      case 'per_litre':
        return l10n.earningsPerLitre;
      case 'salary':
        return l10n.earningsSalary;
      default:
        return l10n.earningsPerCan;
    }
  }

  Future<void> _recordDeposit() async {
    final Map<String, String>? result = await showDialog<Map<String, String>>(
      context: context,
      builder: (BuildContext dialogContext) {
        final AppLocalizations l10n = AppLocalizations.of(dialogContext)!;
        String amountText = '';
        String referenceText = '';

        return AlertDialog(
          title: Text(l10n.earningsRecordDeposit),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: l10n.earningsDepositAmount,
                  prefixText: '₹',
                ),
                onChanged: (String value) => amountText = value,
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  labelText: l10n.earningsDepositReference,
                ),
                onChanged: (String value) => referenceText = value,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                final double? amount = double.tryParse(amountText.trim());
                if (amount == null || amount <= 0) return;
                Navigator.pop(dialogContext, <String, String>{
                  'amount': amountText.trim(),
                  'reference': referenceText.trim(),
                });
              },
              child: Text(l10n.save),
            ),
          ],
        );
      },
    );

    if (result == null || !mounted) return;

    final double amount = double.tryParse(result['amount'] ?? '') ?? 0;
    if (amount <= 0) return;

    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final DioApiResponse response = await _repository.depositCash(
      amount,
      reference: result['reference'],
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          response.errorType == NetErrorType.none
              ? l10n.earningsDepositSaved
              : l10n.somethingWentWrong,
        ),
      ),
    );

    if (response.errorType == NetErrorType.none) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final AppThemeData theme = appThemeData[
        Theme.of(context).brightness == Brightness.dark
            ? AppTheme.dark
            : AppTheme.light]!;

    final int cansIn = (_earnings['cansIn'] as num?)?.toInt() ?? 0;
    final int deliveredStops =
        (_earnings['deliveredStops'] as num?)?.toInt() ?? 0;
    final num rate = (_earnings['payoutRate'] as num?) ?? 0;
    final bool perLitreUnsupported =
        _earnings['payoutMode'] == 'per_litre' &&
            _earnings['perLitreSupported'] != true;

    final int cashStops = (_cash['cashStops'] as num?)?.toInt() ?? 0;
    final num collected = (_cash['collected'] as num?) ?? 0;
    final num deposited = (_cash['deposited'] as num?) ?? 0;
    final num outstanding = (_cash['outstanding'] as num?) ?? 0;

    return SectionListScreen(
      title: l10n.navEarnings,
      icon: Icons.payments_outlined,
      onRefresh: _load,
      children: <Widget>[
        const SizedBox(height: 6),
        SegmentedButton<bool>(
          segments: <ButtonSegment<bool>>[
            ButtonSegment<bool>(
              value: false,
              label: Text(l10n.earningsToday),
            ),
            ButtonSegment<bool>(
              value: true,
              label: Text(l10n.earningsThisWeek),
            ),
          ],
          selected: <bool>{_week},
          onSelectionChanged: (Set<bool> selection) {
            setState(() => _week = selection.first);
            _load();
          },
        ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          EmptyState(
            title: l10n.earningsUnavailable,
            message: _error!,
            icon: Icons.cloud_off_outlined,
          )
        else ...<Widget>[
          Card(
            child: ListTile(
              leading: Icon(Icons.savings_outlined, color: theme.primary),
              title: Text(
                _rupees(_earnings['earned']),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              subtitle: Text(
                '$deliveredStops ${l10n.earningsDeliveredStops} · '
                '$cansIn ${l10n.earningsCansMoved}',
              ),
            ),
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: MetricTile(
                  label: l10n.earningsCansMoved,
                  value: '$cansIn',
                  icon: Icons.recycling_outlined,
                  accent: AppColors.canInStore,
                ),
              ),
              Expanded(
                child: MetricTile(
                  label: l10n.earningsRate,
                  value: '${_rupees(rate)} ${_payoutMode(l10n)}',
                  icon: Icons.percent_outlined,
                  accent: theme.secondary,
                ),
              ),
            ],
          ),
          if (perLitreUnsupported)
            EmptyState(
              title: l10n.earningsPerLitreUnsupported,
              message: l10n.earningsPerLitreHint,
              icon: Icons.info_outline,
            ),
          Card(
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: Icon(Icons.account_balance_wallet_outlined,
                      color: theme.primary),
                  title: Text(l10n.earningsCashInHand),
                  subtitle: Text('$cashStops ${l10n.earningsCashStops}'),
                  trailing: Text(
                    _rupees(outstanding),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  dense: true,
                  title: Text(l10n.earningsCashCollected),
                  trailing: Text(_rupees(collected)),
                ),
                ListTile(
                  dense: true,
                  title: Text(l10n.earningsCashDeposited),
                  trailing: Text(_rupees(deposited)),
                ),
                ListTile(
                  dense: true,
                  title: Text(l10n.earningsCashOutstanding),
                  trailing: Text(_rupees(outstanding)),
                ),
              ],
            ),
          ),
          if (outstanding > 0)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: FilledButton.icon(
                onPressed: _recordDeposit,
                icon: const Icon(Icons.add_card_outlined),
                label: Text(l10n.earningsRecordDeposit),
              ),
            ),
        ],
      ],
    );
  }
}
