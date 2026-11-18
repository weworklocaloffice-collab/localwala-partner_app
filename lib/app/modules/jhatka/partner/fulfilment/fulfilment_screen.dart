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
import 'package:partner/app/modules/jhatka/partner/fulfilment/jhatka_fulfilment_repository.dart';
import 'package:partner/app/modules/jhatka/partner/labels/jhatka_labels_repository.dart';
import 'package:partner/app/presentation/styles/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

/// Pack → ready → dispatch, one screen following the order lifecycle.
///
/// Each step calls its endpoint and reads the server's answer: pack returns
/// `canDispatch`, ready refuses a cold-chain breach, dispatch refuses a
/// foreign/blocked rider or a blown transit limit. Every refusal carries a
/// code, and every code maps to a message telling the dispatcher what to do
/// next — never a bare "failed".
class FulfilmentScreen extends StatefulWidget {
  const FulfilmentScreen({
    super.key,
    required this.orderId,
    required this.lifecycle,
    this.fulfilmentMode = 'delivery',
  });

  final String orderId;
  final String lifecycle;

  /// OD-12: 'pickup' orders hand over at the counter from READY — no rider,
  /// no dispatch. The order list passes it; the server is the enforcer either
  /// way (dispatch 409 PICKUP_ORDER, collect 409 DELIVERY_ORDER).
  final String fulfilmentMode;

  @override
  State<FulfilmentScreen> createState() => _FulfilmentScreenState();
}

class _FulfilmentScreenState extends State<FulfilmentScreen> {
  final JhatkaFulfilmentRepository _repository = JhatkaFulfilmentRepository();
  final JhatkaLabelsRepository _labels = JhatkaLabelsRepository();

  final TextEditingController _packages = TextEditingController(text: '1');
  final TextEditingController _weightGrams = TextEditingController();
  final TextEditingController _tempC = TextEditingController();
  final TextEditingController _note = TextEditingController();
  bool _fragile = false;

  bool _busy = false;
  String _lifecycle = '';
  bool? _canDispatch;
  List<dynamic> _drivers = const <dynamic>[];
  String? _driverId;
  String? _notice;
  String? _deliveryId;
  Map<String, dynamic>? _delivery;
  Map<String, dynamic>? _pod;

  @override
  void initState() {
    super.initState();
    _lifecycle = widget.lifecycle;
    _loadDrivers();
  }

