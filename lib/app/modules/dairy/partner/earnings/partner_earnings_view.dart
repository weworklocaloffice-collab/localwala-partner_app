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

import 'dart:convert';
import 'dart:typed_data';

import 'package:partner/app/core/config/api_request_service.dart';
import 'package:partner/app/core/repositories/partner_repository.dart';
import 'package:partner/app/presentation/styles/theme.dart';
import 'package:partner/app/presentation/styles/widgets.dart';
import 'package:partner/gen/l10n/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

/// Outlet money: gross sales, platform commission, what the outlet keeps, and
/// the settlements closed against it.
///
/// Backed by `GET /partner/earnings` for the live figures and
/// `GET /partner/settlements` for the statements.
///
/// The earnings figure is a *preview* computed from delivered, paid orders, so it
/// moves before any settlement exists. The statements below it are what has
/// actually been closed and paid. Both read the outlet from the token.
class PartnerEarningsScreen extends StatefulWidget {
  const PartnerEarningsScreen({super.key});

  @override
  State<PartnerEarningsScreen> createState() => _PartnerEarningsScreenState();
}

class _PartnerEarningsScreenState extends State<PartnerEarningsScreen> {
  final PartnerRepository _partnerRepository = PartnerRepository();

  bool _loading = true;
  String? _error;
  String? _settlementsError;
  Map<String, dynamic> _earnings = <String, dynamic>{};
  List<dynamic> _settlements = const <dynamic>[];
  DateTimeRange? _range;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _settlementsError = null;
    });

    final DateTime? from = _range?.start;
    final DateTime? to = _range?.end.add(const Duration(days: 1));
    final DioApiResponse earnings = await _partnerRepository.earnings(
      from: from?.toUtc().toIso8601String(),
      to: to?.toUtc().toIso8601String(),
    );
    final DioApiResponse settlements = await _partnerRepository.settlements(limit: 100);

    if (!mounted) return;

    if (earnings.errorType != NetErrorType.none) {
      setState(() {
        _loading = false;
        _error = AppLocalizations.of(context)!.couldNotLoadEarnings;
      });
      return;
    }

    final Map<String, dynamic> earningsBody = decodeBody(earnings);
    final bool settlementsFailed = settlements.errorType != NetErrorType.none;
    final Map<String, dynamic> settlementsBody = settlementsFailed
        ? <String, dynamic>{}
        : decodeBody(settlements);

    setState(() {
      _loading = false;
      _earnings = Map<String, dynamic>.from(
        (earningsBody['earnings'] as Map?) ?? <String, dynamic>{},
      );
      _settlements = (settlementsBody['settlements'] as List?)
          ?? const <dynamic>[];
      _settlementsError = settlementsFailed
          ? 'Settlement statements could not be loaded. Retry to reconcile payouts.'
          : null;
    });
  }

  /// The API already sends rupees, so this only formats.
  String _rupees(Object? amount) {
    final double value = double.tryParse(amount?.toString() ?? '') ?? 0;
    return '₹${value.toStringAsFixed(2)}';
  }

  String _id(Map<String, dynamic> value) => (value['_id'] ?? value['id'] ?? '').toString();

  Future<void> _chooseRange() async {
    final DateTime now = DateTime.now();
    final DateTimeRange? range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: _range,
      helpText: 'Filter delivered order earnings',
    );
    if (range == null || !mounted) return;
    setState(() => _range = range);
    await _load();
  }

  String _csvCell(Object? value) {
    final String text = value?.toString() ?? '';
    return '"${text.replaceAll('"', '""')}"';
  }

  Future<void> _exportStatements() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final DioApiResponse listResponse = await _partnerRepository.settlements(page: 1, limit: 100);
      if (listResponse.errorType != NetErrorType.none) throw StateError('Settlement statements could not be loaded.');
      final List<dynamic> rows = decodeBody(listResponse)['settlements'] as List? ?? const <dynamic>[];
      final List<List<Object?>> csvRows = <List<Object?>>[
        <Object?>['Settlement', 'Type', 'Period from', 'Period to', 'Status', 'Payout method', 'Gross sales', 'Discounts', 'Net sales', 'Delivery charges', 'Taxes', 'Commission', 'Payout', 'Payout reference', 'Order', 'Order gross', 'Order discount', 'Order net', 'Order delivery', 'Order tax', 'Customer paid', 'Coupon'],
      ];
      for (final dynamic raw in rows) {
        if (raw is! Map) continue;
        final Map<String, dynamic> summary = Map<String, dynamic>.from(raw);
        final String id = _id(summary);
        if (id.isEmpty) continue;
        final DioApiResponse detailResponse = await _partnerRepository.settlementDetail(id);
        if (detailResponse.errorType != NetErrorType.none) throw StateError('A settlement detail could not be loaded. Retry the export.');
        final Map<String, dynamic> detail = Map<String, dynamic>.from((decodeBody(detailResponse)['settlement'] as Map?) ?? summary);
        final Map<String, dynamic> totals = Map<String, dynamic>.from((detail['totals'] as Map?) ?? <String, dynamic>{});
        final List<dynamic> items = detail['lineItems'] as List? ?? const <dynamic>[];
        final List<dynamic> exportItems = items.isEmpty ? <dynamic>[<String, dynamic>{}] : items;
        for (final dynamic rawItem in exportItems) {
          final Map<String, dynamic> item = rawItem is Map ? Map<String, dynamic>.from(rawItem) : <String, dynamic>{};
          csvRows.add(<Object?>[
            detail['settlementNo'], detail['settlementType'], detail['from'], detail['to'], detail['status'], detail['payoutMethod'],
            totals['grossSales'], totals['discounts'], totals['netSales'], totals['deliveryCharges'], totals['taxes'], totals['commissionAmount'], totals['netAmount'], detail['payoutReference'],
            item['orderNo'], item['grossSales'], item['discounts'], item['netSales'], item['deliveryCharges'], item['taxes'], item['customerPaid'], item['couponCode'],
          ]);
        }
      }
      final String csv = csvRows.map((List<Object?> row) => row.map(_csvCell).join(',')).join('\r\n');
      final String? path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Dairy settlement statements',
        fileName: 'dairy-settlements-${DateTime.now().toIso8601String().substring(0, 10)}.csv',
        type: FileType.custom,
        allowedExtensions: const <String>['csv'],
        bytes: Uint8List.fromList(utf8.encode(csv)),
      );
      if (!mounted) return;
      if (path != null) _message('Settlement CSV saved.');
    } catch (error) {
      if (mounted) _message(error.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _openSettlement(Map<String, dynamic> summary) async {
    final String id = _id(summary);
    if (id.isEmpty) return;
    final DioApiResponse response = await _partnerRepository.settlementDetail(id);
    if (!mounted) return;
    if (response.errorType != NetErrorType.none) {
      _message('Settlement detail could not be loaded.');
      return;
    }
    final Map<String, dynamic> detail = Map<String, dynamic>.from((decodeBody(response)['settlement'] as Map?) ?? summary);
    final Map<String, dynamic> totals = Map<String, dynamic>.from((detail['totals'] as Map?) ?? <String, dynamic>{});
    final List<dynamic> lineItems = detail['lineItems'] as List? ?? const <dynamic>[];
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => SafeArea(child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        builder: (BuildContext context, ScrollController controller) => ListView(controller: controller, padding: const EdgeInsets.all(16), children: <Widget>[
          Text('Settlement #${detail['settlementNo']}', style: Theme.of(context).textTheme.titleLarge),
          Text('${_period(detail)} · ${detail['status'] ?? ''}'),
          const Divider(height: 24),
          for (final String key in <String>['grossSales', 'discounts', 'netSales', 'deliveryCharges', 'taxes', 'commissionAmount', 'netAmount'])
            ListTile(dense: true, title: Text(key.replaceAll(RegExp(r'([A-Z])'), r' $1').trim()), trailing: Text(_rupees(totals[key]))),
          const Divider(height: 24),
          Text('Included orders (${lineItems.length})', style: Theme.of(context).textTheme.titleMedium),
          ...lineItems.map((dynamic raw) {
            final Map<String, dynamic> line = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
            return ListTile(dense: true, title: Text('Order #${line['orderNo'] ?? '—'}${(line['couponCode'] ?? '').toString().isEmpty ? '' : ' · ${line['couponCode']}'}'), subtitle: Text('Gross ${_rupees(line['grossSales'])} · Discount ${_rupees(line['discounts'])} · Net ${_rupees(line['netSales'])} · Paid ${_rupees(line['customerPaid'])}'));
          }),
        ]),
      )),
    );
  }

  void _message(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  String _period(Map<String, dynamic> settlement) {
    final String from = settlement['from']?.toString() ?? '';
    final String to = settlement['to']?.toString() ?? '';
    final DateTime? start = DateTime.tryParse(from);
    final DateTime? end = DateTime.tryParse(to);
    if (start == null || end == null) return '';
    String month(int value) => value.toString().padLeft(2, '0');
    return '${start.day}/${month(start.month)}/${start.year}'
        ' – ${end.day}/${month(end.month)}/${end.year}';
  }

  String _settlementLabel(String status, AppLocalizations l10n) {
    switch (status) {
      case 'paid':
        return l10n.settlementStatusPaid;
      case 'approved':
        return l10n.settlementStatusApproved;
      case 'submitted':
        return l10n.settlementStatusSubmitted;
      case 'void':
        return l10n.settlementStatusVoid;
      case 'disputed':
        return l10n.settlementStatusDisputed;
      default:
        return status.isEmpty ? l10n.unknownStatus : status;
    }
  }

  Color _statusColour(String status) {
    switch (status) {
      case 'paid':
        return AppColors.canInStore;
      case 'approved':
      case 'submitted':
        return AppColors.expirySoon;
      case 'void':
      case 'disputed':
        return AppColors.expired;
      default:
        return AppColors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final AppThemeData theme =
        appThemeData[Theme.of(context).brightness == Brightness.dark
            ? AppTheme.dark
            : AppTheme.light]!;

    final num orderCount = (_earnings['orderCount'] as num?) ?? 0;
    // An outlet with no signed agreement has no commission to deduct. Showing a
    // zero commission without saying why would read as "the platform is charging
    // nothing", which is a different claim.
    final bool hasAgreement = _earnings['hasAgreement'] == true;
    final num rate = (_earnings['ratePercentage'] as num?) ?? 0;

    return SectionListScreen(
      title: l10n.navEarnings,
      icon: Icons.account_balance_wallet_outlined,
      onRefresh: _load,
      children: <Widget>[
        Wrap(spacing: 8, runSpacing: 8, children: <Widget>[
          OutlinedButton.icon(
            onPressed: _loading ? null : _chooseRange,
            icon: const Icon(Icons.date_range_outlined),
            label: Text(_range == null
                ? 'All delivered orders'
                : '${_range!.start.day}/${_range!.start.month}/${_range!.start.year} – ${_range!.end.day}/${_range!.end.month}/${_range!.end.year}'),
          ),
          if (_range != null)
            TextButton(
              onPressed: _loading ? null : () { setState(() => _range = null); _load(); },
              child: const Text('Clear filter'),
            ),
        ]),
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
            child: Column(children: <Widget>[
              ListTile(
                leading: Icon(Icons.savings_outlined, color: theme.primary),
                title: Text(_rupees(_earnings['grossSales'])),
                subtitle: Text('Gross product sales · ${l10n.livePreSettlementSummary(orderCount.toInt())}'),
              ),
              const Divider(height: 1),
              ListTile(dense: true, title: Text('Customer coupons and discounts (${_earnings['couponOrderCount'] ?? 0} orders)'), trailing: Text('−${_rupees(_earnings['discounts'])}')),
              ListTile(dense: true, title: const Text('Product sales after discounts'), trailing: Text(_rupees(_earnings['netSales'])), subtitle: const Text('Before platform commission and tax reconciliation')),
              ListTile(dense: true, title: const Text('Delivery charges'), trailing: Text(_rupees(_earnings['deliveryCharges']))),
              ListTile(dense: true, title: const Text('Taxes collected'), trailing: Text(_rupees(_earnings['taxes']))),
            ]),
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: MetricTile(
                  label: l10n.commissions,
                  value: _rupees(_earnings['commissionAmount']),
                  icon: Icons.percent_outlined,
                  accent: AppColors.expirySoon,
                ),
              ),
              Expanded(
                child: MetricTile(
                  label: l10n.youKeep,
                  value: _rupees(_earnings['netEarnings']),
                  icon: Icons.account_balance_wallet_outlined,
                  accent: theme.secondary,
                ),
              ),
            ],
          ),
          if (!hasAgreement)
            EmptyState(
              title: l10n.noPartnerAgreement,
              message: l10n.noPartnerAgreementHint,
              icon: Icons.assignment_outlined,
            )
          else
            Card(
              child: ListTile(
                leading: Icon(Icons.percent_outlined, color: theme.primary),
                title: Text(l10n.commissionRate('$rate')),
                subtitle: Text(
                  _earnings['commissionBasis'] == 'product_and_delivery'
                      ? l10n.commissionOnProductAndDelivery
                      : l10n.commissionOnProductOnly,
                ),
              ),
            ),
          if (_settlementsError != null)
            Card(
              child: ListTile(
                title: const Text('Settlement statements unavailable'),
                subtitle: Text(_settlementsError!),
                trailing: TextButton(
                  onPressed: _loading ? null : _load,
                  child: const Text('Retry'),
                ),
              ),
            ),
          if (_settlementsError == null && _settlements.isNotEmpty)
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ListTile(
                    title: Text(l10n.settlements),
                    subtitle: Text(l10n.closedStatements),
                    trailing: IconButton(
                      tooltip: 'Export settlement CSV',
                      onPressed: _exporting ? null : _exportStatements,
                      icon: _exporting
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.download_outlined),
                    ),
                  ),
                  ..._settlements.map((dynamic raw) {
                    final Map<String, dynamic> settlement =
                        Map<String, dynamic>.from(raw as Map);
                    final Map<String, dynamic> totals = Map<String, dynamic>.from(
                      (settlement['totals'] as Map?) ?? <String, dynamic>{},
                    );
                    final String status =
                        settlement['status']?.toString() ?? '';
                    return ListTile(
                      dense: true,
                      onTap: () => _openSettlement(settlement),
                      title: Text(
                        '#${settlement['settlementNo'] ?? '—'} · ${_period(settlement)}',
                      ),
                      subtitle: Text('Payout ${_rupees(totals['netAmount'])} · discounts ${_rupees(totals['discounts'])}'),
                      trailing: StatusChip(
                        label: _settlementLabel(status, l10n),
                        color: _statusColour(status),
                      ),
                    );
                  }),
                ],
              ),
            ),
          if (_settlementsError == null && _settlements.isEmpty)
            EmptyState(
              title: l10n.nothingSettledYet,
              message: l10n.nothingSettledYetHint,
              icon: Icons.receipt_long_outlined,
            ),
        ],
      ],
    );
  }
}
