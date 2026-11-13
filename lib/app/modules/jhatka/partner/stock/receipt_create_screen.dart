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
import 'package:partner/app/modules/jhatka/partner/catalogue/jhatka_catalogue_repository.dart';
import 'package:partner/app/modules/jhatka/partner/stock/jhatka_stock_repository.dart';
import 'package:partner/app/presentation/styles/widgets.dart';
import 'package:flutter/material.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

/// Draft a procurement receipt.
///
/// Quality is evaluated server side per line; stock moves only when the
/// receipt is POSTED, so a delivery can be inspected before it is counted.
/// This screen drafts — posting stays on the procurement list, where the
/// all-or-nothing consequence is visible.
class ReceiptCreateScreen extends StatefulWidget {
  const ReceiptCreateScreen({
    super.key,
    required this.suppliers,
    required this.purchaseOrders,
  });

  /// Each: `id`, `name`.
  final List<Map<String, String>> suppliers;

  /// Each: `id`, `label`.
  final List<Map<String, String>> purchaseOrders;

  @override
  State<ReceiptCreateScreen> createState() => _ReceiptCreateScreenState();
}

class _ReceiptLine {
  final TextEditingController rawSku = TextEditingController();
  final TextEditingController qty = TextEditingController();
  final TextEditingController unitPrice = TextEditingController();
  String? productId;
  String unit = 'KG';
}

class _ReceiptCreateScreenState extends State<ReceiptCreateScreen> {
  final JhatkaStockRepository _repository = JhatkaStockRepository();
  final JhatkaCatalogueRepository _catalogue = JhatkaCatalogueRepository();

