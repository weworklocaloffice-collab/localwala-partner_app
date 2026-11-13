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
import 'package:partner/app/modules/jhatka/partner/subscriptions/jhatka_subscriptions_repository.dart';
import 'package:partner/app/presentation/styles/widgets.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

/// One subscription: status, upcoming occurrences with billing state, event trail.
///
/// ## Why billing state is the point of this screen
///
/// The list shows status and failure counts. What the outlet needs when a customer
/// calls — "I paid, where is my delivery?" — is per-occurrence truth: billed or
/// not, paid or not, skipped or not. That lives here, and the two recovery actions
/// live next to it:
///
///   Retry billing — mints a FRESH initiation for a prepaid charge that never
///     arrived. It does not mark anything paid; only a gateway callback does.
///     The screen says "charge restarted", never "paid".
///   Generate — manually raises an occurrence for a date. Idempotent per
///     subscription+date: a retry replays, never duplicates.
class SubscriptionDetailScreen extends StatefulWidget {
  const SubscriptionDetailScreen({super.key, required this.subscriptionId});

  final String subscriptionId;

  @override
  State<SubscriptionDetailScreen> createState() =>
      _SubscriptionDetailScreenState();
}

class _SubscriptionDetailScreenState extends State<SubscriptionDetailScreen> {
  final JhatkaSubscriptionsRepository _repository =
      JhatkaSubscriptionsRepository();

