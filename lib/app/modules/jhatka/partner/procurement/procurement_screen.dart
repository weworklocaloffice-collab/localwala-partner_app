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
import 'package:partner/app/modules/jhatka/partner/procurement/jhatka_procurement_repository.dart';
import 'package:partner/app/modules/jhatka/partner/stock/receipt_create_screen.dart';
import 'package:partner/app/presentation/styles/theme.dart';
import 'package:partner/app/presentation/styles/widgets.dart';
import 'package:flutter/material.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

/// Suppliers, purchase orders and receipts for the outlet.
///
/// Draft POs are placed from here; draft receipts are posted from here.
/// Posting is the point of no return for stock — batches, ledger, allocations
/// and the PO advance commit together — so a refusal reloads state rather
/// than optimistically flipping the row.
class ProcurementScreen extends StatefulWidget {
  const ProcurementScreen({super.key});

  @override
  State<ProcurementScreen> createState() => _ProcurementScreenState();
}

class _ProcurementScreenState extends State<ProcurementScreen> {
  final JhatkaProcurementRepository _repository = JhatkaProcurementRepository();

  bool _loading = true;
  String? _error;
  List<dynamic> _suppliers = const <dynamic>[];
  List<dynamic> _orders = const <dynamic>[];
  List<dynamic> _receipts = const <dynamic>[];
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
    final List<DioApiResponse> results = await Future.wait(
      <Future<DioApiResponse>>[
        _repository.suppliers(),
        _repository.purchaseOrders(),
        _repository.receipts(),
      ],
    );
    if (!mounted) return;
    if (results.any((DioApiResponse r) => r.errorType != NetErrorType.none)) {
      setState(() {
        _loading = false;
        _error = 'Could not load procurement.';
      });
      return;
    }
    setState(() {
      _loading = false;
      _suppliers =
          (decodeBody(results[0])['suppliers'] as List?) ?? const <dynamic>[];
      _orders =
          (decodeBody(results[1])['purchaseOrders'] as List?) ??
          const <dynamic>[];
      _receipts =
          (decodeBody(results[2])['receipts'] as List?) ?? const <dynamic>[];
    });
  }

  Future<void> _act(String key, Future<DioApiResponse> Function() call) async {
    setState(() => _actingOn = key);
    final DioApiResponse response = await call();
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
      title: AppLocalizations.of(context)!.jhatkaNavProcurement,
      icon: Icons.local_shipping_outlined,
      onRefresh: _load,
      children: <Widget>[
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          EmptyState(
            title: AppLocalizations.of(context)!.jhatkaProcurementUnavailable,
            message: _error!,
            icon: Icons.cloud_off_outlined,
          )
        else ...<Widget>[
          _sectionTitle('Purchase orders (${_orders.length})'),
          ..._orders.map(_orderTile),
          const SizedBox(height: 12),
          _sectionTitle('Receipts (${_receipts.length})'),
          ..._receipts.map(_receiptTile),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: () async {
                final bool? created = await Navigator.of(context).push<bool>(
                  MaterialPageRoute<bool>(
                    builder: (_) => ReceiptCreateScreen(
                      suppliers: _suppliers
                          .map((dynamic raw) {
                            final Map<String, dynamic> s =
                                Map<String, dynamic>.from(raw as Map);
                            return <String, String>{
                              'id': (s['id'] ?? s['_id'] ?? '').toString(),
                              'name': (s['name'] ?? '').toString(),
                            };
                          })
                          .where((Map<String, String> s) => s['id']!.isNotEmpty)
                          .toList(),
                      purchaseOrders: _orders
                          .map((dynamic raw) {
                            final Map<String, dynamic> o =
                                Map<String, dynamic>.from(raw as Map);
                            return <String, String>{
                              'id': (o['id'] ?? o['_id'] ?? '').toString(),
                              'label':
                                  'PO ${(o['poNo'] ?? '').toString()} · ${(o['status'] ?? '').toString()}',
                            };
                          })
                          .where((Map<String, String> o) => o['id']!.isNotEmpty)
                          .toList(),
                    ),
                  ),
                );
                if (created == true && mounted) await _load();
              },
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  AppLocalizations.of(context)!.jhatkaActionNewReceipt,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _sectionTitle('Suppliers (${_suppliers.length})'),
          ..._suppliers.map(_supplierTile),
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

  Widget _busy() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _orderTile(dynamic raw) {
    final Map<String, dynamic> po = Map<String, dynamic>.from(raw as Map);
    final String id = (po['id'] ?? po['_id'] ?? '').toString();
    final String status = (po['status'] ?? '').toString();
    final bool busy = _actingOn == 'po:$id';
    return Card(
      child: ListTile(
        title: Text('PO ${po['poNo'] ?? '—'}'),
        subtitle: Text(status.isEmpty ? '—' : status),
        trailing: busy
            ? _busy()
            : status == 'draft'
            ? TextButton(
                onPressed: () =>
                    _act('po:$id', () => _repository.placeOrder(id)),
                child: Text(AppLocalizations.of(context)!.jhatkaActionPlace),
              )
            : StatusChip(label: status, color: AppColors.grey),
      ),
    );
  }

  Widget _receiptTile(dynamic raw) {
    final Map<String, dynamic> receipt = Map<String, dynamic>.from(raw as Map);
    final String id = (receipt['id'] ?? receipt['_id'] ?? '').toString();
    final String status = (receipt['status'] ?? '').toString();
    final bool busy = _actingOn == 'rc:$id';
    return Card(
      child: ListTile(
        title: Text('Receipt ${receipt['receiptNo'] ?? '—'}'),
        subtitle: Text('${receipt['qualityStatus'] ?? ''} · $status'.trim()),
        trailing: busy
            ? _busy()
            : status == 'draft'
            ? TextButton(
                onPressed: () =>
                    _act('rc:$id', () => _repository.postReceipt(id)),
                child: Text(AppLocalizations.of(context)!.jhatkaActionPost),
              )
            : StatusChip(label: status, color: AppColors.grey),
      ),
    );
  }

  Widget _supplierTile(dynamic raw) {
    final Map<String, dynamic> supplier = Map<String, dynamic>.from(raw as Map);
    return Card(
      child: ListTile(
        title: Text((supplier['name'] ?? '—').toString()),
        subtitle: Text((supplier['code'] ?? '').toString()),
        trailing: StatusChip(
          label: (supplier['status'] ?? '').toString(),
          color: AppColors.grey,
        ),
      ),
    );
  }
}
