/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright Â© 2026 WeWorkLocal.
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
import 'package:partner/app/core/repositories/partner_repository.dart';
import 'package:partner/app/env.dart';
import 'package:partner/app/modules/dairy/partner/inventory/partner_product_create_view.dart';
import 'package:partner/app/modules/dairy/partner/inventory/partner_product_edit_view.dart';
import 'package:partner/app/presentation/styles/theme.dart';
import 'package:partner/app/presentation/styles/widgets.dart';
import 'package:partner/gen/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Finished-goods stock and product setup for the outlet.
///
/// Stock is backed by `GET /partner/skus/list`; product setup creates an
/// outlet-owned product and its first SKU using the Admin-managed taxonomy.
/// These partner endpoints derive outlet ownership from the access token.
///
/// This screen previously rendered five hardcoded rows — "Cow Milk 42",
/// "Full Cream Milk 18" and so on. That was worse than an empty screen: the
/// figures were plausible enough to be believed, and a partner taking stock
/// decisions against invented quantities is a real hazard. Invented rows are now
/// gone; the list is either real stock or an explicit empty state.
class PartnerInventoryScreen extends StatefulWidget {
  const PartnerInventoryScreen({super.key, this.partnerRepository});

  final PartnerRepository? partnerRepository;

  @override
  State<PartnerInventoryScreen> createState() => _PartnerInventoryScreenState();
}

class _PartnerInventoryScreenState extends State<PartnerInventoryScreen> {
  late final PartnerRepository _partnerRepository =
      widget.partnerRepository ?? PartnerRepository();

  bool _loading = true;
  String? _error;
  List<dynamic> _skus = const <dynamic>[];
  String _searchQuery = '';
  _InventoryFilter _filter = _InventoryFilter.all;

  int _quantity(Map<String, dynamic> sku) =>
      int.tryParse(sku['availableQty']?.toString() ?? '') ?? 0;

  bool _isAvailable(Map<String, dynamic> sku) =>
      sku['status'] != false && sku['inStock'] == true && _quantity(sku) > 0;

  List<Map<String, dynamic>> _visibleSkus() {
    final String query = _searchQuery.trim().toLowerCase();
    return _skus
        .whereType<Map>()
        .map((Map row) => Map<String, dynamic>.from(row))
        .where((Map<String, dynamic> sku) {
          final bool available = _isAvailable(sku);
          if (_filter == _InventoryFilter.inStock && !available) return false;
          if (_filter == _InventoryFilter.outOfStock && available) return false;
          if (query.isEmpty) return true;
          final String searchable =
              '${sku['name'] ?? ''} ${_packSize(sku)} ${sku['price'] ?? ''}'
                  .toLowerCase();
          return searchable.contains(query);
        })
        .toList();
  }

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

    final DioApiResponse response = await _partnerRepository.inventory();

    if (!mounted) return;