  bool _loading = true;
  bool _busy = false;
  String? _error;
  Map<String, dynamic> _subscription = <String, dynamic>{};
  List<dynamic> _occurrences = const <dynamic>[];
  List<dynamic> _events = const <dynamic>[];

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
    final DioApiResponse response = await _repository.detail(
      widget.subscriptionId,
    );
    if (!mounted) return;
    if (response.errorType != NetErrorType.none) {
      setState(() {
        _loading = false;
        _error = 'Could not load the subscription.';
      });
      return;
    }
    final Map<String, dynamic> body = decodeBody(response);
    setState(() {
      _loading = false;
      _subscription = Map<String, dynamic>.from(
        (body['subscription'] ?? {}) as Map,
      );
      _occurrences = (body['occurrences'] as List?) ?? const <dynamic>[];
      _events = (body['events'] as List?) ?? const <dynamic>[];
    });
  }

  Future<void> _retryBilling(String occurrenceId) async {
    setState(() => _busy = true);
    final DioApiResponse response = await _repository.retryBilling(
      occurrenceId: occurrenceId,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (response.errorType != NetErrorType.none) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.jhatkaRetryDidNotGoThrough,
          ),
        ),
      );
      return;
    }
    String action = '';
    try {
      action = (decodeBody(response)['occurrence']?['action'] ?? '').toString();
    } catch (_) {
      action = '';
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          action == 'charged'
              ? 'Charge restarted — the customer has been notified. Not paid until the gateway confirms.'
              : 'Nothing to retry ($action).',
        ),
      ),
    );
    await _load();
  }

  /// Billing state → what the outlet sees. Unpaid + past-due is the case that
  /// needs the retry button; paid and skipped need none.
  Widget _billingChip(Map<String, dynamic> occurrence) {
    final String payment = (occurrence['paymentStatus'] ?? '').toString();
    final String billing = (occurrence['billingStatus'] ?? '').toString();
    if (payment == 'paid') {
      return StatusChip(
        label: AppLocalizations.of(context)!.jhatkaStatusPaid,
        color: Colors.green,
      );
    }
    if (billing == 'unpaid_skipped') {
      return StatusChip(
        label: AppLocalizations.of(context)!.jhatkaStatusSkippedCredited,
        color: Colors.orange,
      );
    }
    if (billing == 'pending') {
      return StatusChip(
        label: AppLocalizations.of(context)!.jhatkaStatusAwaitingPayment,
        color: Colors.blue,
      );
    }
    return StatusChip(
      label: (occurrence['generationStatus'] ?? '').toString(),
      color: Colors.grey,
    );
  }

  /// Standing items with quantity editing.
  ///
  /// The server enforces `editCutoffHours` — inside the cutoff the call fails with
  /// INSIDE_EDIT_CUTOFF naming the hours, and the message says to skip the occurrence
  /// instead. That guidance is surfaced verbatim rather than paraphrased, because it
  /// is the server telling the operator the correct next action.
  Widget _itemsCard() {
    final List<dynamic> items =
        (_subscription['items'] as List?) ?? const <dynamic>[];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  'Standing items (${items.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton(
                  onPressed: _busy ? null : _editItems,
                  child: Text(
                    AppLocalizations.of(context)!.jhatkaActionEditQuantities,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...items.map((dynamic raw) {
              final Map<String, dynamic> line = Map<String, dynamic>.from(
                raw as Map,
              );
              final Map<String, dynamic>? qty =
                  (line['requestedQuantity'] as Map?)?.cast<String, dynamic>();
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '• ${line['name'] ?? line['sku'] ?? 'Line'} — '
                  '${qty?['value'] ?? '?'} ${qty?['unit'] ?? ''}',
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _editItems() async {
    final List<dynamic> items =
        (_subscription['items'] as List?) ?? const <dynamic>[];
    if (items.isEmpty) return;

    // Local editable copies: variant id + quantity per line.
    final List<TextEditingController> controllers = items.map((dynamic raw) {
      final Map<String, dynamic> line = Map<String, dynamic>.from(raw as Map);
      final Map<String, dynamic>? qty = (line['requestedQuantity'] as Map?)
          ?.cast<String, dynamic>();
      return TextEditingController(text: '${qty?['value'] ?? ''}');
    }).toList();
    final TextEditingController reason = TextEditingController();

    try {
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
                const Text(
                  'Edit quantities',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Close to a delivery this refuses with the cutoff hours — '
                  'skip the occurrence instead.',
                ),
                const SizedBox(height: 16),
                ...List<Widget>.generate(items.length, (int i) {
                  final Map<String, dynamic> line = Map<String, dynamic>.from(
                    items[i] as Map,
                  );
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextField(
                      controller: controllers[i],
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText:
                            '${line['name'] ?? line['sku'] ?? 'Line'} — quantity',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  );
                }),
                TextField(
                  controller: reason,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(
                      context,
                    )!.jhatkaFieldReasonCustomer,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      AppLocalizations.of(context)!.jhatkaActionSaveQuantities,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
      if (go != true || !mounted) return;

      final String reasonText = reason.text.trim();
      if (reasonText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.jhatkaReasonRequired),
          ),
        );
        return;
      }

      final List<Map<String, dynamic>> payload = <Map<String, dynamic>>[];
      for (int i = 0; i < items.length; i += 1) {
        final Map<String, dynamic> line = Map<String, dynamic>.from(
          items[i] as Map,
        );
        final Map<String, dynamic>? qty = (line['requestedQuantity'] as Map?)
            ?.cast<String, dynamic>();
        final double? value = double.tryParse(controllers[i].text.trim());
        if (value == null || value <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Quantity for ${line['name'] ?? line['sku']} must be a positive number.',
              ),
            ),
          );
          return;
        }
        payload.add(<String, dynamic>{
          'variant': (line['variant'] ?? '').toString(),
          'quantity': <String, dynamic>{
            'value': value,
            'unit': (qty?['unit'] ?? 'GRAM').toString(),
          },
        });
      }
      if (payload.any(
        (Map<String, dynamic> e) => (e['variant'] ?? '').toString().isEmpty,
      )) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.jhatkaLineMissingVariant,
            ),
          ),
        );
        return;
      }

      setState(() => _busy = true);
      final DioApiResponse response = await _repository.updateItems(
        subscriptionId: widget.subscriptionId,
        items: payload,
        reason: reasonText,
      );
      if (!mounted) return;
      setState(() => _busy = false);
      if (response.errorType != NetErrorType.none) {
        String message = 'Save failed. Retry.';
        try {
          final Map<String, dynamic> err = decodeBody(response);
          if ((err['code'] ?? '').toString() == 'INSIDE_EDIT_CUTOFF') {
            message =
                'Too close to the next delivery — skip the occurrence instead.';
          }
        } catch (_) {
          message = 'Save failed. Retry.';
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
        return;
      }
      await _load();
    } finally {
      for (final TextEditingController c in controllers) {
        c.dispose();
      }
      reason.dispose();
    }
  }

  Widget _occurrenceTile(dynamic raw) {
    final Map<String, dynamic> occurrence = Map<String, dynamic>.from(
      raw as Map,
    );
    final String id = (occurrence['id'] ?? occurrence['_id'] ?? '').toString();
    final String payment = (occurrence['paymentStatus'] ?? '').toString();
    final String billing = (occurrence['billingStatus'] ?? '').toString();
    // Retryable: a charge was attempted, nothing arrived, and the occurrence was
    // not skipped. Skipped means credited — retrying it would charge for a
    // delivery that will never happen.
    final bool retryable =
        payment != 'paid' &&
        billing != 'unpaid_skipped' &&
        billing != 'not_required';
    return Card(
      child: ListTile(
        title: Text('${occurrence['occurrenceDate'] ?? '—'}'),
        subtitle: Text(
          'Charge ${occurrence['chargeAmount'] ?? '—'} · '
          '${occurrence['generationStatus'] ?? ''}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _billingChip(occurrence),
            if (retryable)
              TextButton(
                onPressed: _busy ? null : () => _retryBilling(id),
                child: Text(
                  AppLocalizations.of(context)!.jhatkaActionRetryCharge,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Subscription ${_subscription['subscriptionNo'] ?? ''}'),
      ),
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
                            'Status: ${_subscription['status'] ?? '—'}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if ((_subscription['statusReason'] ?? '')
                              .toString()
                              .isNotEmpty)
                            Text(
                              (_subscription['statusReason'] ?? '').toString(),
                            ),
                          const SizedBox(height: 8),
                          Text(
                            'Next: ${_subscription['nextOccurrenceDate'] ?? '—'} · '
                            '${_subscription['scheduleType'] ?? ''}',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Occurrences (${_occurrences.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ..._occurrences.map(_occurrenceTile),
                  const SizedBox(height: 16),
                  _itemsCard(),
                  const SizedBox(height: 16),
                  Text(
                    'History (${_events.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ..._events.map((dynamic raw) {
                    final Map<String, dynamic> event =
                        Map<String, dynamic>.from(raw as Map);
                    return ListTile(
                      dense: true,
                      title: Text((event['type'] ?? '').toString()),
                      subtitle: Text(
                        '${event['reason'] ?? ''}\n${event['at'] ?? ''}',
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}
