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
import 'package:partner/app/modules/local_services/partner/shared/ls_ui.dart';
import 'package:partner/app/modules/local_services/models/lead.dart';
import 'package:partner/app/modules/local_services/repository/provider_repository.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

/// Growth tab: lead board (qualify/invalidate) + upcoming occurrences.
/// Qualifying claims the lead and charges the lead fee once; invalidating
/// an uncharged lead simply closes it, a charged one credits via reversal.
class GrowthScreen extends StatefulWidget {
  const GrowthScreen({super.key});

  @override
  State<GrowthScreen> createState() => _GrowthScreenState();
}

class _GrowthScreenState extends State<GrowthScreen> {
  final LocalServicesProviderRepository _repository =
      LocalServicesProviderRepository();

  bool _loading = true;
  String? _error;
  List<LsLead> _leads = const <LsLead>[];
  List<Map<String, dynamic>> _occurrences = const <Map<String, dynamic>>[];
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
      String? providerId;
      try {
        final DioApiResponse me = await _repository.myProvider();
        final dynamic raw = decodeBody(me)['provider'];
        if (raw is Map<String, dynamic>) {
          providerId = '${raw['_id'] ?? ''}';
        }
      } catch (_) {
        providerId = null;
      }
      final List<DioApiResponse> results = await Future.wait(
        <Future<DioApiResponse>>[
          _repository.leads(),
          _repository.occurrences(),
          _repository.revenueSummary(),
        ],
      );
      final List<dynamic> leadRaw =
          (decodeBody(results[0])['results'] ?? []) as List<dynamic>;
      final List<dynamic> occRaw =
          (decodeBody(results[1])['results'] ?? []) as List<dynamic>;
      final Map<String, dynamic> summary =
          decodeBody(results[2]);
      setState(() {
        _leads = leadRaw
            .whereType<Map<String, dynamic>>()
            .map((Map<String, dynamic> j) =>
                LsLead.fromJson(j, myProviderId: providerId))
            .toList();
        _occurrences = occRaw.whereType<Map<String, dynamic>>().toList();
        _summary = summary;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _qualify(LsLead lead) async {
    try {
      await _repository.qualifyLead(lead.id);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)?.ls_failed_error('$e') ?? 'Failed: $e')),
        );
      }
    }
  }

  Future<void> _invalidate(LsLead lead) async {
    try {
      await _repository.invalidateLead(lead.id);
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
      return LsErrorState(message: _error!, onRetry: _load);
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: <Widget>[
           Text(AppLocalizations.of(context)?.ls_revenue_summary ?? 'Revenue summary',
               style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                    Text(
                      '${AppLocalizations.of(context)?.ls_gross_booking_value ?? 'Gross booking value'}: ${_summary['grossBookingValue'] ?? 0}',
                    ),
                  Text('${AppLocalizations.of(context)?.ls_booking_fees ?? 'Booking fees'}: ${_summary['bookingFees'] ?? 0}'),
                  Text('${AppLocalizations.of(context)?.ls_commission ?? 'Commission'}: ${_summary['commission'] ?? 0}'),
                    Text(
                      '${AppLocalizations.of(context)?.ls_provider_payable ?? 'Provider payable'}: ${_summary['providerPayable'] ?? 0}',
                    ),
                  Text('${AppLocalizations.of(context)?.ls_reversals ?? 'Reversals'}: ${_summary['reversals'] ?? 0}'),
                  Text('${AppLocalizations.of(context)?.ls_net_payable ?? 'Net payable'}: ${_summary['netPayable'] ?? 0}'),
                  Text('${AppLocalizations.of(context)?.ls_total_bookings ?? 'Total bookings'}: ${_summary['totalBookings'] ?? 0}'),
                  Text('${AppLocalizations.of(context)?.ls_completed ?? 'Completed'}: ${_summary['completedBookings'] ?? 0}'),
                  Text('${AppLocalizations.of(context)?.ls_cancelled ?? 'Cancelled'}: ${_summary['cancelledBookings'] ?? 0}'),
                  Text(
                    '${AppLocalizations.of(context)?.ls_conversion_rate ?? 'Conversion rate'}: ${_summary['conversionRate'] ?? 0}%',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context)?.ls_lead_board ?? 'Lead board',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          for (final LsLead l in _leads)
            Card(
              child: ListTile(
                title: Text(l.code.isEmpty ? l.id : l.code),
                subtitle: Text(
                  '${l.status}${l.qualified ? ' · qualified' : ''}${l.mine ? ' · mine' : ''}',
                ),
                trailing: l.qualified
                    ? null
                    : Wrap(
                        spacing: 4,
                        children: <Widget>[
                          TextButton(
                            onPressed: () => _qualify(l),
                            child: Text(AppLocalizations.of(context)?.ls_qualify ?? 'QUALIFY'),
                          ),
                          TextButton(
                            onPressed: () => _invalidate(l),
                            child: Text(AppLocalizations.of(context)?.ls_invalid ?? 'INVALID'),
                          ),
                        ],
                      ),
              ),
            ),
          if (_leads.isEmpty) Text(AppLocalizations.of(context)?.ls_no_leads_board ?? 'No leads on the board'),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context)?.ls_upcoming_occurrences ?? 'Upcoming occurrences',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          for (final Map<String, dynamic> o in _occurrences)
            ListTile(
              dense: true,
              title: Text('${o['occurrenceDate'] ?? ''}'),
              subtitle: Text('${o['status'] ?? ''}'),
            ),
          if (_occurrences.isEmpty) Text(AppLocalizations.of(context)?.ls_none_scheduled ?? 'None scheduled'),
        ],
      ),
    );
  }
}
