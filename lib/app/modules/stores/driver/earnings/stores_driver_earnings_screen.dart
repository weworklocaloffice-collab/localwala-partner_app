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

/// Store-driver earnings.
///
/// BR-39 matters on this screen: COD cash the driver collected is NOT theirs yet. It moves
/// pending -> collected -> reconciled, and the collected-but-unreconciled figure is shown
/// apart from the reconciled total, because a driver reading one combined number would think
/// they are owed money the outlet has not yet taken in.
class StoresDriverEarningsScreen extends StatefulWidget {
  const StoresDriverEarningsScreen({super.key});

  @override
  State<StoresDriverEarningsScreen> createState() => _StoresDriverEarningsScreenState();
}

class _StoresDriverEarningsScreenState extends State<StoresDriverEarningsScreen> {
  StoresDriverRepository? _repo;

  @override
  void initState() {
    super.initState();
    _repo = StoresDriverRepository();
  }

  void _reload() {
    setState(() => _repo = StoresDriverRepository());
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    final StoresDriverRepository repo = _repo ?? StoresDriverRepository();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.storesTitleEarnings),
        actions: <Widget>[
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: StoresAsyncView<Map<String, dynamic>>(
        future: repo.earnings(),
        builder: (BuildContext context, Map<String, dynamic> data) {
          final Map<String, dynamic> totals =
              (data['totals'] as Map<String, dynamic>?) ?? data;

          return ListView(
            children: <Widget>[
              const StoresSectionHeader(title: 'Reconciled'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '${totals['net'] ?? totals['reconciled'] ?? totals['total'] ?? 0}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              const StoresSectionHeader(title: 'Awaiting reconciliation'),
              // COD the driver has taken in but the outlet has not yet settled. Shown
              // separately so it is never mistaken for earned money.
              ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: const Text('Collected, not yet reconciled'),
                trailing: Text('${totals['codPending'] ?? totals['collected'] ?? 0}'),
              ),
              ListTile(
                leading: const Icon(Icons.route_outlined),
                title: const Text('Deliveries completed'),
                trailing: Text('${totals['deliveries'] ?? totals['count'] ?? 0}'),
              ),
            ],
          );
        },
      ),
    );
  }
}