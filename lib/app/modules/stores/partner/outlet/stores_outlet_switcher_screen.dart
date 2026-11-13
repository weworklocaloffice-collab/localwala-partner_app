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
import 'package:partner/app/modules/stores/partner/onboarding/stores_onboarding_wizard_screen.dart';
import 'package:partner/app/modules/stores/stores_partner_repository.dart';
import 'package:partner/app/modules/stores/widgets/stores_ui_states.dart';

/// The outlet picker — BR-38, made usable.
///
/// ## What this screen is allowed to do
///
/// It sends ONE thing: an outlet id, to `POST /partner/session/outlet`. That is a request to
/// change a SERVER-SIDE SESSION PROPERTY, and the server checks it against the user's role
/// scope first — a Kukatpally-scoped manager asking for Miyapur gets `403 OUT_OF_SCOPE`.
///
/// ## What it deliberately does not do
///
/// It does not filter anything. No screen in this module takes an outlet id to widen a query,
/// because the server scopes every read by the session. This screen exists so a partner
/// operating several outlets can change WHICH outlet the server scopes them to — not so the
/// client can read another one.
///
/// BR-35 is why the list is what it is: a chain is the brand, an outlet is a location, and a
/// single-outlet business is simply a chain with one entry here. There is no separate
/// single-outlet code path anywhere in this module.
class StoresOutletSwitcherScreen extends StatefulWidget {
  const StoresOutletSwitcherScreen({super.key});

  @override
  State<StoresOutletSwitcherScreen> createState() => _StoresOutletSwitcherScreenState();
}

class _StoresOutletSwitcherScreenState extends State<StoresOutletSwitcherScreen> {
  StoresPartnerRepository? _repo;
  String? _busyId;

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
        title: Text(l10n.storesTitleOutlets),
        actions: <Widget>[
          IconButton(
            onPressed: () => setState(() => _repo = StoresPartnerRepository()),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
            floatingActionButton: FloatingActionButton.extended(
        // BR-35: chains grow outlets. Registering a new store starts the same six-step
        // application every chain began with — there is no separate "first store" path.
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const StoresOnboardingWizardScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add_business_outlined),
        label: Text(AppLocalizations.of(context)!.storesTitleNewStore),
      ),
      body: StoresAsyncView<List<Map<String, dynamic>>>(
        future: repo.myOutlets(),
        builder: (BuildContext context, List<Map<String, dynamic>> outlets) {
          if (outlets.isEmpty) {
            return const StoresEmptyView(
              message: 'No outlets are linked to this account.',
              icon: Icons.storefront_outlined,
            );
          }

          return ListView.separated(
            itemCount: outlets.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (BuildContext context, int index) {
              final Map<String, dynamic> outlet = outlets[index];
              final String id = '${outlet['_id'] ?? outlet['id'] ?? ''}';
              final String status = '${outlet['status'] ?? 'active'}';

              // BR-32: a suspended outlet still belongs to the partner and must stay
              // visible — hiding it would make a suspension look like a deletion. The
              // server refuses new orders for it regardless.
              final bool suspended = status == 'suspended';
              final bool busy = _busyId == id;

              return ListTile(
                leading: Icon(
                  suspended ? Icons.storefront_outlined : Icons.storefront,
                  color: suspended ? AppColors.grey : null,
                ),
                title: Text('${outlet['name'] ?? AppLocalizations.of(context)!.storesFallbackOutlet}'),
                subtitle: Text(
                  <String>[
                    if (outlet['outletCode'] != null) '${outlet['outletCode']}',
                    status,
                    if (outlet['isOpenNow'] == true) 'Open',
                    if (outlet['isOpenNow'] == false) 'Closed',
                    if (outlet['nextOpensAt'] != null)
                      'opens ${outlet['nextOpensAt']}',
                  ].join(' · '),
                ),
                trailing: busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        tooltip: 'Work in this outlet',
                        onPressed: id.isEmpty
                            ? null
                            : () async {
                                setState(() => _busyId = id);
                                try {
                                  await repo.switchOutlet(id);
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        l10n.storesNowWorkingIn((outlet['name'] ?? 'outlet').toString()),
                                      ),
                                    ),
                                  );
                                } on StoresApiException catch (e) {
                                  // OUT_OF_SCOPE lands here — the partner asked for an
                                  // outlet their role does not cover. Say so rather than
                                  // appearing to do nothing.
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(e.message)),
                                  );
                                } finally {
                                  if (mounted) setState(() => _busyId = null);
                                }
                              },
                        icon: const Icon(Icons.swap_horiz),
                      ),
              );
            },
          );
        },
      ),
    );
  }
}