  @override
  void dispose() {
    _packages.dispose();
    _weightGrams.dispose();
    _tempC.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _viewInvoice() async {
    final DioApiResponse response = await _repository.orderInvoice(
      orderId: widget.orderId,
    );
    if (!mounted) return;
    if (response.errorType != NetErrorType.none) {
      _say('Could not load invoice');
      return;
    }
    final Map<String, dynamic> body = decodeBody(response);
    final Map<String, dynamic> inv = (body['invoice'] is Map)
        ? Map<String, dynamic>.from(body['invoice'] as Map)
        : <String, dynamic>{};
    if (inv.isEmpty) {
      _say('No invoice issued yet');
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Invoice ${inv['invoiceNo'] ?? ''}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Status: ${inv['status'] ?? ''}'),
                if (inv['issuedAt'] != null) Text('Issued: ${inv['issuedAt']}'),
                if (inv['isVoided'] == true) const Text('VOIDED'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadDrivers() async {
    final DioApiResponse response = await _repository.outletDrivers();
    if (!mounted || response.errorType != NetErrorType.none) return;
    final Map<String, dynamic> body = decodeBody(response);
    setState(() {
      _drivers = (body['drivers'] as List?) ?? const <dynamic>[];
    });
  }

  String _codeOf(DioApiResponse response) {
    try {
      return (decodeBody(response)['code'] ?? '').toString();
    } catch (_) {
      return '';
    }
  }

  void _say(String message) {
    setState(() => _notice = message);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pack() async {
    setState(() => _busy = true);
    final DioApiResponse response = await _repository.pack(
      orderId: widget.orderId,
      packageCount: int.tryParse(_packages.text.trim()),
      totalWeightGrams: int.tryParse(_weightGrams.text.trim()),
      coldChainTempC: double.tryParse(_tempC.text.trim()),
      fragile: _fragile,
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (response.errorType != NetErrorType.none) {
      _say(
        _codeOf(response) == 'WEIGHT_NOT_CONFIRMED'
            ? 'Weigh every variable-weight line first.'
            : 'Packing failed. Retry.',
      );
      return;
    }
    final Map<String, dynamic> body = decodeBody(response);
    final Map<String, dynamic> order = Map<String, dynamic>.from(
      (body['order'] ?? {}) as Map,
    );
    setState(() {
      _lifecycle = (order['lifecycle'] ?? 'PACKING').toString();
      _canDispatch = order['canDispatch'] as bool?;
    });
    if (_canDispatch == false) {
      _say('Packed with a cold-chain breach — dispatch is blocked.');
    }
  }

  Future<void> _ready() async {
    setState(() => _busy = true);
    final DioApiResponse response = await _repository.markReady(widget.orderId);
    if (!mounted) return;
    setState(() => _busy = false);
    if (response.errorType != NetErrorType.none) {
      _say(
        _codeOf(response) == 'COLD_CHAIN_BREACH'
            ? 'Cold-chain breach at packing — this order cannot go ready.'
            : 'Marking ready failed. Retry.',
      );
      return;
    }
    setState(() => _lifecycle = 'READY');
  }

  /// Generate pack labels for this order.
  ///
  /// Offered after packing (labels need weights + batch trace) and before
  /// dispatch — a pack leaving without its QR is a pack §12.3 cannot trace.
  /// Commits as a set server-side; a partial failure leaves zero labels, not
  /// four of five.
  Future<void> _generateLabels() async {
    setState(() => _busy = true);
    final DioApiResponse response = await _labels.create(
      orderId: widget.orderId,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (response.errorType != NetErrorType.none) {
      _say('Label generation failed. Retry — nothing was printed.');
      return;
    }
    int count = 0;
    try {
      final Map<String, dynamic> body = decodeBody(response);
      count = ((body['labels'] as List?) ?? const <dynamic>[]).length;
    } catch (_) {
      count = 0;
    }
    _say(count > 0 ? '$count label(s) ready to print.' : 'Labels ready.');
  }

  Future<void> _dispatch() async {
    if (_driverId == null) {
      _say('Pick the rider first.');
      return;
    }
    setState(() => _busy = true);
    final DioApiResponse response = await _repository.dispatch(
      orderId: widget.orderId,
      driverId: _driverId!,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (response.errorType != NetErrorType.none) {
      final String code = _codeOf(response);
      _say(
        code == 'MAX_TRANSIT_EXCEEDED'
            ? 'Too long since ready — re-fire the order or escalate.'
            : code == 'FORBIDDEN' || response.statusCode == 403
            ? 'That rider cannot take this order.'
            : 'Dispatch failed. Retry.',
      );
      return;
    }
    final Map<String, dynamic> body = decodeBody(response);
    final Map<String, dynamic> delivery = Map<String, dynamic>.from(
      (body['delivery'] ?? {}) as Map,
    );
    setState(() {
      _lifecycle = 'DRIVER_ASSIGNED';
      _deliveryId = (delivery['id'] ?? '').toString();
    });
    _say('Rider assigned.');
    await _refreshDelivery();
  }

  /// The counter hand-over for a pickup order: READY → COMPLETED, no rider.
  /// Mirrors `_dispatch` for the other fulfilment mode.
  Future<void> _collect() async {
    setState(() => _busy = true);
    final DioApiResponse response = await _repository.collect(
      orderId: widget.orderId,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (response.errorType != NetErrorType.none) {
      final String code = _codeOf(response);
      _say(
        code.startsWith('OTP_')
            ? 'Handover code rejected — ask the customer to read it again.'
            : 'Hand-over failed. Retry.',
      );
      return;
    }
    setState(() => _lifecycle = 'COMPLETED');
    _say('Handed over — order completed.');
  }

  Future<void> _refreshDelivery() async {
    if (_deliveryId == null || _deliveryId!.isEmpty) return;
    final DioApiResponse response = await _repository.deliveryDetail(
      _deliveryId!,
    );
    if (!mounted || response.errorType != NetErrorType.none) return;
    final Map<String, dynamic> body = decodeBody(response);
    setState(() {
      _delivery = Map<String, dynamic>.from((body['delivery'] ?? {}) as Map);
      final dynamic pod = body['pod'];
      _pod = pod is Map ? Map<String, dynamic>.from(pod) : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SectionListScreen(
      title: AppLocalizations.of(context)!.jhatkaActionPackDispatch,
      icon: Icons.local_shipping_outlined,
      children: <Widget>[
        Card(
          child: ListTile(
            title: Text(
              AppLocalizations.of(context)!.jhatkaStageLabel(_lifecycle),
            ),
            subtitle: _notice != null ? Text(_notice!) : null,
          ),
        ),
        OutlinedButton(
          onPressed: _busy ? null : _viewInvoice,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('View invoice'),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  'Pack',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _packages,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  style: const TextStyle(fontSize: 22),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(
                      context,
                    )!.realEstateNavPackages,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _weightGrams,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  style: const TextStyle(fontSize: 22),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(
                      context,
                    )!.storesFieldWeightGrams,
                    border: OutlineInputBorder(),
                    suffixText: 'g',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _tempC,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(fontSize: 22),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(
                      context,
                    )!.jhatkaFieldPackingTemp,
                    border: OutlineInputBorder(),
                  ),
                ),
                SwitchListTile(
                  title: Text(AppLocalizations.of(context)!.jhatkaFragile),
                  value: _fragile,
                  onChanged: (bool v) => setState(() => _fragile = v),
                ),
                TextField(
                  controller: _note,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(
                      context,
                    )!.jhatkaFieldNoteOptional,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _busy ? null : _pack,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('Pack', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  'Ready & dispatch',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: _busy ? null : _ready,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      AppLocalizations.of(context)!.jhatkaActionMarkReady,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _busy ? null : _generateLabels,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      AppLocalizations.of(context)!.jhatkaActionGenerateLabels,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // OD-12 forks here. A pickup order's READY hand is the counter
                // collect — offering a rider picker for it is a button that
                // lies (the server refuses it with PICKUP_ORDER).
                if (widget.fulfilmentMode == 'pickup') ...<Widget>[
                  Text(
                    AppLocalizations.of(context)!.jhatkaPickupOrderNote,
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _busy ? null : _collect,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Text(
                        AppLocalizations.of(context)!.jhatkaActionHandOver,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ] else ...<Widget>[
                  DropdownButtonFormField<String>(
                    initialValue: _driverId,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.jhatkaNavRider,
                      border: OutlineInputBorder(),
                    ),
                    items: _drivers.map((dynamic raw) {
                      final Map<String, dynamic> d = Map<String, dynamic>.from(
                        raw as Map,
                      );
                      final bool eligible = d['eligible'] == true;
                      return DropdownMenuItem<String>(
                        value: (d['id'] ?? '').toString(),
                        enabled: eligible,
                        child: Text(
                          '${d['name'] ?? '—'}${eligible ? '' : ' (${d['ineligibleReason'] ?? 'unavailable'})'}',
                        ),
                      );
                    }).toList(),
                    onChanged: (String? v) => setState(() => _driverId = v),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _busy ? null : _dispatch,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Text('Dispatch', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_deliveryId != null) _trackingCard(),
      ],
    );
  }

  Widget _trackingCard() {
    final Map<String, dynamic> delivery = _delivery ?? <String, dynamic>{};
    final String status = (delivery['status'] ?? '').toString();
    final String codStatus = (delivery['codStatus'] ?? '').toString();
    final bool breached = (_pod?['coldChainBreached'] as bool?) ?? false;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Expanded(
                  child: Text(
                    'Delivery',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  tooltip: AppLocalizations.of(context)!.storesActionRefresh,
                  icon: const Icon(Icons.refresh_outlined),
                  onPressed: _busy ? null : _refreshDelivery,
                ),
              ],
            ),
            Text(
              AppLocalizations.of(context)!.jhatkaDeliveryStatus(
                (delivery['deliveryNo'] ?? '—').toString(),
                status.isEmpty ? '…' : status,
              ),
            ),
            Text(
              AppLocalizations.of(
                context,
              )!.jhatkaCodLabel(codStatus.isEmpty ? '…' : codStatus),
            ),
            if (_pod != null)
              Text(
                breached == true
                    ? 'Cold chain BREACHED at ${_pod!['deliveredTempC'] ?? '?'}°C — complaint raised automatically'
                    : 'Delivered at ${_pod!['deliveredTempC'] ?? '?'}°C, chain intact',
                style: TextStyle(
                  color: breached == true ? Colors.red : Colors.green,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
