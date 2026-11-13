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
import 'package:partner/app/modules/jhatka/jhatka_supply_repository.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

/// Request stock from LocalWala (OD-12 companion).
///
/// Three things live here: the request form (catalogue picker + quantities +
/// payment mode — the SERVER's eligible-mode list, never a local guess), the
/// request history with statuses, and the prepaid ledger card. Prepay hands off
/// to the shared checkout with the returned initiation, exactly like a customer
/// order pay; the verified callback marks the request paid server-side.
class SupplyRequestScreen extends StatefulWidget {
  const SupplyRequestScreen({super.key});

  @override
  State<SupplyRequestScreen> createState() => _SupplyRequestScreenState();
}

class _SupplyRequestScreenState extends State<SupplyRequestScreen> {
  final JhatkaSupplyRepository _repository = JhatkaSupplyRepository();

  bool _loading = true;
  String? _error;
  List<dynamic> _requests = const <dynamic>[];
  List<dynamic> _catalogue = const <dynamic>[];
  Map<String, dynamic> _modes = const <String, dynamic>{};
  Map<String, dynamic> _area = const <String, dynamic>{};
  int _balancePaise = 0;
  bool _busy = false;

  // form state
  final Map<String, TextEditingController> _qty =
      <String, TextEditingController>{};
  final TextEditingController _areaRadius = TextEditingController();
  final TextEditingController _areaExtended = TextEditingController();
  final TextEditingController _areaFeeRupees = TextEditingController();
  final TextEditingController _areaReason = TextEditingController();
  String _paymentMode = 'on_delivery';
  DateTime _neededBy = DateTime.now().add(const Duration(days: 1));

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _qty.values) {
      c.dispose();
    }
    _areaRadius.dispose();
    _areaExtended.dispose();
    _areaFeeRupees.dispose();
    _areaReason.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final results = await Future.wait([
      _repository.listRequests(),
      _repository.catalogue(),
      _repository.modes(),
      _repository.ledger(),
      _repository.area(),
    ]);
    if (!mounted) return;
    final failed = results.any((r) => r.errorType != NetErrorType.none);
    if (failed) {
      setState(() {
        _loading = false;
        _error = AppLocalizations.of(context)!.jhatkaSupplyLoadFailed;
      });
      return;
    }
    Map<String, dynamic> bodyOf(DioApiResponse r) => decodeBody(r);

    final ledger = bodyOf(results[3]);
    final area = bodyOf(results[4]);
    setState(() {
      _loading = false;
      _requests =
          (bodyOf(results[0])['requests'] as List?) ?? const <dynamic>[];
      _catalogue =
          (bodyOf(results[1])['products'] as List?) ?? const <dynamic>[];
      _modes = bodyOf(results[2]);
      _area = area;
      _balancePaise = (ledger['balancePaise'] as num?)?.toInt() ?? 0;
      final modes =
          (_modes['modes'] as List?)?.cast<String>() ?? const <String>[];
      if (!modes.contains(_paymentMode) && modes.isNotEmpty) {
        _paymentMode = modes.first;
      }
      final serviceArea = Map<String, dynamic>.from(
        (area['serviceArea'] as Map?) ?? const <String, dynamic>{},
      );
      if (_areaRadius.text.trim().isEmpty) {
        _areaRadius.text = (serviceArea['radiusKm'] ?? 5).toString();
      }
      if (_areaExtended.text.trim().isEmpty) {
        _areaExtended.text =
            (serviceArea['extendedRadiusKm'] ?? 0).toString();
      }
      if (_areaFeeRupees.text.trim().isEmpty) {
        final num feePaise =
            (serviceArea['extendedDeliveryFee'] as num?) ?? 0;
        _areaFeeRupees.text = (feePaise / 100).toStringAsFixed(2);
      }
    });
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final items = <Map<String, dynamic>>[];
    for (final entry in _qty.entries) {
      final qty = double.tryParse(entry.value.text.trim());
      if (qty != null && qty > 0) {
        items.add(<String, dynamic>{
          'product': entry.key,
          'quantity': <String, dynamic>{'value': qty, 'unit': 'KG'},
        });
      }
    }
    if (items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.jhatkaSupplyPickItems)));
      return;
    }
    setState(() => _busy = true);
    final response = await _repository.createRequest(
      items: items,
      paymentMode: _paymentMode,
      neededBy: _neededBy.toIso8601String(),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (response.errorType != NetErrorType.none) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.jhatkaSupplySubmitFailed)));
      return;
    }
    for (final c in _qty.values) {
      c.clear();
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.jhatkaSupplySubmitted)));
    await _load();
  }

  Future<void> _pay(String requestId) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    final response = await _repository.pay(requestId: requestId);
    if (!mounted) return;
    setState(() => _busy = false);
    if (response.errorType != NetErrorType.none) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.jhatkaSupplyPayFailed)));
      return;
    }
    String initiationId = '';
    final Map<String, dynamic> body = decodeBody(response);
    final dynamic initiation = body['initiation'];
    if (initiation is Map) {
      initiationId = (initiation['id'] ?? initiation['_id'] ?? '').toString();
    }
    if (initiationId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.jhatkaSupplyPayFailed)));
      return;
    }
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushNamed('/make_payments', arguments: [initiationId]);
  }

  String _modeLabel(AppLocalizations l10n, String mode) {
    switch (mode) {
      case 'prepaid':
        return l10n.jhatkaSupplyModePrepaid;
      case 'on_delivery':
        return l10n.jhatkaSupplyModeOnDelivery;
      case 'deduct':
        return l10n.jhatkaSupplyModeDeduct;
    }
    return mode;
  }

  /// Propose new delivery rings. The platform ceiling is checked locally as a
  /// courtesy — the server checks it again and is the authority.
  Future<void> _submitAreaRequest() async {
    final l10n = AppLocalizations.of(context)!;
    final double radius = double.tryParse(_areaRadius.text.trim()) ?? -1;
    final double extended =
        double.tryParse(_areaExtended.text.trim()) ?? -1;
    final double feeRupees =
        double.tryParse(_areaFeeRupees.text.trim()) ?? -1;
    final String reason = _areaReason.text.trim();
    final double maxRadius =
        (_area['maxRadiusKm'] as num?)?.toDouble() ?? 12;
    if (radius < 0 || extended < 0 || feeRupees < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.jhatkaAreaInvalidNumbers)),
      );
      return;
    }
    if (radius + extended > maxRadius) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.jhatkaAreaCeiling} $maxRadius km'),
        ),
      );
      return;
    }
    if (extended > 0 && feeRupees <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.jhatkaAreaFeeRequired)),
      );
      return;
    }
    if (reason.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.jhatkaAreaReasonRequired)),
      );
      return;
    }
    setState(() => _busy = true);
    final response = await _repository.createAreaRequest(
      radiusKm: radius,
      extendedRadiusKm: extended,
      extendedDeliveryFee: feeRupees,
      reason: reason,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (response.errorType != NetErrorType.none) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.jhatkaAreaSubmitFailed)),
      );
      return;
    }
    _areaReason.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.jhatkaAreaSubmitted)),
    );
    await _load();
  }

  Future<void> _cancelAreaRequest(String requestId) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    final response = await _repository.cancelAreaRequest(requestId);
    if (!mounted) return;
    setState(() => _busy = false);
    if (response.errorType != NetErrorType.none) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.jhatkaAreaSubmitFailed)),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.jhatkaAreaWithdrawn)),
    );
    await _load();
  }

  /// Current rings, the ceiling, and either the open proposal (withdrawable)
  /// or the proposal form. Direct outlets never see the form: LocalWala edits
  /// their area directly.
  Widget _areaCard(AppLocalizations l10n) {
    final Map<String, dynamic> serviceArea = Map<String, dynamic>.from(
      (_area['serviceArea'] as Map?) ?? const <String, dynamic>{},
    );
    final double radiusKm =
        (serviceArea['radiusKm'] as num?)?.toDouble() ?? 5;
    final double extendedRadiusKm =
        (serviceArea['extendedRadiusKm'] as num?)?.toDouble() ?? 0;
    final int feePaise =
        (serviceArea['extendedDeliveryFee'] as num?)?.toInt() ?? 0;
    final double maxRadiusKm =
        (_area['maxRadiusKm'] as num?)?.toDouble() ?? 12;
    final Map<String, dynamic>? open = _area['openRequest'] is Map
        ? Map<String, dynamic>.from(_area['openRequest'] as Map)
        : null;
    final bool canRequest = _area['canRequest'] == true;
    final Map<String, dynamic> proposed = open == null
        ? const <String, dynamic>{}
        : Map<String, dynamic>.from(
            (open['proposed'] as Map?) ?? const <String, dynamic>{},
          );
    final int proposedFeePaise =
        (proposed['extendedDeliveryFee'] as num?)?.toInt() ?? 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              l10n.jhatkaAreaTitle,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${l10n.jhatkaAreaFreeRing} $radiusKm km · '
              '${extendedRadiusKm > 0 ? '${l10n.jhatkaAreaPaidRing} +$extendedRadiusKm km (₹${(feePaise / 100).toStringAsFixed(2)})' : l10n.jhatkaAreaNoOuterBand}',
              style: const TextStyle(fontSize: 13),
            ),
            Text(
              '${l10n.jhatkaAreaCeiling} $maxRadiusKm km',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            if (open != null) ...<Widget>[
              Text(
                '${l10n.jhatkaAreaPending} · ${open['requestNo'] ?? ''}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '${proposed['radiusKm'] ?? '-'} km free · '
                '${(proposed['extendedRadiusKm'] as num?) ?? 0} km paid · '
                '₹${(proposedFeePaise / 100).toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed:
                    _busy ? null : () => _cancelAreaRequest('${open['id']}'),
                child: Text(l10n.jhatkaAreaWithdraw),
              ),
            ] else if (canRequest) ...<Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _areaRadius,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: '${l10n.jhatkaAreaFreeRing} (km)',
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _areaExtended,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: '${l10n.jhatkaAreaPaidRing} (km)',
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _areaFeeRupees,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.jhatkaAreaFee,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _areaReason,
                decoration: InputDecoration(
                  labelText: l10n.jhatkaAreaReason,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _busy ? null : _submitAreaRequest,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(l10n.jhatkaAreaSubmit),
                ),
              ),
            ] else
              Text(
                l10n.jhatkaAreaDirect,
                style: const TextStyle(fontSize: 13),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final eligibleModes =
        (_modes['modes'] as List?)?.cast<String>() ?? const <String>[];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.jhatkaSupplyTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: <Widget>[
                  // ---- the ledger card ---------------------------------
                  Card(
                    child: ListTile(
                      title: Text(l10n.jhatkaSupplyLedgerBalance),
                      subtitle: Text(
                        '₹${(_balancePaise / 100).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      leading: const Icon(
                        Icons.account_balance_wallet_outlined,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ---- delivery area (partner proposes, admin approves) ----
                  _areaCard(l10n),
                  const SizedBox(height: 12),

                  // ---- the request form --------------------------------
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Text(
                            l10n.jhatkaSupplyNewRequest,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._catalogue.map((dynamic raw) {
                            final product = Map<String, dynamic>.from(
                              raw as Map,
                            );
                            final id = (product['id'] ?? product['_id'] ?? '')
                                .toString();
                            _qty.putIfAbsent(id, () => TextEditingController());
                            return TextField(
                              controller: _qty[id],
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText:
                                    '${product['name']} (${l10n.jhatkaSupplyQtyKg})',
                                border: const OutlineInputBorder(),
                                isDense: true,
                              ),
                            );
                          }),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: _paymentMode.isEmpty
                                ? null
                                : _paymentMode,
                            decoration: InputDecoration(
                              labelText: l10n.jhatkaSupplyPaymentMode,
                              border: const OutlineInputBorder(),
                            ),
                            items: eligibleModes
                                .map(
                                  (m) => DropdownMenuItem<String>(
                                    value: m,
                                    child: Text(_modeLabel(l10n, m)),
                                  ),
                                )
                                .toList(),
                            onChanged: (String? v) {
                              if (v != null) setState(() => _paymentMode = v);
                            },
                          ),
                          const SizedBox(height: 12),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(l10n.jhatkaSupplyNeededBy),
                            subtitle: Text(
                              '${_neededBy.year}-${_neededBy.month.toString().padLeft(2, '0')}-${_neededBy.day.toString().padLeft(2, '0')}',
                            ),
                            trailing: const Icon(Icons.calendar_today_outlined),
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _neededBy,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 30),
                                ),
                              );
                              if (date != null) {
                                setState(() => _neededBy = date);
                              }
                            },
                          ),
                          FilledButton(
                            onPressed: _busy ? null : _submit,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(l10n.jhatkaSupplySubmit),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ---- the history -------------------------------------
                  Text(
                    l10n.jhatkaSupplyHistory,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_requests.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(child: Text(l10n.jhatkaSupplyNoRequests)),
                    )
                  else
                    ..._requests.map((dynamic raw) {
                      final request = Map<String, dynamic>.from(raw as Map);
                      final id = (request['id'] ?? request['_id'] ?? '')
                          .toString();
                      final status = (request['status'] ?? '').toString();
                      final canPay =
                          status == 'approved' &&
                          request['paymentMode'] == 'prepaid' &&
                          (request['payment'] is Map
                              ? (request['payment'] as Map)['status'] != 'paid'
                              : true);
                      return Card(
                        child: ListTile(
                          title: Text((request['requestNo'] ?? '—').toString()),
                          subtitle: Text(
                            '$status · ${_modeLabel(l10n, (request['paymentMode'] ?? '').toString())}'
                            '${request['approvedValuePaise'] is num ? ' · ₹${((request['approvedValuePaise'] as num) / 100).toStringAsFixed(2)}' : ''}',
                          ),
                          trailing: canPay
                              ? FilledButton.tonal(
                                  onPressed: _busy ? null : () => _pay(id),
                                  child: Text(l10n.jhatkaSupplyPay),
                                )
                              : status == 'settled' || status == 'fulfilled'
                              ? const Icon(
                                  Icons.check_circle_outline,
                                  color: Colors.green,
                                )
                              : null,
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
