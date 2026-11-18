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
import 'package:partner/app/modules/jhatka/partner/fulfilment/jhatka_fulfilment_repository.dart';
import 'package:partner/app/modules/jhatka/partner/weighing/jhatka_weigh_repository.dart';
import 'package:partner/app/modules/jhatka/partner/weighing/jhatka_money.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

/// The counter's intake: receive → accept → prepare, or reject.
///
/// ## Why this screen exists
///
/// An order placed by a customer arrives at CREATED. Weighing needs PREPARING.
/// Between them are three moves — receive (onto the screen), accept (commit), and
/// start-preparation (open the cutting ticket + allocate stock) — and until this
/// screen existed the app had none of them: the order list showed new orders as dead
/// rows and every one sat at CREATED forever.
///
/// ## What each action means, in the operator's terms
///
///   Receive  — "I see it." Starts the outlet's SLA clock. COD orders come from
///              CREATED, paid ones from PAID; the server decides.
///   Accept   — "We'll do it." New business: a lapsed outlet is refused here, and
///              the message says documents, not "error".
///   Reject   — "We can't." Needs a reason the customer reads. For a paid order the
///              server raises the refund as a document and the screen shows what
///              comes back — never just "rejected".
///   Prepare  — "Start cutting." Allocates real stock; refused with the shortfall
///              SKUs when the counter cannot cover the order.
///
/// After PREPARING the operator goes to the weigh screen — that handoff is a button
/// here, not a hunt through the list.
class IntakeScreen extends StatefulWidget {
  const IntakeScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<IntakeScreen> createState() => _IntakeScreenState();
}

class _IntakeScreenState extends State<IntakeScreen> {
  final JhatkaFulfilmentRepository _fulfilment = JhatkaFulfilmentRepository();
  final JhatkaWeighRepository _weigh = JhatkaWeighRepository();
  final TextEditingController _rejectReason = TextEditingController();

  bool _loading = true;
  bool _busy = false;
  String? _error;
  Map<String, dynamic> _order = <String, dynamic>{};

