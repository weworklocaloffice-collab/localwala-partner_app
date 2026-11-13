/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

import 'package:flutter/material.dart';
import 'package:partner/app/core/config/api_request_service.dart';
import 'package:partner/app/modules/local_services/repository/provider_repository.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

/// Partner subscriptions: list active plans and the provider's current
/// subscription; subscribe to a plan.
class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  final LocalServicesProviderRepository _repository =
      LocalServicesProviderRepository();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _plans = const <Map<String, dynamic>>[];
  Map<String, dynamic>? _subscription;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final DioApiResponse res = await _repository.subscriptions();
      final Map<String, dynamic> body = decodeBody(res);
      final List<dynamic> rawPlans = (body['plans'] ?? []) as List<dynamic>;
      setState(() {
        _plans = rawPlans.whereType<Map<String, dynamic>>().toList();
        final dynamic rawSub = body['subscription'];
        _subscription = rawSub is Map<String, dynamic> ? rawSub : null;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _subscribe(String planId) async {
    try {
      await _repository.subscribePlan(planId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)?.ls_subscribed ?? 'Subscribed')),
        );
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)?.ls_failed_error('$e') ?? 'Failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(_error!),
            TextButton(onPressed: _load, child: Text(AppLocalizations.of(context)?.ls_retry ?? 'Retry')),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: <Widget>[
          if (_subscription != null) ...<Widget>[
            Text(AppLocalizations.of(context)?.ls_current_subscription ?? 'Current subscription',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('${AppLocalizations.of(context)?.ls_plan ?? 'Plan'}: ${_subscription!['plan']?['name'] ?? _subscription!['plan'] ?? ''}'),
                    Text('${AppLocalizations.of(context)?.ls_status ?? 'Status'}: ${_subscription!['status'] ?? ''}'),
                    Text('${AppLocalizations.of(context)?.ls_renews ?? 'Renews'}: ${_subscription!['renewAt'] ?? ''}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(AppLocalizations.of(context)?.ls_available_plans ?? 'Available plans',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          for (final Map<String, dynamic> p in _plans)
            Card(
              child: ListTile(
                title: Text('${p['name'] ?? p['code'] ?? ''}'),
                subtitle: Text(
                  '${p['interval'] ?? ''} · ${p['price'] ?? 0} · ${(p['entitlements'] as List?)?.join(', ') ?? ''}',
                ),
                trailing: TextButton(
                  onPressed: () => _subscribe('${p['_id'] ?? p['id'] ?? ''}'),
                  child: Text(AppLocalizations.of(context)?.ls_subscribe ?? 'SUBSCRIBE'),
                ),
              ),
            ),
          if (_plans.isEmpty) Text(AppLocalizations.of(context)?.ls_no_plans ?? 'No plans available'),
        ],
      ),
    );
  }
}