    if (response.errorType != NetErrorType.none) {
      setState(() {
        _loading = false;
        _error = AppLocalizations.of(context)!.couldNotLoadStock;
      });
      return;
    }
    final Map<String, dynamic> body = decodeBody(response);
    setState(() {
      _loading = false;
      _skus = (body['skus'] as List?) ?? const <dynamic>[];
    });
  }

  String _packSize(Map<String, dynamic> sku) {
    final Map<String, dynamic> pack =
        Map<String, dynamic>.from((sku['packSize'] as Map?) ?? <String, dynamic>{});
    final dynamic value = pack['value'] ?? pack['quantity'];
    final String unit = pack['unit']?.toString() ?? '';
    if (value == null && unit.isEmpty) return '';
    return '$value $unit'.trim();
  }

  Future<void> _addProduct() async {
    final bool? added = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) =>
            PartnerProductCreateScreen(repository: _partnerRepository),
      ),
    );
    if (added == true && mounted) await _load();
  }

  Future<void> _adjustStock(Map<String, dynamic> sku) async {
    final String skuName = sku['name']?.toString() ?? 'item';
    final _StockAdjustmentResult? action = await showDialog<_StockAdjustmentResult>(
      context: context,
      builder: (BuildContext context) => _StockAdjustmentDialog(skuName: skuName),
    );
    if (action == null || !mounted) return;

    final String? skuId = (sku['_id'] ?? sku['id'])?.toString();
    if (skuId == null || skuId.isEmpty) return;
    if (action.receiveLot) {
      final _InventoryLotInput? lot = await showDialog<_InventoryLotInput>(
        context: context,
        builder: (_) => _InventoryLotReceiveDialog(skuName: skuName),
      );
      if (lot == null || !mounted) return;
      final DioApiResponse response = await _partnerRepository.receiveInventoryLot(
        skuId,
        lotNo: lot.lotNo,
        quantity: lot.quantity,
        expiry: lot.expiry,
        notes: lot.notes,
      );
      if (!mounted) return;
      if (response.errorType != NetErrorType.none) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Batch could not be received. Check the batch number and expiry date, then try again.')),
        );
        return;
      }
      await _load();
      return;
    }

    await _viewLots(sku, suggestedWriteOffQuantity: action.quantity);
  }

  Future<void> _viewLots(Map<String, dynamic> sku, {int? suggestedWriteOffQuantity}) async {
    final String skuId = (sku['_id'] ?? sku['id'])?.toString() ?? '';
    if (skuId.isEmpty) return;
    await showDialog<void>(
      context: context,
      builder: (_) => _InventoryLotsDialog(
        skuName: sku['name']?.toString() ?? 'Product',
        loadLots: () => _partnerRepository.inventoryLots(skuId),
        loadMovements: () => _partnerRepository.inventoryMovements(skuId: skuId),
        onWriteOff: (Map<String, dynamic> lot, String bucket) => _writeOffLot(
          skuId, lot, bucket, suggestedWriteOffQuantity,
        ),
        onDisposition: (Map<String, dynamic> lot, String action) => _changeLotDisposition(skuId, lot, action),
      ),
    );
  }

  Future<bool> _writeOffLot(String skuId, Map<String, dynamic> lot, String bucket, int? suggestedQuantity) async {
    final int available = int.tryParse(lot[bucket == 'available' ? 'availableQty' : bucket == 'held' ? 'heldQty' : 'expiredQty']?.toString() ?? '') ?? 0;
    if (available <= 0) return false;
    final _InventoryWriteOffInput? input = await showDialog<_InventoryWriteOffInput>(
      context: context,
      builder: (_) => _InventoryWriteOffDialog(
        lotNo: lot['lotNo']?.toString() ?? 'Batch',
        bucket: bucket,
        maximum: available,
        initialQuantity: suggestedQuantity,
      ),
    );
    if (input == null || !mounted) return false;
    final DioApiResponse response = await _partnerRepository.writeOffInventoryLot(
      skuId, (lot['_id'] ?? lot['id']).toString(),
      quantity: input.quantity,
      bucket: bucket,
      reason: input.reason,
      note: input.note,
    );
    if (!mounted) return false;
    if (response.errorType != NetErrorType.none) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Write-off failed. Refresh the batch and try again.')));
      return false;
    }
    await _load();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Batch write-off recorded.')));
    return true;
  }

  Future<bool> _changeLotDisposition(String skuId, Map<String, dynamic> lot, String action) async {
    final String? reason = await showDialog<String>(
      context: context,
      builder: (_) => _LotReasonDialog(action: action, lotNo: lot['lotNo']?.toString() ?? 'Batch'),
    );
    if (reason == null || !mounted) return false;
    final DioApiResponse response = await _partnerRepository.setInventoryLotDisposition(
      skuId, (lot['_id'] ?? lot['id']).toString(), action: action, reason: reason,
    );
    if (!mounted) return false;
    if (response.errorType != NetErrorType.none) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Batch status was not changed. Refresh and try again.')));
      return false;
    }
    await _load();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(action == 'recall' ? 'Batch recalled and blocked from sale.' : action == 'hold' ? 'Batch put on hold.' : 'Hold released.')));
    return true;
  }

  Future<void> _showInventoryMovements({String? skuId, String? lotId}) async {
    final DioApiResponse response = await _partnerRepository.inventoryMovements(skuId: skuId, lotId: lotId);
    if (!mounted) return;
    if (response.errorType != NetErrorType.none) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Inventory history could not be loaded.')));
      return;
    }
    final Map<String, dynamic> body = decodeBody(response);
    final List<dynamic> movements = body['movements'] as List? ?? const <dynamic>[];
    await showDialog<void>(
      context: context,
      builder: (_) => _InventoryMovementsDialog(movements: movements),
    );
  }

  Future<void> _showInventoryReport() async {
    final DioApiResponse response = await _partnerRepository.inventoryReport();
    if (!mounted) return;
    if (response.errorType != NetErrorType.none) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Inventory report could not be loaded.')));
      return;
    }
    final Map<String, dynamic> report = Map<String, dynamic>.from(decodeBody(response)['report'] as Map? ?? <String, dynamic>{});
    await showDialog<void>(
      context: context,
      builder: (_) => _InventoryReportDialog(
        report: report,
        onMovements: () => _showInventoryMovements(),
      ),
    );
  }

  Future<void> _editProduct(Map<String, dynamic> sku) async {
    final dynamic raw = sku['product'];
    if (raw is! Map) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product details are unavailable. Refresh and try again.')));
      return;
    }
    final bool? saved = await Navigator.of(context).push<bool>(MaterialPageRoute<bool>(
      builder: (_) => PartnerProductEditScreen(repository: _partnerRepository, product: Map<String, dynamic>.from(raw)),
    ));
    if (saved == true && mounted) await _load();
  }

  Future<void> _editPack(Map<String, dynamic> sku) async {
    final String id = (sku['_id'] ?? sku['id'])?.toString() ?? '';
    if (id.isEmpty) return;
    final Map<String, dynamic>? changes = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) => _SkuEditDialog(sku: sku, quantity: _quantity(sku)),
    );
    if (changes == null || !mounted) return;
    final DioApiResponse response = await _partnerRepository.updateSku(id, changes);
    if (!mounted) return;
    if (response.errorType != NetErrorType.none) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pack details could not be updated.')));
      return;
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final List<Map<String, dynamic>> skuRows = _skus
        .whereType<Map>()
        .map((Map row) => Map<String, dynamic>.from(row))
        .toList();
    final List<Map<String, dynamic>> visibleSkus = _visibleSkus();
    final int availableCount = skuRows.where(_isAvailable).length;
    final int outOfStockCount = skuRows.length - availableCount;

    return SectionListScreen(
      title: l10n.navInventory,
      icon: Icons.inventory_2_outlined,
      onRefresh: _load,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addProduct,
        icon: const Icon(Icons.add),
        label: const Text('Add product'),
      ),
      children: <Widget>[
        if (!_loading && _error == null && skuRows.isNotEmpty) ...<Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: MetricTile(
                  label: 'Product packs',
                  value: '${skuRows.length}',
                  icon: Icons.inventory_2_outlined,
                ),
              ),
              Expanded(
                child: MetricTile(
                  label: 'Out of stock',
                  value: '$outOfStockCount',
                  icon: Icons.warning_amber_outlined,
                  accent: outOfStockCount > 0 ? AppColors.expirySoon : AppColors.canInStore,
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _showInventoryReport,
              icon: const Icon(Icons.analytics_outlined),
              label: const Text('Inventory report'),
            ),
          ),
          Card(
            child: TextField(
              key: const ValueKey<String>('dairy-inventory-search'),
              onChanged: (String value) => setState(() => _searchQuery = value),
              decoration: const InputDecoration(
                hintText: 'Search products, pack sizes or prices',
                prefixIcon: Icon(Icons.search),
                border: InputBorder.none,
              ),
            ),
          ),
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: <Widget>[
                _filterChip('All · ${skuRows.length}', _InventoryFilter.all),
                const SizedBox(width: 8),
                _filterChip('In stock · $availableCount', _InventoryFilter.inStock),
                const SizedBox(width: 8),
                _filterChip('Out of stock · $outOfStockCount', _InventoryFilter.outOfStock),
              ],
            ),
          ),
        ],
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          EmptyState(
            title: l10n.stockUnavailable,
            message: _error!,
            icon: Icons.cloud_off_outlined,
          )
        else if (_skus.isEmpty)
          EmptyState(
            title: l10n.noStockRecords,
            message: l10n.noStockRecordsHint,
            icon: Icons.inventory_2_outlined,
          )
        else if (visibleSkus.isEmpty)
          const EmptyState(
            title: 'No matching stock items',
            message: 'Try a different search or stock filter.',
            icon: Icons.search_off_outlined,
          )
        else
          Card(
            child: Column(
              children: visibleSkus.asMap().entries.map((MapEntry<int, Map<String, dynamic>> entry) {
                final Map<String, dynamic> sku = entry.value;
                return Column(
                  children: <Widget>[
                    if (entry.key > 0) const Divider(height: 1, indent: 16, endIndent: 16),
                    _row(
                      context,
                      sku,
                      sku['name']?.toString() ?? '',
                      _packSize(sku),
                      _quantity(sku),
                      _isAvailable(sku),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _filterChip(String label, _InventoryFilter filter) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: ChoiceChip(
      label: Text(label),
      selected: _filter == filter,
      onSelected: (_) => setState(() => _filter = filter),
    ),
  );

  Widget _row(
    BuildContext context,
    Map<String, dynamic> sku,
    String name,
    String pack,
    int qty,
    bool inStock,
  ) {
    // Red for anything a customer could actually order and we cannot fulfil.
    final bool short = !inStock || qty <= 0;
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final num? price = num.tryParse(sku['price']?.toString() ?? '');
    final Map<String, dynamic> product = sku['product'] is Map
        ? Map<String, dynamic>.from(sku['product'] as Map)
        : <String, dynamic>{};
    final List<dynamic> images = product['images'] as List? ?? const <dynamic>[];
    final String image = images.isEmpty ? '' : images.first.toString();
    return ListTile(
      leading: image.isEmpty ? const CircleAvatar(child: Icon(Icons.water_drop_outlined)) : ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(_imageUrl(image), width: 44, height: 44, fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const CircleAvatar(child: Icon(Icons.broken_image_outlined))),
      ),
      title: Text(name, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Text(
        <String>[
          if (pack.isNotEmpty) pack,
          if (price != null) '₹$price',
        ].join(' · '),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          StatusChip(
            label: sku['status'] == false ? 'Paused' : short ? l10n.outOfStock : '$qty',
            color: short ? AppColors.expired : AppColors.canInStore,
          ),
          PopupMenuButton<String>(
            tooltip: 'Edit $name',
            onSelected: (String action) {
              if (action == 'product') {
                _editProduct(sku);
              } else if (action == 'lots') {
                _viewLots(sku);
              } else {
                _editPack(sku);
              }
            },
            itemBuilder: (BuildContext context) => const <PopupMenuEntry<String>>[
              PopupMenuItem<String>(value: 'product', child: Text('Edit product and photos')),
              PopupMenuItem<String>(value: 'pack', child: Text('Edit price and availability')),
              PopupMenuItem<String>(value: 'lots', child: Text('View batches and expiry')),
            ],
          ),
          IconButton(
            tooltip: 'Adjust stock for $name',
            onPressed: () => _adjustStock(sku),
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
    );
  }

  String _imageUrl(String path) {
    if (path.startsWith('https://') || path.startsWith('http://')) return path;
    final String base = Environments.apiBaseURL.endsWith('/') ? Environments.apiBaseURL.substring(0, Environments.apiBaseURL.length - 1) : Environments.apiBaseURL;
    return '$base/storage/${path.startsWith('/') ? path.substring(1) : path}';
  }
}

enum _InventoryFilter { all, inStock, outOfStock }

class _StockAdjustmentDialog extends StatefulWidget {
  const _StockAdjustmentDialog({required this.skuName});

  final String skuName;

  @override
  State<_StockAdjustmentDialog> createState() => _StockAdjustmentDialogState();
}

class _StockAdjustmentDialogState extends State<_StockAdjustmentDialog> {
  final TextEditingController _quantityController = TextEditingController();

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _submitRemoval() {
    final int? quantity = int.tryParse(_quantityController.text.trim());
    if (quantity == null || quantity <= 0) return;
    Navigator.of(context).pop(_StockAdjustmentResult.remove(quantity));
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('Adjust ${widget.skuName} stock'),
    content: TextField(
      controller: _quantityController,
      autofocus: true,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(labelText: 'Number of packs'),
    ),
    actions: <Widget>[
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      TextButton(
        onPressed: () => Navigator.of(context).pop(const _StockAdjustmentResult.receive()),
        child: const Text('Receive batch'),
      ),
      TextButton(onPressed: _submitRemoval, child: const Text('Remove')),
    ],
  );
}

class _StockAdjustmentResult {
  const _StockAdjustmentResult._({this.receiveLot = false, this.quantity = 0});
  const _StockAdjustmentResult.receive() : this._(receiveLot: true);
  const _StockAdjustmentResult.remove(int quantity) : this._(quantity: quantity);

  final bool receiveLot;
  final int quantity;
}

class _InventoryLotInput {
  const _InventoryLotInput({required this.lotNo, required this.quantity, required this.expiry, this.notes});

  final String lotNo;
  final int quantity;
  final DateTime expiry;
  final String? notes;
}

class _InventoryLotReceiveDialog extends StatefulWidget {
  const _InventoryLotReceiveDialog({required this.skuName});

  final String skuName;

  @override
  State<_InventoryLotReceiveDialog> createState() => _InventoryLotReceiveDialogState();
}

class _InventoryLotReceiveDialogState extends State<_InventoryLotReceiveDialog> {
  final TextEditingController _lotNo = TextEditingController();
  final TextEditingController _quantity = TextEditingController();
  final TextEditingController _notes = TextEditingController();
  DateTime? _expiry;
  String? _error;

  @override
  void dispose() {
    _lotNo.dispose();
    _quantity.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _chooseExpiry() async {
    final DateTime today = DateUtils.dateOnly(DateTime.now());
    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: today.add(const Duration(days: 7)),
      firstDate: today.add(const Duration(days: 1)),
      lastDate: today.add(const Duration(days: 3650)),
    );
    if (selected != null && mounted) setState(() => _expiry = selected);
  }

  void _submit() {
    final String lotNo = _lotNo.text.trim();
    final int? quantity = int.tryParse(_quantity.text.trim());
    if (lotNo.isEmpty || quantity == null || quantity <= 0 || _expiry == null) {
      setState(() => _error = 'Enter a batch number, pack quantity, and expiry date.');
      return;
    }
    Navigator.of(context).pop(_InventoryLotInput(
      lotNo: lotNo,
      quantity: quantity,
      expiry: _expiry!,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('Receive ${widget.skuName} batch'),
    content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
      TextField(controller: _lotNo, autofocus: true, decoration: const InputDecoration(labelText: 'Supplier batch / lot number')),
      TextField(controller: _quantity, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Number of packs')),
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Expiry date'),
        subtitle: Text(_expiry == null ? 'Required for every received batch' : MaterialLocalizations.of(context).formatMediumDate(_expiry!)),
        trailing: const Icon(Icons.calendar_month_outlined),
        onTap: _chooseExpiry,
      ),
      TextField(controller: _notes, maxLines: 2, decoration: const InputDecoration(labelText: 'Notes (optional)')),
      if (_error != null) Align(alignment: Alignment.centerLeft, child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
    ])),
    actions: <Widget>[
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      FilledButton(onPressed: _submit, child: const Text('Receive stock')),
    ],
  );
}

class _InventoryLotsDialog extends StatefulWidget {
  const _InventoryLotsDialog({
    required this.skuName,
    required this.loadLots,
    required this.loadMovements,
    required this.onWriteOff,
    required this.onDisposition,
  });

  final String skuName;
  final Future<DioApiResponse> Function() loadLots;
  final Future<DioApiResponse> Function() loadMovements;
  final Future<bool> Function(Map<String, dynamic> lot, String bucket) onWriteOff;
  final Future<bool> Function(Map<String, dynamic> lot, String action) onDisposition;

  @override
  State<_InventoryLotsDialog> createState() => _InventoryLotsDialogState();
}

class _InventoryLotsDialogState extends State<_InventoryLotsDialog> {
  late Future<DioApiResponse> _response = widget.loadLots();

  Future<void> _runAction(Map<String, dynamic> lot, String action) async {
    bool success;
    if (action.startsWith('write_off_')) {
      success = await widget.onWriteOff(lot, action.substring('write_off_'.length));
    } else {
      success = await widget.onDisposition(lot, action == 'release_hold' ? 'release' : action);
    }
    if (success && mounted) {
      setState(() { _response = widget.loadLots(); });
    }
  }

  List<PopupMenuEntry<String>> _lotActions(Map<String, dynamic> lot) {
    final String status = lot['status']?.toString() ?? '';
    final int available = int.tryParse(lot['availableQty']?.toString() ?? '') ?? 0;
    final int held = int.tryParse(lot['heldQty']?.toString() ?? '') ?? 0;
    final int expired = int.tryParse(lot['expiredQty']?.toString() ?? '') ?? 0;
    return <PopupMenuEntry<String>>[
      if (status == 'active' && available > 0) ...const <PopupMenuEntry<String>>[
        PopupMenuItem<String>(value: 'write_off_available', child: Text('Write off available stock')),
        PopupMenuItem<String>(value: 'hold', child: Text('Put batch on hold')),
        PopupMenuItem<String>(value: 'recall', child: Text('Recall batch')),
      ],
      if (status == 'held') ...const <PopupMenuEntry<String>>[
        PopupMenuItem<String>(value: 'release_hold', child: Text('Release hold')),
        PopupMenuItem<String>(value: 'recall', child: Text('Recall batch')),
      ],
      if (status == 'held' && held > 0)
        const PopupMenuItem<String>(value: 'write_off_held', child: Text('Write off held stock')),
      if (status == 'recalled' && held > 0)
        const PopupMenuItem<String>(value: 'write_off_held', child: Text('Write off recalled stock')),
      if (status == 'expired' && expired > 0)
        const PopupMenuItem<String>(value: 'write_off_expired', child: Text('Write off expired stock')),
    ];
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('${widget.skuName} batches'),
    content: SizedBox(
      width: 440,
      child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
        FutureBuilder<DioApiResponse>(
        future: _response,
        builder: (BuildContext context, AsyncSnapshot<DioApiResponse> snapshot) {
          if (!snapshot.hasData) return const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()));
          if (snapshot.data!.errorType != NetErrorType.none) return const Text('Batches could not be loaded. Try again later.');
          final Map<String, dynamic> body = decodeBody(snapshot.data!);
          final List<dynamic> lots = body['lots'] as List? ?? const <dynamic>[];
          return SizedBox(
            height: 320,
            child: lots.isEmpty
                ? const Center(child: Text('No received batches yet. Existing opening stock has unknown expiry.'))
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: lots.length,
                    itemBuilder: (BuildContext context, int index) {
                      final Map<String, dynamic> lot = Map<String, dynamic>.from(lots[index] as Map);
                      final dynamic expiry = lot['expiry'];
                      final String expiryText = expiry == null
                          ? 'Legacy stock · expiry unknown'
                          : 'Expires ${MaterialLocalizations.of(context).formatMediumDate(DateTime.tryParse(expiry.toString()) ?? DateTime.now())}';
                      final int available = int.tryParse(lot['availableQty']?.toString() ?? '') ?? 0;
                      final int held = int.tryParse(lot['heldQty']?.toString() ?? '') ?? 0;
                      final int expired = int.tryParse(lot['expiredQty']?.toString() ?? '') ?? 0;
                      final int writtenOff = int.tryParse(lot['writtenOffQty']?.toString() ?? '') ?? 0;
                      final List<String> quantities = <String>[
                        '$available available', if (held > 0) '$held held', if (expired > 0) '$expired expired', if (writtenOff > 0) '$writtenOff written off',
                      ];
                      final List<PopupMenuEntry<String>> actions = _lotActions(lot);
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('${lot['lotNo'] ?? 'Batch'} · ${lot['status'] ?? 'active'}'),
                        subtitle: Text('$expiryText\n${quantities.join(' · ')}'),
                        isThreeLine: true,
                        trailing: actions.isEmpty ? null : PopupMenuButton<String>(
                          tooltip: 'Batch actions',
                          onSelected: (String action) => _runAction(lot, action),
                          itemBuilder: (_) => actions,
                        ),
                      );
                    },
                  ),
          );
        },
        ),
        Align(alignment: Alignment.centerLeft, child: TextButton.icon(
          onPressed: () async {
            final DioApiResponse response = await widget.loadMovements();
            if (!context.mounted) return;
            if (response.errorType != NetErrorType.none) return;
            final List<dynamic> movements = decodeBody(response)['movements'] as List? ?? const <dynamic>[];
            await showDialog<void>(context: context, builder: (_) => _InventoryMovementsDialog(movements: movements));
          },
          icon: const Icon(Icons.history),
          label: const Text('Movement history'),
        )),
      ]),
    ),
    actions: <Widget>[TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
  );
}

class _InventoryWriteOffInput {
  const _InventoryWriteOffInput({required this.quantity, required this.reason, this.note});
  final int quantity;
  final String reason;
  final String? note;
}

class _InventoryWriteOffDialog extends StatefulWidget {
  const _InventoryWriteOffDialog({required this.lotNo, required this.bucket, required this.maximum, this.initialQuantity});
  final String lotNo;
  final String bucket;
  final int maximum;
  final int? initialQuantity;

  @override
  State<_InventoryWriteOffDialog> createState() => _InventoryWriteOffDialogState();
}

class _InventoryWriteOffDialogState extends State<_InventoryWriteOffDialog> {
  late final TextEditingController _quantity = TextEditingController(
    text: (widget.initialQuantity == null || widget.initialQuantity! > widget.maximum ? widget.maximum : widget.initialQuantity).toString(),
  );
  final TextEditingController _reason = TextEditingController();
  final TextEditingController _note = TextEditingController();
  String? _error;

  @override
  void dispose() { _quantity.dispose(); _reason.dispose(); _note.dispose(); super.dispose(); }

  void _submit() {
    final int? quantity = int.tryParse(_quantity.text.trim());
    final String reason = _reason.text.trim();
    if (quantity == null || quantity < 1 || quantity > widget.maximum || reason.length < 3) {
      setState(() => _error = 'Enter a valid quantity up to ${widget.maximum} and a reason of at least 3 characters.');
      return;
    }
    Navigator.pop(context, _InventoryWriteOffInput(quantity: quantity, reason: reason, note: _note.text.trim()));
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('Write off ${widget.lotNo}'),
    content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
      Text('This stock is ${widget.bucket}. Written-off quantity cannot be sold or restored.'),
      TextField(controller: _quantity, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Quantity (max ${widget.maximum})')),
      TextField(controller: _reason, maxLength: 300, decoration: const InputDecoration(labelText: 'Required reason')),
      TextField(controller: _note, maxLines: 2, decoration: const InputDecoration(labelText: 'Additional note (optional)')),
      if (_error != null) Align(alignment: Alignment.centerLeft, child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
    ])),
    actions: <Widget>[
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      FilledButton(onPressed: _submit, child: const Text('Record write-off')),
    ],
  );
}

class _LotReasonDialog extends StatefulWidget {
  const _LotReasonDialog({required this.action, required this.lotNo});
  final String action;
  final String lotNo;

  @override
  State<_LotReasonDialog> createState() => _LotReasonDialogState();
}

class _LotReasonDialogState extends State<_LotReasonDialog> {
  final TextEditingController _reason = TextEditingController();
  String? _error;

  @override
  void dispose() { _reason.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('${widget.action == 'hold' ? 'Hold' : widget.action == 'recall' ? 'Recall' : 'Release hold'} ${widget.lotNo}?'),
    content: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
      Text(widget.action == 'recall' ? 'A recalled batch stays blocked from sale and cannot be released.' : 'Enter a reason for the batch status change.'),
      TextField(controller: _reason, autofocus: true, maxLength: 300, decoration: const InputDecoration(labelText: 'Reason')),
      if (_error != null) Align(alignment: Alignment.centerLeft, child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
    ]),
    actions: <Widget>[
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      FilledButton(onPressed: () {
        if (_reason.text.trim().length < 3) { setState(() => _error = 'Enter a reason of at least 3 characters.'); return; }
        Navigator.pop(context, _reason.text.trim());
      }, child: Text(widget.action == 'recall' ? 'Recall batch' : widget.action == 'hold' ? 'Put on hold' : 'Release hold')),
    ],
  );
}

