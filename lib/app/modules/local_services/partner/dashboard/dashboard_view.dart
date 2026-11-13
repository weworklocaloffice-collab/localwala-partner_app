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

/// Provider home: today's jobs, action-needed count, earnings snapshot.
/// Read-only aggregates over existing endpoints — no new backend needed.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final LocalServicesProviderRepository _repository =
      LocalServicesProviderRepository();

  bool _loading = true;
  String? _error;
  int _today = 0;
  int _needAction = 0;
  Map<String, dynamic> _earnings = const <String, dynamic>{};

  static const List<String> _actionable = <String>[
    'PENDING_PROVIDER',
    'ACCEPTED',
    'CONFIRMED',
    'IN_PROGRESS',
  ];

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
      final List<DioApiResponse> results = await Future.wait(
        <Future<DioApiResponse>>[
          _repository.bookings(),
          _repository.revenueSummary(),
        ],
      );
      final Map<String, dynamic> bookingsBody = decodeBody(results[0]);
      final List<dynamic> raw =
          (bookingsBody['results'] ?? bookingsBody['data'] ?? [])
              as List<dynamic>;
      final DateTime now = DateTime.now();
      int today = 0;
      int needAction = 0;
      for (final dynamic item in raw) {
        if (item is! Map<String, dynamic>) continue;
        final String status = '${item['status'] ?? ''}';
        if (_actionable.contains(status)) needAction += 1;
        final dynamic when = item['scheduledAt'] ?? item['startAt'];
        final DateTime? dt = when == null ? null : DateTime.tryParse('$when');
        if (dt != null &&
            dt.year == now.year &&
            dt.month == now.month &&
            dt.day == now.day) {
          today += 1;
        }
      }
      setState(() {
        _today = today;
        _needAction = needAction;
        _earnings = decodeBody(results[1]);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Widget _card(String label, String value, IconData icon) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: <Widget>[
              Icon(icon, size: 28),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(label),
            ],
          ),
        ),
      );

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
      child: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(12),
        children: <Widget>[
          _card(AppLocalizations.of(context)?.ls_todays_jobs ?? "Today's jobs", '$_today', Icons.today_outlined),
          _card(AppLocalizations.of(context)?.ls_need_action ?? 'Need action', '$_needAction', Icons.pending_actions_outlined),
          _card(
            AppLocalizations.of(context)?.ls_payable ?? 'Payable',
            '₹${_earnings['providerPayable'] ?? 0}',
            Icons.account_balance_wallet_outlined,
          ),
          _card(
            AppLocalizations.of(context)?.ls_completed_value ?? 'Completed value',
            '₹${_earnings['grossBookingValue'] ?? 0}',
            Icons.trending_up_outlined,
          ),
        ],
      ),
    );
  }
}
