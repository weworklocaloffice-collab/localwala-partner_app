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
import 'package:partner/app/modules/jhatka/partner/labels/jhatka_labels_repository.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

/// One pack label: what the customer reads, and what the inspector reads.
///
/// A fresh-meat pack is a statutory surface — product, weight, packed-on,
/// use-by, storage, FSSAI licence — plus the QR that resolves to the batch.
/// When a customer calls about a pack, this screen turns the phone call into
/// a batch lookup: the batch link is right there, not in another system.
class LabelDetailScreen extends StatefulWidget {
  const LabelDetailScreen({super.key, required this.labelId});

  final String labelId;

  @override
  State<LabelDetailScreen> createState() => _LabelDetailScreenState();
}

class _LabelDetailScreenState extends State<LabelDetailScreen> {
  final JhatkaLabelsRepository _repository = JhatkaLabelsRepository();

  bool _loading = true;
  String? _error;
  Map<String, dynamic> _label = <String, dynamic>{};

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
    final DioApiResponse response = await _repository.detail(widget.labelId);
    if (!mounted) return;
    if (response.errorType != NetErrorType.none) {
      setState(() {
        _loading = false;
        _error = 'Could not load the label.';
      });
      return;
    }
    final Map<String, dynamic> body = decodeBody(response);
    setState(() {
      _loading = false;
      _label = Map<String, dynamic>.from((body['label'] ?? {}) as Map);
    });
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? batch = (_label['batch'] as Map?)
        ?.cast<String, dynamic>();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(
            context,
          )!.jhatkaLabelNo((_label['labelNo'] ?? '').toString()),
        ),
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
                            '${_label['productName'] ?? 'Pack'}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          _row(
                            AppLocalizations.of(context)!.jhatkaFieldPack,
                            '${_label['packSize'] ?? ''}',
                          ),
                          _row(
                            AppLocalizations.of(context)!.jhatkaFieldNet,
                            '${_label['netQuantity'] ?? ''}',
                          ),
                          _row(
                            AppLocalizations.of(context)!.jhatkaFieldPackedOn,
                            '${_label['packedOn'] ?? ''}',
                          ),
                          _row(
                            AppLocalizations.of(context)!.jhatkaFieldUseBy,
                            '${_label['useBy'] ?? ''}',
                          ),
                          _row(
                            AppLocalizations.of(
                              context,
                            )!.realEstateCheckoutStatus,
                            '${_label['status'] ?? ''}',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Traceability',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          _row(
                            'Batch',
                            '${batch?['batchNo'] ?? '—'} (${batch?['status'] ?? ''})',
                          ),
                          _row('QR', '${_label['qrTraceBatch'] ?? '—'}'),
                          _row('FSSAI', '${_label['fssaiLicenceNo'] ?? '—'}'),
                          _row('Outlet', '${_label['outletName'] ?? ''}'),
                          _row('Order', '${_label['orderNo'] ?? ''}'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Customer-facing',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          _row(
                            'Storage',
                            '${_label['storageInstruction'] ?? ''}',
                          ),
                          _row('Care', '${_label['customerCare'] ?? ''}'),
                          if (((_label['allergens'] as List?) ??
                                  const <dynamic>[])
                              .isNotEmpty)
                            _row(
                              'Allergens',
                              ((_label['allergens'] as List?) ??
                                      const <dynamic>[])
                                  .join(', '),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
