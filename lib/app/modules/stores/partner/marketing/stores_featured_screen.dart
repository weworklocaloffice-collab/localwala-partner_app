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

/// Featured placements — paid visibility for the outlet.
///
/// A placement moves through request -> approval -> live. The partner requests; someone
/// with the right approves. The approve/reject endpoints in this file hit
/// `POST .../{placement}/approve` and `POST .../{placement}/reject`, which mirror the
/// product-approval gate (BR-09) one level up: nothing customer-visible goes live without
/// a recorded decision and a decider.
class StoresFeaturedScreen extends StatefulWidget {
  const StoresFeaturedScreen({super.key});

  @override
  State<StoresFeaturedScreen> createState() => _StoresFeaturedScreenState();
}

class _StoresFeaturedScreenState extends State<StoresFeaturedScreen> {
  StoresPartnerRepository? _repo;

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

  Future<void> _approve(Map<String, dynamic> placement) async {
    final StoresPartnerRepository repo = _repo ?? StoresPartnerRepository();
    final String? id = placement['_id']?.toString() ?? placement['id']?.toString();
    if (id == null) return;

    try {
      await repo.approveFeatured(id);
      _snack('Placement approved');
      _reload();
    } on StoresApiException catch (e) {
      _snack(e.message);
    }
  }

  Future<void> _reject(BuildContext context, Map<String, dynamic> placement) async {
    final StoresPartnerRepository repo = _repo ?? StoresPartnerRepository();
    final String? id = placement['_id']?.toString() ?? placement['id']?.toString();
    if (id == null) return;

    final TextEditingController reason = TextEditingController();
    final String? submitted = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.storesDialogRejectPlacement),
          content: TextField(
            controller: reason,
            decoration: InputDecoration(labelText: l10n.storesFieldReasonRequired),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.storesActionCancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(reason.text.trim()),
              child: Text(l10n.storesActionReject),
            ),
          ],
        );
      },
    );

    final String text = submitted ?? '';
    reason.dispose();
    if (text.isEmpty) return;

    try {
      await repo.rejectFeatured(id, text);
      _snack('Placement rejected');
      _reload();
    } on StoresApiException catch (e) {
      _snack(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    final StoresPartnerRepository repo = _repo ?? StoresPartnerRepository();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.storesTitleFeatured),
          actions: <Widget>[
            IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
          ],
          bottom: const TabBar(
            tabs: <Widget>[
              Tab(text: 'Live'),
              Tab(text: 'Pending'),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            _PlacementList(
              future: repo.featured(),
              empty: 'Nothing featured right now.',
              onApprove: null,
              onReject: null,
              canAct: false,
            ),
            _PlacementList(
              future: repo.featuredPending(),
              empty: 'Nothing awaiting a decision.',
              onApprove: _approve,
              onReject: (Map<String, dynamic> p) => _reject(context, p),
              canAct: true,
            ),
          ],
        ),
      ),
    );
  }
}

/// One placements list. The `canAct` switch is what keeps the Live tab read-only:
/// approving something already live would be a meaningless call, so the buttons simply
/// do not exist there.
class _PlacementList extends StatelessWidget {
  const _PlacementList({
    required this.future,
    required this.empty,
    required this.canAct,
    this.onApprove,
    this.onReject,
  });

  final Future<Map<String, dynamic>> future;
  final String empty;
  final bool canAct;
  final Future<void> Function(Map<String, dynamic>)? onApprove;
  final Future<void> Function(Map<String, dynamic>)? onReject;

  @override
  Widget build(BuildContext context) {
    return StoresAsyncView<Map<String, dynamic>>(
      future: future,
      builder: (BuildContext context, Map<String, dynamic> data) {
        final dynamic raw = data['items'] ?? data['placements'] ?? data['results'] ?? data;
        final List<Map<String, dynamic>> rows = raw is List
            ? raw.whereType<Map<String, dynamic>>().toList()
            : <Map<String, dynamic>>[];

        if (rows.isEmpty) {
          return StoresEmptyView(
            message: empty,
            icon: Icons.star_outline,
          );
        }

        return ListView.separated(
          itemCount: rows.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (BuildContext context, int index) {
            final Map<String, dynamic> row = rows[index];
            return ListTile(
              leading: const Icon(Icons.star_outlined),
              title: Text('${row['title'] ?? row['name'] ?? AppLocalizations.of(context)!.storesFallbackPlacement}'),
              subtitle: Text('${row['status'] ?? ''}'),
              trailing: canAct
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        IconButton(
                          tooltip: 'Approve',
                          onPressed: () => onApprove?.call(row),
                          icon: const Icon(Icons.check_circle_outline),
                        ),
                        IconButton(
                          tooltip: 'Reject',
                          onPressed: () => onReject?.call(row),
                          icon: const Icon(Icons.cancel_outlined),
                        ),
                      ],
                    )
                  : null,
            );
          },
        );
      },
    );
  }
}