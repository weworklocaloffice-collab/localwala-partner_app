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

/// Who holds what role, at which scope.
///
/// BR-40: role assignment is a MODEL (`StoreRoleAssignment` carrying user, role, scope),
/// not a `User.role` value. This screen renders that model — the same human can be an
/// inventory manager in one business and an order manager in another, and a role with
/// outlet scope is visibly narrower than one with chain scope.
///
/// Read-only on purpose. Granting and revoking roles is an admin-surface action with
/// its own approval, not a button on a roster.
class StoresTeamScreen extends StatefulWidget {
  const StoresTeamScreen({super.key});

  @override
  State<StoresTeamScreen> createState() => _StoresTeamScreenState();
}

class _StoresTeamScreenState extends State<StoresTeamScreen> {
  StoresPartnerRepository? _repo;

  @override
  void initState() {
    super.initState();
    _repo = StoresPartnerRepository();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    final StoresPartnerRepository repo = _repo ?? StoresPartnerRepository();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.storesTitleTeam),
        actions: <Widget>[
          IconButton(
            onPressed: () => setState(() => _repo = StoresPartnerRepository()),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: StoresAsyncView<Map<String, dynamic>>(
        future: repo.team(),
        builder: (BuildContext context, Map<String, dynamic> data) {
          final dynamic raw = data['items'] ?? data['team'] ?? data['members'] ?? data['results'] ?? data;
          final List<Map<String, dynamic>> rows = raw is List
              ? raw.whereType<Map<String, dynamic>>().toList()
              : <Map<String, dynamic>>[];

          if (rows.isEmpty) {
            return const StoresEmptyView(
              message: 'Just you, for now.',
              icon: Icons.group_outlined,
            );
          }

          return ListView.separated(
            itemCount: rows.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (BuildContext context, int index) {
              final Map<String, dynamic> member = rows[index];
              final String role = '${member['role'] ?? 'staff'}';
              final String scope = '${member['scopeType'] ?? member['scope'] ?? 'outlet'}';

              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                title: Text('${member['name'] ?? member['userName'] ?? AppLocalizations.of(context)!.storesFallbackMember}'),
                subtitle: Text('$role · $scope scope'),
                trailing: (member['status'] ?? 'active') == 'active'
                    ? null
                    : Chip(label: Text('${member['status']}')),
              );
            },
          );
        },
      ),
    );
  }
}