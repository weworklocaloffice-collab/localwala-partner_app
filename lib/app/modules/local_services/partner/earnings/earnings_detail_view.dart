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

/// Detailed provider earnings breakdown (per-booking, commission, payable).
/// Mirrors the revenue summary structure but with per-booking granularity.
class EarningsDetailScreen extends StatefulWidget {
  const EarningsDetailScreen({super.key});

  @override
  State<EarningsDetailScreen> createState() => _EarningsDetailScreenState();
}

class _EarningsDetailScreenState extends State<EarningsDetailScreen> {
  final LocalServicesProviderRepository _repository =
      LocalServicesProviderRepository();
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _summary = const <String, dynamic>{};
  List<dynamic> _bookings = const <dynamic>[];

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
      // Load summary
      final DioApiResponse sumRes = await _repository.revenueSummary();
      setState(() {
        _summary = decodeBody(sumRes);
      });

      // Load bookings for the period
      final DioApiResponse bookRes = await _repository.bookings();
      final Map<String, dynamic> bookBody = decodeBody(bookRes);
      final List<dynamic> raw =
          (bookBody['results'] ?? bookBody['data'] ?? []) as List<dynamic>;
      setState(() {
        _bookings = raw.whereType<Map<String, dynamic>>().toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final int totalBookings = _bookings.length;
    final double totalGross = (_summary['grossBookingValue'] ?? 0) as double;
    final double totalCommission = (_summary['commission'] ?? 0) as double;
    final double totalPayable = (_summary['providerPayable'] ?? 0) as double;

    return Scaffold(
       appBar: AppBar(title: Text(AppLocalizations.of(context)?.ls_earnings_detail ?? 'Earnings Detail')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Summary cards row
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _card(
                          AppLocalizations.of(context)?.ls_total_bookings ?? 'Total Bookings',
                          '$totalBookings',
                          Icons.calendar_today,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _card(
                          AppLocalizations.of(context)?.ls_gross_value ?? 'Gross Value',
                          '₹$totalGross',
                          Icons.trending_up,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _card(
                          AppLocalizations.of(context)?.ls_commission ?? 'Commission',
                          '₹$totalCommission',
                          Icons.percent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _card(
                          AppLocalizations.of(context)?.ls_payable ?? 'Payable',
                          '₹$totalPayable',
                          Icons.account_balance_wallet,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Per-booking list
                  Text(
                    AppLocalizations.of(context)?.ls_booking_breakdown ?? 'Booking Breakdown',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _bookings.isEmpty
                      ? Center(child: Text(AppLocalizations.of(context)?.ls_no_bookings_period ?? 'No bookings in period'))
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: _bookings.length,
                          itemBuilder: (BuildContext context, int i) {
                            final dynamic b = _bookings[i];
                            final String status = b['status'] ?? '';
                            final double labour =
                                (b['labourAmount'] ?? 0) as double;
                            final double parts =
                                (b['partsAmount'] ?? 0) as double;
                            final double commission =
                                (b['commission'] ?? 0) as double;
                            final double payable =
                                (b['providerPayable'] ?? 0) as double;
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: ListTile(
                                title: Text('${AppLocalizations.of(context)?.ls_booking ?? 'Booking'} ${i + 1} · $status'),
                                subtitle: Text(
                                  '${AppLocalizations.of(context)?.ls_labour ?? 'Labour'} ₹$labour · '
                                  '${AppLocalizations.of(context)?.ls_parts ?? 'Parts'} ₹$parts · '
                                  '${AppLocalizations.of(context)?.ls_commission ?? 'Commission'} ₹$commission · '
                                  '${AppLocalizations.of(context)?.ls_payable ?? 'Payable'} ₹$payable',
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
    );
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
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(label),
        ],
      ),
    ),
  );
}
