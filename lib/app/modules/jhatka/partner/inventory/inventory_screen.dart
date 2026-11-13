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
import 'package:partner/app/modules/jhatka/partner/inventory/jhatka_inventory_repository.dart';
import 'package:partner/app/modules/jhatka/partner/inventory/stock_detail_screen.dart';
import 'package:partner/app/modules/jhatka/partner/stock/adjust_wastage_screen.dart';
import 'package:partner/app/presentation/styles/theme.dart';
import 'package:partner/app/presentation/styles/widgets.dart';
import 'package:flutter/material.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

/// Stock rows and batches for the outlet.
///
/// Two tabs: stock (with a low-stock filter — the dashboard's tile reads the
/// same flag) and batches (with quarantine / release, each requiring a written
/// reason). Expired rows report zero available regardless of on-hand: the
/// stock physically exists but cannot be sold.
///
/// Recalls sit below batches: a quarantined batch that must not sell gets a
/// recall, and the recall — not a phone call — is what finds the customers who
/// ate from it.
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final JhatkaInventoryRepository _repository = JhatkaInventoryRepository();

  bool _loading = true;
  String? _error;
  bool _lowStockOnly = false;
  List<dynamic> _items = const <dynamic>[];
  List<dynamic> _batches = const <dynamic>[];
  List<dynamic> _recalls = const <dynamic>[];
  String? _actingOn;

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
    final List<DioApiResponse> results =
        await Future.wait(<Future<DioApiResponse>>[
          _repository.stock(lowStockOnly: _lowStockOnly),
          _repository.batches(),
          _repository.recalls(),
        ]);
    if (!mounted) return;
    if (results.any((DioApiResponse r) => r.errorType != NetErrorType.none)) {
      setState(() {
        _loading = false;
        _error = 'Could not load inventory.';
      });
      return;
    }
    final Map<String, dynamic> stock = decodeBody(results[0]);
    final Map<String, dynamic> batchBody = decodeBody(results[1]);
    final Map<String, dynamic> recallBody = decodeBody(results[2]);
    setState(() {
      _loading = false;
      _items = (stock['inventory'] as List?) ?? const <dynamic>[];
      _batches = (batchBody['batches'] as List?) ?? const <dynamic>[];
      _recalls = (recallBody['recalls'] as List?) ?? const <dynamic>[];
    });
  }

  Future<void> _reasonSheet({
    required String title,
    required Future<DioApiResponse> Function(String reason) call,
    required String batchId,
  }) async {
    final TextEditingController reason = TextEditingController();
    final bool? go = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reason,
                autofocus: true,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(
                    context,
                  )!.storesFieldReasonRequired,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    AppLocalizations.of(context)!.realEstateDetailConfirm,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
    final String text = reason.text.trim();
    reason.dispose();
    if (go != true || text.isEmpty || !mounted) return;
    setState(() => _actingOn = batchId);
    final DioApiResponse response = await call(text);
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
      title: AppLocalizations.of(context)!.navInventory,
      icon: Icons.inventory_2_outlined,
      onRefresh: _load,
      children: <Widget>[
        SwitchListTile(
          title: Text(AppLocalizations.of(context)!.jhatkaLowStockOnly),
          value: _lowStockOnly,
          onChanged: (bool v) {
            setState(() => _lowStockOnly = v);
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
            title: AppLocalizations.of(context)!.jhatkaInventoryUnavailable,
            message: _error!,
            icon: Icons.cloud_off_outlined,
          )
        else ...<Widget>[
          _sectionTitle('Stock (${_items.length})'),
          ..._items.map(_stockTile),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: () async {
                final bool? recorded = await Navigator.of(context).push<bool>(
                  MaterialPageRoute<bool>(
                    builder: (_) => AdjustWastageScreen(
                      items: _items
                          .map((dynamic raw) {
                            final Map<String, dynamic> item =
                                Map<String, dynamic>.from(raw as Map);
                            final Map<String, dynamic> variant =
                                Map<String, dynamic>.from(
                                  (item['variant'] ?? {}) as Map,
                                );
                            return <String, String>{
                              'id': (item['id'] ?? item['_id'] ?? '')
                                  .toString(),
                              'label':
                                  ((variant['name'] ??
                                          variant['sku'] ??
                                          item['kind'] ??
                                          '')
                                      .toString()),
                              'unit': (item['unit'] ?? 'GRAM').toString(),
                            };
                          })
                          .where(
                            (Map<String, String> item) =>
                                item['id']!.isNotEmpty,
                          )
                          .toList(),
                    ),
                  ),
                );
                if (recorded == true && mounted) await _load();
              },
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  AppLocalizations.of(context)!.jhatkaActionRecordAdjustWastage,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _sectionTitle('Batches (${_batches.length})'),
          ..._batches.map(_batchTile),
          const SizedBox(height: 12),
          _sectionTitle('Recalls (${_recalls.length})'),
          ..._recalls.map(_recallTile),
          if (_recalls.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No open recalls. Open one from a quarantined batch below — '
                'a recall finds the customers who ate from it.',
              ),
            ),
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

  Widget _stockTile(dynamic raw) {
    final Map<String, dynamic> item = Map<String, dynamic>.from(raw as Map);
    final bool expired = item['expired'] == true;
    final String variant =
        ((item['variant'] ?? {}) as Map)['name']?.toString() ??
        ((item['variant'] ?? {}) as Map)['sku']?.toString() ??
        (item['kind'] ?? '').toString();
    return Card(
      child: ListTile(
        title: Text(variant.isEmpty ? 'Stock line' : variant),
        subtitle: Text(
          'On hand ${item['onHand'] ?? 0} ${item['unit'] ?? ''} · '
          'available ${item['availableQty'] ?? 0}',
        ),
        trailing: expired
            ? StatusChip(
                label: AppLocalizations.of(context)!.jhatkaStatusExpired,
                color: AppColors.expired,
              )
            : ((item['availableQty'] as num?) ?? 1) <= 0
            ? StatusChip(
                label: AppLocalizations.of(context)!.jhatkaStatusLow,
                color: AppColors.expirySoon,
              )
            : const Icon(Icons.chevron_right),
        // Tap for the line's ledger: every movement in sequence. The list row
        // carries balances; only the detail carries how they got there.
        onTap: () {
          final String id = (item['id'] ?? item['_id'] ?? '').toString();
          if (id.isEmpty) return;
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => StockDetailScreen(itemId: id),
            ),
          );
        },
      ),
    );
  }

  Widget _batchTile(dynamic raw) {
    final Map<String, dynamic> batch = Map<String, dynamic>.from(raw as Map);
    final String id = (batch['id'] ?? batch['_id'] ?? '').toString();
    final String status = (batch['status'] ?? '').toString();
    final bool busy = _actingOn == id;
    final bool quarantined = status == 'quarantined';
    return Card(
      child: ListTile(
        title: Text('Batch ${batch['batchNo'] ?? '—'}'),
        subtitle: Text(
          '${batch['rawSku'] ?? ''} · ${batch['availableQty'] ?? 0} available · $status',
        ),
        trailing: busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : quarantined
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextButton(
                    onPressed: () => _reasonSheet(
                      title: AppLocalizations.of(
                        context,
                      )!.jhatkaActionReleaseBatch,
                      batchId: id,
                      call: (String reason) =>
                          _repository.releaseBatch(batchId: id, reason: reason),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.jhatkaActionRelease,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _recallSheet(batchId: id),
                    child: const Text(
                      'Recall',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ],
              )
            : TextButton(
                onPressed: () => _reasonSheet(
                  title: AppLocalizations.of(
                    context,
                  )!.jhatkaActionQuarantineBatch,
                  batchId: id,
                  call: (String reason) =>
                      _repository.quarantineBatch(batchId: id, reason: reason),
                ),
                child: Text(
                  AppLocalizations.of(context)!.jhatkaActionQuarantine,
                ),
              ),
      ),
    );
  }

  /// Open a recall against a quarantined batch.
  ///
  /// Severity decides whether customers are notified — advisory stays in-house,
  /// withdraw pulls it from sale, recall tells the customers who ate from it.
  /// The sheet states this plainly because picking "advisory" to avoid the
  /// notifications is the failure this screen exists to prevent.
  Future<void> _recallSheet({required String batchId}) async {
    final TextEditingController reason = TextEditingController();
    String severity = 'withdraw';
    final bool? go = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Text(
                    'Open a recall',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Finds every order cut from it. Withdraw and recall freeze '
                    'the batch; "recall" also notifies the customers; '
                    '"advisory" stays in-house.',
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: severity,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(
                        context,
                      )!.jhatkaFieldSeverity,
                      border: OutlineInputBorder(),
                    ),
                    items: <DropdownMenuItem<String>>[
                      DropdownMenuItem(
                        value: 'advisory',
                        child: Text(
                          AppLocalizations.of(context)!.jhatkaSeverityAdvisory,
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'withdraw',
                        child: Text(
                          AppLocalizations.of(context)!.jhatkaSeverityWithdraw,
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'recall',
                        child: Text(
                          AppLocalizations.of(
                            context,
                          )!.jhatkaActionRecallNotify,
                        ),
                      ),
                    ],
                    onChanged: (String? v) {
                      if (v != null) setSheetState(() => severity = v);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: reason,
                    autofocus: true,
                    minLines: 2,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(
                        context,
                      )!.jhatkaFieldReasonOutlet,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Text(
                        AppLocalizations.of(context)!.jhatkaActionOpenRecall,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    final String text = reason.text.trim();
    reason.dispose();
    if (go != true || text.isEmpty || !mounted) return;
    setState(() => _actingOn = batchId);
    final DioApiResponse response = await _repository.openRecall(
      batchId: batchId,
      reason: text,
      severity: severity,
    );
    if (!mounted) return;
    setState(() => _actingOn = null);
    if (response.errorType == NetErrorType.none) {
      await _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.jhatkaRecallOpenFailed),
        ),
      );
    }
  }

  Widget _recallTile(dynamic raw) {
    final Map<String, dynamic> recall = Map<String, dynamic>.from(raw as Map);
    final String id = (recall['id'] ?? recall['_id'] ?? '').toString();
    final String status = (recall['status'] ?? '').toString();
    final bool busy = _actingOn == id;
    final bool open = status == 'open' || status == 'notifying';
    return Card(
      child: ListTile(
        title: Text('Recall ${recall['recallNo'] ?? '—'}'),
        subtitle: Text(
          '${recall['severity'] ?? ''} · ${recall['reason'] ?? ''}\n'
          'Notified ${recall['notifiedCount'] ?? 0} · status $status',
        ),
        isThreeLine: true,
        trailing: busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : open
            ? TextButton(
                onPressed: () async {
                  setState(() => _actingOn = id);
                  final DioApiResponse response = await _repository.closeRecall(
                    recallId: id,
                  );
                  if (!mounted) return;
                  setState(() => _actingOn = null);
                  if (response.errorType == NetErrorType.none) {
                    await _load();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!.jhatkaCloseFailed,
                        ),
                      ),
                    );
                  }
                },
                child: Text(AppLocalizations.of(context)!.storesActionClose),
              )
            : null,
      ),
    );
  }
}
