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
import 'package:partner/app/core/media/evidence_media.dart';
import 'package:partner/app/modules/jhatka/partner/weighing/jhatka_money.dart'
    as jhatka_money;
import 'package:partner/app/modules/jhatka/partner/weighing/jhatka_weigh_repository.dart';
import 'package:partner/app/presentation/styles/theme.dart';
import 'package:partner/app/presentation/styles/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

/// The weighing screen — the highest-consequence UI in the vertical.
///
/// One row per WEIGHT line with live arithmetic as the operator types, so the
/// number about to be confirmed is the number the customer will see. The
/// server is authoritative (tolerance bands, hard caps, refunds); this screen
/// previews with the same floor math and refuses locally only what VW-01
/// forbids — charging above the estimate.
///
/// Operability: big targets, grams keypad, one hand, wet glove.
class WeighScreen extends StatefulWidget {
  const WeighScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<WeighScreen> createState() => _WeighScreenState();
}

class _WeighLine {
  _WeighLine({required this.item});

  final Map<String, dynamic> item;
  final TextEditingController actual = TextEditingController();
}

class _WeighScreenState extends State<WeighScreen> {
  final JhatkaWeighRepository _repository = JhatkaWeighRepository();

  bool _loading = true;
  String? _error;
  List<_WeighLine> _lines = <_WeighLine>[];
  bool _confirming = false;
  Map<String, dynamic>? _result;
  bool _replayed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final _WeighLine l in _lines) {
      l.actual.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    final DioApiResponse response = await _repository.orderDetail(
      widget.orderId,
    );
    if (!mounted) return;
    if (response.errorType != NetErrorType.none) {
      setState(() {
        _loading = false;
        _error = 'Could not load order.';
      });
      return;
    }
    final Map<String, dynamic> body = decodeBody(response);
    final Map<String, dynamic> order = Map<String, dynamic>.from(
      (body['order'] ?? body) as Map,
    );
    final List<dynamic> items = (order['items'] as List? ?? const <dynamic>[])
        .where((dynamic raw) {
          final Map<String, dynamic> item = Map<String, dynamic>.from(
            raw as Map,
          );
          return (item['measurementMode'] ?? 'WEIGHT') == 'WEIGHT';
        })
        .toList();
    setState(() {
      _loading = false;
      _lines = items
          .map(
            (dynamic raw) =>
                _WeighLine(item: Map<String, dynamic>.from(raw as Map)),
          )
          .toList();
    });
  }

  int _requestedGrams(Map<String, dynamic> item) {
    final dynamic q = item['requestedQuantity'];
    if (q is! Map) return 0;
    return jhatka_money.toGrams(
          (q['value'] as num?) ?? 0,
          (q['unit'] ?? 'GRAM').toString(),
        ) ??
        0;
  }

  int _unitPricePaise(Map<String, dynamic> item) {
    return jhatka_money.rupeesToPaise((item['unitPrice'] as num?) ?? 0);
  }

  int? _actualGrams(_WeighLine line) {
    final num? value = num.tryParse(line.actual.text.trim());
    if (value == null || value <= 0) return null;
    // The screen weighs in grams; the server normalises either way.
    return value.round();
  }

  /// Local preview. Server figures win on confirm.
  Map<String, int> _preview(_WeighLine line) {
    final int requested = _requestedGrams(line.item);
    final int? actual = _actualGrams(line);
    if (actual == null) {
      return <String, int>{'estimated': 0, 'final': 0, 'delta': 0};
    }
    final int unitPrice = _unitPricePaise(line.item);
    final int estimated = jhatka_money.estimatedLinePaise(
      requestedGrams: requested,
      unitPricePaise: unitPrice,
    );
    final int final_ = jhatka_money.estimatedLinePaise(
      requestedGrams: actual,
      unitPricePaise: unitPrice,
    );
    return <String, int>{
      'estimated': estimated,
      'final': final_ - estimated > 0 ? estimated : final_,
      'delta': final_ - estimated,
    };
  }

  bool get _allEntered =>
      _lines.isNotEmpty &&
      _lines.every((_WeighLine l) => _actualGrams(l) != null);

  /// Bag photo uploaded through the shared endpoint. Confirmations above the
  /// evidence threshold are refused without it — the photo is taken here so
  /// the operator is never stuck at the confirm button.
  String? _evidencePhotoUrl;
  bool _uploadingPhoto = false;

  Future<void> _attachPhoto() async {
    setState(() => _uploadingPhoto = true);
    final String? path = await EvidenceMedia().takeAndUploadPhoto();
    if (!mounted) return;
    setState(() => _uploadingPhoto = false);
    if (path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.jhatkaPhotoNotAttached),
        ),
      );
      return;
    }
    setState(() => _evidencePhotoUrl = path);
  }

  Future<void> _confirm({String? overrideReason}) async {
    setState(() => _confirming = true);
    final DioApiResponse response = await _repository.weigh(
      orderId: widget.orderId,
      lines: _lines
          .map(
            (line) => WeighLineInput(
              orderItem: (line.item['_id'] ?? line.item['id']).toString(),
              actualValue: num.parse(line.actual.text.trim()),
              actualUnit: 'GRAM',
            ),
          )
          .toList(),
      evidence: _evidencePhotoUrl != null
          ? <String, dynamic>{'photoUrl': _evidencePhotoUrl}
          : null,
      overrideReason: overrideReason,
    );
    if (!mounted) return;
    setState(() => _confirming = false);
    if (response.errorType == NetErrorType.none) {
      final Map<String, dynamic> body = decodeBody(response);
      setState(() {
        _result = body;
        _replayed = body['replayed'] == true;
      });
      await _load();
      return;
    }
    String code = '';
    try {
      final Map<String, dynamic> err = decodeBody(response);
      code = (err['code'] ?? '').toString();
    } catch (_) {
      code = '';
    }
    if (code == 'WEIGHT_OVERRIDE_REQUIRED') {
      if (!mounted) return;
      await _overrideSheet();
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.jhatkaWeighingFailed),
      ),
    );
  }

  Future<void> _overrideSheet() async {
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
              const Text(
                'Over the hard cap — manager override required',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'The overage is absorbed, never charged. The reason is written '
                'to a variance flag against this outlet.',
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
                    AppLocalizations.of(context)!.jhatkaActionManagerOverride,
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
    if (go == true && text.isNotEmpty && mounted) {
      await _confirm(overrideReason: text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SectionListScreen(
      title: AppLocalizations.of(context)!.jhatkaActionWeighOrder,
      icon: Icons.scale_outlined,
      onRefresh: _load,
      children: <Widget>[
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          EmptyState(
            title: AppLocalizations.of(context)!.jhatkaOrderUnavailable,
            message: _error!,
            icon: Icons.cloud_off_outlined,
          )
        else ...<Widget>[
          if (_replayed)
            Card(
              child: ListTile(
                leading: Icon(Icons.replay_outlined),
                title: Text(AppLocalizations.of(context)!.jhatkaAlreadyWeighed),
              ),
            ),
          ..._lines.map(_lineCard),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _uploadingPhoto ? null : _attachPhoto,
              icon: _uploadingPhoto
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      _evidencePhotoUrl != null
                          ? Icons.check_circle_outline
                          : Icons.photo_camera_outlined,
                    ),
              label: Text(
                _evidencePhotoUrl != null
                    ? 'Bag photo attached'
                    : 'Attach bag photo (required over Rs 500)',
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _allEntered && !_confirming ? () => _confirm() : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: _confirming
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Confirm weights',
                        style: TextStyle(fontSize: 18),
                      ),
              ),
            ),
          ),
          if (_result != null) _resultCard(),
        ],
      ],
    );
  }

  Widget _lineCard(_WeighLine line) {
    final Map<String, dynamic> item = line.item;
    final Map<String, int> preview = _preview(line);
    final String priceBasis = (item['priceBasis'] ?? '').toString();
    final String rateSuffix = priceBasis.isEmpty ? '' : ' / $priceBasis';
    final int delta = preview['delta']!;
    final String deltaText = delta == 0
        ? 'No adjustment'
        : delta > 0
        ? '+${jhatka_money.formatPaise(delta)} absorbed by LocalWala'
        : '${jhatka_money.formatPaise(-delta)} auto-refunded';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              (item['name'] ?? item['sku'] ?? 'Line').toString(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Requested ${_requestedGrams(item)} g · '
              '${jhatka_money.formatRupees((item['unitPrice'] as num?) ?? 0)}$rateSuffix',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: line.actual,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: false,
                signed: false,
              ),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
              style: const TextStyle(fontSize: 28),
              decoration: InputDecoration(
                labelText: AppLocalizations.of(
                  context,
                )!.jhatkaFieldActualWeightGrams,
                border: OutlineInputBorder(),
                suffixText: 'g',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Text(
              'Estimated ${jhatka_money.formatPaise(preview['estimated']!)}',
            ),
            Text(
              'Customer charged ${jhatka_money.formatPaise(preview['final']!)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              deltaText,
              style: TextStyle(
                color: delta == 0 ? AppColors.grey : AppColors.expirySoon,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultCard() {
    final Map<String, dynamic> result = _result!;
    final Map<String, dynamic> order =
        _result!.containsKey('order') && result['order'] is Map
        ? Map<String, dynamic>.from(result['order'] as Map)
        : <String, dynamic>{};
    final List<dynamic> confirmations =
        (result['confirmations'] as List?) ?? const <dynamic>[];
    int shortfall = 0;
    for (final dynamic raw in confirmations) {
      final Map<String, dynamic> c = Map<String, dynamic>.from(raw as Map);
      shortfall += ((c['stockShortfallGrams'] as num?) ?? 0).toInt();
    }
    final num codRupees =
        (order['codAmount'] as num?) ??
        (result['codCollectable'] != null
            ? (result['codCollectable'] as num) / 100
            : 0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              'Confirmed',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Customer pays ${jhatka_money.formatRupees((order['finalTotal'] as num?) ?? 0)}',
            ),
            Text('Rider collects ${jhatka_money.formatRupees(codRupees)}'),
            if (shortfall > 0)
              Text(
                'Ledger short by $shortfall g — recorded, weighing stands',
                style: const TextStyle(color: AppColors.expired),
              ),
          ],
        ),
      ),
    );
  }
}
