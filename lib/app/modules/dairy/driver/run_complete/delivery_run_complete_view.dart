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

import 'dart:convert';

import 'package:partner/app/core/config/api_request_service.dart';
import 'package:partner/app/core/repositories/delivery_repository.dart';
import 'package:partner/app/presentation/styles/theme.dart';
import 'package:partner/app/presentation/styles/widgets.dart';
import 'package:partner/gen/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Depot reconciliation.
///
/// This is the screen that makes dairy delivery accountable: a shift cannot be
/// closed while `cansLoaded` does not equal `cansIssued + cansReturned`. The
/// rider sees the imbalance first and must state a reason to override, which
/// then lands in `DairyCanLedger` as an adjustment for admin review.
///
/// The loaded/issued figures come from `GET /driver/cans/run_balance/:run`,
/// which derives them from the ledger. They are not free-text inputs: a rider
/// typing their own expected figure would defeat the check.
class DeliveryRunCompleteScreen extends StatefulWidget {
  const DeliveryRunCompleteScreen({super.key});

  @override
  State<DeliveryRunCompleteScreen> createState() => _DeliveryRunCompleteScreenState();
}

class _DeliveryRunCompleteScreenState extends State<DeliveryRunCompleteScreen> {
  final DeliveryRepository _deliveryRepository = DeliveryRepository();
  final TextEditingController _runController = TextEditingController();
  final TextEditingController _returnedController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  String _runId = '';
  int _loaded = 0;
  int _issued = 0;
  bool _busy = false;
  bool _balanceLoading = false;
  String? _balanceError;
  int _openStops = 0;
  bool _forceClose = false;

  int get _returned => int.tryParse(_returnedController.text) ?? 0;

  /// Cans the rider is expected to hand back: what he loaded minus what he
  /// actually issued to customers. This mirrors the server's gate.
  int get _expectedReturn => _loaded - _issued;

  int get _variance => _returned - _expectedReturn;

  bool get _balanced => _variance == 0;

  @override
  void initState() {
    super.initState();
    _loadToday();
  }