class _InventoryMovementsDialog extends StatelessWidget {
  const _InventoryMovementsDialog({required this.movements});
  final List<dynamic> movements;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Stock movement history'),
    content: SizedBox(
      width: 460,
      height: 420,
      child: movements.isEmpty
          ? const Center(child: Text('No inventory movements recorded yet.'))
          : ListView.builder(
              itemCount: movements.length,
              itemBuilder: (BuildContext context, int index) {
                final Map<String, dynamic> row = Map<String, dynamic>.from(movements[index] as Map);
                final dynamic rawSku = row['sku'];
                final String skuName = rawSku is Map ? (rawSku['name']?.toString() ?? 'Product') : 'Product';
                final String date = row['occurredAt']?.toString() ?? '';
                final DateTime? when = DateTime.tryParse(date)?.toLocal();
                final String timestamp = when == null ? date : MaterialLocalizations.of(context).formatMediumDate(when);
                final List<dynamic> allocations = row['allocations'] as List? ?? const <dynamic>[];
                final String lots = allocations.map((dynamic item) => item is Map ? (item['lotNo'] ?? 'Batch').toString() : '').where((String v) => v.isNotEmpty).join(', ');
                final String reason = row['reason']?.toString() ?? '';
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('${row['eventType'] ?? 'movement'} · ${row['quantity'] ?? 0} packs'),
                  subtitle: Text('$skuName · $lots\n$timestamp${reason.isEmpty ? '' : ' · $reason'}'),
                  isThreeLine: true,
                );
              },
            ),
    ),
    actions: <Widget>[TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
  );
}

