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
import 'package:partner/app/modules/jhatka/jhatka_media.dart';
import 'package:partner/app/modules/jhatka/partner/driver/jhatka_rider_repository.dart';
import 'package:partner/app/modules/jhatka/partner/weighing/jhatka_money.dart'
    as jhatka_money;
import 'package:partner/app/presentation/styles/theme.dart';
import 'package:partner/app/presentation/styles/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

/// One delivery, worked front to back.
///
/// The action offered follows the status: accept → pickup → arrived →
/// out-for-delivery → deliver, or fail with a reason at any point before
/// delivered. Delivery shows the frozen collect amount so there is no
/// argument at the door about how much to collect.
class RiderDeliveryScreen extends StatefulWidget {
  const RiderDeliveryScreen({super.key, required this.deliveryId});

  final String deliveryId;

  @override
  State<RiderDeliveryScreen> createState() => _RiderDeliveryScreenState();
}

class _RiderDeliveryScreenState extends State<RiderDeliveryScreen> {
  final JhatkaRiderRepository _repository = JhatkaRiderRepository();

  bool _loading = true;
  String? _error;
  Map<String, dynamic> _delivery = const <String, dynamic>{};
  Map<String, dynamic>? _order;
  Map<String, dynamic>? _pod;
  bool _busy = false;

  final TextEditingController _clientRef = TextEditingController();
  final TextEditingController _temp = TextEditingController();
  final TextEditingController _otp = TextEditingController();
  final TextEditingController _receiver = TextEditingController();
  final TextEditingController _cod = TextEditingController();
  final TextEditingController _failReason = TextEditingController();
  final TextEditingController _collectAmount = TextEditingController();

