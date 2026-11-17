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

/// The outlet's support queue.
///
/// A complaint is a customer asking to be heard, and the worst thing an outlet can do is
/// offer it a transition the server will refuse. So the next actions offered here are the
/// server's own transition table (`COMPLAINT_TRANSITIONS`), mirrored as a lookup rather
/// than re-derived:
///
///   open        -> in_progress, resolved, closed, escalated
///   in_progress -> resolved, closed, escalated, open
///   resolved    -> closed, open
///   closed      -> open
///   escalated   -> in_progress, resolved, closed
///
/// Adding a state server-side without updating this map degrades to offering no actions,
/// which is the safe failure — a button that 409s is worse than a missing one.
class StoresComplaintsScreen extends StatefulWidget {
  const StoresComplaintsScreen({super.key});

  @override
  State<StoresComplaintsScreen> createState() => _StoresComplaintsScreenState();
}

class _StoresComplaintsScreenState extends State<StoresComplaintsScreen> {
  StoresPartnerRepository? _repo;

  static const Map<String, List<String>> _next = <String, List<String>>{
    'open': <String>['in_progress', 'resolved', 'closed', 'escalated'],
    'in_progress': <String>['resolved', 'closed', 'escalated', 'open'],
    'resolved': <String>['closed', 'open'],
    'closed': <String>['open'],
    'escalated': <String>['in_progress', 'resolved', 'closed'],
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

  Future<void> _transition(Map<String, dynamic> complaint, String status) async {
    final StoresPartnerRepository repo = _repo ?? StoresPartnerRepository();
    final String? id = complaint['_id']?.toString() ?? complaint['id']?.toString();
    if (id == null) return;

    try {
      await repo.transitionComplaint(id, status);
      _snack('Complaint $status');
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
        title: Text(l10n.storesTitleSupport),
        actions: <Widget>[
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: StoresAsyncView<Map<String, dynamic>>(
        future: repo.complaints(),
        builder: (BuildContext context, Map<String, dynamic> data) {
          final dynamic raw = data['items'] ?? data['complaints'] ?? data['results'] ?? data;
          final List<Map<String, dynamic>> rows = raw is List
              ? raw.whereType<Map<String, dynamic>>().toList()
              : <Map<String, dynamic>>[];

          if (rows.isEmpty) {
            return const StoresEmptyView(
              message: 'No open complaints. A quiet queue.',
              icon: Icons.support_agent_outlined,
            );
          }

          return ListView.separated(
            itemCount: rows.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (BuildContext context, int index) {
              final Map<String, dynamic> complaint = rows[index];
              final String status = '${complaint['status'] ?? 'open'}';
              final List<String> actions = _next[status] ?? const <String>[];

              return ExpansionTile(
                leading: Icon(
                  status == 'open' || status == 'escalated'
                      ? Icons.mark_unread_chat_alt_outlined
                      : Icons.mark_chat_read_outlined,
                ),
                title: Text('${complaint['subject'] ?? complaint['title'] ?? AppLocalizations.of(context)!.storesFallbackComplaint}'),
                subtitle: Text(
                  '$status'
                  '${complaint['orderNo'] != null ? ' · order ${complaint['orderNo']}' : ''}',
                ),
                children: <Widget>[
                  if ((complaint['message'] ?? complaint['description']) != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('${complaint['message'] ?? complaint['description']}'),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Wrap(
                      spacing: 8,
                      children: <Widget>[
                        for (final String next in actions)
                          OutlinedButton(
                            onPressed: () => _transition(complaint, next),
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