class _InventoryReportDialog extends StatelessWidget {
  const _InventoryReportDialog({required this.report, required this.onMovements});
  final Map<String, dynamic> report;
  final VoidCallback onMovements;

  Map<String, dynamic> _map(dynamic value) => value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  Widget _metric(BuildContext context, String label, dynamic value) => Container(
    constraints: const BoxConstraints(minWidth: 125),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[Text('$value', style: Theme.of(context).textTheme.titleMedium), Text(label, style: Theme.of(context).textTheme.bodySmall)]),
  );

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> summary = _map(report['summary']);
    final List<Map<String, dynamic>> rows = report['rows'] is List
        ? (report['rows'] as List).whereType<Map>().map((Map row) => Map<String, dynamic>.from(row)).where((Map<String, dynamic> row) => row['discrepancy'] != 0 || row['ledgerDiscrepancy'] != 0).toList()
        : <Map<String, dynamic>>[];
    final List<Map<String, dynamic>> expiring = report['expiring'] is List
        ? (report['expiring'] as List).whereType<Map>().map((Map row) => Map<String, dynamic>.from(row)).toList()
        : <Map<String, dynamic>>[];
    final List<Map<String, dynamic>> totals = report['movementTotals'] is List
        ? (report['movementTotals'] as List).whereType<Map>().map((Map row) => Map<String, dynamic>.from(row)).toList()
        : <Map<String, dynamic>>[];
    return AlertDialog(
      title: const Text('Inventory reconciliation'),
      content: SizedBox(width: 480, child: ListView(shrinkWrap: true, children: <Widget>[
        Text('Current stock snapshot · movement totals for the last 30 days'),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: <Widget>[
          _metric(context, 'SKU packs', summary['skuAvailableQty'] ?? 0),
          _metric(context, 'Lot available', summary['lotAvailableQty'] ?? 0),
          _metric(context, 'On hold', summary['heldQty'] ?? 0),
          _metric(context, 'Expired', summary['expiredQty'] ?? 0),
          _metric(context, 'Written off', summary['writtenOffQty'] ?? 0),
          _metric(context, 'Stock mismatches', summary['discrepancyCount'] ?? 0),
          _metric(context, 'Expiring batches', summary['expiringLotCount'] ?? 0),
        ]),
        if (rows.isNotEmpty) ...<Widget>[
          const SizedBox(height: 18),
          Text('Reconciliation differences', style: Theme.of(context).textTheme.titleMedium),
          ...rows.map((Map<String, dynamic> row) => ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(row['name']?.toString() ?? 'Product'),
            subtitle: Text('SKU ${row['skuAvailableQty']} · batches ${row['lotAvailableQty']} · ledger ${row['ledgerAvailableQty']}'),
            trailing: Text('Δ ${row['discrepancy']} / ${row['ledgerDiscrepancy']}'),
          )),
        ],
        if (expiring.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          Text('Expiring within 30 days', style: Theme.of(context).textTheme.titleMedium),
          ...expiring.take(10).map((Map<String, dynamic> row) => ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('${row['skuName'] ?? 'Product'} · ${row['lotNo'] ?? 'Batch'}'),
            subtitle: Text('${row['availableQty'] ?? 0} packs · ${row['expiry'] ?? ''}'),
          )),
        ],
        if (totals.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          Text('Movement totals', style: Theme.of(context).textTheme.titleMedium),
          ...totals.map((Map<String, dynamic> row) => ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(row['eventType']?.toString() ?? ''),
            trailing: Text('${row['events'] ?? 0} · ${row['quantity'] ?? 0} packs'),
          )),
        ],
      ])),
      actions: <Widget>[
        TextButton.icon(onPressed: () { Navigator.pop(context); onMovements(); }, icon: const Icon(Icons.history), label: const Text('Full movement history')),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
      ],
    );
  }
}

