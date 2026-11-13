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
import 'package:partner/app/core/repositories/partner_repository.dart';
import 'package:partner/app/modules/dairy/partner/dashboard/partner_dashboard_view.dart';
import 'package:partner/app/modules/dairy/partner/inventory/partner_inventory_view.dart';
import 'package:partner/app/modules/dairy/partner/order_list/partner_order_list_view.dart';
import 'package:partner/app/modules/dairy/partner/partner_more_view.dart';
import 'package:partner/app/modules/dairy/partner/partner_outlet_picker_view.dart';
import 'package:partner/app/modules/dairy/partner/partner_outlet_location_view.dart';
import 'package:partner/app/modules/dairy/partner/subscription_list/partner_subscription_list_view.dart';
import 'package:partner/app/shell/role_gate/bloc/role_gate_bloc.dart';
import 'package:partner/app/presentation/styles/theme.dart';
import 'package:partner/gen/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:partner/app/core/config/shared_pref_keys.dart';

/// Partner (outlet) nav tree.
///
/// Five primary destinations keep the high-use workflows reachable without
/// compressing eight labels into the bottom bar. Operational and account tools
/// are grouped under More.
class PartnerShellScreen extends StatefulWidget {
  const PartnerShellScreen({super.key, required this.gate});

  /// Resolved session passed down by `AppHomeScreen`. Passing it explicitly
  /// keeps every child off the bloc lookup, which matters because this shell
  /// rebuilds all destinations on role change.
  final RoleGateState gate;

  @override
  State<PartnerShellScreen> createState() => _PartnerShellScreenState();
}

