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

import 'package:partner/app/presentation/styles/theme.dart';
import 'package:partner/gen/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:partner/app/modules/stores/stores_partner_repository.dart';
import 'package:partner/app/modules/stores/widgets/stores_ui_states.dart';

/// The chain's subscription.
///
/// One live row per chain plus history, enforced by the partial unique index — so this is
/// a status screen for the CURRENT subscription, not a list to pick from.
///
/// ## What the partner acts on
///
/// The dunning ladder: `payment_due` -> `retrying` -> `grace_period` -> suspended/expired.
/// A partner in `grace_period` is one successful charge from being fine, and a partner
/// whose trial ran out reads as `expired` immediately (the server's `effectiveStatus`), not
/// after the nightly sweep. The screen says exactly which state the chain is in and what
/// the next action is, because "your subscription needs attention" without a reason is why
/// these screens get ignored.
///
/// Pay starts a gateway payment (BR-16) — it returns a PaymentInitiation to complete, not
/// a paid flag.
class StoresSubscriptionScreen extends StatefulWidget {
  const StoresSubscriptionScreen({super.key});

  @override
  State<StoresSubscriptionScreen> createState() => _StoresSubscriptionScreenState();
}

class _StoresSubscriptionScreenState extends State<StoresSubscriptionScreen> {
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

  Future<void> _pay(Map<String, dynamic> subscription) async {
    final StoresPartnerRepository repo = _repo ?? StoresPartnerRepository();
    final String? id = subscription['_id']?.toString() ?? subscription['id']?.toString();
    if (id == null) return;

    try {
      final Map<String, dynamic> initiation = await repo.paySubscription(id);
      _snack('Payment started${initiation['gatewayReference'] != null ? ' (${initiation['gatewayReference']})' : ''}. Complete it in the gateway.');
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
        title: Text(l10n.storesTitleSubscription),
        actions: <Widget>[
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: repo.currentSubscription(),
        builder: (BuildContext context, AsyncSnapshot<Map<String, dynamic>?> snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return StoresErrorView(error: snapshot.error);
          }

          final Map<String, dynamic>? subscription = snapshot.data;
          if (subscription == null) {
            return const StoresEmptyView(
              message: 'No subscription yet. Choose a plan to start the trial.',
              icon: Icons.card_membership_outlined,
            );
          }

          final String status = '${subscription['effectiveStatus'] ?? subscription['status'] ?? 'unknown'}';
          final bool dunning = <String>['payment_due', 'retrying', 'grace_period'].contains(status);
          final bool expired = status == 'expired' || status == 'suspended' || status == 'cancelled';

          return ListView(
            children: <Widget>[
              if (dunning)
                Container(
                  color: AppColors.expirySoon.withValues(alpha: 0.12),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.warning_amber_outlined, color: AppColors.expirySoon),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Payment needs attention: $status'
                          '${subscription['retryCount'] != null ? ' (attempt ${subscription['retryCount']})' : ''}',
                        ),
                      ),
                    ],
                  ),
                ),
              const StoresSectionHeader(title: 'Plan'),
              ListTile(
                leading: const Icon(Icons.card_membership_outlined),
                title: Text('${subscription['plan'] ?? '—'}'),
                subtitle: Text('${AppLocalizations.of(context)!.storesLabelStatus}: $status'),
              ),
              const StoresSectionHeader(title: 'Billing'),
              ListTile(
                leading: const Icon(Icons.payments_outlined),
                title: Text(AppLocalizations.of(context)!.storesLabelAmount),
                trailing: Text('${subscription['totalAmount'] ?? subscription['amount'] ?? 0}'),
              ),
              if (subscription['nextPaymentDueAt'] != null)
                ListTile(
                  leading: const Icon(Icons.event_outlined),
                  title: Text(AppLocalizations.of(context)!.storesLabelNextPaymentDue),
                  trailing: Text('${subscription['nextPaymentDueAt']}'),
                ),
              if (subscription['trialEndsAt'] != null)
                ListTile(
                  leading: const Icon(Icons.timer_outlined),
                  title: Text(AppLocalizations.of(context)!.storesLabelTrialEnds),
                  trailing: Text('${subscription['trialEndsAt']}'),
                ),
              if (subscription['graceEndsAt'] != null && dunning)
                ListTile(
                  leading: const Icon(Icons.hourglass_bottom_outlined),
                  title: Text(AppLocalizations.of(context)!.storesLabelGracePeriodEnds),
                  trailing: Text('${subscription['graceEndsAt']}'),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton(
                  onPressed: expired
                      ? null
                      : () => _pay(subscription),
                  child: Text(dunning ? 'Pay now' : 'Manage payment'),
                ),
              ),
              if (expired)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'This subscription is no longer live. Contact support to reactivate.',
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