class _SkuEditDialog extends StatefulWidget {
  const _SkuEditDialog({required this.sku, required this.quantity});

  final Map<String, dynamic> sku;
  final int quantity;

  @override
  State<_SkuEditDialog> createState() => _SkuEditDialogState();
}

class _SkuEditDialogState extends State<_SkuEditDialog> {
  late final TextEditingController _price = TextEditingController(text: widget.sku['price']?.toString() ?? '0');
  late final TextEditingController _mrp = TextEditingController(text: widget.sku['mrp']?.toString() ?? '');
  late final TextEditingController _stockAlertThreshold = TextEditingController(text: widget.sku['stockAlertThreshold']?.toString() ?? '10');
  late bool _active = widget.sku['status'] != false;
  late bool _inStock = widget.sku['inStock'] == true;
  String? _error;

  @override
  void dispose() {
    _price.dispose();
    _mrp.dispose();
    _stockAlertThreshold.dispose();
    super.dispose();
  }

  void _save() {
    final double? price = double.tryParse(_price.text.trim());
    final double? mrp = _mrp.text.trim().isEmpty ? null : double.tryParse(_mrp.text.trim());
    final int? alertThreshold = int.tryParse(_stockAlertThreshold.text.trim());
    if (price == null || price < 0 || (_mrp.text.trim().isNotEmpty && (mrp == null || mrp < 0)) || alertThreshold == null || alertThreshold < 0 || alertThreshold > 100000) {
      setState(() => _error = 'Enter valid prices and a stock alert threshold from 0 to 100,000.');
      return;
    }
    Navigator.of(context).pop(<String, dynamic>{
      'price': price,
      'inStock': widget.quantity > 0 && _inStock,
      'stockAlertThreshold': alertThreshold,
      'status': _active,
      'mrp': ?mrp,
    });
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Edit pack and availability'),
    content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
      TextField(controller: _price, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Selling price (₹)')),
      TextField(controller: _mrp, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'MRP (optional, ₹)')),
      TextField(controller: _stockAlertThreshold, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Low-stock alert threshold', helperText: 'Show a replenishment alert at or below this quantity.')),
      SwitchListTile.adaptive(contentPadding: EdgeInsets.zero, value: _active, onChanged: (bool value) => setState(() => _active = value), title: const Text('Active in catalogue'), subtitle: const Text('Turn off to hide this pack from customers.')),
      SwitchListTile.adaptive(contentPadding: EdgeInsets.zero, value: _inStock, onChanged: widget.quantity <= 0 ? null : (bool value) => setState(() => _inStock = value), title: const Text('Available to order'), subtitle: Text(widget.quantity <= 0 ? 'Add stock before making this pack orderable.' : 'Current stock: ${widget.quantity}')),
      if (_error != null) Align(alignment: Alignment.centerLeft, child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
    ])),
    actions: <Widget>[
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      FilledButton(onPressed: _save, child: const Text('Save')),
    ],
  );
}
