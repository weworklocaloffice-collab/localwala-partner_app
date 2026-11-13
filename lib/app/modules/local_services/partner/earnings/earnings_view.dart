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

/// Provider earnings from the revenue summary (server-computed, rupees).
/// GBV vs collected vs payable vs net stay distinct — never netted here.
class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  final LocalServicesProviderRepository _repository =
      LocalServicesProviderRepository();

  bool _loading = true;
  String? _error;
  Map<String, dynamic> _summary = const <String, dynamic>{};

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
      final DioApiResponse response = await _repository.revenueSummary();
      setState(() {
        _summary = decodeBody(response);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Widget _tile(String label, dynamic value) => ListTile(
        title: Text(label),
        trailing: Text(
          '₹$value',
          style: const TextStyle(fontWeight: FontWeight.bold),
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
      child: ListView(
        children: <Widget>[
          _tile(AppLocalizations.of(context)?.ls_gross_booking_value ?? 'Gross booking value', _summary['grossBookingValue'] ?? 0),
          _tile(AppLocalizations.of(context)?.ls_booking_fees ?? 'Booking fees', _summary['bookingFees'] ?? 0),
          _tile(AppLocalizations.of(context)?.ls_commission ?? 'Commission', _summary['commission'] ?? 0),
          _tile(AppLocalizations.of(context)?.ls_provider_payable ?? 'Provider payable', _summary['providerPayable'] ?? 0),
          _tile(AppLocalizations.of(context)?.ls_reversals ?? 'Reversals', _summary['reversals'] ?? 0),
        ],
      ),
    );
  }
}
