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

import 'package:partner/app/modules/stores/partner/settlements/stores_settlement_detail_screen.dart';
import 'package:partner/app/modules/stores/stores_partner_repository.dart';
import 'package:partner/app/modules/stores/widgets/stores_ui_states.dart';
import 'package:flutter/material.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

/// The outlet's settlement history.
///
/// The server scopes every call to the session's active outlet (BR-38), so this screen
/// cannot ask for another outlet's payouts. A settlement is a statement of what the
/// platform owes the outlet for one closed period; the detail screen is where the line
/// items that make up the net amount live.
class StoresSettlementsScreen extends StatefulWidget {
  const StoresSettlementsScreen({super.key});

  @override
  State<StoresSettlementsScreen> createState() =>
      _StoresSettlementsScreenState();
}

class _StoresSettlementsScreenState extends State<StoresSettlementsScreen> {
  StoresPartnerRepository? _repo;
  List<Map<String, dynamic>> _rows = <Map<String, dynamic>>[];
  Object? _error;
  bool _loading = true;
  bool _loadingMore = false;
  int _page = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _repo = StoresPartnerRepository();
    _load();
  }

  Future<void> _load({bool more = false}) async {
    if (more && (_loadingMore || _page >= _totalPages)) return;
    setState(() {
      if (more) {
        _loadingMore = true;
      } else {
        _loading = true;
        _error = null;
      }
    });

    try {
      final StoresPartnerRepository repo = _repo ?? StoresPartnerRepository();
      final Map<String, dynamic> body = await repo.settlements(
        page: more ? _page + 1 : 1,
      );
      final dynamic raw =
          body['items'] ?? body['settlements'] ?? body['results'] ?? body;
      final List<Map<String, dynamic>> rows = raw is List
          ? raw.whereType<Map<String, dynamic>>().toList()
          : <Map<String, dynamic>>[];

      if (!mounted) return;
      setState(() {
        if (more) {
          _rows = <Map<String, dynamic>>[..._rows, ...rows];
          _page += 1;
        } else {
          _rows = rows;
          _page = 1;
        }
        _totalPages = int.tryParse('${body['totalPages'] ?? 1}') ?? 1;
      });
    } catch (error) {
      if (!mounted) return;
      if (more) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      } else {
        setState(() => _error = error);
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  void _open(Map<String, dynamic> settlement) {
    final String? id =
        settlement['_id']?.toString() ?? settlement['id']?.toString();
    if (id == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StoresSettlementDetailScreen(settlementId: id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.storesTabSettlements),
        actions: <Widget>[
          IconButton(
            onPressed: _loading ? null : () => _load(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return StoresErrorView(error: _error, onRetry: () => _load());
    }
    if (_rows.isEmpty) {
      return const StoresEmptyView(
        message:
            'No settlements yet. They appear after the first closed period.',
        icon: Icons.account_balance_wallet_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: () => _load(),
      child: ListView.separated(
        itemCount: _rows.length + (_page < _totalPages ? 1 : 0),
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (BuildContext context, int index) {
          if (index >= _rows.length) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: _loadingMore
                    ? const CircularProgressIndicator()
                    : OutlinedButton(
                        onPressed: () => _load(more: true),
                        child: Text(AppLocalizations.of(context)!.storesLoadMore),
                      ),
              ),
            );
          }
          return _settlementTile(context, _rows[index]);
        },
      ),
    );
  }

  Widget _settlementTile(
    BuildContext context,
    Map<String, dynamic> settlement,
  ) {
    final dynamic totals = settlement['totals'];
    final String net = totals is Map
        ? _money(totals['netAmount'])
        : _money(settlement['netAmount']);
    final String status = '${settlement['status'] ?? 'pending'}';

    return ListTile(
      leading: const Icon(Icons.account_balance_wallet_outlined),
      title: Text(AppLocalizations.of(context)!.storesSettlementNumber('')),
      subtitle: Text(
        '${settlement['period'] ?? 'period'} · '
        '${_date(settlement['from'])} – ${_date(settlement['to'])}',
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Text(net, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 2),
          Text(status, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
      onTap: () => _open(settlement),
    );
  }
}

String _money(dynamic value) {
  if (value is num) return value.toStringAsFixed(2);
  if (value == null) return '0.00';
  return '$value';
}

String _date(dynamic value) {
  final DateTime? parsed = DateTime.tryParse('$value');
  if (parsed == null) return value == null ? '—' : '$value';
  final DateTime local = parsed.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)}';
}
