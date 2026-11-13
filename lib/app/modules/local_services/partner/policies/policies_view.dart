/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
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

import 'package:flutter/material.dart';
import 'package:partner/app/core/config/api_request_service.dart';
import 'package:partner/app/modules/local_services/repository/provider_repository.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

class PoliciesScreen extends StatefulWidget {
  const PoliciesScreen({super.key});

  @override
  State<PoliciesScreen> createState() => _PoliciesScreenState();
}

class _PoliciesScreenState extends State<PoliciesScreen> {
  final LocalServicesProviderRepository _repository =
      LocalServicesProviderRepository();

  bool _loading = true;
  String? _error;
  List<dynamic> _policies = <dynamic>[];

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
      final DioApiResponse response = await _repository.policies();
      final Map<String, dynamic> body = decodeBody(response);
      setState(() {
        _policies = body['policies'] ?? <dynamic>[];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  String _scopeLabel(Map<String, dynamic> policy) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    if (policy['provider'] != null) {
      return l10n?.ls_scope_provider ?? 'Your business';
    }
    if ('${policy['serviceKey'] ?? ''}'.isNotEmpty) {
      return l10n?.ls_scope_service ?? 'Service';
    }
    if ('${policy['subcategoryKey'] ?? ''}'.isNotEmpty) {
      return l10n?.ls_scope_subcategory ?? 'Subcategory';
    }
    if ('${policy['categoryKey'] ?? ''}'.isNotEmpty) {
      return l10n?.ls_scope_category ?? 'Category';
    }
    return l10n?.ls_scope_platform ?? 'Platform';
  }

  String _number(dynamic value, {int decimals = 0}) {
    final double number = double.tryParse('${value ?? ''}') ?? 0;
    return number.toStringAsFixed(number % 1 == 0 ? 0 : decimals);
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 132,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _policyCard(Map<String, dynamic> policy) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final String fee = _number(policy['cancellationFee'], decimals: 2);
    final String deposit = _number(policy['depositPercent'], decimals: 2);
    final String tax = _number(policy['taxPercent'], decimals: 2);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '${policy['name'] ?? ''}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text(_scopeLabel(policy)),
                ),
              ],
            ),
            if ('${policy['code'] ?? ''}'.isNotEmpty)
              Text(
                '${policy['code']}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if ('${policy['description'] ?? ''}'.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Text('${policy['description']}'),
            ],
            const SizedBox(height: 8),
            _row(
              l10n?.ls_policy_cancellation ?? 'Cancellation',
              '${_number(policy['cancellationCutoffHours'])}h A� ₹$fee',
            ),
            _row(
              l10n?.ls_policy_reschedule ?? 'Reschedule',
              '${_number(policy['rescheduleCutoffHours'])}h A� '
              '${l10n?.ls_limit ?? 'Limit'} '
              '${_number(policy['rescheduleCountLimit'])}',
            ),
            _row(
              l10n?.ls_policy_quote_expiry ?? 'Quote expiry',
              '${_number(policy['quoteExpiryHours'])}h '
              '(max ${_number(policy['quoteMaxExpiryHours'])}h)',
            ),
            _row(
              l10n?.ls_policy_booking_window ?? 'Booking window',
              '${_number(policy['advanceBookingDays'])}d A� '
              '${l10n?.ls_min_notice ?? 'Min notice'} '
              '${_number(policy['minNoticeHours'])}h',
            ),
            _row(
              l10n?.ls_policy_deposit ?? 'Deposit',
              '$deposit%',
            ),
            if (double.tryParse('${policy['taxPercent'] ?? 0}') != 0)
              _row(
                l10n?.ls_policy_tax ?? 'Tax',
                '$tax% ${policy['taxLabel'] ?? ''}',
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.ls_policies_title ?? 'Policies'),
        actions: <Widget>[
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
            tooltip: l10n?.ls_refresh ?? 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _load,
                        child: Text(l10n?.ls_retry ?? 'Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          l10n?.ls_policies_note ??
                              'These rules apply to your services. Contact '
                                  'support to request a change.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      if (_policies.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 48),
                          child: Column(
                            children: <Widget>[
                              const Icon(Icons.gavel_outlined, size: 48),
                              const SizedBox(height: 12),
                              Text(
                                l10n?.ls_no_policies ??
                                    'No active policies apply to your services',
                              ),
                            ],
                          ),
                        )
                      else
                        for (final dynamic raw in _policies)
                          _policyCard(
                            (raw as Map).cast<String, dynamic>(),
                          ),
                    ],
                  ),
                ),
    );
  }
}
