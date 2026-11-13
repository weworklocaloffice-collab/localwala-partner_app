import 'dart:convert';

import 'package:partner/app/core/config/api_request_service.dart';
import 'package:partner/app/core/repositories/delivery_repository.dart';
import 'package:partner/app/core/services/offline_can_scan_queue.dart';
import 'package:partner/app/presentation/styles/theme.dart';
import 'package:partner/app/presentation/styles/widgets.dart';
import 'package:partner/gen/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Manifest-linked can scanning for Dairy drivers. Run and stop context is
/// loaded from the authenticated driver's assignment; IDs are never typed.
class DeliveryCanScanScreen extends StatefulWidget {
  const DeliveryCanScanScreen({super.key});

  @override
  State<DeliveryCanScanScreen> createState() => _DeliveryCanScanScreenState();
}

class _DeliveryCanScanScreenState extends State<DeliveryCanScanScreen> {
  final DeliveryRepository _deliveryRepository = DeliveryRepository();
  final TextEditingController _codeController = TextEditingController();

  String? _runId;
  String? _selectedStopId;
  String _runStatus = '';
  String _runNo = '';
  List<Map<String, dynamic>> _stops = <Map<String, dynamic>>[];
  final List<String> _codes = <String>[];
  DairyCanScanType _scanType = DairyCanScanType.issue;
  int _pending = 0;
  bool _loading = true;
  bool _busy = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    setState(() {
      _loading = true;
      _loadError = null;
      _runId = null;
      _runStatus = '';
      _runNo = '';
      _stops = <Map<String, dynamic>>[];
    });
    try {
      final DioApiResponse runResponse = await _deliveryRepository.todayRun();
      if (runResponse.errorType != NetErrorType.none) {
        _loadError = _responseMessage(runResponse, l10n.driverCouldNotLoadRun);
      } else if (runResponse.body?.isNotEmpty ?? false) {
        final Map<String, dynamic> decoded =
            jsonDecode(runResponse.body!) as Map<String, dynamic>;
        final dynamic rawRun = decoded['run'];
        if (rawRun is Map) {
          final Map<String, dynamic> run = Map<String, dynamic>.from(rawRun);
          final dynamic id = run['_id'] ?? run['id'];
          if (id != null) {
            _runId = id.toString();
            _runStatus = run['status']?.toString() ?? '';
            _runNo = run['runNo']?.toString() ?? '';
            final DioApiResponse stopResponse =
                await _deliveryRepository.stops(_runId!);
            if (stopResponse.errorType != NetErrorType.none) {
              _loadError = _responseMessage(stopResponse, l10n.driverCouldNotLoadRun);
            } else if (stopResponse.body?.isNotEmpty ?? false) {
              final Map<String, dynamic> stopPayload =
                  jsonDecode(stopResponse.body!) as Map<String, dynamic>;
              _stops = (stopPayload['stops'] as List<dynamic>? ?? <dynamic>[])
                  .whereType<Map>()
                  .map((Map<dynamic, dynamic> value) =>
                      Map<String, dynamic>.from(value))
                  .toList();
              _selectNextStop();
            }
          }
        }
      }
    } catch (_) {
      _loadError = l10n.driverCouldNotLoadRun;
    }
    _pending = await _deliveryRepository.pendingScanCount();
    if (mounted) setState(() => _loading = false);
  }

  void _selectNextStop() {
    final List<Map<String, dynamic>> openStops = _stops.where(
      (Map<String, dynamic> stop) =>
          !const <String>{'delivered', 'skipped', 'failed'}.contains(
            stop['status']?.toString(),
          ),
    ).toList();
    if (_selectedStopId != null &&
        openStops.any((Map<String, dynamic> stop) =>
            _id(stop['_id'] ?? stop['id']) == _selectedStopId)) {
      return;
    }
    _selectedStopId = openStops.isEmpty ? null : _id(openStops.first['_id']);
  }

  String _id(dynamic value) {
    if (value is Map) return (value['_id'] ?? value['id'] ?? '').toString();
    return value?.toString() ?? '';
  }

  Map<String, dynamic>? get _selectedStop {
    for (final Map<String, dynamic> stop in _stops) {
      if (_id(stop['_id'] ?? stop['id']) == _selectedStopId) return stop;
    }
    return null;
  }

  bool get _needsStop =>
      _scanType == DairyCanScanType.issue ||
      _scanType == DairyCanScanType.collect;

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

  void _addCode(String value) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final String code = value.trim().toUpperCase();
    if (code.isEmpty) return;
    if (_codes.contains(code)) {
      _snack(l10n.canAlreadyScanned(code));
      _codeController.clear();
      return;
    }
    if (_codes.length >= 20) {
      _snack(l10n.canScanBatchLimit);
      return;
    }
    setState(() => _codes.add(code));
    _codeController.clear();
  }

  Future<void> _openScanner() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => _CanBarcodeScannerPage(onCode: _addCode),
      ),
    );
  }

  Future<void> _submit() async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    if (_runId == null || _runStatus != 'in_progress') {
      _snack(l10n.canScanActiveRunRequired);
      return;
    }
    final Map<String, dynamic>? stop = _selectedStop;
    if (_needsStop && stop == null) {
      _snack(l10n.canScanSelectStop);
      return;
    }
    if (_codes.isEmpty) {
      _snack(l10n.canScanAddCode);
      return;
    }
    final String? customerId = stop == null ? null : _id(stop['customer']);
    if (_needsStop && (customerId == null || customerId.isEmpty)) {
      _snack(l10n.canScanSelectStop);
      return;
    }

    setState(() => _busy = true);
    final String codesLabel = _codes.join(', ');
    final bool synced = await _deliveryRepository.queueCanScan(
      PendingCanScan(
        clientRef: OfflineCanScanQueue.newClientRef(),
        runId: _runId!,
        stopId: _needsStop ? _selectedStopId : null,
        customerId: customerId,
        orderId: stop == null ? null : _id(stop['order']),
        type: _scanType,
        canCodes: List<String>.of(_codes),
        capturedAt: DateTime.now(),
      ),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _codes.clear();
    });
    await _refreshPending();
    if (mounted) {
      _snack(synced ? l10n.canSynced(codesLabel) : l10n.canQueuedOffline(codesLabel));
    }
  }

  Future<void> _refreshPending() async {
    final int count = await _deliveryRepository.pendingScanCount();
    if (mounted) setState(() => _pending = count);
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _stopLabel(Map<String, dynamic> stop) {
    final Map<String, dynamic>? customer = stop['customerInfo'] is Map
        ? Map<String, dynamic>.from(stop['customerInfo'] as Map)
        : null;
    final String receiver = stop['receiverName']?.toString().trim() ?? '';
    final String name = receiver.isNotEmpty
        ? receiver
        : <String?>[
                customer?['firstName']?.toString(),
                customer?['lastName']?.toString(),
              ]
              .where((String? part) => part != null && part.trim().isNotEmpty)
              .join(' ');
    final String title = name.isEmpty ? 'Stop ${stop['sequence'] ?? ''}' : name;
    final String address = stop['addressRaw']?.toString().trim() ?? '';
    return address.isEmpty ? title : '$title · $address';
  }

  String _scanTypeLabel(AppLocalizations l10n, DairyCanScanType type) {
    return switch (type) {
      DairyCanScanType.pickup => l10n.pickupScan,
      DairyCanScanType.issue => l10n.cansToDeliver,
      DairyCanScanType.collect => l10n.emptyCansToCollect,
      DairyCanScanType.returnToStore => l10n.canDeposit,
    };
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final AppThemeData theme = appThemeData[
      Theme.of(context).brightness == Brightness.dark
          ? AppTheme.dark
          : AppTheme.light
    ]!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navScan),
        leading: Icon(Icons.qr_code_scanner_outlined, color: theme.primary),
        actions: <Widget>[
          IconButton(
            tooltip: l10n.retry,
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: Center(
              child: _pending > 0
                  ? StatusChip(label: '$_pending', color: AppColors.expirySoon)
                  : StatusChip(label: l10n.syncComplete, color: AppColors.canInStore),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: <Widget>[
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
                    Card(
                      child: ListTile(
                        leading: Icon(Icons.route_outlined, color: theme.primary),
                        title: Text('${l10n.runLabel} $_runNo'),
                        subtitle: Text(
                          _runStatus == 'in_progress'
                              ? l10n.driverRunStarted
                              : l10n.canScanActiveRunRequired,
                        ),
                        trailing: StatusChip(
                          label: _runStatus.replaceAll('_', ' '),
                          color: _runStatus == 'in_progress'
                              ? AppColors.canInStore
                              : AppColors.expirySoon,
                        ),
                      ),
                    ),
                    if (_runStatus != 'in_progress')
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.info_outline),
                          title: Text(l10n.canScanActiveRunRequired),
                        ),
                      )
                    else ...<Widget>[
                      const SizedBox(height: 8),
                      DropdownButtonFormField<DairyCanScanType>(
                        initialValue: _scanType,
                        decoration: InputDecoration(labelText: l10n.navScan),
                        items: DairyCanScanType.values
                            .map((DairyCanScanType type) =>
                                DropdownMenuItem<DairyCanScanType>(
                                  value: type,
                                  child: Text(_scanTypeLabel(l10n, type)),
                                ))
                            .toList(),
                        onChanged: _busy
                            ? null
                            : (DairyCanScanType? value) {
                                if (value != null) setState(() => _scanType = value);
                              },
                      ),
                      if (_needsStop) ...<Widget>[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _stops.any((Map<String, dynamic> stop) =>
                                  _id(stop['_id'] ?? stop['id']) == _selectedStopId)
                              ? _selectedStopId
                              : null,
                          isExpanded: true,
                          decoration: InputDecoration(labelText: l10n.canScanSelectStop),
                          items: _stops
                              .where((Map<String, dynamic> stop) =>
                                  !const <String>{'delivered', 'skipped', 'failed'}
                                      .contains(stop['status']?.toString()))
                              .map((Map<String, dynamic> stop) {
                            final String id = _id(stop['_id'] ?? stop['id']);
                            return DropdownMenuItem<String>(
                              value: id,
                              child: Text(
                                '${stop['sequence'] ?? ''}. ${_stopLabel(stop)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: _busy
                              ? null
                              : (String? value) => setState(() => _selectedStopId = value),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _busy ? null : _openScanner,
                              icon: const Icon(Icons.qr_code_scanner),
                              label: Text(l10n.canScannerOpen),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _codeController,
                              textCapitalization: TextCapitalization.characters,
                              textInputAction: TextInputAction.done,
                              decoration: InputDecoration(
                                labelText: l10n.canCode,
                                isDense: true,
                              ),
                              onSubmitted: _addCode,
                            ),
                          ),
                          IconButton(
                            tooltip: l10n.canScanAddCode,
                            onPressed: _busy ? null : () => _addCode(_codeController.text),
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(l10n.canScanBatchLimit, style: Theme.of(context).textTheme.bodySmall),
                      if (_codes.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _codes
                              .map((String code) => InputChip(
                                    label: Text(code),
                                    onDeleted: _busy
                                        ? null
                                        : () => setState(() => _codes.remove(code)),
                                  ))
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _busy ? null : _submit,
                          icon: _busy
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.cloud_upload_outlined),
                          label: Text(l10n.canScanSubmit),
                        ),
                      ),
                    ],
                    if (_pending > 0) ...<Widget>[
                      const SizedBox(height: 16),
                      Card(
                        child: ListTile(
                          leading: Icon(Icons.cloud_off_outlined, color: theme.primary),
                          title: Text(l10n.syncPending(_pending)),
                          subtitle: Text(l10n.offlineMode),
                          trailing: TextButton(
                            onPressed: _busy
                                ? null
                                : () async {
                                    await _deliveryRepository.flushCanScans();
                                    await _refreshPending();
                                  },
                            child: Text(l10n.retry),
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
    );
  }
}

class _CanBarcodeScannerPage extends StatefulWidget {
  const _CanBarcodeScannerPage({required this.onCode});

  final void Function(String code) onCode;

  @override
  State<_CanBarcodeScannerPage> createState() => _CanBarcodeScannerPageState();
}

class _CanBarcodeScannerPageState extends State<_CanBarcodeScannerPage> {
  late final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const <BarcodeFormat>[
      BarcodeFormat.qrCode,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
    ],
  );
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    for (final Barcode barcode in capture.barcodes) {
      final String? value = barcode.rawValue?.trim();
      if (value != null && value.isNotEmpty) {
        widget.onCode(value);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.canScannerOpen),
        actions: <Widget>[
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: _controller,
            builder: (BuildContext context, MobileScannerState state, Widget? child) =>
                IconButton(
              tooltip: l10n.canScannerTorch,
              onPressed: _controller.toggleTorch,
              icon: Icon(
                state.torchState.name == 'on' ? Icons.flash_on : Icons.flash_off,
               ),
             ),
           ),
           IconButton(
             tooltip: 'Done',
             onPressed: () => Navigator.of(context).pop(),
             icon: const Icon(Icons.check),
           ),
         ],
       ),
       body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (BuildContext context, MobileScannerException error) =>
                Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(Icons.no_photography_outlined, size: 44),
                    const SizedBox(height: 12),
                    Text(
                      error.errorCode.name == 'permissionDenied'
                          ? l10n.canScannerPermission
                          : l10n.canScannerUnavailable,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            overlayBuilder: (BuildContext context, BoxConstraints constraints) =>
                Center(
              child: Container(
                width: constraints.maxWidth * 0.72,
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 3),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          PositionedDirectional(
            start: 24,
            end: 24,
            bottom: 44,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.62),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    l10n.canScannerHint,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}