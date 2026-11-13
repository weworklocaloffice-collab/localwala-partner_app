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

import 'dart:convert';

import 'package:partner/app/core/config/api_request_service.dart';
import 'package:partner/app/core/repositories/delivery_repository.dart';
import 'package:partner/app/core/services/offline_delivery_queue.dart';
import 'package:partner/app/modules/dairy/driver/driver_location.dart';
import 'package:partner/app/presentation/styles/theme.dart';
import 'package:partner/app/presentation/styles/widgets.dart';
import 'package:partner/gen/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:partner/app/shell/role_gate/bloc/role_gate_bloc.dart';
import 'package:partner/app/modules/jhatka/jhatka_media.dart';

/// Rider home. A run is assigned, never bid for, so this is a manifest with a
/// progress bar rather than an inbox of offers (which is what
/// `Deliveryman_app` shows a food courier).
class DeliveryManifestScreen extends StatefulWidget {
  const DeliveryManifestScreen({
    super.key,
    required this.gate,
    this.onOpenReconciliation,
  });

  final RoleGateState gate;
  final VoidCallback? onOpenReconciliation;

  @override
  State<DeliveryManifestScreen> createState() => _DeliveryManifestScreenState();
}

class _DeliveryManifestScreenState extends State<DeliveryManifestScreen> {
  final DeliveryRepository _deliveryRepository = DeliveryRepository();
  final JhatkaMedia _media = JhatkaMedia();
  final OfflineDeliveryQueue _offlineQueue = OfflineDeliveryQueue();
  String? _pendingProofLocalPath;
  bool _loading = true;
  int _pendingScans = 0;
  String? _runId;
  String _runStatus = '';
  String _runNo = '';
  String _slot = '';
  bool _savingRun = false;
  String? _loadError;
  int _totalStops = 0;
  int _completedStops = 0;
  int _cansToDeliver = 0;
  int _cansToCollect = 0;
  List<Map<String, dynamic>> _stops = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _runs = <Map<String, dynamic>>[];
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    setState(() {
      _loading = true;
      _loadError = null;
    });
    _runId = null;
    _runStatus = '';
    _stops = <Map<String, dynamic>>[];

    final DioApiResponse runResponse = await _deliveryRepository.todayRun();
    if (runResponse.errorType != NetErrorType.none) {
      _loadError = _responseMessage(runResponse, l10n.driverCouldNotLoadRun);
    }
    if (runResponse.errorType == NetErrorType.none &&
        (runResponse.body?.isNotEmpty ?? false)) {
      try {
        final Map<String, dynamic> decoded =
            jsonDecode(runResponse.body!) as Map<String, dynamic>;
        final List<Map<String, dynamic>> runs = decoded['runs'] is List
            ? (decoded['runs'] as List)
                .whereType<Map>()
                .map((Map<dynamic, dynamic> e) => Map<String, dynamic>.from(e))
                .toList()
            : <Map<String, dynamic>>[];
        _runs = runs;
        final dynamic rawRun = runs.isNotEmpty
            ? runs.first
            : (decoded['run'] ?? decoded);
        final Map<String, dynamic> run = rawRun is Map
            ? Map<String, dynamic>.from(rawRun)
            : decoded;

        if ((run['_id'] ?? run['id']) != null) {
          _applyRun(run);
          final String? resolvedRunId = _runId;
          if (resolvedRunId == null) {
            throw StateError('missing run id');
          }
          // Best-effort telemetry ping.
          captureDairyDriverPoint().then((Map<String, dynamic>? point) {
            if (point != null) {
              _deliveryRepository.pingLocation(resolvedRunId, point);
            }
          });

          final DioApiResponse stopResponse = await _deliveryRepository.stops(
            resolvedRunId,
          );
          if (stopResponse.errorType == NetErrorType.none &&
              (stopResponse.body?.isNotEmpty ?? false)) {
            final Map<String, dynamic> stopDecoded =
                jsonDecode(stopResponse.body!) as Map<String, dynamic>;
            _stops = (stopDecoded['stops'] as List<dynamic>? ?? <dynamic>[])
                .whereType<Map<String, dynamic>>()
                .toList();
            _completedStops = _stops
                .where(
                  (Map<String, dynamic> s) => <String>{
                    'delivered',
                    'skipped',
                    'failed',
                  }.contains(s['status']?.toString()),
                )
                .length;
          }
        }
      } catch (_) {
        // Leave the empty state in place.
      }
    }

