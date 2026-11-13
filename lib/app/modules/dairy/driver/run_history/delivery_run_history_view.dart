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

import 'package:partner/app/core/config/api_request_service.dart';
import 'package:partner/app/core/repositories/delivery_repository.dart';
import 'package:partner/app/presentation/styles/theme.dart';
import 'package:partner/app/presentation/styles/widgets.dart';
import 'package:partner/gen/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Past runs for the signed-in rider.
///
/// `GET /driver/runs/history` resolves the rider from the token, so this screen
/// never carries an id. Pagination is explicit rather than infinite: a rural
/// rider on a weak connection should not trigger a fetch just by scrolling.
class DeliveryRunHistoryScreen extends StatefulWidget {
  const DeliveryRunHistoryScreen({super.key});

  @override
  State<DeliveryRunHistoryScreen> createState() => _DeliveryRunHistoryScreenState();
}

class _DeliveryRunHistoryScreenState extends State<DeliveryRunHistoryScreen> {
  final DeliveryRepository _repository = DeliveryRepository();

  static const int _limit = 10;

  bool _loading = true;
  bool _loadingMore = false;
  bool _failed = false;
  int _page = 1;
  int _total = 0;
  final List<Map<String, dynamic>> _runs = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });

    final DioApiResponse response = await _repository.runHistory(
      page: 1,
      limit: _limit,
    );

    if (!mounted) return;

    if (response.errorType != NetErrorType.none) {
      setState(() {
        _loading = false;
        _failed = true;
      });
      return;
    }

    final Map<String, dynamic> body = decodeBody(response);
    final List<Map<String, dynamic>> runs =
        (body['runs'] as List<dynamic>? ?? <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .toList();

    setState(() {
      _loading = false;
      _page = 1;
      _total = (body['totalResults'] as num?)?.toInt() ?? runs.length;
      _runs
        ..clear()
        ..addAll(runs);
    });
  }

  Future<void> _loadMore() async {
    if (_loadingMore) return;
    setState(() => _loadingMore = true);

    final DioApiResponse response = await _repository.runHistory(
      page: _page + 1,
      limit: _limit,
    );

    if (!mounted) return;

    if (response.errorType != NetErrorType.none) {
      setState(() => _loadingMore = false);
      return;
    }

    final Map<String, dynamic> body = decodeBody(response);
    final List<Map<String, dynamic>> runs =
        (body['runs'] as List<dynamic>? ?? <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .toList();

    setState(() {
      _loadingMore = false;
      _page += 1;
      _total = (body['totalResults'] as num?)?.toInt() ?? _total;
      _runs.addAll(runs);
    });
  }

  String _date(Object? raw) {
    final DateTime? date = DateTime.tryParse(raw?.toString() ?? '');
    if (date == null) return '';
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year}';
  }

  String _statusLabel(AppLocalizations l10n, String status) {
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
        return status;
    }
  }

  Color _statusColour(String status) {
    switch (status) {
      case 'completed':
        return AppColors.canInStore;
      case 'in_progress':
        return AppColors.expirySoon;
      case 'cancelled':
        return AppColors.expired;
      default:
        return AppColors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return SectionListScreen(
      title: l10n.navRunHistory,
      icon: Icons.history_outlined,
      onRefresh: _load,
      children: <Widget>[
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_failed)
          EmptyState(
            title: l10n.runsUnavailable,
            message: l10n.somethingWentWrong,
            icon: Icons.cloud_off_outlined,
          )
        else if (_runs.isEmpty)
          EmptyState(
            title: l10n.noPastRuns,
            message: l10n.noPastRunsHint,
            icon: Icons.history_toggle_off_outlined,
          )
        else ...<Widget>[
          ..._runs.map((Map<String, dynamic> run) {
            final String status = run['status']?.toString() ?? 'planned';
            final Map<String, dynamic> totals = Map<String, dynamic>.from(
              (run['totals'] as Map?) ?? <String, dynamic>{},
            );
            final int stops = (totals['stopCount'] as num?)?.toInt() ?? 0;
            final int cans = (totals['cansOut'] as num?)?.toInt() ?? 0;

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _statusColour(status).withValues(alpha: 0.14),
                  child: Text(
                    '${run['runNo'] ?? ''}',
                    style: TextStyle(
                      color: _statusColour(status),
                      fontFamily: 'semibold',
                    ),
                  ),
                ),
                title: Text('${l10n.runLabel} #${run['runNo'] ?? '—'}'),
                subtitle: Text(
                  '${_date(run['serviceDate'])} · $stops ${l10n.stops} · '
                  '$cans ${l10n.cans}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                trailing: StatusChip(
                  label: _statusLabel(l10n, status),
                  color: _statusColour(status),
                ),
              ),
            );
          }),
          if (_runs.length < _total)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: OutlinedButton(
                onPressed: _loadingMore ? null : _loadMore,
                child: _loadingMore
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.loadMore),
              ),
            ),
        ],
      ],
    );
  }
}