  List<Map<String, String>> _products = const <Map<String, String>>[];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final DioApiResponse response = await _catalogue.products();
    if (!mounted || response.errorType != NetErrorType.none) return;
    final Map<String, dynamic> body = decodeBody(response);
    final List<dynamic> products =
        (body['products'] as List?) ?? const <dynamic>[];
    setState(() {
      _products = products
          .map((dynamic raw) {
            final Map<String, dynamic> p = Map<String, dynamic>.from(
              raw as Map,
            );
            return <String, String>{
              'id': (p['id'] ?? p['_id'] ?? '').toString(),
              'label': (p['name'] ?? '').toString(),
            };
          })
          .where((Map<String, String> p) => p['id']!.isNotEmpty)
          .toList();
    });
  }

  String? _supplierId;
  String? _purchaseOrderId;
  final TextEditingController _invoiceRef = TextEditingController();
  final TextEditingController _vehicleNo = TextEditingController();
  final TextEditingController _note = TextEditingController();
  final List<_ReceiptLine> _lines = <_ReceiptLine>[_ReceiptLine()];
  bool _busy = false;

  static const List<String> _units = <String>[
    'GRAM',
    'KG',
    'PIECE',
    'DOZEN',
    'TIER',
  ];

  @override
  void dispose() {
    _invoiceRef.dispose();
    _vehicleNo.dispose();
    _note.dispose();
    for (final _ReceiptLine l in _lines) {
      l.rawSku.dispose();
      l.qty.dispose();
      l.unitPrice.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_supplierId == null) {
      _say('Pick the supplier first.');
      return;
    }
    final List<Map<String, dynamic>> lines = <Map<String, dynamic>>[];
    for (final _ReceiptLine line in _lines) {
      if (line.productId == null ||
          line.rawSku.text.trim().isEmpty ||
          line.qty.text.trim().isEmpty ||
          line.unitPrice.text.trim().isEmpty) {
        continue;
      }
      final num? qty = num.tryParse(line.qty.text.trim());
      final num? price = num.tryParse(line.unitPrice.text.trim());
      if (qty == null || qty <= 0 || price == null || price < 0) continue;
      lines.add(<String, dynamic>{
        'product': line.productId,
        'rawSku': line.rawSku.text.trim(),
        'receivedQty': <String, dynamic>{'value': qty, 'unit': line.unit},
        'unitPrice': price,
      });
    }
    if (lines.isEmpty) {
      _say('Add at least one complete line.');
      return;
    }
    setState(() => _busy = true);
    final DioApiResponse response = await _repository.createReceipt(
      purchaseOrder: _purchaseOrderId,
      supplier: _supplierId!,
      supplierInvoiceRef: _invoiceRef.text.trim().isEmpty
          ? null
          : _invoiceRef.text.trim(),
      lines: lines,
      vehicleNo: _vehicleNo.text.trim().isEmpty ? null : _vehicleNo.text.trim(),
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (response.errorType == NetErrorType.none) {
      Navigator.of(context).pop(true);
    } else {
      _say('Drafting failed. Check the lines and retry.');
    }
  }

  void _say(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return SectionListScreen(
      title: AppLocalizations.of(context)!.jhatkaActionNewReceipt,
      icon: Icons.local_shipping_outlined,
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                DropdownButtonFormField<String>(
                  initialValue: _supplierId,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(
                      context,
                    )!.jhatkaFieldSupplier,
                    border: OutlineInputBorder(),
                  ),
                  items: widget.suppliers
                      .map(
                        (Map<String, String> s) => DropdownMenuItem<String>(
                          value: s['id'],
                          child: Text(
                            s['name'] ?? '',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (String? v) => setState(() => _supplierId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _purchaseOrderId,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(
                      context,
                    )!.jhatkaFieldPoOptional,
                    border: OutlineInputBorder(),
                  ),
                  items: <DropdownMenuItem<String>>[
                    DropdownMenuItem<String>(
                      child: Text(
                        AppLocalizations.of(context)!.jhatkaWalkInNoPo,
                      ),
                    ),
                    ...widget.purchaseOrders.map(
                      (Map<String, String> p) => DropdownMenuItem<String>(
                        value: p['id'],
                        child: Text(
                          p['label'] ?? '',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (String? v) =>
                      setState(() => _purchaseOrderId = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _invoiceRef,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(
                      context,
                    )!.jhatkaFieldSupplierInvoiceRef,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _vehicleNo,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(
                      context,
                    )!.jhatkaFieldVehicleNo,
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ..._lines.asMap().entries.map((MapEntry<int, _ReceiptLine> entry) {
          return _lineCard(entry.key, entry.value);
        }),
        TextButton.icon(
          onPressed: () => setState(() => _lines.add(_ReceiptLine())),
          icon: const Icon(Icons.add_outlined),
          label: Text(AppLocalizations.of(context)!.jhatkaActionAddLine),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _note,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.jhatkaFieldNoteOptional,
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Draft receipt', style: TextStyle(fontSize: 18)),
          ),
        ),
      ],
    );
  }

  Widget _lineCard(int index, _ReceiptLine line) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Line ${index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (_lines.length > 1)
                  IconButton(
                    tooltip: AppLocalizations.of(
                      context,
                    )!.jhatkaActionRemoveLine,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => setState(() {
                      line.rawSku.dispose();
                      line.qty.dispose();
                      line.unitPrice.dispose();
                      _lines.removeAt(index);
                    }),
                  ),
              ],
            ),
            DropdownButtonFormField<String>(
              initialValue: line.productId,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.storesFallbackProduct,
                border: OutlineInputBorder(),
              ),
              items: _products
                  .map(
                    (Map<String, String> p) => DropdownMenuItem<String>(
                      value: p['id'],
                      child: Text(
                        p['label'] ?? '',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (String? v) => setState(() => line.productId = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: line.rawSku,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.jhatkaFieldRawSku,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: line.qty,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(
                        context,
                      )!.jhatkaFieldReceivedQty,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: line.unit,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.jhatkaFieldUnit,
                      border: OutlineInputBorder(),
                    ),
                    items: _units
                        .map(
                          (String u) => DropdownMenuItem<String>(
                            value: u,
                            child: Text(u),
                          ),
                        )
                        .toList(),
                    onChanged: (String? v) {
                      if (v != null) setState(() => line.unit = v);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: line.unitPrice,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: AppLocalizations.of(
                  context,
                )!.jhatkaFieldUnitPriceFrozen,
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
