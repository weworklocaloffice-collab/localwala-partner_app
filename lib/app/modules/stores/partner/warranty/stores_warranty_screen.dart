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
import 'package:partner/app/modules/stores/stores_partner_repository.dart';
import 'package:partner/app/modules/stores/widgets/stores_ui_states.dart';

/// Warranty requests (BR-21).
///
/// The ladder is requested -> approved -> in_repair -> resolved -> closed, with
/// rejected and cancelled as exits. Like complaints, the actions offered are the server's
/// `WARRANTY_TRANSITIONS` mirrored as a lookup — a button that 409s is worse than a
/// missing one.
///
/// A warranty outlives the order it came from, which is why this screen is warranty-first
/// rather than order-first: the partner tracks the claim, not the sale.
class StoresWarrantyScreen extends StatefulWidget {
  const StoresWarrantyScreen({super.key});

  @override
  State<StoresWarrantyScreen> createState() => _StoresWarrantyScreenState();
}

class _StoresWarrantyScreenState extends State<StoresWarrantyScreen> {
  StoresPartnerRepository? _repo;

  static const Map<String, List<String>> _next = <String, List<String>>{
    'requested': <String>['approved', 'rejected', 'cancelled'],
    'approved': <String>['in_repair', 'resolved', 'cancelled'],
    'in_repair': <String>['resolved', 'rejected'],
    'resolved': <String>['closed'],
    'rejected': <String>['closed'],
    'closed': <String>[],
    'cancelled': <String>[],
  };

  @override
  void initState() {
    super.initState();
    _repo = StoresPartnerRepository();
  }

  void _reload() {
    setState(() => _repo = StoresPartnerRepository());
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _transition(Map<String, dynamic> warranty, String status) async {
    final StoresPartnerRepository repo = _repo ?? StoresPartnerRepository();
    final String? id = warranty['_id']?.toString() ?? warranty['id']?.toString();
    if (id == null) return;

    try {
      await repo.transitionWarranty(id, status);
      _snack('Warranty $status');
      _reload();
    } on StoresApiException catch (e) {
      _snack(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    final StoresPartnerRepository repo = _repo ?? StoresPartnerRepository();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.storesTitleWarranty),
        actions: <Widget>[
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: StoresAsyncView<Map<String, dynamic>>(
        future: repo.warranties(),
        builder: (BuildContext context, Map<String, dynamic> data) {
          final dynamic raw = data['items'] ?? data['warranties'] ?? data['results'] ?? data;
          final List<Map<String, dynamic>> rows = raw is List
              ? raw.whereType<Map<String, dynamic>>().toList()
              : <Map<String, dynamic>>[];

          if (rows.isEmpty) {
            return const StoresEmptyView(
              message: 'No warranty claims.',
              icon: Icons.verified_outlined,
            );
          }

          return ListView.separated(
            itemCount: rows.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (BuildContext context, int index) {
              final Map<String, dynamic> warranty = rows[index];
              final String status = '${warranty['status'] ?? 'requested'}';
              final List<String> actions = _next[status] ?? const <String>[];

              return ExpansionTile(
                leading: const Icon(Icons.verified_outlined),
                title: Text('${warranty['productName'] ?? warranty['name'] ?? AppLocalizations.of(context)!.storesFallbackClaim}'),
                subtitle: Text(status),
                children: <Widget>[
                  if ((warranty['description'] ?? warranty['issue']) != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('${warranty['description'] ?? warranty['issue']}'),
                      ),
                    ),
                  if (actions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Wrap(
                        spacing: 8,
                        children: <Widget>[
                          for (final String next in actions)
                            OutlinedButton(
                              onPressed: () => _transition(warranty, next),
                              child: Text(next.replaceAll('_', ' ')),
                            ),
                        ],
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}