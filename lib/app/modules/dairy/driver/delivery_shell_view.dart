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

import 'package:partner/app/core/models/user_session_model.dart';
import 'package:partner/app/core/config/api_request_service.dart';
import 'package:partner/app/core/repositories/delivery_repository.dart';
import 'package:partner/app/presentation/pages/account/profile_view.dart';
import 'package:partner/app/modules/dairy/driver/can_scan/delivery_can_scan_view.dart';
import 'package:partner/app/modules/dairy/driver/earnings/delivery_earnings_view.dart';
import 'package:partner/app/modules/dairy/driver/manifest/delivery_manifest_view.dart';
import 'package:partner/app/modules/dairy/driver/run_complete/delivery_run_complete_view.dart';
import 'package:partner/app/modules/dairy/driver/run_history/delivery_run_history_view.dart';
import 'package:partner/app/shell/role_gate/bloc/role_gate_bloc.dart';
import 'package:partner/app/presentation/styles/theme.dart';
import 'package:partner/gen/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

/// Delivery agent nav tree.
///
/// Five destinations. Note what is absent compared with the food driver app:
/// there is no offer inbox. The home surface is a manifest with a progress
/// bar, because a run is assigned rather than bid for.
class DeliveryShellScreen extends StatefulWidget {
  const DeliveryShellScreen({super.key, required this.gate, this.repository});

  /// Resolved session passed down by `AppHomeScreen`.
  final RoleGateState gate;
  final DeliveryRepository? repository;

  @override
  State<DeliveryShellScreen> createState() => _DeliveryShellScreenState();
}

class _DeliveryShellScreenState extends State<DeliveryShellScreen> {
  int _index = 0;
  late final DeliveryRepository _deliveryRepository;
  bool _checkingApproval = true;
  String? _approvalStatus;
  String _outletName = '';
  String _approvalReason = '';
  String? _statusError;

  @override
  void initState() {
    super.initState();
    _deliveryRepository = widget.repository ?? DeliveryRepository();
    _loadApprovalStatus();
  }

  Future<void> _loadApprovalStatus() async {
    setState(() {
      _checkingApproval = true;
      _statusError = null;
    });
    final DioApiResponse response = await _deliveryRepository.onboardingStatus();
    if (!mounted) return;
    if (response.errorType != NetErrorType.none || response.body == null) {
      setState(() {
        _checkingApproval = false;
        _statusError = 'We could not verify your driver approval. Retry before starting deliveries.';
      });
      return;
    }
    try {
      final Map<String, dynamic> body = jsonDecode(response.body!) as Map<String, dynamic>;
      final Map<String, dynamic> onboarding = body['onboarding'] is Map
          ? Map<String, dynamic>.from(body['onboarding'] as Map)
          : <String, dynamic>{};
      setState(() {
        _checkingApproval = false;
        _approvalStatus = onboarding['status']?.toString() ?? 'pending';
        _outletName = onboarding['outletName']?.toString() ?? '';
        _approvalReason = onboarding['reason']?.toString() ?? '';
      });
    } catch (_) {
      setState(() {
        _checkingApproval = false;
        _statusError = 'We could not read your driver approval status. Retry to check again.';
      });
    }
  }

  List<Widget> get _pages => <Widget>[
    DeliveryManifestScreen(
      gate: widget.gate,
      onOpenReconciliation: () => setState(() => _index = 2),
    ),
    const DeliveryCanScanScreen(),
    const DeliveryRunCompleteScreen(),
    const DeliveryRunHistoryScreen(),
    const DeliveryEarningsScreen(),
    ProfileScreen(session: widget.gate.session ?? const UserSessionModel(id: '')),
  ];

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final AppThemeData theme = appThemeData[Theme.of(context).brightness == Brightness.dark ? AppTheme.dark : AppTheme.light]!;

    if (_checkingApproval || _statusError != null || _approvalStatus != 'approved') {
      final bool rejected = _approvalStatus == 'rejected';
      final bool blocked = _approvalStatus == 'blocked';
      return Scaffold(
        backgroundColor: theme.scaffoldBg,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        rejected ? Icons.gpp_bad_outlined : blocked ? Icons.pause_circle_outline : Icons.pending_actions_outlined,
                        size: 48,
                        color: rejected || blocked ? AppColors.expired : AppColors.expirySoon,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _checkingApproval
                            ? l10n.checkingDriverApproval
                            : _statusError != null
                                ? l10n.approvalStatusUnavailable
                                : rejected
                                    ? l10n.applicationNotApproved
                                    : blocked
                                        ? l10n.deliveryAccessPaused
                                        : l10n.waitingOutletApproval,
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _statusError ??
                            (rejected
                                    ? (_approvalReason.isNotEmpty ? _approvalReason : l10n.contactOutletOwner)
                                    : blocked
                                        ? l10n.contactOutletToRestore(
                                            _outletName.isEmpty
                                                ? 'the outlet owner'
                                                : _outletName,
                                          )
                                        : l10n.profileSubmittedToOutlet(
                                            _outletName.isEmpty
                                                ? 'the dairy outlet'
                                                : _outletName,
                                          )),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: _checkingApproval ? null : _loadApprovalStatus,
                        icon: const Icon(Icons.refresh),
                        label: Text(l10n.checkAgain),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final List<NavigationDestination> destinations = <NavigationDestination>[
      NavigationDestination(icon: const Icon(Icons.list_alt_outlined), label: l10n.navManifest),
      NavigationDestination(icon: const Icon(Icons.qr_code_scanner_outlined), label: l10n.navScan),
      NavigationDestination(icon: const Icon(Icons.fact_check_outlined), label: l10n.depotReconciliation),
      NavigationDestination(icon: const Icon(Icons.history_outlined), label: l10n.navRunHistory),
      NavigationDestination(icon: const Icon(Icons.payments_outlined), label: l10n.navEarnings),
      NavigationDestination(icon: const Icon(Icons.person_outline), label: l10n.navAccount),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (int value) => setState(() => _index = value),
        backgroundColor: theme.cardBg,
        destinations: destinations,
      ),
    );
  }
}