  @override
  void dispose() {
    _runController.dispose();
    _returnedController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadOpenStops() async {
    if (_runId.isEmpty) return;
    final DioApiResponse response = await _deliveryRepository.stops(_runId);
    if (!mounted) return;
    if (response.errorType != NetErrorType.none) return;
    final Map<String, dynamic> body = decodeBody(response);
    final List<dynamic> stops = body['stops'] is List
        ? body['stops'] as List<dynamic>
        : (body['data'] is List ? body['data'] as List<dynamic> : <dynamic>[]);
    int open = 0;
    for (final dynamic raw in stops) {
      if (raw is Map) {
        final String status = (raw['status'] ?? '').toString();
        if (status == 'pending' || status == 'arrived') open++;
      }
    }
    setState(() {
      _openStops = open;
      if (open == 0) _forceClose = false;
    });
  }

  /// Prefills today's run and its ledger-derived balance, so the rider does not
  /// have to copy a run id from the manifest. Manual entry still works for a
  /// run missed while the device was offline.
  Future<void> _loadToday() async {
    final DioApiResponse response = await _deliveryRepository.todayRun();
    if (!mounted) return;

    if (response.errorType != NetErrorType.none) {
      setState(() => _balanceError = 'Could not load the run.');
      return;
    }

    final Map<String, dynamic> body = decodeBody(response);
    final Map<String, dynamic>? run = body['run'] is Map
        ? Map<String, dynamic>.from(body['run'] as Map)
        : (body.isEmpty ? null : body);

    final Object? id = run?['_id'] ?? run?['id'];
    if (id == null) {
      setState(() => _balanceError = null);
      return;
    }

    _runId = id.toString();
    _runController.text = _runId;
    await _loadBalance();
    await _loadOpenStops();
  }

  Future<void> _loadBalance() async {
    if (_runId.isEmpty) return;

    setState(() {
      _balanceLoading = true;
      _balanceError = null;
    });

    final DioApiResponse response = await _deliveryRepository.runBalance(_runId);
    if (!mounted) return;

    if (response.errorType != NetErrorType.none) {
      setState(() {
        _balanceLoading = false;
        _balanceError = 'Could not load the run\'s can balance.';
      });
      return;
    }

    final Map<String, dynamic> body = decodeBody(response);
    final Map<String, dynamic> balance = Map<String, dynamic>.from(
      (body['balance'] as Map?) ?? <String, dynamic>{},
    );

    setState(() {
      _balanceLoading = false;
      _loaded = (balance['cansLoaded'] as num?)?.toInt() ??
          (balance['pickup'] as num?)?.toInt() ??
          0;
      _issued = (balance['issue'] as num?)?.toInt() ?? 0;
    });
  }

  /// The API's 409 carries the figures ("Expected 8 back, received 6"). Showing
  /// that is more useful than a generic failure.
  String _serverMessage(DioApiResponse response, AppLocalizations l10n) {
    final dynamic raw = response.response?.data;
    if (raw is String && raw.isNotEmpty) {
      try {
        final dynamic decoded = jsonDecode(raw);
        if (decoded is Map && decoded['message'] is String) {
          return decoded['message'] as String;
        }
      } on FormatException {
        // Fall through to the generic message.
      }
    }
    return l10n.couldNotCompleteRun;
  }

  Future<void> _complete() async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    if (_runId.isEmpty) {
      _snack(l10n.runIdRequired);
      return;
    }
    if (!_balanced && _reasonController.text.trim().isEmpty) {
      _snack(l10n.adjustmentReasonRequired);
      return;
    }
    setState(() => _busy = true);

    final DioApiResponse response = await _deliveryRepository.completeRun(
      runId: _runId,
      cansReturned: _returned,
      adjustmentReason: _reasonController.text.trim().isEmpty
          ? null
          : _reasonController.text.trim(),
      forceClose: _forceClose,
    );

    if (!mounted) return;
    setState(() => _busy = false);

    _snack(response.errorType == NetErrorType.none
        ? l10n.runCompleted
        : _serverMessage(response, l10n));
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final AppThemeData theme = appThemeData[
        Theme.of(context).brightness == Brightness.dark
            ? AppTheme.dark
            : AppTheme.light]!;

    final Color varianceColor =
        _balanced ? AppColors.canInStore : AppColors.expired;
    final String varianceLabel = _balanced
        ? l10n.reconciliationBalanced
        : (_variance < 0 ? l10n.reconciliationShort : l10n.reconciliationOver);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.depotReconciliation),
        leading: Icon(Icons.fact_check_outlined, color: theme.primary),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          if (_balanceLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_balanceError != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.cloud_off_outlined),
                title: Text(l10n.runBalanceUnavailable),
                subtitle: Text(_balanceError!),
              ),
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            varianceLabel,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        StatusChip(
                          label: _variance == 0 ? '0' : '$_variance',
                          color: varianceColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _row(context, l10n.cansToDeliver, '$_loaded'),
                    _row(context, l10n.issuedToCustomers, '$_issued'),
                    _row(context, l10n.expectedReturn, '$_expectedReturn'),
                    _row(context, l10n.actualReturn, '$_returned'),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          TextField(
            controller: _runController,
            decoration: InputDecoration(
              labelText: l10n.runId,
              suffixIcon: IconButton(
                tooltip: l10n.retry,
                icon: const Icon(Icons.refresh),
                onPressed: _runId.isEmpty
                    ? null
                    : () {
                        _loadBalance();
                        _loadOpenStops();
                      },
              ),
            ),
            onChanged: (String value) => _runId = value.trim(),
            onSubmitted: (String value) {
              _runId = value.trim();
              _loadBalance();
              _loadOpenStops();
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _returnedController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.cansReturned,
              suffixText: '/$_expectedReturn',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reasonController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: l10n.adjustmentReason,
              hintText: l10n.adjustmentReasonHint,
            ),
          ),
          if (_openStops > 0) ...<Widget>[
            const SizedBox(height: 12),
            CheckboxListTile(
              value: _forceClose,
              onChanged: (bool? value) =>
                  setState(() => _forceClose = value ?? false),
              title: Text('Force close with $_openStops open stop(s)'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _busy ? null : _complete,
            icon: const Icon(Icons.lock_clock_outlined),
            label: Text(l10n.completeRun),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
