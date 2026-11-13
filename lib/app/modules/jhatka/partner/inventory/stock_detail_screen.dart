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
import 'package:partner/app/modules/jhatka/partner/inventory/jhatka_inventory_repository.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

/// One stock line with its movement ledger.
///
/// The list row carries balances (on-hand, reserved, available). This screen
/// carries HOW they got there — every movement in sequence number order. A
/// disputed count is answered by replaying this ledger, which is why the
/// sequence exists at all.
class StockDetailScreen extends StatefulWidget {
  const StockDetailScreen({super.key, required this.itemId});

  final String itemId;

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {
  final JhatkaInventoryRepository _repository = JhatkaInventoryRepository();

  bool _loading = true;
  String? _error;
  Map<String, dynamic> _item = <String, dynamic>{};
  List<dynamic> _movements = const <dynamic>[];

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
    final DioApiResponse response = await _repository.stockDetail(
      widget.itemId,
    );
    if (!mounted) return;
    if (response.errorType != NetErrorType.none) {
      setState(() {
        _loading = false;
        _error = 'Could not load the stock line.';
      });
      return;
    }
    final Map<String, dynamic> body = decodeBody(response);
    setState(() {
      _loading = false;
      _item = Map<String, dynamic>.from((body['item'] ?? {}) as Map);
      _movements = (body['movements'] as List?) ?? const <dynamic>[];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.jhatkaStockLine),
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
                            '${_item['kind'] ?? ''} · ${_item['unit'] ?? ''}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text('On hand: ${_item['onHand'] ?? 0}'),
                          Text('Reserved: ${_item['reserved'] ?? 0}'),
                          Text(
                            'Available: ${_item['availableQty'] ?? 0}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (_item['expired'] == true)
                            const Text(
                              'Expired — reports zero available regardless of on-hand.',
                              style: TextStyle(color: Colors.redAccent),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Movements (${_movements.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ..._movements.map((dynamic raw) {
                    final Map<String, dynamic> movement =
                        Map<String, dynamic>.from(raw as Map);
                    return Card(
                      child: ListTile(
                        dense: true,
                        title: Text(
                          (movement['movementType'] ?? '').toString(),
                        ),
                        subtitle: Text(
                          '${movement['reason'] ?? ''}\n'
                          'seq ${movement['movementSeq'] ?? '—'} · '
                          '${movement['createdAt'] ?? ''}',
                        ),
                        trailing: Text(
                          '${movement['qtyDelta'] ?? 0}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}