  String get _lifecycle => (_order['lifecycle'] ?? '').toString();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _rejectReason.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final DioApiResponse response = await _weigh.orderDetail(widget.orderId);
    if (!mounted) return;
    if (response.errorType != NetErrorType.none) {
      setState(() {
        _loading = false;
        _error = AppLocalizations.of(context)!.jhatkaIntakeLoadFailed;
      });
      return;
    }
    final Map<String, dynamic> body = decodeBody(response);
    setState(() {
      _loading = false;
      _order = Map<String, dynamic>.from((body['order'] ?? {}) as Map);
    });
  }

  /// Server refusal code → what the operator does next. Every code the intake
  /// endpoints can return is mapped; anything else is an honest "retry".
  String _messageFor(String code, String fallback) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    switch (code) {
      case 'OUTLET_NOT_TRADING':
        return l10n.jhatkaIntakeOutletNotTrading;
      case 'FSSAI_NOT_VALID':
        return l10n.jhatkaIntakeFssaiNotValid;
      case 'INSUFFICIENT_RAW_STOCK':
        return l10n.jhatkaIntakeInsufficientStock;
      case 'RECEIPT_ALREADY_POSTED':
        return l10n.jhatkaIntakeAlreadyDone;
      default:
        return fallback;
    }
  }

  String _codeOf(DioApiResponse response) {
    try {
      return (decodeBody(response)['code'] ?? '').toString();
    } catch (_) {
      return '';
    }
  }

  Future<void> _run(
    Future<DioApiResponse> Function() call,
    String fallback,
  ) async {
    setState(() => _busy = true);
    final DioApiResponse response = await call();
    if (!mounted) return;
    setState(() => _busy = false);
    if (response.errorType != NetErrorType.none) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_messageFor(_codeOf(response), fallback))),
      );
      return;
    }
    await _load();
  }

  Future<void> _receive() => _run(
    () => _fulfilment.receive(orderId: widget.orderId),
    AppLocalizations.of(context)!.jhatkaIntakeReceiveFailed,
  );

  Future<void> _accept() => _run(
    () => _fulfilment.accept(orderId: widget.orderId),
    AppLocalizations.of(context)!.jhatkaIntakeAcceptFailed,
  );

  Future<void> _prepare() => _run(
    () => _fulfilment.startPreparation(orderId: widget.orderId),
    AppLocalizations.of(context)!.jhatkaIntakePrepareFailed,
  );

  Future<void> _reject() async {
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
                AppLocalizations.of(context)!.jhatkaIntakeRejectTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(AppLocalizations.of(context)!.jhatkaIntakeRejectBody),
              const SizedBox(height: 16),
              TextField(
                controller: reason,
                autofocus: true,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(
                    context,
                  )!.jhatkaFieldReasonShown,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  AppLocalizations.of(context)!.jhatkaActionRejectOrder,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(AppLocalizations.of(context)!.jhatkaActionKeepIt),
              ),
            ],
          ),
        );
      },
    );
    if (go != true || !mounted) return;
    final String text = reason.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.jhatkaReasonRequiredCustomer,
          ),
        ),
      );
      return;
    }
    setState(() => _busy = true);
    final DioApiResponse response = await _fulfilment.reject(
      orderId: widget.orderId,
      reason: text,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (response.errorType != NetErrorType.none) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _messageFor(
              _codeOf(response),
              AppLocalizations.of(context)!.jhatkaIntakeRejectFailed,
            ),
          ),
        ),
      );
      return;
    }
    // A paid rejection comes back with what the customer gets — show it, then leave.
    try {
      final Map<String, dynamic> body = decodeBody(response);
      final Map<String, dynamic>? refund = (body['refund'] as Map?)
          ?.cast<String, dynamic>();
      if (refund != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.jhatkaIntakeRefundRaised(
                (refund['refundNo'] ?? '').toString(),
              ),
            ),
          ),
        );
      }
    } catch (_) {
      // The state change is what matters; the toast is courtesy.
    }
    if (mounted) Navigator.of(context).pop();
  }

  List<Widget> _actions() {
    if (_busy) {
      return const <Widget>[Center(child: CircularProgressIndicator())];
    }
    switch (_lifecycle) {
      case 'CREATED':
      case 'PAYMENT_PENDING':
      case 'PAID':
        return <Widget>[
          FilledButton(
            onPressed: _receive,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                AppLocalizations.of(context)!.jhatkaIntakeReceiveOrder,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.jhatkaIntakeReceiveHint,
            textAlign: TextAlign.center,
          ),
        ];
      case 'OUTLET_RECEIVED':
        return <Widget>[
          FilledButton(
            onPressed: _accept,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                AppLocalizations.of(context)!.jhatkaIntakeAcceptOrder,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _reject,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                AppLocalizations.of(context)!.jhatkaActionRejectWithReason,
              ),
            ),
          ),
        ];
      case 'ACCEPTED':
        return <Widget>[
          FilledButton(
            onPressed: _prepare,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                AppLocalizations.of(context)!.jhatkaIntakeStartPreparation,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _reject,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                AppLocalizations.of(context)!.jhatkaActionRejectWithReason,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.jhatkaIntakePreparationHint,
            textAlign: TextAlign.center,
          ),
        ];
      case 'PREPARING':
      case 'WEIGHING':
      case 'WEIGHT_CONFIRMED':
        return <Widget>[
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                AppLocalizations.of(context)!.jhatkaIntakeBackToList,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ];
      default:
        return <Widget>[
          Text(
            _lifecycle.isEmpty
                ? '—'
                : AppLocalizations.of(context)!.jhatkaIntakeNothingToDo(
                    _lifecycle,
                  ),
            textAlign: TextAlign.center,
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> items = (_order['items'] as List?) ?? const <dynamic>[];
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(
            context,
          )!.jhatkaOrderNoLabel((_order['orderNo'] ?? '—').toString()),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          AppLocalizations.of(
                            context,
                          )!.jhatkaStageLabel(_lifecycle),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context)!.jhatkaIntakeEstimated(
                            _order['estimatedTotal'] != null
                                ? formatRupees(
                                    (_order['estimatedTotal'] as num),
                                  )
                                : '—',
                            (_order['paymentMode'] ?? '')
                                .toString()
                                .toUpperCase(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...items.map((dynamic raw) {
                          final Map<String, dynamic> line =
                              Map<String, dynamic>.from(raw as Map);
                          final Map<String, dynamic>? qty =
                              (line['requestedQuantity'] as Map?)
                                  ?.cast<String, dynamic>();
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              AppLocalizations.of(context)!.jhatkaIntakeLine(
                                (line['name'] ??
                                        line['sku'] ??
                                        AppLocalizations.of(
                                          context,
                                        )!.jhatkaIntakeLineFallback)
                                    .toString(),
                                (qty?['value'] ?? '?').toString(),
                                (qty?['unit'] ?? '').toString(),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ..._actions(),
              ],
            ),
    );
  }
}