class _PartnerShellScreenState extends State<PartnerShellScreen> {
  int _index = 0;
  final PartnerRepository _repository = PartnerRepository();
  bool _locationComplete = false;
  bool _outletVerified = false;
  bool _checkingLocation = true;
  bool _locationCheckFailed = false;
  bool _outletContextLoading = true;
  bool _outletContextFailed = false;
  bool _outletSelectionRequired = false;
  String? _activeOutletId;
  String _activeOutletName = '';
  List<Map<String, dynamic>> _outlets = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _prepareOutletContext();
  }

  Future<void> _prepareOutletContext() async {
    final DioApiResponse response = await _repository.dairyOutlets();
    if (!mounted) return;
    if (response.errorType != NetErrorType.none) {
      setState(() { _outletContextLoading = false; _outletContextFailed = true; });
      return;
    }
    final Map<String, dynamic> body = decodeBody(response);
    final List<dynamic> raw = body['outlets'] is List ? body['outlets'] as List<dynamic> : <dynamic>[];
    final List<Map<String, dynamic>> outlets = raw.whereType<Map>().map((Map row) => Map<String, dynamic>.from(row)).toList();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? saved = prefs.getString(SharedPreferencesKey.authKeys.activeDairyOutlet);
    Map<String, dynamic>? selected;
    for (final Map<String, dynamic> row in outlets) {
      if ((row['id'] ?? row['_id'])?.toString() == saved) {
        selected = row;
        break;
      }
    }
    _outlets = outlets;
    if (outlets.length == 1) {
      final String id = (outlets.first['id'] ?? outlets.first['_id']).toString();
      await _activateOutlet(id, outlets.first, persist: true);
      return;
    }
    if (selected != null && saved != null) {
      await _activateOutlet(saved, selected, persist: false);
      return;
    }
    setState(() {
      _outlets = outlets;
      _outletSelectionRequired = outlets.length > 1;
      _outletContextLoading = false;
      _outletContextFailed = false;
    });
    if (outlets.length <= 1) await _refreshLocationStatus();
  }

  Future<void> _activateOutlet(String id, Map<String, dynamic> outlet, {required bool persist}) async {
    final DioApiResponse selected = await _repository.selectDairyOutlet(id);
    if (!mounted) return;
    if (selected.errorType != NetErrorType.none) {
      setState(() { _outletContextLoading = false; _outletContextFailed = true; });
      return;
    }
    if (persist) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(SharedPreferencesKey.authKeys.activeDairyOutlet, id);
    }
    setState(() {
      _activeOutletId = id;
      _activeOutletName = outlet['name']?.toString() ?? 'Dairy outlet';
      _outletSelectionRequired = false;
      _outletContextLoading = false;
      _outletContextFailed = false;
      _index = 0;
    });
    await _refreshLocationStatus();
  }

  Future<void> _refreshLocationStatus() async {
    if (mounted) setState(() { _checkingLocation = true; _locationCheckFailed = false; });
    final DioApiResponse response = await _repository.partnerBusinessProfile();
    if (!mounted) return;
    if (response.errorType != NetErrorType.none) {
      setState(() {
      _checkingLocation = false;
      _locationComplete = false;
      _outletVerified = false;
      _locationCheckFailed = true;
      });
      return;
    }
    final Map<String, dynamic> body = decodeBody(response);
    final Map<String, dynamic> profile = body['profile'] is Map
        ? Map<String, dynamic>.from(body['profile'] as Map)
        : <String, dynamic>{};
    setState(() {
      _checkingLocation = false;
      _locationComplete = profile['locationComplete'] == true;
      _outletVerified = profile['verified'] == true;
      _locationCheckFailed = false;
    });
  }

  List<Widget> get _pages => <Widget>[
    PartnerDashboardScreen(
      gate: widget.gate,
      outletLocationComplete: _locationComplete,
      outletVerified: _outletVerified,
      onCompleteOutletLocation: _outletVerified ? _openOutletLocation : null,
      onRefreshOutletStatus: _refreshLocationStatus,
      onNavigate: _selectDestination,
    ),
    if (_outletVerified && _locationComplete) const PartnerOrderListScreen() else _lockedDestination('Orders'),
    if (_outletVerified && _locationComplete) const PartnerInventoryScreen() else _lockedDestination('Products and inventory'),
    if (_outletVerified && _locationComplete) const PartnerSubscriptionListScreen() else _lockedDestination('Subscriptions'),
    PartnerMoreScreen(
      session: widget.gate.session ?? const UserSessionModel(id: ''),
      outletVerified: _outletVerified,
      locationComplete: _locationComplete,
      onLocationRequired: _showLocationRequired,
      onOpenLocationSetup: _openOutletLocation,
      onRefreshOutletStatus: _refreshLocationStatus,
      activeOutletName: _activeOutletName,
      outletCount: _outlets.length,
      onChangeOutlet: _outlets.length > 1 ? _showOutletPicker : null,
    ),
  ];

  Future<void> _showOutletPicker() async {
    final String? selectedId = await Navigator.of(context).push<String>(MaterialPageRoute<String>(
      builder: (_) => PartnerOutletPickerScreen(
        outlets: _outlets,
        onSelect: (String id) => Navigator.of(context).pop(id),
      ),
    ));
    if (selectedId == null || !mounted) return;
    final Map<String, dynamic> selected = _outlets.firstWhere((Map<String, dynamic> row) => (row['id'] ?? row['_id']).toString() == selectedId);
    await _activateOutlet(selectedId, selected, persist: true);
  }

  Widget _lockedDestination(String section) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
        const Icon(Icons.location_off_outlined, size: 44),
        const SizedBox(height: 12),
        Text(
          _outletVerified
              ? '$section are locked until you set the outlet address and map pin.'
              : '$section will be available after admin verification and outlet location setup.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _showLocationRequired,
          icon: Icon(_outletVerified ? Icons.add_location_alt_outlined : Icons.verified_user_outlined),
          label: Text(_outletVerified ? 'Complete outlet location' : 'Check verification status'),
        ),
      ]),
    ),
  );

  void _selectDestination(int index) {
    if ((!_outletVerified || !_locationComplete) && index != 0 && index != 4) {
      _showLocationRequired();
      return;
    }
    setState(() => _index = index);
  }

  Future<void> _showLocationRequired() async {
    if (!mounted) return;
    final bool canSetLocation = _outletVerified && !_checkingLocation && !_locationCheckFailed;
    final String title = _locationCheckFailed
        ? 'Could not check outlet status'
        : _checkingLocation
            ? 'Checking outlet status'
            : !_outletVerified
                ? 'Admin verification pending'
                : 'Outlet location required';
    final String message = _locationCheckFailed
        ? 'We could not verify your outlet status. Check your connection and try again.'
        : _checkingLocation
            ? 'Please wait while we check your account and outlet location.'
            : !_outletVerified
                ? 'The outlet address and map pin setup will become available after Admin verifies your partner account.'
                : 'Add the complete physical outlet address and confirm the map pin before creating products, managing inventory, or changing business availability.';
    final bool? action = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        icon: Icon(canSetLocation ? Icons.add_location_alt_outlined : Icons.verified_user_outlined),
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Later')),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(canSetLocation ? 'Set location' : 'Check again'),
          ),
        ],
      ),
    );
    if (action == true && mounted) {
      if (canSetLocation) {
        await _openOutletLocation();
      } else {
        await _refreshLocationStatus();
      }
    }
  }

  Future<void> _openOutletLocation() async {
    if (!_outletVerified) {
      await _showLocationRequired();
      return;
    }
    await Navigator.of(context).push<bool>(MaterialPageRoute<bool>(
      builder: (_) => PartnerOutletLocationScreen(onSaved: () { _refreshLocationStatus(); }),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_outletContextLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_outletSelectionRequired) {
      return PartnerOutletPickerScreen(
        outlets: _outlets,
        loading: false,
        onSelect: (String id) async {
          final Map<String, dynamic> selected = _outlets.firstWhere((Map<String, dynamic> row) => (row['id'] ?? row['_id']).toString() == id);
          await _activateOutlet(id, selected, persist: true);
        },
      );
    }
    if (_outletContextFailed) {
      return Scaffold(body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
        const Text('We could not verify your outlet access.'),
        const SizedBox(height: 12),
        FilledButton(onPressed: _prepareOutletContext, child: const Text('Try again')),
      ])));
    }
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final AppThemeData theme = appThemeData[Theme.of(context).brightness == Brightness.dark ? AppTheme.dark : AppTheme.light]!;

    final List<NavigationDestination> destinations = <NavigationDestination>[
      NavigationDestination(icon: const Icon(Icons.dashboard_outlined), label: l10n.navHome),
      NavigationDestination(icon: const Icon(Icons.receipt_long_outlined), label: l10n.navOrders),
      NavigationDestination(icon: const Icon(Icons.inventory_2_outlined), label: l10n.navInventory),
      NavigationDestination(icon: const Icon(Icons.event_repeat_outlined), label: l10n.navSubscriptions),
      NavigationDestination(icon: const Icon(Icons.more_horiz), label: l10n.storesNavMore),
    ];

    return Scaffold(
      body: KeyedSubtree(key: ValueKey<String>(_activeOutletId ?? 'default'), child: IndexedStack(index: _index, children: _pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _selectDestination,
        backgroundColor: theme.cardBg,
        destinations: destinations,
      ),
    );
  }
}
