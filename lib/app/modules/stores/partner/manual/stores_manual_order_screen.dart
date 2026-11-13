/*
 * WeWorkLocal
 * Hyperlocal Commerce & Service Platform
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

import 'package:partner/gen/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:partner/app/modules/stores/partner/orders/stores_order_detail_screen.dart';
import 'package:partner/app/modules/stores/stores_partner_repository.dart';
import 'package:partner/app/modules/stores/widgets/stores_ui_states.dart';
import 'package:partner/app/presentation/styles/theme.dart';

/// §10.3.1 — manual order entry, the counter-sale slice of F20.
///
/// V1 scope, deliberately small: search the catalogue, add variants with a quantity
/// stepper, and place a CASH order (COD). No tax invoice, no barcode scanning, no held
/// orders. Online mode is absent on purpose in V1: a `gateway`-mode order can only be
/// accepted after a gateway callback, which the partner workflow has no way to produce,
/// so a counter sale paid by card would sit in `created` forever. The COD ladder — cash
/// in the drawer, order walks the lifecycle, settle on reconcile — is the one path that
/// completes without a gateway.
///
/// The server's work: totals are recomputed from `StoreOutletProduct` and the COD gate
/// (`codMinOrder`/`codMaxOrder`) is applied there. The picker's line prices are the
/// chain's indicative `variant.price`; the placed order announces the outlet truth, and
/// any COD-limit refusal surfaces the server's code (e.g. `COD_MAX_ORDER_EXCEEDED`).
///
/// Capability gating (BR-32) comes from `GET /partner/capabilities`: when
/// `acceptNewOrders` is false the picker still opens — the partner can browse — but the
/// place button is disabled and a banner explains why, instead of letting the server
/// 403 with no explanation.
class StoresManualOrderScreen extends StatefulWidget {
  const StoresManualOrderScreen({super.key});

  @override
  State<StoresManualOrderScreen> createState() =>
      _StoresManualOrderScreenState();
}

class _ManualLine {
  _ManualLine({
    required this.product,
    required this.variant,
    required this.name,
    required this.price,
    this.quantity = 1,
  });

  final String product;
  final String variant;
  final String name;
  final num price;
  int quantity;

  num get lineTotal => price * quantity;
}

class _StoresManualOrderScreenState extends State<StoresManualOrderScreen> {
  StoresPartnerRepository? _repo;
  Object? _contextError;
  String? _blocked; // non-null means new orders are disabled (BR-32)
  Map<String, dynamic>? _deliveryConfig;
  final List<_ManualLine> _lines = <_ManualLine>[];
  String _query = '';
  bool _placing = false;
  bool _loading = true;
  bool _loadingMore = false;
  List<Map<String, dynamic>> _rows = <Map<String, dynamic>>[];
  Object? _listError;
  int _page = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _repo = StoresPartnerRepository();
    _loadContext();
    _loadProducts();
  }

  StoresPartnerRepository get _r => _repo ?? StoresPartnerRepository();

  Future<void> _loadContext() async {
    try {
      final Map<String, dynamic> caps = await _r.capabilities();
      final dynamic row = caps['capabilities'];
      final bool accept = row is Map ? row['acceptNewOrders'] == true : true;
      if (mounted) {
        setState(() {
          _blocked = accept ? null : l10nOf(context).storesManualEntryDisabled;
        });
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() => _contextError = error);
      }
      return;
    }
    try {
      final Map<String, dynamic> scope = await _r.scope();
      final String active = '${scope['activeOutletId'] ?? ''}';
      if (active.isNotEmpty) {
        final Map<String, dynamic> outlet = await _r.outletDetail(active);
        final dynamic config = outlet['deliveryConfig'];
        if (mounted) {
          setState(
            () => _deliveryConfig =
                config is Map<String, dynamic> ? config : null,
          );
        }
      }
    } on Object {
      // COD limits are display; their absence must not block the sale.
    }
  }

  Future<void> _loadProducts({bool more = false}) async {
    if (more) {
      setState(() => _loadingMore = true);
    } else {
      setState(() {
        _loading = true;
        _listError = null;
      });
    }
    try {
      final Map<String, dynamic> body =
          await _r.catalogueProducts(search: _query, page: _page, limit: 20);
      final dynamic raw = body['items'] ?? body['products'] ?? body['results'];
      final List<Map<String, dynamic>> fetched = raw is List
          ? raw.whereType<Map<String, dynamic>>().toList()
          : <Map<String, dynamic>>[];
      setState(() {
        _rows = more ? (_rows + fetched) : fetched;
        _totalPages = body['totalPages'] is int ? body['totalPages'] as int : 1;
        _page = _page + 1;
        _loading = false;
        _loadingMore = false;
      });
    } on Object catch (error) {
      setState(() {
        _listError = error;
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  void _search(String value) {
    setState(() {
      _query = value.trim();
      _rows = <Map<String, dynamic>>[];
      _page = 1;
      _totalPages = 1;
    });
    _loadProducts();
  }

  /// Only products the outlet can actually sell and has variant rows for reach the
  /// picker. A chain product with zero variants cannot be ordered at all — the server
  /// resolves `variantNotFound` and hearts it as a 404 — so it is filtered rather than
  /// discoverable by the partner as an error.
  List<Map<String, dynamic>> get _orderable => _rows.where((row) {
        final dynamic availability = row['availability'];
        if (availability is! Map) return false;
        final int variants =
            availability['variantCount'] is num ? availability['variantCount'] as int : 0;
        return availability['inStock'] == true && variants > 0;
      }).toList();

  num get _cartTotal =>
      _lines.fold<num>(0, (num sum, _ManualLine line) => sum + line.lineTotal);

  Future<void> _addVariant(Map<String, dynamic> product) async {
    final String productId = _idOf(product);
    if (productId.isEmpty) return;

    try {
      final Map<String, dynamic> detail = await _r.catalogueProduct(productId);
      final dynamic raw = detail['variants'] ?? const <dynamic>[];
      final List<Map<String, dynamic>> variants = raw is List
          ? raw.whereType<Map<String, dynamic>>().toList()
          : const <Map<String, dynamic>>[];

      if (!mounted) return;
      if (variants.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.storesMsgNoOrderableVariant)),
        );
        return;
      }

      String? nextVariantId;
      if (variants.length == 1) {
        nextVariantId = _idOf(variants.first);
      } else {
        nextVariantId = await showModalBottomSheet<String>(
          context: context,
          builder: (BuildContext sheet) => SafeArea(
            child: ListView(
              shrinkWrap: true,
              children: <Widget>[
                for (final Map<String, dynamic> variant in variants)
                  ListTile(
                    title: Text('${variant['name'] ?? _idOf(variant)}'),
                    subtitle: Text(
                      '${_money(variant['price'])}'
                      '${variant['sku'] != null ? ' · ${variant['sku']}' : ''}',
                    ),
                    onTap: () => Navigator.of(sheet).pop(_idOf(variant)),
                  ),
              ],
            ),
          ),
        );
      }
      if (nextVariantId == null || nextVariantId.isEmpty) return;

      final Map<String, dynamic>? chosen = variants.firstWhere(
        (Map<String, dynamic> v) => _idOf(v) == nextVariantId,
        orElse: () => variants.first,
      );

      final String variantKey = nextVariantId;
      final int existing =
          _lines.indexWhere((_ManualLine line) => line.variant == variantKey);
      setState(() {
        if (existing >= 0) {
          _lines[existing].quantity += 1;
        } else {
          _lines.add(
            _ManualLine(
              product: productId,
              variant: variantKey,
              name: '${chosen?['name'] ?? product['name'] ?? ''}',
              price: (chosen?['price'] as num?) ?? 0,
            ),
          );
        }
      });
    } on StoresApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  Future<void> _place() async {
    if (_lines.isEmpty || _placing || _blocked != null) return;
    setState(() => _placing = true);

    try {
      final Map<String, dynamic> response = await _r.createManualOrder(
        items: <Map<String, dynamic>>[
          for (final _ManualLine line in _lines)
            <String, dynamic>{
              'product': line.product,
              'variant': line.variant,
              'quantity': line.quantity,
              'name': line.name,
            },
        ],
        paymentMode: 'cod',
      );
      final dynamic raw = response['order'] ?? response;
      final String? orderId = raw is Map<String, dynamic> ? _idOf(raw) : null;
      final String orderNo = raw is Map ? '${raw['orderNo'] ?? '—'}' : '—';
      final String total = raw is Map ? _money(raw['grandTotal']) : '0.00';

      if (!mounted) return;
      setState(() {
        _placing = false;
        _lines.clear();
      });
      await showDialog<void>(
        context: context,
        builder: (BuildContext dialog) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.storesTitleCounterSalePlaced),
          content: Text(AppLocalizations.of(context)!.storesMsgCashDue(orderNo, total)),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialog).pop(),
              child: Text(AppLocalizations.of(context)!.storesActionNewSale),
            ),
            if (orderId != null)
              FilledButton(
                onPressed: () {
                  Navigator.of(dialog).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          StoresOrderDetailScreen(orderId: orderId),
                    ),
                  );
                },
                child: Text(AppLocalizations.of(context)!.storesActionWorkOrder),
              ),
          ],
        ),
      );
    } on StoresApiException catch (error) {
      if (!mounted) return;
      setState(() => _placing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.message + (error.code != null ? ' (${error.code})' : ''),
          ),
        ),
      );
    } catch (_) {
      if (mounted) setState(() => _placing = false);
    }
  }

  String get _codBanner {
    final Map<String, dynamic>? cfg = _deliveryConfig;
    if (cfg == null) return '';
    if (cfg['codEnabled'] == false) {
      return 'Cash on delivery is disabled at this outlet.';
    }
    final num min = cfg['codMinOrder'] is num ? cfg['codMinOrder'] as num : 0;
    final num max = cfg['codMaxOrder'] is num ? cfg['codMaxOrder'] as num : 0;
    final num floor =
        cfg['minimumOrder'] is num ? cfg['minimumOrder'] as num : 0;
    final String parts = <String>[
      if (min > 0) 'COD min ₹${min.toStringAsFixed(2)}',
      if (max > 0) 'COD max ₹${max.toStringAsFixed(2)}',
      if (floor > 0) 'Min order ₹${floor.toStringAsFixed(2)}',
    ].join(' · ');
    return parts;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.storesTitleManualOrder)),
      body: Column(
        children: <Widget>[
          if (_contextError != null)
            Material(
              color: AppColors.expired.withValues(alpha: 0.12),
              child: ListTile(
                dense: true,
                leading:
                    const Icon(Icons.error_outline, color: AppColors.expired),
                title: Text(_contextError.toString()),
              ),
            )
          else if (_blocked != null)
            Material(
              color: AppColors.expirySoon.withValues(alpha: 0.12),
              child: ListTile(
                dense: true,
                leading: const Icon(
                  Icons.warning_amber_outlined,
                  color: AppColors.expirySoon,
                ),
                title: Text(_blocked!),
              ),
            )
          else if (_codBanner.isNotEmpty)
            Material(
              color: AppColors.expirySoon.withValues(alpha: 0.08),
              child: ListTile(
                dense: true,
                leading: const Icon(
                  Icons.payments_outlined,
                  color: AppColors.expirySoon,
                ),
                title: Text(_codBanner,
                    style: Theme.of(context).textTheme.bodySmall),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.storesFieldSearchProducts,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: _search,
            ),
          ),
          Expanded(child: _list(context)),
          SafeArea(child: _cartBar(context)),
        ],
      ),
    );
  }

  Widget _list(BuildContext context) {
    if (_loading && _rows.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_listError != null && _rows.isEmpty) {
      return StoresErrorView(error: _listError, onRetry: () => _loadProducts());
    }
    final List<Map<String, dynamic>> orderable = _orderable;
    if (orderable.isEmpty) {
      return StoresEmptyView(
        message: _rows.isEmpty
            ? 'No products match.'
            : 'No in-stock products match. Stock rows and variants decide what can be sold.',
        icon: Icons.storefront_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _rows = <Map<String, dynamic>>[];
          _page = 1;
          _totalPages = 1;
        });
        await _loadProducts();
      },
      child: ListView.builder(
        itemCount: orderable.length + (_page < _totalPages ? 1 : 0),
        itemBuilder: (BuildContext context, int index) {
          if (index >= orderable.length) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: _loadingMore
                    ? const CircularProgressIndicator()
                    : OutlinedButton(
                        onPressed: () => _loadProducts(more: true),
                        child: Text(AppLocalizations.of(context)!.storesLoadMore),
                      ),
              ),
            );
          }
          final Map<String, dynamic> row = orderable[index];
          final dynamic availability = row['availability'];
          return ListTile(
            leading: const Icon(Icons.storefront_outlined),
            title: Text('${row['name'] ?? ''}'),
            subtitle: Text(
              '${availability is Map ? availability['availableQty'] ?? 0 : 0} in stock · '
              '${availability is Map ? availability['variantCount'] ?? 0 : 0} variants',
            ),
            trailing: const Icon(Icons.add),
            onTap: () => _addVariant(row),
          );
        },
      ),
    );
  }

  Widget _cartBar(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (_lines.isEmpty)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(AppLocalizations.of(context)!.storesMsgCashSaleHint),
              )
            else
              for (final _ManualLine line in _lines)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text('${line.name} ×${line.quantity}'),
                  subtitle: Text(
                    '${line.price.toStringAsFixed(2)} · line ${line.lineTotal.toStringAsFixed(2)}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () => setState(() {
                          if (line.quantity > 1) line.quantity -= 1;
                        }),
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () => setState(() => line.quantity += 1),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () => setState(() => _lines.remove(line)),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ),
            const Divider(height: 1),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Cash due ₹${_cartTotal.toStringAsFixed(2)} (outlet totals apply)',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                FilledButton(
                  onPressed:
                      (_lines.isEmpty || _placing || _blocked != null)
                          ? null
                          : _place,
                  child: _placing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10nOf(context).storesActionPlaceOrder),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

AppLocalizations l10nOf(BuildContext context) => AppLocalizations.of(context)!;

String _idOf(dynamic value) {
  if (value is Map) {
    return value['_id']?.toString() ?? value['id']?.toString() ?? '';
  }
  return value?.toString() ?? '';
}

String _money(dynamic value) {
  if (value is num) return value.toStringAsFixed(2);
  if (value == null) return '0.00';
  return '$value';
}