  /// POD photo, uploaded before the sheet confirms. A delivery without proof
  /// is a reconciliation that never balances.
  String? _podPhotoUrl;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _clientRef.dispose();
    _temp.dispose();
    _otp.dispose();
    _receiver.dispose();
    _cod.dispose();
    _failReason.dispose();
    _collectAmount.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final DioApiResponse response = await _repository.delivery(
      widget.deliveryId,
    );
    if (!mounted) return;
    if (response.errorType != NetErrorType.none) {
      setState(() {
        _loading = false;
        _error = 'Could not load delivery.';
      });
      return;
    }
    final Map<String, dynamic> body = decodeBody(response);
    setState(() {
      _loading = false;
      _delivery = Map<String, dynamic>.from((body['delivery'] ?? {}) as Map);
      final dynamic order = body['order'];
      _order = order is Map ? Map<String, dynamic>.from(order) : null;
      final dynamic pod = body['pod'];
      _pod = pod is Map ? Map<String, dynamic>.from(pod) : null;
    });
  }

  Future<void> _step(
    Future<DioApiResponse> Function() call,
    String done,
  ) async {
    setState(() => _busy = true);
    final DioApiResponse response = await call();
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          response.errorType == NetErrorType.none
              ? done
              : 'That did not go through. Retry.',
        ),
      ),
    );
    if (response.errorType == NetErrorType.none) await _load();
  }

  Future<void> _deliverSheet() async {
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
                'Complete delivery',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _clientRef,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.jhatkaFieldClientRef,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _temp,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(
                    context,
                  )!.jhatkaFieldDeliveredTemp,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _otp,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(
                    context,
                  )!.jhatkaFieldOtpOptional,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _receiver,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(
                    context,
                  )!.jhatkaFieldReceiverName,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _cod,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(
                    context,
                  )!.jhatkaFieldCodCollectedPaise,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final String? path = await JhatkaMedia().takeAndUploadPhoto();
                  if (!context.mounted) return;
                  if (path == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!.jhatkaPhotoNotAttached,
                        ),
                      ),
                    );
                    return;
                  }
                  _podPhotoUrl = path;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context)!.jhatkaProofPhotoAttached,
                      ),
                    ),
                  );
                },
                icon: Icon(
                  _podPhotoUrl != null
                      ? Icons.check_circle_outline
                      : Icons.photo_camera_outlined,
                ),
                label: Text(
                  _podPhotoUrl != null
                      ? 'Proof photo attached'
                      : 'Capture proof photo',
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  if (_clientRef.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(
                            context,
                          )!.jhatkaClientRefRequiredFirst,
                        ),
                      ),
                    );
                    return;
                  }
                  final String? path = await JhatkaMedia().takeAndUploadPhoto();
                  if (!context.mounted) return;
                  if (path == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!.jhatkaPhotoNotAttached,
                        ),
                      ),
                    );
                    return;
                  }
                  final DioApiResponse response = await _repository.capturePod(
                    deliveryId: widget.deliveryId,
                    clientRef: _clientRef.text.trim(),
                    photo: path,
                    deliveredTempC: double.tryParse(_temp.text.trim()),
                  );
                  if (!context.mounted) return;
                  if (response.errorType == NetErrorType.none) {
                    _podPhotoUrl = path;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!.jhatkaPodCaptured,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!.jhatkaPodCaptureFailed,
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.cloud_upload_outlined),
                label: Text(
                  AppLocalizations.of(context)!.jhatkaActionCapturePod,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    AppLocalizations.of(context)!.jhatkaActionDeliver,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (go != true || !mounted) return;
    if (_clientRef.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.jhatkaClientRefRequired),
        ),
      );
      return;
    }
    await _step(
      () => _repository.deliver(
        deliveryId: widget.deliveryId,
        clientRef: _clientRef.text.trim(),
        photo: _podPhotoUrl,
        deliveredTempC: double.tryParse(_temp.text.trim()),
        otp: _otp.text.trim().isEmpty ? null : _otp.text.trim(),
        receiverName: _receiver.text.trim().isEmpty
            ? null
            : _receiver.text.trim(),
        codCollected: num.tryParse(_cod.text.trim()),
      ),
      'Delivered.',
    );
    _podPhotoUrl = null;
  }

  Future<void> _failSheet() async {
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
                'Fail delivery — reason required',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'The reason is what the outlet reads. Failed is a '
                'first-class outcome, not an error to swallow.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _failReason,
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
                    AppLocalizations.of(context)!.jhatkaActionFailDelivery,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (go != true || !mounted) return;
    if (_failReason.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.jhatkaReasonRequired),
        ),
      );
      return;
    }
    await _step(
      () => _repository.fail(
        deliveryId: widget.deliveryId,
        reason: _failReason.text.trim(),
      ),
      'Marked failed.',
    );
  }

  Future<void> _collectSheet() async {
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
                'Record COD collection',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _collectAmount,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                style: const TextStyle(fontSize: 22),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(
                    context,
                  )!.jhatkaFieldAmountPaise,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    AppLocalizations.of(context)!.realEstateExecRecord,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (go != true || !mounted) return;
    final int? amount = int.tryParse(_collectAmount.text.trim());
    if (amount == null || amount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.jhatkaInvalidPaise),
        ),
      );
      return;
    }
    await _step(
      () => _repository.collectCod(
        deliveryId: widget.deliveryId,
        amountPaise: amount,
      ),
      'Collection recorded.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final String status = (_delivery['status'] ?? '').toString();
    return SectionListScreen(
      title: AppLocalizations.of(
        context,
      )!.jhatkaDeliveryNo((_delivery['deliveryNo'] ?? '—').toString()),
      icon: Icons.delivery_dining_outlined,
      onRefresh: _load,
      children: <Widget>[
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          EmptyState(
            title: AppLocalizations.of(context)!.jhatkaDeliveryUnavailable,
            message: _error!,
            icon: Icons.cloud_off_outlined,
          )
        else ...<Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  StatusChip(
                    label: status.isEmpty ? '—' : status,
                    color: status == 'failed'
                        ? AppColors.expired
                        : status == 'delivered'
                        ? AppColors.canInStore
                        : AppColors.grey,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.jhatkaCollectCollected(
                      jhatka_money.formatPaise(
                        (((_delivery['codCollectionAmount'] as num?) ?? 0))
                            .toInt(),
                      ),
                      jhatka_money.formatPaise(
                        (((_delivery['codCollectedAmount'] as num?) ?? 0))
                            .toInt(),
                      ),
                    ),
                  ),
                  if ((_delivery['receiverName'] ?? '').toString().isNotEmpty)
                    Text(
                      AppLocalizations.of(context)!.jhatkaReceiverLabel(
                        (_delivery['receiverName'] ?? '').toString(),
                      ),
                    ),
                  if (_order != null)
                    Text(
                      'Order ${(_order!['orderNo'] ?? '').toString()} · '
                      '${((_order!['items'] as List?) ?? const []).length} line(s)',
                    ),
                  if (_pod != null)
                    Text(
                      'POD at ${(_pod!['deliveredTempC'] ?? '?').toString()}°C'
                      '${_pod!['coldChainBreached'] == true ? ' — BREACH' : ''}',
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _actionsCard(status),
        ],
      ],
    );
  }

  Widget _actionsCard(String status) {
    Widget action(
      String label,
      Future<void> Function() onPressed, {
      bool primary = false,
    }) {
      if (primary) {
        return SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _busy ? null : onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(label, style: const TextStyle(fontSize: 18)),
            ),
          ),
        );
      }
      return SizedBox(
        width: double.infinity,
        child: FilledButton.tonal(
          onPressed: _busy ? null : onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Text(label),
          ),
        ),
      );
    }

    final List<Widget> buttons = <Widget>[];
    switch (status) {
      case 'assigned':
        buttons.add(
          action(
            'Accept',
            () =>
                _step(() => _repository.accept(widget.deliveryId), 'Accepted.'),
            primary: true,
          ),
        );
      case 'accepted':
        buttons.add(
          action(
            'Pick up',
            () => _step(
              () => _repository.pickup(widget.deliveryId),
              'Picked up.',
            ),
            primary: true,
          ),
        );
      case 'picked_up':
        buttons.add(
          action(
            'Out for delivery',
            () => _step(
              () => _repository.outForDelivery(widget.deliveryId),
              'Out for delivery.',
            ),
            primary: true,
          ),
        );
      case 'out_for_delivery':
      case 'arrived':
        buttons.add(action('Complete delivery', _deliverSheet, primary: true));
        buttons.add(const SizedBox(height: 8));
        buttons.add(action('Record COD collection', _collectSheet));
      case 'delivered':
        buttons.add(action('Record COD collection', _collectSheet));
      default:
        break;
    }
    if (status != 'delivered' && status != 'failed' && status != 'cancelled') {
      if (buttons.isNotEmpty) buttons.add(const SizedBox(height: 8));
      buttons.add(action('Fail delivery', _failSheet));
    }
    if (buttons.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(AppLocalizations.of(context)!.jhatkaNothingLeftToDo),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: buttons,
        ),
      ),
    );
  }
}
