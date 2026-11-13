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

import 'package:partner/app/core/config/api_request_service.dart';
import 'package:partner/app/core/repositories/partner_repository.dart';
import 'package:partner/app/presentation/styles/theme.dart';
import 'package:partner/app/presentation/styles/widgets.dart';
import 'package:partner/gen/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Delivery runs for the outlet, newest first.
///
/// Backed by `POST /partner/runs/list/{id}`. A partner uses this to watch
/// today's routes rather than to drive them — the rider app owns the run
/// lifecycle.
class PartnerDeliveryRunListScreen extends StatefulWidget {
  const PartnerDeliveryRunListScreen({super.key});

  @override
  State<PartnerDeliveryRunListScreen> createState() =>
      _PartnerDeliveryRunListScreenState();
}

class _PartnerDeliveryRunListScreenState extends State<PartnerDeliveryRunListScreen> {
  final PartnerRepository _partnerRepository = PartnerRepository();

  bool _loading = true;
  String? _error;
  List<dynamic> _runs = const <dynamic>[];

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

    final DioApiResponse response = await _partnerRepository.runs();

    if (!mounted) return;

    if (response.errorType != NetErrorType.none) {
      setState(() {
        _loading = false;
        _error = AppLocalizations.of(context)!.couldNotLoadRuns;
      });
      return;
    }
final Map<String, dynamic> body = decodeBody(response);
    setState(() {
      _loading = false;
      _runs = (body['runs'] as List?) ?? const <dynamic>[];
    });
  }

  int _stops(Map<String, dynamic> run) {
    final Map<String, dynamic> totals =
        Map<String, dynamic>.from((run['totals'] as Map?) ?? <String, dynamic>{});
    return int.tryParse(totals['stopCount']?.toString() ?? '') ?? 0;
  }

  int _cans(Map<String, dynamic> run) {
    final Map<String, dynamic> totals =
        Map<String, dynamic>.from((run['totals'] as Map?) ?? <String, dynamic>{});
    return int.tryParse(totals['cansOut']?.toString() ?? '') ?? 0;
  }

  String _slot(Map<String, dynamic> run) {
    final Map<String, dynamic> slot =
        Map<String, dynamic>.from((run['slot'] as Map?) ?? <String, dynamic>{});
    final String from = slot['startTime']?.toString() ?? '';
    final String to = slot['endTime']?.toString() ?? '';
    if (from.isEmpty && to.isEmpty) return '';
    return '$from–$to';
  }

  String _statusLabel(String status, AppLocalizations l10n) {
    switch (status) {
      case 'planned':
        return l10n.runStatusPlanned;
      case 'dispatched':
        return l10n.runStatusDispatched;
      case 'in_progress':
        return l10n.runStatusInProgress;
      case 'completed':
        return l10n.runStatusCompleted;
      case 'cancelled':
        return l10n.runStatusCancelled;
      default:
        return status.isEmpty ? l10n.unknownStatus : status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final AppThemeData theme = appThemeData[Theme.of(context).brightness == Brightness.dark ? AppTheme.dark : AppTheme.light]!;
    final List<Map<String, dynamic>> runs = _runs
        .whereType<Map>()
        .map((Map row) => Map<String, dynamic>.from(row))
        .toList();
    final int activeRuns = runs.where((Map<String, dynamic> run) {
      final String status = run['status']?.toString() ?? '';
      return status == 'dispatched' || status == 'in_progress';
    }).length;
    final int activeStops = runs.fold<int>(0, (int total, Map<String, dynamic> run) {
      final String status = run['status']?.toString() ?? '';
      return total + (status == 'dispatched' || status == 'in_progress' ? _stops(run) : 0);
    });

    return SectionListScreen(
      title: l10n.todayRuns,
      icon: Icons.route_outlined,
      onRefresh: _load,
      children: <Widget>[
        if (!_loading && _error == null && runs.isNotEmpty)
          Row(
            children: <Widget>[
              Expanded(
                child: MetricTile(
                  label: 'Delivery runs',
                  value: '${runs.length}',
                  icon: Icons.route_outlined,
                ),
              ),
              Expanded(
                child: MetricTile(
                  label: 'Stops on active runs',
                  value: '$activeStops',
                  icon: Icons.location_on_outlined,
                  accent: activeRuns > 0 ? AppColors.canWithAgent : AppColors.canInStore,
                ),
              ),
            ],
          ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          EmptyState(
            title: l10n.runsUnavailable,
            message: _error!,
            icon: Icons.cloud_off_outlined,
          )
        else if (_runs.isEmpty)
          EmptyState(
            title: l10n.noRunsYet,
            message: l10n.noRunsYetHint,
            icon: Icons.route_outlined,
          )
        else
          Card(
            child: Column(
              children: runs.asMap().entries.map((MapEntry<int, Map<String, dynamic>> entry) {
                final Map<String, dynamic> run = entry.value;
                final String status = run['status']?.toString() ?? '';
                final String serviceDate =
                    run['serviceDate']?.toString().split('T').first ?? '';

                return Column(
                  children: <Widget>[
                    if (entry.key > 0)
                      const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.primary.withValues(alpha: 0.12),
                        child: Icon(Icons.route_outlined, color: theme.primary),
                      ),
                      title: Text('${run['runNo'] ?? '—'}'),
                      subtitle: Text(
                        <String>[
                          serviceDate,
                          if (_slot(run).isNotEmpty) _slot(run),
                          '${_stops(run)} ${l10n.stops}',
                          '${_cans(run)} ${l10n.cans}',
                        ].join(' · '),
                      ),
                      trailing: StatusChip(
                        label: _statusLabel(status, l10n),
                        color: status == 'completed' ? AppColors.canInStore : theme.primary,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
