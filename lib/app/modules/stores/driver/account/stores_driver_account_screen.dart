/*
 * WeWorkLocal
 * Hyperlocal Commerce & Service Platform
 *
 * Copyright Ac 2026 WeWorkLocal.
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
import 'package:partner/app/core/repositories/auth_repository.dart';
import 'package:partner/app/modules/stores/stores_partner_repository.dart';
import 'package:partner/app/modules/stores/widgets/stores_ui_states.dart';
import 'package:partner/app/router/app_route_config.dart';
import 'package:partner/gen/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Store-driver account tab.
///
/// Deliberately not the shared dairy `ProfileScreen`: that screen renders dairy
/// fulfilment and payout configuration (platform fleet, driver payout responsibility),
/// none of which exists in stores. Delivery here is store-owned (BR-04) and the outlet
/// pays its own rider, so showing the dairy model would state the opposite of the truth.
class StoresDriverAccountScreen extends StatefulWidget {
  const StoresDriverAccountScreen({super.key, required this.session});

  final UserSessionModel session;

  @override
  State<StoresDriverAccountScreen> createState() => _StoresDriverAccountScreenState();
}

class _StoresDriverAccountScreenState extends State<StoresDriverAccountScreen> {
  final AuthRepository _authRepository = AuthRepository();
  StoresDriverRepository? _repo;
  bool _loggingOut = false;

  @override
  void initState() {
    super.initState();
    _repo = StoresDriverRepository();
  }

  void _reload() {
    setState(() => _repo = StoresDriverRepository());
  }

  Future<void> _confirmLogout() async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(l10n.logout),
        content: const Text('You will need to sign in again to receive deliveries.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.storesActionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.logout),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _loggingOut = true);
    await _authRepository.logout();
    if (!mounted) return;
    AppRouter.pushNamedAndRemoveAll(context, AppRouter.loginRoute);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final UserSessionModel session = widget.session;
    final StoresDriverRepository repo = _repo ?? StoresDriverRepository();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.storesNavAccount),
        actions: <Widget>[
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: StoresAsyncView<Map<String, dynamic>>(
        future: repo.earnings(),
        builder: (BuildContext context, Map<String, dynamic> data) {
          final Map<String, dynamic> driver =
              (data['driver'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
          final String name = '${session.firstName} ${session.lastName}'.trim();
          final String mobile = session.mobile == null
              ? (session.email ?? '')
              : '+${session.countryCode ?? ''}${session.mobile}';

          return ListView(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 28,
                      child: Text(
                        _initials(name),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(name.isEmpty ? 'Store driver' : name, style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 2),
                          Text(mobile, style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const StoresSectionHeader(title: 'Driver'),
              if (driver['driverCode'] != null)
                ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: const Text('Driver code'),
                  trailing: Text('${driver['driverCode']}'),
                ),
              if (driver['rating'] != null)
                ListTile(
                  leading: const Icon(Icons.star_outline),
                  title: const Text('Rating'),
                  trailing: Text('${driver['rating']}'),
                ),
              ListTile(
                leading: const Icon(Icons.storefront_outlined),
                title: const Text('Delivery model'),
                subtitle: const Text('Owned by your store, paid by your store'),
              ),
              const StoresSectionHeader(title: 'Account'),
              ListTile(
                leading: const Icon(Icons.support_agent_outlined),
                title: Text(l10n.storesTitleSupport),
                trailing: const Icon(Icons.chevron_right),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                child: OutlinedButton.icon(
                  onPressed: _loggingOut ? null : _confirmLogout,
                  icon: const Icon(Icons.logout),
                  label: Text(l10n.logout),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _initials(String name) {
    final List<String> parts = name
        .split(RegExp(r'\s+'))
        .where((String part) => part.isNotEmpty)
        .take(2)
        .toList();
    if (parts.isEmpty) return 'D';
    return parts.map((String part) => part[0].toUpperCase()).join();
  }
}