    _pendingScans = await _deliveryRepository.pendingScanCount();
    await _syncPendingDeliveries();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _switchRun(Map<String, dynamic> run) async {
    if (!mounted) return;
    setState(() => _loading = true);
    _applyRun(run);
    if (_runId == null) {
      setState(() => _loading = false);
      return;
    }
    final DioApiResponse stopResponse = await _deliveryRepository.stops(_runId!);
    if (stopResponse.errorType == NetErrorType.none &&
        (stopResponse.body?.isNotEmpty ?? false)) {
      try {
        final Map<String, dynamic> stopDecoded =
            jsonDecode(stopResponse.body!) as Map<String, dynamic>;
        _stops = (stopDecoded['stops'] as List<dynamic>? ?? <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .toList();
        _completedStops = _stops
            .where(
              (Map<String, dynamic> s) => <String>{
                'delivered',
                'skipped',
                'failed',
              }.contains(s['status']?.toString()),
            )
            .length;
      } catch (_) {}
    }
    _pendingScans = await _deliveryRepository.pendingScanCount();
    await _syncPendingDeliveries();
    if (mounted) setState(() => _loading = false);
  }

  void _applyRun(Map<String, dynamic> run) {
    final dynamic id = run['_id'] ?? run['id'];
    if (id != null) _runId = id.toString();
    _runStatus = run['status']?.toString() ?? 'planned';
    _runNo = run['runNo']?.toString() ?? '';
    final Map<String, dynamic>? slot = run['slot'] is Map
        ? run['slot'] as Map<String, dynamic>
        : null;
    _slot = slot == null
        ? ''
        : '${slot['startTime'] ?? ''} - ${slot['endTime'] ?? ''}';
    final Map<String, dynamic>? totals = run['totals'] is Map
        ? run['totals'] as Map<String, dynamic>
        : null;
    _totalStops =
        int.tryParse(totals?['stopCount']?.toString() ?? '0') ?? 0;
    _cansToDeliver =
        int.tryParse(totals?['cansOut']?.toString() ?? '0') ?? 0;
    _cansToCollect =
        int.tryParse(totals?['cansIn']?.toString() ?? '0') ?? 0;
  }

  Future<void> _syncPendingDeliveries() async {
    final List<PendingDelivery> pending = await _offlineQueue.pending();
    if (pending.isEmpty) return;
    final List<String> done = <String>[];
    for (final PendingDelivery item in pending) {
      try {
        String? proofPath = item.localProofPath;
        if (proofPath != null) {
          final String? uploaded = await _media.uploadPhoto(proofPath);
          if (uploaded != null) proofPath = uploaded;
        }
        final Map<String, dynamic>? proof = proofPath == null ||
                proofPath.startsWith('/')
            ? (proofPath == null
                ? null
                : <String, dynamic>{
                    'photo': proofPath,
                    'capturedAt': item.capturedAt,
                  })
            : <String, dynamic>{
                'photo': proofPath,
                'capturedAt': item.capturedAt,
              };
        final DioApiResponse response = await _deliveryRepository.deliverStop(
          stopId: item.stopId,
          cansDelivered: item.cansDelivered,
          emptyCansCollected: item.emptyCansCollected,
          amountCollected: item.amountCollected,
          shortfallReason: item.shortfallReason,
          clientRef: item.clientRef,
          proof: proof,
        );
        if (response.errorType == NetErrorType.none) {
          done.add(item.clientRef);
        }
      } catch (_) {
        // Leave queued for next attempt.
      }
    }
    if (done.isNotEmpty) await _offlineQueue.acknowledge(done);
  }

  String _responseMessage(DioApiResponse response, String fallback) {
    dynamic raw = response.response?.data;
    if (raw is String && raw.isNotEmpty) {
      try {
        raw = jsonDecode(raw);
      } on FormatException {
        return raw;
      }
    }
    if (raw is Map && raw['message'] is String) return raw['message'] as String;
    return fallback;
  }

  String _customerName(Map<String, dynamic> stop, AppLocalizations l10n) {
    final String receiver = stop['receiverName']?.toString().trim() ?? '';
    if (receiver.isNotEmpty) return receiver;
    final Object? info = stop['customerInfo'];
    if (info is Map) {
      final String first = info['firstName']?.toString().trim() ?? '';
      final String last = info['lastName']?.toString().trim() ?? '';
      final String full = '$first $last'.trim();
      if (full.isNotEmpty) return full;
    }
    return l10n.customer;
  }

  String _slotWindow(Map<String, dynamic> stop) {
    final Object? slot = stop['slot'];
    if (slot is! Map) return '';
    final String start =
        (slot['windowStart'] ?? slot['startTime'])?.toString().trim() ?? '';
    final String end =
        (slot['windowEnd'] ?? slot['endTime'])?.toString().trim() ?? '';
    if (start.isEmpty && end.isEmpty) return '';
    if (start.isEmpty) return end;
    if (end.isEmpty) return start;
    return '$start - $end';
  }

  String _callableContact(Map<String, dynamic> stop) {
    final String receiver =
        stop['receiverContact']?.toString().trim() ?? '';
    if (receiver.isNotEmpty && !receiver.toUpperCase().contains('X')) {
      return receiver;
    }
    final Object? info = stop['customerInfo'];
    if (info is Map) {
      final String contact = info['contactNumber']?.toString().trim() ?? '';
      if (contact.isNotEmpty && !contact.toUpperCase().contains('X')) {
        return contact;
      }
    }
    return '';
  }

  Map<String, dynamic>? _nextOpenStop() {
    Map<String, dynamic>? pending;
    for (final Map<String, dynamic> stop in _stops) {
      final String status = stop['status']?.toString() ?? 'pending';
      if (status == 'arrived') return stop;
      if (status == 'pending' && pending == null) pending = stop;
    }
    return pending;
  }

  Future<Map<String, int>?> _promptRunLoad(AppLocalizations l10n) async {
    final TextEditingController loadedController = TextEditingController(
      text: '$_cansToDeliver',
    );
    final TextEditingController returnController = TextEditingController(
      text: '$_cansToCollect',
    );
    String? validationError;

    final Map<String, int>? result = await showDialog<Map<String, int>>(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) =>
            AlertDialog(
              title: Text(l10n.startRun),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(l10n.driverRunLoadHint),
                    const SizedBox(height: 16),
                    TextField(
                      controller: loadedController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n.driverCansLoaded,
                        helperText: '${l10n.cansToDeliver}: $_cansToDeliver',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: returnController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n.driverEmptyCansForReturn,
                      ),
                    ),
                    if (validationError != null) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(
                        validationError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: () {
                    final int? loaded = int.tryParse(
                      loadedController.text.trim(),
                    );
                    final int? returning = int.tryParse(
                      returnController.text.trim(),
                    );
                    if (loaded == null ||
                        returning == null ||
                        loaded < 0 ||
                        returning < 0) {
                      setDialogState(
                        () => validationError = l10n.driverEnterValidCanCounts,
                      );
                      return;
                    }
                    if (loaded < _cansToDeliver) {
                      setDialogState(
                        () => validationError = l10n.driverLoadAtLeastManifest,
                      );
                      return;
                    }
                    Navigator.of(dialogContext).pop(<String, int>{
                      'loaded': loaded,
                      'returning': returning,
                    });
                  },
                  child: Text(l10n.startRun),
                ),
              ],
            ),
      ),
    );
    loadedController.dispose();
    returnController.dispose();
    return result;
  }

  Future<void> _startRun(AppLocalizations l10n) async {
    final Map<String, int>? load = await _promptRunLoad(l10n);
    if (load == null || !mounted) return;
    setState(() => _savingRun = true);
    final Map<String, dynamic>? point = await captureDairyDriverPoint();
    final DioApiResponse response = await _deliveryRepository.startRun(
      runId: _runId!,
      cansLoaded: load['loaded']!,
      cansLoadedForReturn: load['returning']!,
      location: point ?? <String, dynamic>{},
    );
    if (!mounted) return;
    setState(() => _savingRun = false);
    if (response.errorType != NetErrorType.none) {
      _snack(_responseMessage(response, l10n.somethingWentWrong));
      return;
    }
    _snack(l10n.driverRunStarted);
    await _load();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _runStatusLabel(AppLocalizations l10n) {
    switch (_runStatus) {
      case 'dispatched':
        return l10n.runStatusDispatched;
      case 'in_progress':
        return l10n.runStatusInProgress;
      case 'completed':
        return l10n.runStatusCompleted;
      case 'cancelled':
        return l10n.runStatusCancelled;
      default:
        return l10n.runStatusPlanned;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final AppThemeData theme =
        appThemeData[Theme.of(context).brightness == Brightness.dark
            ? AppTheme.dark
            : AppTheme.light]!;
    final bool canSwitch = widget.gate.canSwitchRole;
    final Map<String, dynamic>? nextStop = _nextOpenStop();
    final bool runInProgress = _runStatus == 'in_progress';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.todayRuns),
        leading: Icon(Icons.delivery_dining_outlined, color: theme.primary),
        actions: <Widget>[
          if (canSwitch)
            IconButton(
              tooltip: l10n.switchRole,
              icon: const Icon(Icons.swap_horiz),
              onPressed: () {
                context.read<RoleGateBloc>().add(
                  const RoleGateSwitchToPartnerEvent(),
                );
              },
            ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: <Widget>[
                  if (_pendingScans > 0)
                    Card(
                      child: ListTile(
                        leading: Icon(
                          Icons.cloud_off_outlined,
                          color: theme.primary,
                        ),
                        title: Text(l10n.syncPending(_pendingScans)),
                        subtitle: Text(l10n.offlineMode),
                      ),
                    ),
                  if (_loadError != null)
                    EmptyState(
                      title: l10n.runsUnavailable,
                      message: _loadError!,
                      icon: Icons.cloud_off_outlined,
                    )
                  else if (_runId == null)
                    EmptyState(
                      title: l10n.noRunAssigned,
                      message: l10n.noRunAssignedHint,
                      icon: Icons.event_busy_outlined,
                    )
                  else ...<Widget>[
                    _runCard(context, l10n, theme),
                    if (runInProgress && nextStop != null) ...<Widget>[
                      const SizedBox(height: 8),
                      _nextStopCard(context, l10n, theme, nextStop),
                    ],
                    if (runInProgress &&
                        _stops.isNotEmpty &&
                        nextStop == null) ...<Widget>[
                      const SizedBox(height: 8),
                      _allStopsResolvedCard(context, l10n, theme),
                    ],
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        l10n.stops,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ..._stops.map(
                      (Map<String, dynamic> stop) =>
                          _stopTile(context, l10n, theme, stop),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _runCard(
    BuildContext context,
    AppLocalizations l10n,
    AppThemeData theme,
  ) {
    final double progress = _totalStops == 0
        ? 0
        : _completedStops / _totalStops;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (_runs.length > 1) ...<Widget>[
              DropdownButton<String>(
                value: _runId,
                items: _runs
                    .map(
                      (Map<String, dynamic> r) => DropdownMenuItem<String>(
                        value: (r['_id'] ?? r['id'])?.toString(),
                        child: Text(r['runNo']?.toString() ?? 'Run'),
                      ),
                    )
                    .toList(),
                onChanged: (String? value) {
                  if (value == null) return;
                  final Map<String, dynamic> selected = _runs.firstWhere(
                    (Map<String, dynamic> r) =>
                        (r['_id'] ?? r['id'])?.toString() == value,
                    orElse: () => _runs.first,
                  );
                  _switchRun(selected);
                },
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '${l10n.runLabel} $_runNo',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (_slot.isNotEmpty)
                  StatusChip(label: _slot, color: theme.primary),
              ],
            ),
            const SizedBox(height: 8),
            StatusChip(
              label: _runStatusLabel(l10n),
              color: _runStatus == 'in_progress'
                  ? AppColors.canInStore
                  : theme.primary,
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(value: progress, minHeight: 8),
            ),
            const SizedBox(height: 6),
            Text(
              '$_completedStops / $_totalStops ${l10n.stops}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: MetricTile(
                    label: l10n.cansToDeliver,
                    value: '$_cansToDeliver',
                    icon: Icons.local_drink_outlined,
                    accent: theme.primary,
                  ),
                ),
                Expanded(
                  child: MetricTile(
                    label: l10n.driverEmptyCansCollected,
                    value: '$_cansToCollect',
                    icon: Icons.recycling_outlined,
                    accent: AppColors.canWithCustomer,
                  ),
                ),
              ],
            ),
            if (_runStatus == 'planned' ||
                _runStatus == 'dispatched') ...<Widget>[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _savingRun ? null : () => _startRun(l10n),
                  icon: _savingRun
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow_rounded),
                  label: Text(l10n.startRun),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _nextStopCard(
    BuildContext context,
    AppLocalizations l10n,
    AppThemeData theme,
    Map<String, dynamic> stop,
  ) {
    final String status = stop['status']?.toString() ?? 'pending';
    final String address = stop['addressRaw']?.toString().trim() ?? '';
    final String slot = _slotWindow(stop);
    final String contact = _callableContact(stop);
    final Color statusColor = status == 'arrived'
        ? theme.primary
        : AppColors.grey;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.near_me_outlined, color: theme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.nextStop,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                StatusChip(
                  label: _statusLabel(l10n, status),
                  color: statusColor,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _customerName(stop, l10n),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (address.isNotEmpty) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                address,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (slot.isNotEmpty) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                '${l10n.slotWindow}: $slot',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _showStopSheet(context, stop, l10n),
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: Text(l10n.openStop),
                  ),
                ),
                if (contact.isNotEmpty) ...<Widget>[
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: l10n.callCustomer,
                    onPressed: () => _callStop(contact),
                    icon: const Icon(Icons.call_outlined),
                  ),
                ],
                if (address.isNotEmpty || stop['location'] is Map) ...<Widget>[
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: l10n.driverNavigate,
                    onPressed: () => _navigateToStop(stop, l10n),
                    icon: const Icon(Icons.navigation_outlined),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _allStopsResolvedCard(
    BuildContext context,
    AppLocalizations l10n,
    AppThemeData theme,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.check_circle_outline, color: AppColors.canInStore),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.allStopsResolved,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: widget.onOpenReconciliation,
              icon: const Icon(Icons.fact_check_outlined),
              label: Text(l10n.completeRun),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stopTile(
    BuildContext context,
    AppLocalizations l10n,
    AppThemeData theme,
    Map<String, dynamic> stop,
  ) {
    final String status = stop['status']?.toString() ?? 'pending';
    final Color statusColor = switch (status) {
      'delivered' => AppColors.canInStore,
      'arrived' => theme.primary,
      'skipped' => AppColors.expirySoon,
      'failed' => AppColors.expired,
      _ => AppColors.grey,
    };

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.14),
          child: Text(
            '${stop['sequence'] ?? ''}',
            style: TextStyle(color: statusColor, fontFamily: 'semibold'),
          ),
        ),
        title: Text(_customerName(stop, l10n)),
        subtitle: Text(
          '${l10n.cans}: ${stop['cansOut'] ?? 0} · ${l10n.slotWindow}: ${_slotWindow(stop)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: StatusChip(
          label: _statusLabel(l10n, status),
          color: statusColor,
        ),
        onTap: () => _showStopSheet(context, stop, l10n),
      ),
    );
  }

  String _statusLabel(AppLocalizations l10n, String status) {
    switch (status) {
      case 'arrived':
        return l10n.arrived;
      case 'delivered':
        return l10n.delivered;
      case 'skipped':
        return l10n.skipped;
      case 'failed':
        return l10n.failed;
      default:
        return l10n.pending;
    }
  }

  void _showStopSheet(
    BuildContext context,
    Map<String, dynamic> stop,
    AppLocalizations l10n,
  ) {
    final String stopId = (stop['_id'] ?? stop['id'] ?? '').toString();
    final String status = stop['status']?.toString() ?? 'pending';
    final bool runStarted = _runStatus == 'in_progress';
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        bool saving = false;
        bool uploadingProof = false;
        String? proofPhoto;
        return StatefulBuilder(
          builder: (BuildContext modalContext, StateSetter setModalState) {
            Future<void> submit(
              Future<DioApiResponse> Function() request,
              String success,
            ) async {
              if (saving) return;
              setModalState(() => saving = true);
              final DioApiResponse response = await request();
              if (!sheetContext.mounted) return;
              setModalState(() => saving = false);
              if (response.errorType != NetErrorType.none) {
                _snack(_responseMessage(response, l10n.somethingWentWrong));
                return;
              }
              Navigator.of(sheetContext).pop();
              _snack(success);
              await _load();
            }

            Future<void> markArrival() async {
              final Map<String, dynamic>? point =
                  await captureDairyDriverPoint();
              await submit(
                () => _deliveryRepository.arriveStop(stopId, point),
                l10n.driverArrivalRecorded,
              );
            }

            Future<void> captureProof() async {
              if (uploadingProof) return;
              setModalState(() => uploadingProof = true);
              String? path;
              String? localPath;
              try {
                localPath = await _media.takePhoto();
                if (localPath != null) {
                  path = await _media.uploadPhoto(localPath);
                  if (path == null) {
                    _pendingProofLocalPath =
                        await _offlineQueue.persistPhoto(localPath, stopId);
                  }
                }
              } catch (_) {
                path = null;
              }
              if (!sheetContext.mounted) return;
              setModalState(() {
                uploadingProof = false;
                if (path != null) proofPhoto = path;
              });
              if (path == null && localPath == null) {
                _snack(l10n.proofNotAttached);
              } else if (path == null) {
                _snack('Proof queued for upload');
              }
            }

            Future<void> finishDelivery() async {
              final Map<String, dynamic>? details = await _promptDelivery(
                stop,
                l10n,
              );
              if (details == null || !sheetContext.mounted) return;

              String? resolvedProof = proofPhoto;
              if (resolvedProof == null && _pendingProofLocalPath != null) {
                resolvedProof = await _media.uploadPhoto(_pendingProofLocalPath!);
                if (resolvedProof != null) proofPhoto = resolvedProof;
              }

              final String clientRef =
                  'pod-$stopId-${DateTime.now().microsecondsSinceEpoch}';
              final Map<String, dynamic>? proof = resolvedProof == null
                  ? null
                  : <String, dynamic>{
                      'photo': resolvedProof,
                      'capturedAt': DateTime.now().toUtc().toIso8601String(),
                    };

              setModalState(() => saving = true);
              DioApiResponse response;
              try {
                response = await _deliveryRepository.deliverStop(
                  stopId: stopId,
                  cansDelivered: details['deliveredCans'] as int,
                  emptyCansCollected: details['emptyCans'] as int,
                  amountCollected: details['amountCollected'] as num,
                  shortfallReason: details['shortfallReason'] as String?,
                  clientRef: clientRef,
                  proof: proof,
                );
              } catch (_) {
                response = DioApiResponse(
                  errorType: NetErrorType.socket,
                );
              }
              if (!sheetContext.mounted) return;

              final bool offline = response.errorType == NetErrorType.socket ||
                  response.errorType == NetErrorType.timeout;
              if (response.errorType == NetErrorType.none) {
                setModalState(() => saving = false);
                _snack(l10n.driverDeliveryRecorded);
                Navigator.of(sheetContext).pop();
                _load();
                return;
              }
              if (offline) {
                await _offlineQueue.enqueue(
                  PendingDelivery(
                    clientRef: clientRef,
                    runId: _runId ?? '',
                    stopId: stopId,
                    cansDelivered: details['deliveredCans'] as int,
                    emptyCansCollected: details['emptyCans'] as int,
                    amountCollected: details['amountCollected'] as num,
                    shortfallReason: details['shortfallReason'] as String?,
                    localProofPath: _pendingProofLocalPath,
                    capturedAt: DateTime.now().toUtc().toIso8601String(),
                  ),
                );
                if (!sheetContext.mounted) return;
                setModalState(() => saving = false);
                _snack('Delivery queued for sync');
                Navigator.of(sheetContext).pop();
                return;
              }
              setModalState(() => saving = false);
              _snack(response.errorType == NetErrorType.none
                  ? l10n.driverDeliveryRecorded
                  : 'Could not record delivery');
            }

            Future<void> markUnsuccessful(bool failed) async {
              final String? reason = await _promptStopReason(l10n, failed);
              if (reason == null || !sheetContext.mounted) return;
              await submit(
                () => failed
                    ? _deliveryRepository.failStop(stopId, reason)
                    : _deliveryRepository.skipStop(stopId, reason),
                failed ? l10n.failed : l10n.skipped,
              );
            }

            final String address = stop['addressRaw']?.toString().trim() ?? '';
            final String contact = _callableContact(stop);
            final int plannedCans =
                int.tryParse(stop['cansOut']?.toString() ?? '0') ?? 0;
            final Object? amountDue = stop['amountDue'];
            final bool isCod = <String>{
              'cod',
              'cash_on_delivery',
            }.contains(stop['paymentMode']?.toString());

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  16 + MediaQuery.viewInsetsOf(modalContext).bottom,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        _customerName(stop, l10n),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (address.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 6),
                        Text(
                          address,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                      if (address.isNotEmpty || contact.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            if (address.isNotEmpty)
                              OutlinedButton.icon(
                                onPressed: () => _navigateToStop(stop, l10n),
                                icon: const Icon(Icons.navigation_outlined),
                                label: Text(l10n.driverNavigate),
                              ),
                            if (contact.isNotEmpty)
                              OutlinedButton.icon(
                                onPressed: () => _callStop(contact),
                                icon: const Icon(Icons.call_outlined),
                                label: Text(l10n.callCustomer),
                              ),
                          ],
                        ),
                      ],
                      if (runStarted && status == 'arrived') ...<Widget>[
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: saving || uploadingProof
                              ? null
                              : captureProof,
                          icon: uploadingProof
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  proofPhoto == null
                                      ? Icons.photo_camera_outlined
                                      : Icons.check_circle_outline,
                                ),
                          label: Text(
                            proofPhoto == null
                                ? l10n.captureProof
                                : l10n.proofAttached,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Card(
                        child: Column(
                          children: <Widget>[
                            ListTile(
                              dense: true,
                              title: Text(
                                status == 'delivered'
                                    ? l10n.cansDelivered
                                    : l10n.cansToDeliver,
                              ),
                              trailing: Text('$plannedCans'),
                            ),
                            if (stop['items'] is List &&
                                (stop['items'] as List).isNotEmpty)
                              ListTile(
                                dense: true,
                                title: Text(l10n.items),
                                subtitle: Text(
                                  (stop['items'] as List)
                                      .map(
                                        (dynamic item) =>
                                            item is Map
                                                ? '${item['name'] ?? 'Item'} x ${item['quantity'] ?? 0}'
                                                : item.toString(),
                                      )
                                      .join(', '),
                                ),
                              ),
                            ListTile(
                              dense: true,
                              title: Text(l10n.driverEmptyCansCollected),
                              trailing: Text('${stop['cansIn'] ?? 0}'),
                            ),
                            ListTile(
                              dense: true,
                              title: Text(l10n.amountDue),
                              trailing: Text(_rupees(amountDue)),
                            ),
                            ListTile(
                              dense: true,
                              title: Text(l10n.paymentMode),
                              trailing: Text(
                                isCod ? l10n.cashOnDelivery : l10n.prepaid,
                              ),
                            ),
                            if (status == 'delivered' &&
                                (stop['shortfallReason']
                                        ?.toString()
                                        .trim()
                                        .isNotEmpty ??
                                    false))
                              ListTile(
                                dense: true,
                                title: Text(l10n.shortfallReason),
                                subtitle: Text(
                                  stop['shortfallReason'].toString(),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (!runStarted &&
                          (status == 'pending' || status == 'arrived'))
                        Text(
                          l10n.driverStartRunBeforeStops,
                          textAlign: TextAlign.center,
                        ),
                      if (runStarted && status == 'pending')
                        FilledButton.icon(
                          onPressed: saving ? null : markArrival,
                          icon: const Icon(Icons.location_on_outlined),
                          label: Text(l10n.driverMarkArrived),
                        ),
                      if (runStarted && status == 'arrived')
                        FilledButton.icon(
                          onPressed: saving ? null : finishDelivery,
                          icon: const Icon(Icons.check_circle_outline),
                          label: Text(l10n.delivered),
                        ),
                      if (runStarted &&
                          (status == 'pending' ||
                              status == 'arrived')) ...<Widget>[
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: saving
                              ? null
                              : () => markUnsuccessful(false),
                          icon: const Icon(Icons.event_busy_outlined),
                          label: Text(l10n.skipped),
                        ),
                        TextButton.icon(
                          onPressed: saving
                              ? null
                              : () => markUnsuccessful(true),
                          icon: const Icon(Icons.report_gmailerrorred_outlined),
                          label: Text(l10n.failed),
                        ),
                      ],
                      if (saving)
                        const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _promptDelivery(
    Map<String, dynamic> stop,
    AppLocalizations l10n,
  ) async {
    final int plannedCans =
        int.tryParse(stop['cansOut']?.toString() ?? '0') ?? 0;
    final int plannedEmptyCans = int.tryParse(
          (stop['plannedEmptyCans'] ?? stop['cansIn'])?.toString() ?? '0',
        ) ??
        0;
    final double due =
        double.tryParse(stop['amountDue']?.toString() ?? '0') ?? 0;
    final bool isCod = <String>{
      'cod',
      'cash_on_delivery',
    }.contains(stop['paymentMode']?.toString());
    final TextEditingController deliveredController = TextEditingController(
      text: '$plannedCans',
    );
    final TextEditingController emptyController = TextEditingController(
      text: '$plannedEmptyCans',
    );
    final TextEditingController reasonController = TextEditingController();
    final TextEditingController amountController = TextEditingController(
      text: due.toStringAsFixed(2),
    );
    String? error;

    final Map<String, dynamic>? result =
        await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (BuildContext dialogContext) => StatefulBuilder(
            builder: (BuildContext context, StateSetter setDialogState) {
              final int? deliveredNow = int.tryParse(
                deliveredController.text.trim(),
              );
              final bool showShortfall =
                  deliveredNow != null && deliveredNow < plannedCans;
              return AlertDialog(
                title: Text(l10n.delivered),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('${l10n.cansToDeliver}: $plannedCans'),
                    const SizedBox(height: 14),
                    TextField(
                      controller: deliveredController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setDialogState(() {}),
                      decoration: InputDecoration(
                        labelText: l10n.cansDelivered,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emptyController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n.driverEmptyCansCollected,
                      ),
                    ),
                    if (showShortfall) ...<Widget>[
                      const SizedBox(height: 12),
                      TextField(
                        controller: reasonController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: l10n.shortfallReason,
                        ),
                      ),
                    ],
                    if (isCod) ...<Widget>[
                      const SizedBox(height: 12),
                      TextField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: l10n.amountCollected,
                          prefixText: '₹',
                          helperText: '${l10n.amountDue}: ${_rupees(due)}',
                        ),
                      ),
                    ],
                    if (error != null) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(
                        error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: Text(l10n.cancel),
                  ),
                  FilledButton(
                    onPressed: () {
                      final int? deliveredCans = int.tryParse(
                        deliveredController.text.trim(),
                      );
                      final int? emptyCans = int.tryParse(
                        emptyController.text.trim(),
                      );
                      final double? amount = isCod
                          ? double.tryParse(amountController.text.trim())
                          : 0;
                      final String shortfallReason = reasonController.text
                          .trim();
                      if (deliveredCans == null ||
                          deliveredCans < 0 ||
                          deliveredCans > plannedCans ||
                          emptyCans == null ||
                          emptyCans < 0) {
                        setDialogState(
                          () => error = l10n.driverEnterValidCanCounts,
                        );
                        return;
                      }
                      if (deliveredCans < plannedCans &&
                          shortfallReason.isEmpty) {
                        setDialogState(
                          () => error = l10n.shortfallReasonRequired,
                        );
                        return;
                      }
                      if (amount == null || amount < 0) {
                        setDialogState(
                          () => error = l10n.driverEnterValidCanCounts,
                        );
                        return;
                      }
                      if (isCod && amount > due + 0.005) {
                        setDialogState(() => error = l10n.amountExceedsDue);
                        return;
                      }
                      Navigator.of(dialogContext).pop(<String, dynamic>{
                        'deliveredCans': deliveredCans,
                        'emptyCans': emptyCans,
                        'amountCollected': amount,
                        'shortfallReason':
                            deliveredCans < plannedCans &&
                                shortfallReason.isNotEmpty
                            ? shortfallReason
                            : null,
                      });
                    },
                    child: Text(l10n.save),
                  ),
                ],
              );
            },
          ),
        );
    deliveredController.dispose();
    emptyController.dispose();
    reasonController.dispose();
    amountController.dispose();
    return result;
  }

  Future<String?> _promptStopReason(AppLocalizations l10n, bool failed) async {
    final List<String> presets = failed
        ? <String>[
            'Customer refused delivery',
            'Damaged goods',
            'Address unreachable',
            'Other',
          ]
        : <String>[
            'Customer not available',
            'Outlet closed',
            'Rescheduled by customer',
            'Other',
          ];
    String selected = presets.first;
    final TextEditingController otherController = TextEditingController();
    String? error;
    final String? reason = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) {
          final bool isOther = selected == 'Other';
          return AlertDialog(
            title: Text(failed ? l10n.failed : l10n.skipped),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                DropdownButtonFormField<String>(
                  initialValue: selected,
                  items: presets
                      .map(
                        (String value) => DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        ),
                      )
                      .toList(),
                  onChanged: (String? value) {
                    if (value == null) return;
                    setDialogState(() => selected = value);
                  },
                  decoration: InputDecoration(labelText: l10n.driverReasonRequired),
                ),
                if (isOther) ...<Widget>[
                  const SizedBox(height: 12),
                  TextField(
                    controller: otherController,
                    autofocus: true,
                    maxLines: 3,
                    decoration: InputDecoration(labelText: l10n.driverReasonRequired),
                  ),
                ],
                if (error != null) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(
                    error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () {
                  final String value = isOther
                      ? otherController.text.trim()
                      : selected;
                  if (value.isEmpty) {
                    setDialogState(() => error = l10n.driverReasonRequired);
                    return;
                  }
                  Navigator.of(dialogContext).pop(value);
                },
                child: Text(l10n.save),
              ),
            ],
          );
        },
      ),
    );
    otherController.dispose();
    return reason;
  }

  Future<void> _callStop(String number) async {
    final Uri uri = Uri(scheme: 'tel', path: number);
    if (!await launchUrl(uri)) {
      if (mounted) _snack(AppLocalizations.of(context)!.somethingWentWrong);
    }
  }

  Future<void> _navigateToStop(
    Map<String, dynamic> stop,
    AppLocalizations l10n,
  ) async {
    final Map<String, dynamic>? location = stop['location'] is Map
        ? Map<String, dynamic>.from(stop['location'] as Map)
        : null;
    final List<dynamic>? coordinates =
        location?['coordinates'] as List<dynamic>?;
    String destination = stop['addressRaw']?.toString().trim() ?? '';
    if (coordinates != null && coordinates.length >= 2) {
      destination = '${coordinates[1]},${coordinates[0]}';
    }
    if (destination.isEmpty) {
      _snack(l10n.driverAddressUnavailable);
      return;
    }
    final Uri uri = Uri.https('www.google.com', '/maps/dir/', <String, String>{
      'api': '1',
      'destination': destination,
      'travelmode': 'driving',
    });
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      _snack(l10n.somethingWentWrong);
    }
  }

  String _rupees(Object? value) {
    final double amount = double.tryParse(value?.toString() ?? '') ?? 0;
    return '₹${amount.toStringAsFixed(2)}';
  }
}
